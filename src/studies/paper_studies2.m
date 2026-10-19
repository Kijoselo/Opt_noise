function paper_studies2
% PAPER_STUDIES2  Resume of paper_studies: the stages that had not finished
% when the previous batch was interrupted (multiobjective, saturation runs,
% figure collection). Table 1 / sensitivity / algorithms already completed.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
t0 = tic;

stage('multiobjective 40x30 (Table 5)', @() run_multiobjective(40, 30, 'NACA63221.txt'));
stage('saturation +-30% (budget 2000)', @() saturation_run(0.3, 2000));
stage('saturation +-70% (budget 2000)', @() saturation_run(0.7, 2000));
stage('collect figures',             @() collect_figures);

fprintf('\n=== PAPER STUDIES 2 COMPLETE in %.1f min ===\n', toc(t0)/60);
end

function saturation_run(bw, budget)
P = setup_problem('base', 'NACA63221.txt', 'bw_rel', bw, 'write_legacy', false);
opts = optimoptions('patternsearch', 'Display','off', ...
    'MaxFunctionEvaluations', budget, 'UseCompletePoll', true, 'MeshTolerance', 1e-4);
dv = patternsearch(@(d) obj_noise_pure(d, P.ctx), P.dv0, [],[],[],[], ...
                   P.lb, P.ub, @(d) con_clcd(d, P.ctx), opts);
R = eval_airfoil_cached(dv, P.ctx);
fprintf('\n  SATURATION bw=+-%.0f%%: %.3f -> %.3f dBA (gain %.3f) | Cl/Cd %.2f | tmax %.4f\n', ...
        100*bw, P.J0, R.OASPL_A, P.J0 - R.OASPL_A, R.clcd, R.tmax);
end

function stage(name, fn)
fprintf('\n>>>>>>>> STAGE: %s\n', name);
try
    fn();
    fprintf('<<<<<<<< STAGE OK: %s\n', name);
catch ME
    fprintf(2, '<<<<<<<< STAGE FAILED: %s -- %s\n', name, ME.message);
end
end
