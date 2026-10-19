function aoa_best = find_best_aoa()
% FIND_BEST_AOA  Sweep the angle of attack for the NACA 63-221 baseline at the
% new operating conditions (U=83.31 m/s, c=0.57 m) and report the angle of
% maximum lift-to-drag ratio --- the natural design point of a wind-turbine
% blade section. Uses the same fixed transition as the noise study (x/c=0.05).
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
[fluid, ~] = inputs_definition();

file  = 'NACA63221.txt';
U     = 83.31;  chord = 0.57;  xtr = 0.05;  Mic = 0.99;
Re    = chord*U/fluid.ni;
M     = U/fluid.c0;

aoas = 0:1:12;
Cl = nan(size(aoas));  Cd = nan(size(aoas));
for i = 1:numel(aoas)
    try
        [~,~,~,~,~,~,~,~,~,~,~,~,cli,cdi] = XFOIL_new_airfoil( ...
            file, aoas(i), Re, M, xtr, xtr, chord, Mic, file);
        Cl(i) = cli;  Cd(i) = cdi;
    catch ME
        fprintf('  AoA %.1f failed (%s)\n', aoas(i), ME.message);
    end
end
LD = Cl./Cd;
[bestLD, ib] = max(LD);  aoa_best = aoas(ib);

fprintf('\n  NACA 63-221  |  Re = %.2e  M = %.3f  transition x/c = %.2f\n', Re, M, xtr);
fprintf('  %5s %8s %9s %9s\n','AoA','Cl','Cd','Cl/Cd');
fprintf('  %s\n', repmat('-',1,34));
for i = 1:numel(aoas)
    fprintf('  %5.1f %8.4f %9.5f %9.2f\n', aoas(i), Cl(i), Cd(i), LD(i));
end
fprintf('\n  >> Best L/D = %.2f at AoA = %.1f deg  (recommended design point)\n\n', ...
        bestLD, aoa_best);

figure('Color','w'); plot(aoas, LD, '-o','LineWidth',1.2); grid on; hold on;
plot(aoa_best, bestLD, 'rs','MarkerSize',10,'MarkerFaceColor','r');
xlabel('Angle of attack [deg]'); ylabel('c_l / c_d');
title(sprintf('NACA 63-221, Re=%.1e: best L/D at AoA=%.1f deg', Re, aoa_best));
end
