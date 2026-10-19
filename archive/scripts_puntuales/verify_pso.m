cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise');
addpath('optim');
P = setup_problem('base','NACA63221.txt','write_legacy',false);
n = numel(P.dv0);
fprintf('Baseline: OASPL(A)=%.3f | Cl/Cd=%.4f (hard floor)\n', P.J0, P.ctx.clcd_min);

% reproduce seed 4 particleswarm exactly as compare_algorithms_seeds does
eval_airfoil_cached('reset'); eval_airfoil_cached(P.dv0, P.ctx);
rng(4);
sw = 30; it = max(1, floor(150/sw));
o = optimoptions('particleswarm','Display','off','SwarmSize',sw, ...
    'MaxIterations',it,'InitialSwarmMatrix',P.dv0');
dv = particleswarm(@(d) obj_noise(d,P.ctx), n, P.lb, P.ub, o);
R = eval_airfoil_cached(dv, P.ctx);

fprintf('\n=== PSO seed 4 candidate ===\n');
fprintf('  OASPL(A) raw      = %.3f dBA\n', R.OASPL_A);
fprintf('  penalized obj J   = %.3f\n', obj_noise(dv,P.ctx));
fprintf('  Cl/Cd             = %.4f   (floor %.4f)  -> %s\n', R.clcd, P.ctx.clcd_min, ...
        ternary(R.clcd >= P.ctx.clcd_min,'FEASIBLE','**INFEASIBLE**'));
fprintf('  Cl=%.4f Cd=%.5f tmax=%.4f (cap %.4f)\n', R.Cl, R.Cd, R.tmax, P.ctx.T0);
fprintf('  valid flag=%d status=%s\n', R.valid, R.status);
save('pso_seed4.mat','dv','R');
% write geometry for inspection
[xo,yo] = cst_to_coords(dv(1:P.ctx.nu), dv(P.ctx.nu+1:end), ...
                        P.ctx.yte_u, P.ctx.yte_l, P.ctx.npts, P.ctx.N1, P.ctx.N2);
write_airfoil_dat('pso_seed4_candidate.dat', xo, yo);
fprintf('  saved pso_seed4_candidate.dat\n');
exit(0);
function s = ternary(c,a,b), if c, s=a; else, s=b; end, end
