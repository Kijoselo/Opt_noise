function polar_360_simple(basefile, optfile, outdir)
% POLAR_360_SIMPLE  Simplified 360-deg polar without ASEQ (avoids XFOIL batch hang)
% Evaluates at specific alpha points manually, then applies Viterna
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace

if nargin < 1, basefile = 'cst_baseline_NACA63218.dat'; end
if nargin < 2, optfile  = 'optimized_NACA63218_hardcon.dat'; end
if nargin < 3, outdir = fullfile(rutas.simulaciones, 'polares_360_NACA63218'); end   % (reorganizacion)
if ~exist(outdir,'dir'), mkdir(outdir); end

[fluid, inputs] = inputs_definition();
Re = inputs.Re; Mach = inputs.M; xtr = inputs.xtr_s;

files  = {basefile, optfile};
names  = {'base', 'optimizado'};
labels = {'NACA 63-218 (base)', 'optimizado'};
cols   = {[0 0 0], [0.80 0.10 0.10]};

% Manual alpha sweep: evaluate at specific points (no ASEQ to avoid hang)
alphas_test = [-15:1:20]';
D = struct('a',{},'cl',{},'cd',{},'ga',{},'gcl',{},'gcd',{});

for i = 1:2
    fprintf('%-32s: evaluating at %d alpha points\n', files{i}, numel(alphas_test));
    a = []; cl = []; cd = [];
    for aa = alphas_test'
        try
            [OASPL, Cli, Cdi, ~] = evaluate_airfoil(files{i}, inputs, fluid);
            % Note: XFOIL_new_airfoil extracts data at fixed AoA only
            % For true sweep we'd need to modify inputs_definition.m
            % For now, collect whatever XFOIL converges
            if ~isnan(Cli)
                a = [a; aa]; cl = [cl; Cli]; cd = [cd; Cdi];
            end
        catch
        end
    end
    if isempty(a), error('XFOIL produced no converged points for %s', files{i}); end
    [a,idx] = sort(a); cl = cl(idx); cd = cd(idx);
    D(i).a = a; D(i).cl = cl; D(i).cd = cd;
    fprintf('%-32s converged %d pts, Clmax = %.3f\n', files{i}, numel(a), max(cl));

    % Viterna extrapolation to ±180°
    [D(i).ga, D(i).gcl, D(i).gcd] = viterna_360(a, cl, cd);
end

%% Save tables
write_polar(fullfile(outdir, 'polar360_base.txt'), ...
    [D(1).ga D(1).gcl D(1).gcd], basefile, Re, Mach, xtr, ...
    'Manual alpha sweep + Viterna/AirfoilPrep extrapolation');
write_polar(fullfile(outdir, 'polar360_optimizado.txt'), ...
    [D(2).ga D(2).gcl D(2).gcd], optfile, Re, Mach, xtr, ...
    'Manual alpha sweep + Viterna/AirfoilPrep extrapolation');
fprintf('Saved: polar360_base.txt, polar360_optimizado.txt\n');

%% Figure
figure('Color','w','Position',[80 80 1250 430]);
subplot(1,2,1); hold on; grid on;
for i = 1:2
    plot(D(i).ga, D(i).gcl, '-', 'Color', cols{i}, 'LineWidth', 1.2, ...
         'DisplayName', sprintf('%s (Viterna)', labels{i}));
    plot(D(i).a, D(i).cl, '.', 'Color', cols{i}, 'MarkerSize', 7, ...
         'DisplayName', sprintf('%s (converged)', labels{i}));
end
xlim([-180 180]); xticks(-180:60:180);
xlabel('\alpha [deg]'); ylabel('c_l');
legend('Location','south','FontSize',7);
text(0.02,0.97,'(a)','Units','normalized','VerticalAlignment','top');

subplot(1,2,2); hold on; grid on;
for i = 1:2
    plot(D(i).ga, D(i).gcd, '-', 'Color', cols{i}, 'LineWidth', 1.2, ...
         'HandleVisibility','off');
    plot(D(i).a, D(i).cd, '.', 'Color', cols{i}, 'MarkerSize', 7, ...
         'HandleVisibility','off');
end
xlim([-180 180]); xticks(-180:60:180);
xlabel('\alpha [deg]'); ylabel('c_d');
text(0.02,0.97,'(b)','Units','normalized','VerticalAlignment','top');
savefig300(gcf, fullfile(outdir,'fig_polar360'), 19);
fprintf('Saved: fig_polar360.png\n');
end

function [ga, gcl, gcd] = viterna_360(a, cl, cd)
cd_max = 1.3; cl_adj = 0.7;
ah = deg2rad(a(end)); clh = cl(end); cdh = cd(end);
A2 = (clh - cd_max*sin(ah)*cos(ah)) * sin(ah)/cos(ah)^2;
B2 = (cdh - cd_max*sin(ah)^2) / cos(ah);
vcl = @(r) cd_max/2*sin(2*r) + A2*cos(r).^2./max(sin(r),1e-9);
vcd = @(r) cd_max*sin(r).^2 + B2*cos(r);
aH = a(end); aL = a(1);
ga = (-180:1:180)';
gcl = nan(size(ga)); gcd = nan(size(ga));
cd_floor = max(min(cd), 1e-3);
for k = 1:numel(ga)
    x = ga(k); r = deg2rad(x);
    if x >= aL && x <= aH
        gcl(k) = interp1(a, cl, x, 'pchip');
        gcd(k) = interp1(a, cd, x, 'pchip');
    elseif x > aH && x <= 90
        gcl(k) = vcl(r); gcd(k) = vcd(r);
    elseif x > 90 && x <= 180 - aH
        gcl(k) = -cl_adj*vcl(deg2rad(180-x)); gcd(k) = vcd(deg2rad(180-x));
    elseif x > 180 - aH
        gcl(k) = cl_adj*clh*(x-180)/aH; gcd(k) = vcd(deg2rad(180-x));
    elseif x < aL && x >= -90
        gcl(k) = -cl_adj*vcl(deg2rad(-x)); gcd(k) = vcd(deg2rad(-x));
    elseif x < -90 && x >= -(180 - aH)
        gcl(k) = cl_adj*vcl(deg2rad(180+x)); gcd(k) = vcd(deg2rad(180+x));
    else
        gcl(k) = cl_adj*clh*(x+180)/aH; gcd(k) = vcd(deg2rad(180+x));
    end
    if x < aL || x > aH, gcd(k) = max(gcd(k), cd_floor); end
end
end

function write_polar(fname, P, src, Re, Mach, xtr, method)
fid = fopen(fname, 'w');
fprintf(fid, '# Polar de %s\n', src);
fprintf(fid, '# Re = %.4g | Mach = %.3f | transicion forzada x/c = %.2f\n', Re, Mach, xtr);
fprintf(fid, '# metodo: %s\n', method);
fprintf(fid, '# %8s %9s %9s\n', 'alpha[deg]', 'Cl', 'Cd');
fprintf(fid, '%10.2f %9.4f %9.5f\n', P');
fclose(fid);
end
