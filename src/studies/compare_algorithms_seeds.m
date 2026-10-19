function S = compare_algorithms_seeds(nseed, budget, basefile)
% COMPARE_ALGORITHMS_SEEDS  Repeatability study for the stochastic optimizers.
% Runs GA, PSO and surrogate optimization with NSEED independent random seeds
% and reports the mean and standard deviation of the best OASPL(A) found, so the
% reproducibility claim in the manuscript can be backed by numbers. Pattern
% search and SQP are deterministic and are not repeated.
%
% Cost: nseed * 3 * budget XFOIL evaluations -> keep budget modest.
%   compare_algorithms_seeds            % 5 seeds, budget 100
%   compare_algorithms_seeds(10, 150)
%   compare_algorithms_seeds(10, 150, 'NACA63218.txt')
if nargin < 1 || isempty(nseed),  nseed  = 5;   end
if nargin < 2 || isempty(budget), budget = 100; end
if nargin < 3 || isempty(basefile), basefile = 'NACA63221.txt'; end
close all; set_pub_defaults();

P = setup_problem('base', basefile, 'write_legacy', false);
objfun = @(dv) obj_noise(dv, P.ctx);
n = numel(P.dv0);
algos = {'ga','particleswarm','surrogateopt'};
best  = nan(numel(algos), nseed);

fprintf('Repeatability study: %d seeds x %d algorithms, budget %d\n\n', ...
        nseed, numel(algos), budget);
for s = 1:nseed
    for a = 1:numel(algos)
        eval_airfoil_cached('reset');
        eval_airfoil_cached(P.dv0, P.ctx);     % seed cache with baseline
        rng(s);                                % control the stochastic search
        dv = run_one(algos{a}, objfun, n, P, budget);
        R  = eval_airfoil_cached(dv, P.ctx);
        best(a,s) = R.OASPL_A;
        fprintf('  seed %d  %-14s -> %.3f dBA\n', s, algos{a}, R.OASPL_A);
    end
end

fprintf('\n%-16s %9s %9s %9s\n','Algorithm','mean','std','min');
fprintf('%s\n', repmat('-',1,46));
for a = 1:numel(algos)
    fprintf('%-16s %9.3f %9.3f %9.3f\n', algos{a}, ...
            mean(best(a,:)), std(best(a,:)), min(best(a,:)));
end
fprintf('\nUse the largest std above to fill the reproducibility sentence.\n');
S = struct('algos',{algos}, 'best',best, ...
           'mean',mean(best,2), 'std',std(best,0,2));
end

function dv = run_one(name, objfun, n, P, budget)
switch name
    case 'ga'
        pop = 30; gen = max(1, floor(budget/pop));
        o = optimoptions('ga','Display','off','PopulationSize',pop, ...
            'MaxGenerations',gen,'InitialPopulationMatrix',P.dv0');
        dv = ga(objfun, n, [],[],[],[], P.lb, P.ub, [], o);
    case 'particleswarm'
        sw = 30; it = max(1, floor(budget/sw));
        o = optimoptions('particleswarm','Display','off','SwarmSize',sw, ...
            'MaxIterations',it,'InitialSwarmMatrix',P.dv0');
        dv = particleswarm(objfun, n, P.lb, P.ub, o);
    case 'surrogateopt'
        o = optimoptions('surrogateopt','Display','off', ...
            'MaxFunctionEvaluations',budget,'InitialPoints',P.dv0');
        dv = surrogateopt(objfun, P.lb, P.ub, o);
end
dv = dv(:);
end
