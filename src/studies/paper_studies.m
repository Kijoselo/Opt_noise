function paper_studies
% PAPER_STUDIES  Re-runs every manuscript study that depends on the base
% airfoil, now with the OFFICIAL NACA63221.txt coordinates, so all paper
% tables/figures are consistent with the definitive single-objective case:
%   1. compare_parameterizations  -> Table 1 (reconstruction errors)
%   2. sensitivity_analysis       -> Sec 3.2 spans + tornado figures
%   3. compare_algorithms(150)    -> Table 4 + penalized counts + figures
%   4. run_multiobjective(40,30)  -> Table 5 Pareto designs + figures
%   5. saturation runs +-30% / +-70% (budget 2000, same as headline run)
%   6. collect_figures            -> copy finals into paper/figures/
% Stages are guarded; check the log for STAGE OK/FAILED markers.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
t0 = tic;

stage('parameterizations (Table 1)', @() compare_parameterizations('NACA63221.txt'));
stage('sensitivity (Sec 3.2)',       @() sensitivity_analysis([], 'NACA63221.txt'));
stage('algorithms 150 (Table 4)',    @() compare_algorithms(150, 'NACA63221.txt'));
stage('multiobjective 40x30 (Table 5)', @() run_multiobjective(40, 30, 'NACA63221.txt'));
stage('saturation +-30% (budget 2000)', @() saturation_run(0.3, 2000));
stage('saturation +-70% (budget 2000)', @() saturation_run(0.7, 2000));
stage('collect figures',             @() collect_figures);

fprintf('\n=== PAPER STUDIES COMPLETE in %.1f min ===\n', toc(t0)/60);
end

function saturation_run(bw, budget)
% Same hard-Cl/Cd problem as the headline run, only the CST box width changes.
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
