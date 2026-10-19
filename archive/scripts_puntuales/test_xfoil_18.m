cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise');
addpath('optim');
[fluid, inputs] = inputs_definition();

% Test eval on baseline
fprintf('Testing XFOIL on NACA63218 baseline...\n');
try
    [OASPL, Cl, Cd, out] = evaluate_airfoil('cst_baseline_NACA63218.dat', inputs, fluid);
    fprintf('Success: OASPL=%.2f, Cl=%.4f, Cd=%.5f\n', OASPL, Cl, Cd);
catch ME
    fprintf('Error: %s\n', ME.message);
end

fprintf('Done.\n');
exit(0);
