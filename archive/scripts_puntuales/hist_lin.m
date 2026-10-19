cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise');
addpath('optim'); set_pub_defaults();
outdir = 'C:\Users\josea\Desktop\Opti_Param_ruidoio\entrega_pala_NACA63218';
% valores reales de opt_lin_NACA63218.log (patternsearch, budget 2000)
it   = [0 1 2 3]';
fc   = [1 4 1169 2000]';
f    = [69.0426 69.0426 66.2321 66.1668]';
mesh = [1 9.772e-3 9.55e-4 9.333e-5]';

figure('Color','w','Position',[50 50 1150 360]);
subplot(1,3,1);
plot(it, f, 'b.-', 'LineWidth', 1.8, 'MarkerSize', 14, 'HandleVisibility','off'); hold on;
plot(0, f(1), 'go', 'MarkerSize', 11, 'DisplayName','baseline');
plot(it(end), f(end), 'r*', 'MarkerSize', 14, 'DisplayName','optimo');
grid on; xlabel('Iteracion'); ylabel('OASPL sin filtro [dB]');
xticks(it); legend('Location','northeast');
text(0.03,0.1,'(a)','Units','normalized');
subplot(1,3,2);
plot(fc, f, 'b.-', 'LineWidth', 1.8, 'MarkerSize', 14);
grid on; xlabel('Evaluaciones de funcion'); ylabel('OASPL sin filtro [dB]');
text(0.03,0.1,'(b)','Units','normalized');
subplot(1,3,3);
semilogy(it, mesh, 'r.-', 'LineWidth', 1.8, 'MarkerSize', 14); hold on;
yline(1e-4, 'k--', 'tolerancia');
grid on; xlabel('Iteracion'); ylabel('Tamano de malla'); xticks(it);
text(0.03,0.1,'(c)','Units','normalized');
savefig300(gcf, fullfile(outdir,'fig_opt_history_sinfiltroA'), 17);
fprintf('saved fig_opt_history_sinfiltroA.png\n');
exit(0);
