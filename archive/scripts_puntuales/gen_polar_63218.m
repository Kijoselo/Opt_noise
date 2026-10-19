cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise');
addpath('optim');
set_pub_defaults();

% Read XFOIL polars (skip header, read from line 13 onwards)
fprintf('Reading XFOIL polars...\n');
P_base = readtable('polar_base_63218.txt', 'FileType', 'text', 'HeaderLines', 12);
P_opt  = readtable('polar_opt_63218.txt',  'FileType', 'text', 'HeaderLines', 12);

a_base = P_base.Var1; cl_base = P_base.Var2; cd_base = P_base.Var3;
a_opt  = P_opt.Var1;  cl_opt  = P_opt.Var2;  cd_opt  = P_opt.Var3;

fprintf('Base: %d pts, opt: %d pts\n', numel(a_base), numel(a_opt));

% Apply Viterna 360 extension
[ga_base, gcl_base, gcd_base] = viterna_360(a_base, cl_base, cd_base);
[ga_opt,  gcl_opt,  gcd_opt]   = viterna_360(a_opt,  cl_opt,  cd_opt);

% Write polar tables
outdir = 'C:\Users\josea\Desktop\Opti_Param_ruidoio\entrega_pala_NACA63218';
write_polar(fullfile(outdir, 'polar360_base.txt'), ...
    [ga_base gcl_base gcd_base], 'NACA63218', 3.166e6, 0.242, 0.05, ...
    'XFOIL + Viterna/AirfoilPrep extrapolation');
write_polar(fullfile(outdir, 'polar360_optimizado.txt'), ...
    [ga_opt gcl_opt gcd_opt], 'optimized_NACA63218', 3.166e6, 0.242, 0.05, ...
    'XFOIL + Viterna/AirfoilPrep extrapolation');

% Figure
figure('Color','w','Position',[80 80 1250 430]);
cols = {[0 0 0], [0.80 0.10 0.10]};
subplot(1,2,1); hold on; grid on;
plot(ga_base, gcl_base, '-', 'Color', cols{1}, 'LineWidth', 1.2, ...
     'DisplayName', 'NACA 63-218 (base) [Viterna]');
plot(a_base, cl_base, '.', 'Color', cols{1}, 'MarkerSize', 7, ...
     'DisplayName', 'NACA 63-218 (base) [XFOIL]');
plot(ga_opt, gcl_opt, '-', 'Color', cols{2}, 'LineWidth', 1.2, ...
     'DisplayName', 'optimizado [Viterna]');
plot(a_opt, cl_opt, '.', 'Color', cols{2}, 'MarkerSize', 7, ...
     'DisplayName', 'optimizado [XFOIL]');
xlim([-180 180]); xticks(-180:60:180);
xlabel('\alpha [deg]'); ylabel('c_l');
legend('Location','south','FontSize',7);
text(0.02,0.97,'(a)','Units','normalized','VerticalAlignment','top');

subplot(1,2,2); hold on; grid on;
plot(ga_base, gcd_base, '-', 'Color', cols{1}, 'LineWidth', 1.2);
plot(a_base, cd_base, '.', 'Color', cols{1}, 'MarkerSize', 7);
plot(ga_opt, gcd_opt, '-', 'Color', cols{2}, 'LineWidth', 1.2);
plot(a_opt, cd_opt, '.', 'Color', cols{2}, 'MarkerSize', 7);
xlim([-180 180]); xticks(-180:60:180);
xlabel('\alpha [deg]'); ylabel('c_d');
text(0.02,0.97,'(b)','Units','normalized','VerticalAlignment','top');
savefig300(gcf, fullfile(outdir,'fig_polar360'), 19);

fprintf('✓ polar360_base.txt\n✓ polar360_optimizado.txt\n✓ fig_polar360.png\nDone.\n');
exit(0);

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
        gcl(k) = interp1(a, cl, x, 'pchip'); gcd(k) = interp1(a, cd, x, 'pchip');
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
fprintf(fid, '# Re = %.4g | Mach = %.3f | transicion forzada x/c = %.2f (ambas caras)\n', Re, Mach, xtr);
fprintf(fid, '# N_crit de Tu = 0.07 (como el caso de ruido) | metodo: %s\n', method);
fprintf(fid, '# %8s %9s %9s\n', 'alpha[deg]', 'Cl', 'Cd');
fprintf(fid, '%10.2f %9.4f %9.5f\n', P');
fclose(fid);
end
