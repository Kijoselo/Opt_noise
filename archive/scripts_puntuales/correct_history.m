cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise');
addpath('optim'); set_pub_defaults();
outdir = 'C:\Users\josea\Desktop\Opti_Param_ruidoio\entrega_pala_NACA63218';

% Actual data from opt_NACA63218_full.log
iter_num = [0, 1, 2, 3]';
func_count = [1, 8, 502, 771]';
f_val = [67.7934, 67.0183, 65.8115, 65.8115]';
mesh = [1, 0.009772, 0.000955, 9.333e-05]';

figure('Color','w','Position',[50 50 1200 380]);

subplot(1,3,1);
semilogy(iter_num, f_val, 'b.-', 'LineWidth', 2.5, 'MarkerSize', 10);
hold on;
plot(0, f_val(1), 'go', 'MarkerSize', 12, 'DisplayName', 'baseline');
plot(3, f_val(end), 'r*', 'MarkerSize', 18, 'DisplayName', 'óptimo');
grid on; xlabel('Iteración'); ylabel('OASPL(A) [dBA]');
legend('Location','best');
title('Convergencia (NACA63218)');
text(0.02, 0.97, '(a)', 'Units', 'normalized', 'VerticalAlignment', 'top');

subplot(1,3,2);
gain = f_val(1) - f_val;
semilogy(iter_num, gain + 1e-4, 'g.-', 'LineWidth', 2.5, 'MarkerSize', 10);
grid on; xlabel('Iteración'); ylabel('Mejora acumulada [dBA]');
title('Progreso');
text(0.02, 0.97, '(b)', 'Units', 'normalized', 'VerticalAlignment', 'top');

subplot(1,3,3);
loglog(func_count, 1 - gain/gain(end), 'r.-', 'LineWidth', 2.5, 'MarkerSize', 10);
grid on; xlabel('Evaluaciones de función (log)'); ylabel('Error residual [dBA, log]');
title('Convergencia vs evaluaciones');
text(0.02, 0.97, '(c)', 'Units', 'normalized', 'VerticalAlignment', 'top');

savefig300(gcf, fullfile(outdir, 'fig_optimization_history_correct'), 16);

fprintf('\n===== OPTIMIZATION HISTORY (NACA63218) =====\n');
fprintf('Iter  FuncCount    OASPL(A)   MeshSize    Gain(dBA)\n');
fprintf('----------------------------------------------------------\n');
for i = 1:numel(iter_num)
    fprintf('  %d      %4d      %.4f    %.2e      %.4f\n', iter_num(i), func_count(i), f_val(i), mesh(i), f_val(1)-f_val(i));
end
fprintf('\nFinal result: %.2f -> %.2f dBA (reduction: %.2f dBA)\n', f_val(1), f_val(end), f_val(1)-f_val(end));
fprintf('Total function evaluations: %d\n', func_count(end));
fprintf('Converged at iteration %d (mesh tolerance: %.2e)\n', iter_num(end), mesh(end));

exit(0);
