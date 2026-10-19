function polar_360(basefile, optfile, outdir)
% POLAR_360  Full +-180 deg Cl/Cd polars for the baseline and optimized
% airfoils, for whole-blade (BEM/AeroDyn-style) simulation.
%
%   1. XFOIL sweep over the attached/lightly-stalled range (-20..+25 deg,
%      steps 0.5 deg, two marches from 0 deg for convergence), SAME conditions
%      as the noise case: Re, Mach from inputs_definition, forced transition
%      x/c = 0.05 both sides, N_crit from Tu = 0.07 (as XFOIL_new_airfoil).
%   2. Viterna extrapolation (AirfoilPrep-style, flat-plate CDmax = 1.3,
%      cl_adj = 0.7) to +-180 deg outside the converged XFOIL range.
%
% Outputs (written to OUTDIR):
%   polar360_base.txt / polar360_optimizado.txt   alpha, Cl, Cd  (-180..180)
%   xfoil_polar_base.txt / xfoil_polar_optimizado.txt  raw converged points
%   fig_polar360.png       Cl and Cd vs alpha, full range (data + Viterna)
%   fig_polar_zoom.png     zoom on the XFOIL range
%
% Uses the CST baseline (the real optimization reference) so both airfoils are
% headerless 199-pt files paneled identically.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace

if nargin < 1 || isempty(basefile), basefile = 'cst_baseline_NACA63221.dat'; end
if nargin < 2 || isempty(optfile),  optfile  = 'optimized_NACA63221_hardcon.dat'; end
if nargin < 3 || isempty(outdir)
    outdir = fullfile(rutas.simulaciones, 'polares_360_NACA63221');   % (reorganizacion)
end
if ~exist(outdir,'dir'), mkdir(outdir); end

[fluid, inputs] = inputs_definition();
Re = inputs.Re; Mach = inputs.M; xtr = inputs.xtr_s;
fprintf('Conditions: Re = %.3g, M = %.3f, xtr = %.2f (both sides)\n', Re, Mach, xtr);

files  = {basefile, optfile};
names  = {'base', 'optimizado'};
labels = {'NACA 63-221 (base)', 'optimizado'};
cols   = {[0 0 0], [0.80 0.10 0.10]};
D = struct('a',{},'cl',{},'cd',{},'ga',{},'gcl',{},'gcd',{});

for i = 1:2
    up = xfoil_sweep(files{i},  0,  25,  0.5, Re, Mach, xtr, sprintf('%s_up',names{i}));
    dn = xfoil_sweep(files{i}, -0.5, -20, -0.5, Re, Mach, xtr, sprintf('%s_dn',names{i}));
    P  = unique([dn; up], 'rows');            % [alpha cl cd], sorted by alpha
    if isempty(P), error('XFOIL produced no converged points for %s.', files{i}); end
    D(i).a = P(:,1); D(i).cl = P(:,2); D(i).cd = P(:,3);
    fprintf('%-32s converged %d pts, alpha in [%.1f, %.1f] deg, Clmax = %.3f\n', ...
            files{i}, numel(D(i).a), min(D(i).a), max(D(i).a), max(D(i).cl));

    [D(i).ga, D(i).gcl, D(i).gcd] = viterna_360(D(i).a, D(i).cl, D(i).cd);

    % data tables
    write_polar(fullfile(outdir, sprintf('xfoil_polar_%s.txt', names{i})), ...
        [D(i).a D(i).cl D(i).cd], files{i}, Re, Mach, xtr, 'XFOIL (converged points only)');
    write_polar(fullfile(outdir, sprintf('polar360_%s.txt', names{i})), ...
        [D(i).ga D(i).gcl D(i).gcd], files{i}, Re, Mach, xtr, ...
        'XFOIL + Viterna/AirfoilPrep extrapolation (CDmax=1.3, cl\_adj=0.7)');
end

%% ---- figure: full +-180 range ----
figure('Color','w','Position',[80 80 1250 430]);
subplot(1,2,1); hold on; grid on;
for i = 1:2
    plot(D(i).ga, D(i).gcl, '-', 'Color', cols{i}, 'LineWidth', 1.2, ...
         'DisplayName', sprintf('%s (Viterna)', labels{i}));
    plot(D(i).a, D(i).cl, '.', 'Color', cols{i}, 'MarkerSize', 7, ...
         'DisplayName', sprintf('%s (XFOIL)', labels{i}));
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

%% ---- figure: zoom on the XFOIL range ----
figure('Color','w','Position',[80 80 1250 430]);
subplot(1,2,1); hold on; grid on;
for i = 1:2
    plot(D(i).a, D(i).cl, '-o', 'Color', cols{i}, 'MarkerSize', 3, ...
         'LineWidth', 1.0, 'DisplayName', labels{i});
end
xlabel('\alpha [deg]'); ylabel('c_l'); xlim([-20 25]);
legend('Location','southeast','FontSize',8);
text(0.02,0.97,'(a)','Units','normalized','VerticalAlignment','top');

subplot(1,2,2); hold on; grid on;
for i = 1:2
    semilogy(D(i).a, D(i).cd, '-o', 'Color', cols{i}, 'MarkerSize', 3, ...
         'LineWidth', 1.0, 'HandleVisibility','off');
end
set(gca,'YScale','log');
xlabel('\alpha [deg]'); ylabel('c_d'); xlim([-20 25]);
text(0.02,0.97,'(b)','Units','normalized','VerticalAlignment','top');
savefig300(gcf, fullfile(outdir,'fig_polar_zoom'), 19);

