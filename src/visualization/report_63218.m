function report_63218
% REPORT_63218  Comprehensive visualization: geometry + aero + optimization history
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace

outdir = fullfile(rutas.exportaciones,'entregas_previas','entrega_pala_NACA63218')   % (reorganizacion);

% Load airfoils
base = load_airfoil('cst_baseline_NACA63218.dat');
opt  = load_airfoil('optimized_NACA63218_hardcon.dat');

%% ===== 1. GEOMETRY =====
fprintf('1. Generating geometry figure...\n');
figure('Color','w','Position',[50 50 900 400]);
subplot(1,2,1);
plot(base.xu, base.yu, 'b-', 'LineWidth', 1.5, 'DisplayName', 'baseline');
hold on; plot(base.xl, base.yl, 'b-', 'LineWidth', 1.5, 'HandleVisibility','off');
plot(opt.xu, opt.yu, 'r--', 'LineWidth', 1.5, 'DisplayName', 'optimizado');
plot(opt.xl, opt.yl, 'r--', 'LineWidth', 1.5, 'HandleVisibility','off');
axis equal; grid on; xlabel('x/c'); ylabel('y/c');
legend('Location','best');
title('NACA 63-218: Geometría'); text(0.02,0.97,'(a)','Units','normalized','VerticalAlignment','top');

% Thickness distribution
subplot(1,2,2);
xu = base.xu; yu = base.yu; yl = base.yl;
t_base = yu + abs(yl);
% For optimized: just use original coordinates without interpolation
t_opt = opt.yu(1:min(numel(opt.xu),numel(opt.xl))) + abs(opt.yl(1:min(numel(opt.xu),numel(opt.xl))));
x_opt = opt.xu(1:numel(t_opt));
plot(xu, t_base, 'b-', 'LineWidth', 1.5, 'DisplayName', 'baseline');
hold on; plot(x_opt, t_opt, 'r--', 'LineWidth', 1.5, 'DisplayName', 'optimizado');
grid on; xlabel('x/c'); ylabel('espesor t/c');
legend('Location','best');
title('Distribución de espesor');
text(0.02,0.97,'(b)','Units','normalized','VerticalAlignment','top');
savefig300(gcf, fullfile(outdir, 'fig_geometria'), 15);

%% ===== 2. AERODYNAMIC PERFORMANCE =====
fprintf('2. Generating aerodynamic figure...\n');
P_base = readtable('polar_base_63218.txt', 'FileType', 'text', 'HeaderLines', 12);
P_opt  = readtable('polar_opt_63218.txt',  'FileType', 'text', 'HeaderLines', 12);
a = P_base.Var1; cl_b = P_base.Var2; cd_b = P_base.Var3;
a_o = P_opt.Var1; cl_o = P_opt.Var2; cd_o = P_opt.Var3;

figure('Color','w','Position',[50 50 1100 400]);
subplot(1,3,1);
plot(a, cl_b, 'b.-', 'LineWidth', 1.5, 'DisplayName', 'baseline');
hold on; plot(a_o, cl_o, 'r.-', 'LineWidth', 1.5, 'DisplayName', 'optimizado');
grid on; xlabel('\alpha [deg]'); ylabel('C_l');
legend; title('Sustentación');
text(0.02,0.97,'(a)','Units','normalized','VerticalAlignment','top');

subplot(1,3,2);
semilogy(a, cd_b, 'b.-', 'LineWidth', 1.5, 'DisplayName', 'baseline');
hold on; semilogy(a_o, cd_o, 'r.-', 'LineWidth', 1.5, 'DisplayName', 'optimizado');
grid on; xlabel('\alpha [deg]'); ylabel('C_d (log)');
legend; title('Resistencia');
text(0.02,0.97,'(b)','Units','normalized','VerticalAlignment','top');

subplot(1,3,3);
l_d_b = cl_b ./ cd_b; l_d_o = cl_o ./ cd_o;
plot(a, l_d_b, 'b.-', 'LineWidth', 1.5, 'DisplayName', 'baseline');
hold on; plot(a_o, l_d_o, 'r.-', 'LineWidth', 1.5, 'DisplayName', 'optimizado');
grid on; xlabel('\alpha [deg]'); ylabel('C_l/C_d');
legend; title('Eficiencia (L/D)');
text(0.02,0.97,'(c)','Units','normalized','VerticalAlignment','top');
savefig300(gcf, fullfile(outdir, 'fig_aerodinamica'), 17);

