cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise');
addpath('optim'); set_pub_defaults();
outdir = 'C:\Users\josea\Desktop\Opti_Param_ruidoio\entrega_pala_NACA63218';

% Geometry
base = dlmread('cst_baseline_NACA63218.dat');
opt = dlmread('optimized_NACA63218_hardcon.dat');

figure('Color','w','Position',[50 50 900 400]);
subplot(1,2,1);
plot(base(:,1), base(:,2), 'b-', 'LineWidth', 1.5, 'DisplayName', 'baseline');
hold on; plot(opt(:,1), opt(:,2), 'r--', 'LineWidth', 1.5, 'DisplayName', 'optimizado');
axis equal; grid on; xlabel('x/c'); ylabel('y/c');
legend('Location','best');
title('NACA 63-218: Geometría base vs optimizada');
text(0.02,0.97,'(a)','Units','normalized','VerticalAlignment','top');

% Polars
subplot(1,2,2);
P_base = readtable('polar_base_63218.txt', 'FileType', 'text', 'HeaderLines', 12);
a_base = P_base.Var1; cl_base = P_base.Var2; 
plot(a_base, cl_base, 'b.-', 'LineWidth', 1.5, 'DisplayName', 'baseline');
hold on;
P_opt = readtable('polar_opt_63218.txt', 'FileType', 'text', 'HeaderLines', 12);
a_opt = P_opt.Var1; cl_opt = P_opt.Var2;
plot(a_opt, cl_opt, 'r.-', 'LineWidth', 1.5, 'DisplayName', 'optimizado');
grid on; xlabel('\alpha [deg]'); ylabel('C_l');
legend; title('Sustentación XFOIL');
text(0.02,0.97,'(b)','Units','normalized','VerticalAlignment','top');
savefig300(gcf, fullfile(outdir, 'fig_geometria_aero'), 15);

fprintf('✓ fig_geometria_aero.png\n');
exit(0);
