function definitive_run
% DEFINITIVE_RUN  Paper-grade final runs for the two official coordinate files:
% budget-2000 single-objective optimisation (hard Cl/Cd), full diagnostic
% figure set, and a closing audit. NACA63221 is the manuscript case, so its
% legacy figure hooks refresh the generic manuscript figures on purpose.
% Every stage is guarded so one failure does not abort the batch.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace

files = {'NACA63221.txt', 'NACA63218.txt'};
t0 = tic;

for k = 1:numel(files)
    stage(sprintf('OPTIMISATION %s (budget 2000)', files{k}), ...
          @() run_optimization(2000, files{k}));
end

for k = 1:numel(files)
    f = files{k};
    case_id = erase(f, '.txt');
    optf = sprintf('optimized_%s_hardcon.dat', case_id);
    stage(['search domain ' f],   @() plot_search_domain(f, optf));
    stage(['silhouette var ' f],  @() silhouette_variation(f));
    stage(['mechanism ' f],       @() plot_mechanism(f));
    stage(['spectrum ' f],        @() regen_optimum_spectrum(f));
    stage(['BL table ' f],        @() boundary_layer_table(f));
end

stage('closing audit', @() audit_optimization(files));

fprintf('\n=== DEFINITIVE RUN COMPLETE in %.1f min ===\n', toc(t0)/60);
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