%% ===== 3. OPTIMIZATION HISTORY =====
fprintf('3. Generating optimization history...\n');
% Parse opt_NACA63218_full.log
logfile = 'opt_NACA63218_full.log';
fid = fopen(logfile, 'r');
line = fgetl(fid);
iter_count = 0; f_hist = []; mesh_hist = [];
while ischar(line)
    if contains(line, 'Iter')
        % Skip header
        line = fgetl(fid);
        while ischar(line) && ~isempty(line)
            parts = strsplit(strtrim(line));
            if numel(parts) >= 3 && ~contains(parts{1}, 'Method')
                try
                    iter = str2double(parts{1});
                    f_val = str2double(parts{3});
                    if ~isnan(iter) && ~isnan(f_val)
                        iter_count = iter_count + 1;
                        f_hist = [f_hist; f_val];
                        if numel(parts) >= 4
                            mesh = str2double(parts{4});
                            if ~isnan(mesh)
                                mesh_hist = [mesh_hist; mesh];
                            end
                        end
                    end
                end
            end
            line = fgetl(fid);
        end
    else
        line = fgetl(fid);
    end
end
fclose(fid);

figure('Color','w','Position',[50 50 1100 400]);
if ~isempty(f_hist)
    subplot(1,3,1);
    semilogy(0:numel(f_hist)-1, f_hist, 'b.-', 'LineWidth', 1.5);
    hold on; plot(0, f_hist(1), 'go', 'MarkerSize', 10, 'DisplayName', 'baseline');
    plot(numel(f_hist)-1, f_hist(end), 'r*', 'MarkerSize', 15, 'DisplayName', 'optimizado');
    grid on; xlabel('Iteración'); ylabel('OASPL(A) [dBA]');
    legend; title('Convergencia del objetivo');
    text(0.02,0.97,'(a)','Units','normalized','VerticalAlignment','top');

    dba_gain = f_hist(1) - f_hist(end);
    pct_gain = 100 * (f_hist(1) - f_hist(end)) / f_hist(1);

    subplot(1,3,2);
    cumulative_gain = f_hist(1) - f_hist;
    semilogy(0:numel(cumulative_gain)-1, cumulative_gain + 1e-3, 'g.-', 'LineWidth', 1.5);
    grid on; xlabel('Iteración'); ylabel('Mejora acumulada [dBA]');
    title('Progreso de la optimización');
    text(0.02,0.97,'(b)','Units','normalized','VerticalAlignment','top');

    if ~isempty(mesh_hist)
        subplot(1,3,3);
        semilogy(0:numel(mesh_hist)-1, mesh_hist, 'r.-', 'LineWidth', 1.5);
        grid on; xlabel('Iteración'); ylabel('Tamaño de malla (log)');
        title('Convergencia de malla');
        text(0.02,0.97,'(c)','Units','normalized','VerticalAlignment','top');
    end

    savefig300(gcf, fullfile(outdir, 'fig_optimization_history'), 17);

    fprintf('\nOptimization Summary:\n');
    fprintf('  Baseline:    %.2f dBA\n', f_hist(1));
    fprintf('  Optimized:   %.2f dBA\n', f_hist(end));
    fprintf('  Gain:        %.2f dBA (%.1f%%)\n', dba_gain, pct_gain);
    fprintf('  Iterations:  %d\n', numel(f_hist));
else
    fprintf('Warning: Could not parse optimization history from log.\n');
end

fprintf('\nAll figures saved to: %s\n', outdir);
exit(0);
end

function a = load_airfoil(fname)
D = dlmread(fname);
n = numel(D(:,1));
n_upper = find(D(:,1) < 0.001 & D(:,2) < 0, 1, 'last');
a.xu = D(1:n_upper, 1);     a.yu = D(1:n_upper, 2);
a.xl = D(n_upper+1:end, 1); a.yl = D(n_upper+1:end, 2);
end
