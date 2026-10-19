%% COMPARE_PARAMETERIZATIONS
% Module 1: justify the choice of airfoil parameterization.
% Fits CST, PARSEC and Hicks-Henne to the base profile and compares how
% faithfully each one reconstructs it, plus the size of its design space.
%
% Usage:  compare_parameterizations
%         compare_parameterizations('NACA63218.txt')
function compare_parameterizations(base_file)
close all; set_pub_defaults(); PAL=pub_colors();

%% --- settings ---
proyecto_init();                                   % rutas del proyecto
if nargin < 1 || isempty(base_file), base_file = 'NACA63221.txt'; end
base_file = buscar_perfil(base_file);
cst_order = 6;                  % Bernstein order per surface for CST

%% --- load base airfoil ---
af = load_airfoil(base_file);

%% --- fit each parameterization ---
pc = cst_fit(af, cst_order);
yu_cst = cst_eval(af.xu, pc.Au, pc.yte_u, pc.N1, pc.N2);
yl_cst = cst_eval(af.xl, pc.Al, pc.yte_l, pc.N1, pc.N2);

pp = parsec_fit(af);
yu_par  = parsec_eval(af.xu, pp.au);       % classic geometric constraints
yl_par  = parsec_eval(af.xl, pp.al);
yu_parL = parsec_eval(af.xu, pp.au_lsq);   % least-squares on PARSEC basis
yl_parL = parsec_eval(af.xl, pp.al_lsq);

ph = hh_fit(af);
yu_hh = hh_eval(af.xu, ph.au, ph.xk, ph.width, false);
yl_hh = hh_eval(af.xl, ph.al, ph.xk, ph.width, true);

%% --- reconstruction error metrics ---
methods = {'CST','PARSEC (geom)','PARSEC (LSQ basis)','Hicks-Henne'};
yu_fit  = {yu_cst, yu_par,  yu_parL, yu_hh};
yl_fit  = {yl_cst, yl_par,  yl_parL, yl_hh};
ndv     = [pc.ndv, pp.ndv,  pp.ndv_lsq, ph.ndv];
nm = numel(methods);

rms = zeros(1,nm); maxerr = zeros(1,nm);
for k = 1:nm
    eu = yu_fit{k} - af.yu;
    el = yl_fit{k} - af.yl;
    e  = [eu; el];
    rms(k)    = sqrt(mean(e.^2));
    maxerr(k) = max(abs(e));
end

%% --- report table ---
fprintf('\n  Reconstruction of %s (chord-normalized error)\n', base_file);
fprintf('  %-14s %8s %12s %12s\n','Method','#DV','RMS','MaxAbs');
fprintf('  %s\n', repmat('-',1,54));
for k = 1:nm
    fprintf('  %-20s %8d %12.3e %12.3e\n', methods{k}, ndv(k), rms(k), maxerr(k));
end
fprintf('\n  Note: PARSEC (geom) uses the classic single-crest feature\n');
fprintf('  constraints and may diverge on reflexed/cambered lower surfaces.\n');
fprintf('  PARSEC (LSQ basis) fits the x^(n-1/2) basis directly.\n\n');

%% --- overlay plot ---
% Three-panel publication figure: (a) geometry overlay, (b) upper-surface error,
% (c) lower-surface error. The divergent geometric-PARSEC variant is omitted from
% the figure (its error is reported in the table); "PARSEC" here is the LSQ-basis
% fit, the best PARSEC can do on this airfoil.
sel  = [1 3 4];                                  % CST, PARSEC (LSQ), Hicks-Henne
labs = {'CST','PARSEC','Hicks--Henne'};
sty  = {'-','--','-.'};
co   = [0 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19];

figure('Color','w','Position',[100 100 1400 380]);

subplot(1,3,1); hold on; grid on; axis equal;
[~,base_label] = fileparts(base_file);
plot(af.x, af.y, '-', 'Color',PAL.gray, 'LineWidth',1.5, 'DisplayName',['Baseline ' base_label]);
for j = 1:numel(sel)
    k = sel(j);
    plot([flipud(af.xu); af.xl], [flipud(yu_fit{k}); yl_fit{k}], sty{j}, ...
        'Color',co(j,:), 'LineWidth',1.2, 'DisplayName',labs{j});
end
legend('Location','best'); xlabel('x/c'); ylabel('y/c');

subplot(1,3,2); hold on; grid on;
for j = 1:numel(sel)
    plot(af.xu, yu_fit{sel(j)}-af.yu, sty{j}, 'Color',co(j,:), 'LineWidth',1.2);
end
yline(0,'k:'); xlabel('x/c'); ylabel('\Deltay/c  (upper)');

subplot(1,3,3); hold on; grid on;
for j = 1:numel(sel)
    plot(af.xl, yl_fit{sel(j)}-af.yl, sty{j}, 'Color',co(j,:), 'LineWidth',1.2);
end
yline(0,'k:'); xlabel('x/c'); ylabel('\Deltay/c  (lower)');

savefig300(gcf, 'parameterization_comparison', 19);
