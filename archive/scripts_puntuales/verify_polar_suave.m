% VERIFY_POLAR_SUAVE  Post-process XFOIL CLI sweeps of the smooth optima:
% coherence checks + Viterna 360 tables + comparison figures.
cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise');
addpath('optim'); set_pub_defaults();
outdir = 'C:\Users\josea\Desktop\Opti_Param_ruidoio\entrega_pala_NACA63218';

names = {'baseline','suaveA','suaveLin'};
pfiles = {{'polar_base_63218.txt'}, ...
          {'polar_suaveA_up.txt','polar_suaveA_dn.txt'}, ...
          {'polar_suaveLin_up.txt','polar_suaveLin_dn.txt'}};
lbl = {'baseline (18%)','opt. suave A','opt. suave lin'};
col = {[0 0 0],[0.85 0.1 0.1],[0 0.35 0.85]};
% reference values from the noise chain (clean evaluations)
ref_clcd = [60.09, 60.15, 61.42];
ref_cl4  = [0.6448, NaN, NaN];

P = cell(1,3);
fprintf('\n===== VERIFICACION DE COHERENCIA (XFOIL polar vs cadena de ruido) =====\n');
fprintf('%-14s %7s %8s %7s %9s %8s %7s %7s %8s %8s\n', ...
  'perfil','Cl@4','Cd@4','ClCd@4','ref ClCd','dCl/da','Clmax','a_stall','Cm@4','rango');
for i = 1:3
    E = [];
    for q = 1:numel(pfiles{i})
        try
            Eq = dlmread(pfiles{i}{q}, '', 12, 0);   % a Cl Cd Cdp Cm ...
            if ~isempty(Eq), E = [E; Eq]; end
        catch
            fprintf('  [aviso] polar vacio o ilegible: %s\n', pfiles{i}{q});
        end
    end
    assert(~isempty(E), 'sin puntos convergidos para %s', names{i});
    E = sortrows(unique(E, 'rows'), 1);
    P{i} = E;
    a = E(:,1); cl = E(:,2); cd = E(:,3); cm = E(:,5);
    cl4  = interp1(a, cl, 4, 'pchip');  cd4 = interp1(a, cd, 4, 'pchip');
    cm4  = interp1(a, cm, 4, 'pchip');
    m = a >= -2 & a <= 6;                        % lift slope, linear range
    pp = polyfit(a(m), cl(m), 1);
    [clmax, im] = max(cl);
    fprintf('%-14s %7.4f %8.5f %7.2f %9.2f %8.4f %7.3f %7.1f %8.4f  [%g,%g]\n', ...
        names{i}, cl4, cd4, cl4/cd4, ref_clcd(i), pp(1), clmax, a(im), cm4, min(a), max(a));
end
fprintf('Nota: dCl/da teorico (placa delgada) = 0.110/deg; XFOIL viscoso tipico 0.10-0.12.\n');
fprintf('Cross-check Cl@4 baseline cadena de ruido: %.4f\n\n', ref_cl4(1));

%% Figura de verificacion (rango XFOIL): Cl, Cd, Cl/Cd, Cm
figure('Color','w','Position',[30 30 1100 640]);
panels = {@(E) E(:,2), @(E) E(:,3), @(E) E(:,2)./E(:,3), @(E) E(:,5)};
ylabs = {'c_l','c_d','c_l/c_d','c_m'};
for k = 1:4
    subplot(2,2,k); hold on; grid on;
    for i = 1:3
        plot(P{i}(:,1), panels{k}(P{i}), '.-', 'Color', col{i}, ...
             'LineWidth', 1.1, 'MarkerSize', 6, 'DisplayName', lbl{i});
    end
    xlabel('\alpha [deg]'); ylabel(ylabs{k});
    if k == 2, set(gca,'YScale','log'); end
    if k == 1, legend('Location','southeast','FontSize',7); end
    if k == 3, xline(4,'k:','HandleVisibility','off'); end
    text(0.03,0.94,sprintf('(%c)','a'+k-1),'Units','normalized');
end
savefig300(gcf, fullfile(outdir,'fig_polar_verificacion_suaves'), 17);

%% Viterna 360 + tablas + figura completa
figure('Color','w','Position',[30 30 1250 430]);
for i = 1:3
    a = P{i}(:,1); cl = P{i}(:,2); cd = P{i}(:,3);
    [ga, gcl, gcd] = viterna_360(a, cl, cd);
    if i == 1, fn = 'polar360_base.txt';
    elseif i == 2, fn = 'polar360_optimizado_suaveA.txt';
    else, fn = 'polar360_optimizado_suaveLin.txt'; end
    fid = fopen(fullfile(outdir, fn), 'w');
    fprintf(fid, '# Polar de %s\n', lbl{i});
    fprintf(fid, '# Re = 3.166e6 | Mach = 0.242 | xtr = 0.05 ambas caras | N_crit = 8.9\n');
    fprintf(fid, '# XFOIL (puntos convergidos) + extrapolacion Viterna/AirfoilPrep (CDmax=1.3)\n');
    fprintf(fid, '# %8s %9s %9s\n', 'alpha[deg]', 'Cl', 'Cd');
    fprintf(fid, '%10.2f %9.4f %9.5f\n', [ga gcl gcd]');
    fclose(fid);
    subplot(1,2,1); hold on; grid on;
    plot(ga, gcl, '-', 'Color', col{i}, 'LineWidth', 1.1, 'DisplayName', lbl{i});
    plot(a, cl, '.', 'Color', col{i}, 'MarkerSize', 6, 'HandleVisibility','off');
    subplot(1,2,2); hold on; grid on;
    plot(ga, gcd, '-', 'Color', col{i}, 'LineWidth', 1.1, 'HandleVisibility','off');
    plot(a, cd, '.', 'Color', col{i}, 'MarkerSize', 6, 'HandleVisibility','off');
end
subplot(1,2,1); xlim([-180 180]); xticks(-180:60:180);
xlabel('\alpha [deg]'); ylabel('c_l'); legend('Location','south','FontSize',7);
text(0.02,0.97,'(a)','Units','normalized','VerticalAlignment','top');
subplot(1,2,2); xlim([-180 180]); xticks(-180:60:180);
xlabel('\alpha [deg]'); ylabel('c_d');
text(0.02,0.97,'(b)','Units','normalized','VerticalAlignment','top');
savefig300(gcf, fullfile(outdir,'fig_polar360_suaves'), 19);

fprintf('Saved: polar360_base/optimizado_suaveA/optimizado_suaveLin.txt + 2 figuras\n');
exit(0);

function [ga, gcl, gcd] = viterna_360(a, cl, cd)
cd_max = 1.3; cl_adj = 0.7;
ah = deg2rad(a(end)); clh = cl(end); cdh = cd(end);
A2 = (clh - cd_max*sin(ah)*cos(ah)) * sin(ah)/cos(ah)^2;
B2 = (cdh - cd_max*sin(ah)^2) / cos(ah);
vcl = @(r) cd_max/2*sin(2*r) + A2*cos(r).^2./max(sin(r),1e-9);
vcd = @(r) cd_max*sin(r).^2 + B2*cos(r);
aH = a(end); aL = a(1);
ga = (-180:1:180)'; gcl = nan(size(ga)); gcd = nan(size(ga));
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
