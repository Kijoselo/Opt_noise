diary('polar_naca63218.log');
fprintf('=== Starting polar_360 for NACA63218 ===\n');
cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise');
addpath('optim');

try
    fprintf('Calling polar_360...\n');
    polar_360('cst_baseline_NACA63218.dat', 'optimized_NACA63218_hardcon.dat', ...
        'C:\Users\josea\Desktop\Opti_Param_ruidoio\entrega_pala_NACA63218');
    fprintf('polar_360 completed successfully.\n');
catch ME
    fprintf('ERROR in polar_360: %s\n', ME.message);
    fprintf('%s\n', ME.getReport);
end
diary off;
exit(0);
