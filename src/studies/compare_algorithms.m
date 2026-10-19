%% COMPARE_ALGORITHMS
% Benchmark several optimisation algorithms on the SAME problem:
% minimise OASPL(A) with a Cl/Cd >= baseline penalty (penalty method keeps the
% formulation identical for solvers that do not support nonlinear constraints).
%
% Algorithm group (derivative-free global + surrogate + gradient baseline)
% reflects what the aerodynamic-shape / aeroacoustic optimisation literature
% uses for expensive (XFOIL/CFD-in-the-loop) objectives:
%   - Genetic Algorithm (ga)            : population-based global
%   - Particle Swarm (particleswarm)    : swarm-based global
%   - Pattern Search (patternsearch)    : direct/derivative-free local-global
%   - Surrogate Optimization (surrogateopt) : Bayesian/Kriging, expensive-fn
%   - SQP (fmincon)                     : gradient-based baseline
%
% Produces, for the article:
%   fig_algo_convergence.png   best-so-far feasible OASPL vs #evaluations
%   fig_algo_exploration.png   every evaluated design (OASPL vs Cl/Cd)
%   fig_algo_silhouettes.png   best silhouette from each algorithm
% Usage:  compare_algorithms                  (default case/budget)
%         results = compare_algorithms(150)
%         results = compare_algorithms('NACA63218.txt', 150)
%         results = compare_algorithms(150, 'NACA63218.txt')
function results = compare_algorithms(varargin)
[budget, basefile] = parse_inputs(varargin{:});
close all; set_pub_defaults(); rng(0);

P = setup_problem('base', basefile, 'write_legacy', false);
objfun = @(dv) obj_noise(dv, P.ctx);
n = numel(P.dv0);

fprintf('Case: %s (%s)\n', P.case_id, P.base_file);
fprintf('Baseline OASPL(A) = %.3f dBA, Cl/Cd = %.2f\n', P.J0, P.clcd0);
fprintf('Budget = %d evaluations per algorithm.\n\n', budget);

% Each entry: name + a runner returning dv_best (or [] on failure).
% column 1: formal display name (figures/tables); column 2: runner
algos = {
  'GA',   @() run_ga(objfun, n, P, budget)
  'PSO',  @() run_pso(objfun, n, P, budget)
  'PS',   @() run_ps(objfun, P, budget)
  'SBO',  @() run_surr(objfun, P, budget)
  'SQP',  @() run_sqp(objfun, P, budget)
};

results = struct('name',{},'dv',{},'OASPL',{},'clcd',{},'nev',{},'conv',{},'logres',{});

for a = 1:size(algos,1)
    name = algos{a,1};
    fprintf('--- %s ---\n', name);
    eval_airfoil_cached('reset');               % isolate this algorithm's log
    eval_airfoil_cached(P.dv0, P.ctx);          % seed cache with baseline
    try
        dv = algos{a,2}();
    catch ME
        fprintf('  skipped (%s)\n\n', ME.message);
        continue;
    end
    if isempty(dv), fprintf('  no result\n\n'); continue; end
    L = eval_airfoil_cached('log');
    R = eval_airfoil_cached(dv, P.ctx);
    conv = bestsofar(L.res, P.ctx.clcd_min);
    k = numel(results)+1;
    results(k) = struct('name',name,'dv',dv,'OASPL',R.OASPL_A,'clcd',R.clcd, ...
                        'nev',size(L.res,1),'conv',conv,'logres',L.res);
    fprintf('  best OASPL(A) = %.3f dBA | Cl/Cd = %.2f | evals = %d\n\n', ...
            R.OASPL_A, R.clcd, size(L.res,1));
end

%% --- summary table (incl. penalized = invalid geometry or XFOIL fail) ---
fprintf('%-28s %10s %8s %8s %10s\n','Algorithm','OASPL(A)','c_l/c_d','#eval','#penalized');
fprintf('%s\n', repmat('-',1,66));
for k = 1:numel(results)
    npen = nnz(results(k).logres(:,5)==0);
    fprintf('%-28s %10.3f %8.2f %8d %10d\n', results(k).name, ...
            results(k).OASPL, results(k).clcd, results(k).nev, npen);
end

%% --- convergence figure ---
co=get(groot,'defaultAxesColorOrder'); cmap=co(1:max(1,numel(results)),:);
figure('Color','w'); hold on; grid on;
for k = 1:numel(results)
    plot(1:numel(results(k).conv), results(k).conv, '-', ...
        'Color',cmap(k,:), 'DisplayName',results(k).name);
end
yb = yline(P.J0,'k--'); set(yb,'HandleVisibility','off');   % keep out of legend
text(3, P.J0, ' baseline', 'VerticalAlignment','bottom', 'FontSize',8);
xlabel('Function evaluations'); ylabel('Best feasible OASPL(A) [dBA]');
title('Algorithm convergence'); legend('Location','northeast');
savefig300(gcf, 'fig_algo_convergence');

