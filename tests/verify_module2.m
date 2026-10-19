%% VERIFY_MODULE2
% Confirms that:
%  (1) evaluate_airfoil reproduces the OASPL(A) of the original pipeline on
%      the base profile perfil2.dat, and
%  (2) round-tripping the base through CST (fit -> coords -> .dat -> evaluate)
%      gives a noise level close to the original (validates the generator).
%
% xfoil.exe and the pipeline .m files live in the parent folder, so we run
% from there and add optim/ to the path.
clear; close all; clc;

rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>   % (reorganizacion) cwd = legacy_workspace

[fluid, inputs] = inputs_definition();

%% (1) baseline through the wrapper
fprintf('Evaluating base perfil2.dat ...\n');
[OASPL_A0, Cl0, Cd0] = evaluate_airfoil('perfil2.dat', inputs, fluid);
fprintf('  base   : OASPL(A) = %.3f dBA | Cl = %.4f | Cd = %.5f\n', OASPL_A0, Cl0, Cd0);
fprintf('  (compare against Spp_OASPL printed by Main_TE_noise_prediction)\n\n');

%% (2) CST round-trip
af = load_airfoil('perfil2.dat');
p  = cst_fit(af, 6);
[x, y] = cst_to_coords(p.Au, p.Al, p.yte_u, p.yte_l, 100);
write_airfoil_dat('cst_perfil2.dat', x, y);

fprintf('Evaluating CST-reconstructed airfoil ...\n');
[OASPL_Ac, Clc, Cdc] = evaluate_airfoil('cst_perfil2.dat', inputs, fluid);
fprintf('  CST    : OASPL(A) = %.3f dBA | Cl = %.4f | Cd = %.5f\n', OASPL_Ac, Clc, Cdc);

fprintf('\n  delta OASPL(A) = %.3f dBA   (should be small, < ~0.3 dBA)\n', OASPL_Ac - OASPL_A0);
fprintf('  delta Cl       = %.4f\n', Clc - Cl0);
fprintf('  delta Cd       = %.5f\n', Cdc - Cd0);
