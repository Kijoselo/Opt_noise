function smooth_study_63218
% SMOOTH_STUDY_63218  Two-part study on the NACA63218 optima:
%   Stage 1 (fast): post-hoc smoothing of the existing optima's CST
%     coefficient distributions (blend levels lam = 0.25/0.5/1.0, endpoints
%     A1/A7 fixed to preserve LE radius and TE angle) + re-evaluation, to see
%     how much of the gain lives in the coefficient waviness.
%   Stage 2/3 (slow): re-optimization of both objectives (OASPL(A) and
%     un-weighted OASPL) with LINEAR SMOOTHNESS CONSTRAINTS
%     |A_i - A_{i+1}| <= 1.5 * max|diff(baseline coeffs)| per surface,
%     same nonlinear constraints and budget as before.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
t0 = tic;

P  = setup_problem('base', 'NACA63218.txt', 'write_legacy', false);
nu = P.ctx.nu;
R0 = eval_airfoil_cached(P.dv0, P.ctx);
fprintf('Baseline: OASPL(A)=%.3f | OASPL_lin=%.3f | Cl/Cd=%.2f | wav=%.4f\n\n', ...
        P.J0, R0.OASPL_lin, P.clcd0, waviness(P.dv0, nu));

dvA = dv_from_log('opt_NACA63218_full.log');    % A-weighted optimum
dvL = dv_from_log('opt_lin_NACA63218.log');     % un-weighted optimum

%% ---------- Stage 1: post-hoc smoothing ----------
fprintf('>>>>>>>> STAGE 1: post-hoc smoothing test\n');
fprintf('%-28s %6s  %8s %8s %7s %7s %8s  %s\n', 'candidate','lam','OASPL_A','OASPLlin','Cl/Cd','tmax','waviness','status');
cases = {dvA, 'optimo OASPL(A)'; dvL, 'optimo sin filtro A'};
for c = 1:2
    dv = cases{c,1};
    for lam = [0 0.25 0.5 1.0]
        dvs = blend_smooth(dv, lam, nu);
        R = eval_airfoil_cached(dvs, P.ctx);
        fprintf('%-28s %6.2f  %8.3f %8.3f %7.2f %7.4f %8.4f  %s\n', ...
            cases{c,2}, lam, R.OASPL_A, R.OASPL_lin, R.clcd, R.tmax, ...
            waviness(dvs, nu), R.status);
        if lam == 1.0 && R.valid
            [xs, ys] = cst_to_coords(dvs(1:nu), dvs(nu+1:end), ...
                P.ctx.yte_u, P.ctx.yte_l, P.ctx.npts, P.ctx.N1, P.ctx.N2);
            if c == 1, fn = 'smoothed_NACA63218_hardcon.dat'; else, fn = 'smoothed_NACA63218_lin.dat'; end
            write_airfoil_dat(fn, xs, ys);
            fprintf('    saved %s\n', fn);
        end
    end
end
fprintf('<<<<<<<< STAGE 1 done\n\n');

%% ---------- Linear smoothness constraints ----------
Au0 = P.dv0(1:nu); Al0 = P.dv0(nu+1:end);
du = 1.5*max(abs(diff(Au0)));  dl = 1.5*max(abs(diff(Al0)));
D = zeros(nu-1, nu);
for i = 1:nu-1, D(i,i) = 1; D(i,i+1) = -1; end
Alin = [blkdiag(D,D); -blkdiag(D,D)];
blin = [du*ones(nu-1,1); dl*ones(nu-1,1); du*ones(nu-1,1); dl*ones(nu-1,1)];
fprintf('Smoothness bounds: |dAu|<=%.4f, |dAl|<=%.4f\n', du, dl);
fprintf('Violations by current optima: A-weighted %d/24, lin %d/24\n\n', ...
        sum(Alin*dvA > blin + 1e-12), sum(Alin*dvL > blin + 1e-12));

opts = optimoptions('patternsearch','Display','iter', ...
    'MaxFunctionEvaluations', 2000, 'UseCompletePoll', true, 'MeshTolerance', 1e-4);
confun = @(dv) con_clcd(dv, P.ctx);

%% ---------- Stage 2: constrained re-opt, OASPL(A) ----------
fprintf('>>>>>>>> STAGE 2: smooth re-opt, objective OASPL(A)\n');
try
    dv2 = patternsearch(@(d) obj_noise_pure(d,P.ctx), P.dv0, Alin, blin, [],[], P.lb, P.ub, confun, opts);
    report_and_save(dv2, P, nu, 'optimized_NACA63218_smoothA.dat', R0);
catch ME, fprintf(2,'STAGE 2 FAILED: %s\n', ME.message); end

%% ---------- Stage 3: constrained re-opt, OASPL lin ----------
fprintf('\n>>>>>>>> STAGE 3: smooth re-opt, objective OASPL sin filtro\n');
try
    dv3 = patternsearch(@(d) obj_noise_lin(d,P.ctx), P.dv0, Alin, blin, [],[], P.lb, P.ub, confun, opts);
    report_and_save(dv3, P, nu, 'optimized_NACA63218_smoothLin.dat', R0);
catch ME, fprintf(2,'STAGE 3 FAILED: %s\n', ME.message); end

fprintf('\n=== SMOOTH STUDY COMPLETE in %.1f min ===\n', toc(t0)/60);
end

%% ================= helpers =================
function report_and_save(dv, P, nu, fname, R0)
R = eval_airfoil_cached(dv, P.ctx);
[xs, ys] = cst_to_coords(dv(1:nu), dv(nu+1:end), ...
    P.ctx.yte_u, P.ctx.yte_l, P.ctx.npts, P.ctx.N1, P.ctx.N2);
write_airfoil_dat(fname, xs, ys);
fprintf('  RESULT: OASPL(A) %.3f->%.3f (gain %.3f) | OASPL_lin %.3f->%.3f (gain %.3f)\n', ...
    P.J0, R.OASPL_A, P.J0-R.OASPL_A, R0.OASPL_lin, R.OASPL_lin, R0.OASPL_lin-R.OASPL_lin);
fprintf('  Cl/Cd %.2f | tmax %.4f | waviness %.4f | saved %s\n', ...
    R.clcd, R.tmax, waviness(dv, nu), fname);
end

function dv = dv_from_log(logfile)
txt = fileread(logfile);
k = strfind(txt, 'ans =');
assert(~isempty(k), 'no dv block found in %s', logfile);
v = sscanf(txt(k(end)+5:end), '%f');
assert(numel(v) >= 14, 'incomplete dv in %s', logfile);
dv = v(1:14);
end

function dvs = blend_smooth(dv, lam, nu)
Au = dv(1:nu); Al = dv(nu+1:end);
dvs = [(1-lam)*Au + lam*smooth7(Au); (1-lam)*Al + lam*smooth7(Al)];
end

function s = smooth7(a)
% 1-2-1 filter on interior coefficients; endpoints (LE radius, TE angle) fixed
s = a;
s(2:end-1) = 0.25*a(1:end-2) + 0.5*a(2:end-1) + 0.25*a(3:end);
end

function w = waviness(dv, nu)
Au = dv(1:nu); Al = dv(nu+1:end);
w = sum(abs(diff(Au,2))) + sum(abs(diff(Al,2)));
end