%% --- exploration scatter (every design that passed through an optimiser) ---
figure('Color','w'); hold on; grid on;
for k = 1:numel(results)
    res = results(k).logres;
    ok = res(:,5)==1;
    scatter(res(ok,1), res(ok,2), 18, cmap(k,:), 'filled', ...
        'MarkerFaceAlpha',0.5, 'DisplayName',results(k).name);
end
plot(P.J0, P.clcd0, 'ks', 'MarkerSize',9, 'MarkerFaceColor','w', ...
     'LineWidth',1.2, 'DisplayName','Baseline');
yb = yline(P.clcd0,'k:'); set(yb,'HandleVisibility','off');   % keep out of legend
xlabel('OASPL(A) [dBA]'); ylabel('c_l / c_d');
title('Designs explored by the optimisers'); legend('Location','northeast');
% Focus on the productive cloud; a few discarded designs lie at higher OASPL.
allres = vertcat(results.logres); okall = allres(:,5)==1;
xhi = min(95, prctile(allres(okall,1), 97));
xlim([floor(min(allres(okall,1)))-1, max(72, xhi)]);
xl = xlim; text(xl(1)+0.02*diff(xl), P.clcd0, ' c_l/c_d floor', ...
                'VerticalAlignment','bottom', 'FontSize',8);
savefig300(gcf, 'fig_algo_exploration');

%% --- best silhouettes ---
nu = P.ctx.nu;
figure('Color','w'); hold on; axis equal; grid on;
plot(P.af.x, P.af.y, 'k-', 'LineWidth',1.5, 'DisplayName','baseline');
for k = 1:numel(results)
    dv = results(k).dv;
    [xx, yy] = cst_to_coords(dv(1:nu), dv(nu+1:end), ...
                             P.ctx.yte_u, P.ctx.yte_l, P.ctx.npts, P.ctx.N1, P.ctx.N2);
    plot(xx, yy, '-', 'Color',cmap(k,:), ...
        'DisplayName',sprintf('%s (%.2f dBA)',results(k).name,results(k).OASPL));
end
xlabel('x/c'); ylabel('y/c'); title('Optimised silhouettes by algorithm');
legend('Location','best');
savefig300(gcf, 'fig_algo_silhouettes');
end

function [budget, basefile] = parse_inputs(varargin)
budget = 250;
basefile = 'NACA63221.txt';
if nargin == 0, return; end
if nargin == 1
    if isnumeric(varargin{1})
        budget = varargin{1};
    else
        basefile = char(varargin{1});
    end
    return;
end
if isnumeric(varargin{1})
    budget = varargin{1};
    basefile = char(varargin{2});
else
    basefile = char(varargin{1});
    budget = varargin{2};
end
end

%% ===== algorithm runners (equal budget) =====
function dv = run_ga(objfun, n, P, budget)
pop = 30; gen = max(1, floor(budget/pop));
o = optimoptions('ga','Display','off','PopulationSize',pop, ...
    'MaxGenerations',gen,'InitialPopulationMatrix',P.dv0');
dv = ga(objfun, n, [],[],[],[], P.lb, P.ub, [], o); dv = dv(:);
end

function dv = run_pso(objfun, n, P, budget)
sw = 30; it = max(1, floor(budget/sw));
o = optimoptions('particleswarm','Display','off','SwarmSize',sw, ...
    'MaxIterations',it,'InitialSwarmMatrix',P.dv0');
dv = particleswarm(objfun, n, P.lb, P.ub, o); dv = dv(:);
end

function dv = run_ps(objfun, P, budget)
o = optimoptions('patternsearch','Display','off', ...
    'MaxFunctionEvaluations',budget,'UseCompletePoll',true,'MeshTolerance',1e-4);
dv = patternsearch(objfun, P.dv0, [],[],[],[], P.lb, P.ub, [], o); dv = dv(:);
end

function dv = run_surr(objfun, P, budget)
o = optimoptions('surrogateopt','Display','off', ...
    'MaxFunctionEvaluations',budget,'InitialPoints',P.dv0');
dv = surrogateopt(objfun, P.lb, P.ub, o); dv = dv(:);
end

function dv = run_sqp(objfun, P, budget)
o = optimoptions('fmincon','Display','off','Algorithm','sqp', ...
    'MaxFunctionEvaluations',budget,'FiniteDifferenceStepSize',1e-3);
dv = fmincon(objfun, P.dv0, [],[],[],[], P.lb, P.ub, [], o); dv = dv(:);
end

%% ===== best-so-far feasible OASPL from an evaluation log =====
function c = bestsofar(res, clcd_min)
% res columns: [OASPL, clcd, Cl, Cd, valid]
feas = res(:,5)==1 & res(:,2) >= clcd_min;
o = res(:,1);
c = inf(size(o)); cur = inf;
for i = 1:numel(o)
    if feas(i) && o(i) < cur, cur = o(i); end
    c(i) = cur;
end
end