fprintf('\nSaved in %s:\n  fig_polar360.png, fig_polar_zoom.png,\n', outdir);
fprintf('  polar360_base.txt, polar360_optimizado.txt (+ raw xfoil_polar_*.txt)\n');
end

%% ================= local functions =================
function P = xfoil_sweep(datfile, a0, a1, da, Re, Mach, xtr, tag)
% One PACC-accumulated ASEQ sweep. Returns [alpha cl cd] of converged points.
pol = sprintf('POLAR_SWEEP_%s.txt', tag);
for f = {pol, xfoil_out('POLAR_OUTPUT'), xfoil_out('doesntmatter')}
    if exist(f{1},'file'), delete(f{1}); end
end
Tu = 0.07; Ncrit = -8.43 - 2.4*log(Tu/100);

fid = fopen('xfoil_ifile.txt','w');
fprintf(fid,'PLOP\nG F\n\n');
fprintf(fid,'load\n%s\nnew\n', datfile);
fprintf(fid,'pane\n');
fprintf(fid,'\n\noper\n');
fprintf(fid,'visc\n%g\n', Re);
fprintf(fid,'mach %g\n', Mach);
fprintf(fid,'iter 200\n');
fprintf(fid,'vpar\nN %g\n\n', Ncrit);
fprintf(fid,'vpar\nxtr\n%g\n%g\n\n', xtr, xtr);
fprintf(fid,'pacc\n%s\n\n', pol);
fprintf(fid,'aseq %g %g %g\n', a0, a1, da);
fprintf(fid,'pacc\n');
fprintf(fid,'\nquit\n');
fclose(fid);

if exist('xfoil_stdout.txt','file'), delete('xfoil_stdout.txt'); end
ps = ['$p = Start-Process -FilePath ''.\xfoil.exe'' ' ...
      '-RedirectStandardInput ''xfoil_ifile.txt'' ' ...
      '-RedirectStandardOutput ''xfoil_stdout.txt'' -NoNewWindow -PassThru; ' ...
      'if (-not $p.WaitForExit(300000)) { Stop-Process -Id $p.Id -Force }'];
system(['powershell -NoProfile -ExecutionPolicy Bypass -Command "' ps '"']);

P = zeros(0,3);
if exist(pol,'file')
    try
        E = dlmread(pol, '', 12, 0);
        if ~isempty(E), P = E(:, 1:3); end
    catch
    end
    delete(pol);
end
end

function [ga, gcl, gcd] = viterna_360(a, cl, cd)
% AirfoilPrep-style extension of a measured polar to [-180, 180] deg.
% Viterna coefficients are anchored at the highest measured angle; the same
% coefficients (with cl_adj) shape the deep-stall and reversed-flow regions.
cd_max = 1.3;  cl_adj = 0.7;

ah  = deg2rad(a(end));  clh = cl(end);  cdh = cd(end);   % positive-side anchor
A2  = (clh - cd_max*sin(ah)*cos(ah)) * sin(ah)/cos(ah)^2;
B2  = (cdh - cd_max*sin(ah)^2) / cos(ah);
vcl = @(r) cd_max/2*sin(2*r) + A2*cos(r).^2./max(sin(r),1e-9);
vcd = @(r) cd_max*sin(r).^2 + B2*cos(r);

aH = a(end); aL = a(1);                                  % data limits (deg)
ga = (-180:1:180)';
gcl = nan(size(ga)); gcd = nan(size(ga));
cd_floor = max(min(cd), 1e-3);

for k = 1:numel(ga)
    x = ga(k); r = deg2rad(x);
    if x >= aL && x <= aH                                % measured range
        gcl(k) = interp1(a, cl, x, 'pchip');
        gcd(k) = interp1(a, cd, x, 'pchip');
    elseif x > aH && x <= 90                             % deep stall +
        gcl(k) = vcl(r);                gcd(k) = vcd(r);
    elseif x > 90 && x <= 180 - aH                       % reversed flow +
        gcl(k) = -cl_adj*vcl(deg2rad(180-x)); gcd(k) = vcd(deg2rad(180-x));
    elseif x > 180 - aH                                  % linear to 0 at 180
        gcl(k) = cl_adj*clh*(x-180)/aH; gcd(k) = vcd(deg2rad(180-x));
    elseif x < aL && x >= -90                            % deep stall -
        gcl(k) = -cl_adj*vcl(deg2rad(-x)); gcd(k) = vcd(deg2rad(-x));
    elseif x < -90 && x >= -(180 - aH)                   % reversed flow -
        gcl(k) = cl_adj*vcl(deg2rad(180+x)); gcd(k) = vcd(deg2rad(180+x));
    else                                                 % linear to 0 at -180
        gcl(k) = cl_adj*clh*(x+180)/aH; gcd(k) = vcd(deg2rad(180+x));
    end
    if x < aL || x > aH, gcd(k) = max(gcd(k), cd_floor); end
end
end

function write_polar(fname, P, src, Re, Mach, xtr, method)
fid = fopen(fname, 'w');
fprintf(fid, '# Polar de %s\n', src);
fprintf(fid, '# Re = %.4g | Mach = %.3f | transicion forzada x/c = %.2f (ambas caras)\n', Re, Mach, xtr);
fprintf(fid, '# N_crit de Tu = 0.07 (como el caso de ruido) | metodo: %s\n', method);
fprintf(fid, '# %8s %9s %9s\n', 'alpha[deg]', 'Cl', 'Cd');
fprintf(fid, '%10.2f %9.4f %9.5f\n', P');
fclose(fid);
end
