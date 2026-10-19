function plot_mechanism(basefile)
% PLOT_MECHANISM  Physical mechanism behind the noise reduction: compares the
% baseline (CST) and optimized airfoils in geometry and aerodynamics/acoustics.
% Produces, for the article:
%   fig_mechanism_geom_<case>.png  thickness t/c, camber, trailing-edge zoom
%   fig_mechanism_aero_<case>.png  surface pressure C_p and wall-pressure spectrum at TE
% Uses two XFOIL evaluations (baseline + optimized).
if nargin < 1 || isempty(basefile), basefile = 'NACA63221.txt'; end
close all; set_pub_defaults(); pc=pub_colors();
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
pref = 20e-6;

P = setup_problem('base', basefile, 'write_legacy', false);
base = P.ctx.baseline_file;
opt  = P.ctx.opt_file;
case_id = P.case_id;
if ~exist(base,'file') || ~exist(opt,'file')
    error('Need matching case files %s and %s. Run run_optimization(''%s'', budget) first.', ...
          base, opt, P.base_file);
end

%% ---------- geometry mechanism (no XFOIL) ----------
[xc, tcb, cmb] = thickness_camber(base, 200);
[~,  tco, cmo] = thickness_camber(opt , 200);
afb = load_airfoil(base);  afo = load_airfoil(opt);

figure('Color','w','Position',[100 100 1100 680]);
cB = pc.base; cO = pc.opt;   % base=naranja, opt=azul

% (a) full silhouette overlay (baseline vs optimized)
subplot(2,2,1); hold on; grid on; axis equal;
plot(afb.x, afb.y, '-', 'Color',cB, 'LineWidth',1.3, 'DisplayName','Baseline');
plot(afo.x, afo.y, '-', 'Color',cO, 'LineWidth',1.3, 'DisplayName','Optimized');
xlim([0 1]); xlabel('x/c'); ylabel('y/c'); legend('Location','best');

% (b) trailing-edge zoom
subplot(2,2,2); hold on; grid on; axis equal;
plot(afb.x, afb.y, '-', 'Color',cB, 'LineWidth',1.3);
plot(afo.x, afo.y, '-', 'Color',cO, 'LineWidth',1.3);
xlim([0.75 1.0]); ylim([-0.01 0.04]);
xlabel('x/c'); ylabel('y/c'); text(0.77, 0.035, 'trailing-edge zoom', 'FontSize',9);

% (c) thickness
subplot(2,2,3); hold on; grid on;
plot(xc, tcb, '-', 'Color',cB); plot(xc, tco, '-', 'Color',cO);
xlabel('x/c'); ylabel('thickness  t/c');

% (d) camber
subplot(2,2,4); hold on; grid on;
plot(xc, cmb, '-', 'Color',cB); plot(xc, cmo, '-', 'Color',cO);
xlabel('x/c'); ylabel('camber  y_c/c');

fig_geom = sprintf('fig_mechanism_geom_%s', case_id);
savefig300(gcf, fig_geom, 16);
if strcmpi(case_id, 'NACA63221')
    copiar_figura(fig_geom, 'fig_mechanism_geom');
end

%% ---------- aerodynamic / acoustic mechanism (XFOIL) ----------
fluid = P.ctx.fluid;
inputs = P.ctx.inputs;

[OAb, Clb, Cdb, ob] = evaluate_airfoil(base, inputs, fluid);
[xcp_b, cp_b] = read_cp();                       % read before it is overwritten
[OAo, Clo, Cdo, oo] = evaluate_airfoil(opt , inputs, fluid);
[xcp_o, cp_o] = read_cp();

f = ob.f;
toDB = @(P) 10*log10(P/pref^2);

figure('Color','w','Position',[100 100 1400 380]);
subplot(1,3,1); hold on; grid on;
plot(xcp_b, cp_b, '-', 'Color',cB, 'DisplayName','Baseline');
plot(xcp_o, cp_o, '-', 'Color',cO, 'DisplayName','Optimized');
set(gca,'YDir','reverse');                        % suction up (standard C_p plot)
xlabel('x/c'); ylabel('C_p'); legend('Location','best');

subplot(1,3,2); hold on; grid on;
semilogx(f, toDB(ob.Phi_pp_s), '-', 'Color',cB);
semilogx(f, toDB(oo.Phi_pp_s), '-', 'Color',cO);
set(gca,'XScale','log'); xlim([f(1) f(end)]);
xlabel('Frequency [Hz]'); ylabel('\Phi_{pp} suction side [dB/Hz]');

subplot(1,3,3); hold on; grid on;
semilogx(f, toDB(ob.Phi_pp_p), '-', 'Color',cB);
semilogx(f, toDB(oo.Phi_pp_p), '-', 'Color',cO);
set(gca,'XScale','log'); xlim([f(1) f(end)]);
xlabel('Frequency [Hz]'); ylabel('\Phi_{pp} pressure side [dB/Hz]');

fig_aero = sprintf('fig_mechanism_aero_%s', case_id);
savefig300(gcf, fig_aero, 19);
if strcmpi(case_id, 'NACA63221')
    copiar_figura(fig_aero, 'fig_mechanism_aero');
end

% A-weighted OASPL split by surface, to locate the reduction
fprintf('\n               OASPL(A) [dBA]   suction-only   pressure-only\n');
fprintf('  baseline   %12.2f %14.2f %15.2f\n', OAb, oaspl_A(f,ob.S_pp_s), oaspl_A(f,ob.S_pp_p));
fprintf('  optimized  %12.2f %14.2f %15.2f\n', OAo, oaspl_A(f,oo.S_pp_s), oaspl_A(f,oo.S_pp_p));
fprintf('\n  baseline : Cl=%.4f Cd=%.5f Cl/Cd=%.2f Cm=%.4f\n', Clb,Cdb,Clb/Cdb,ob.Cm);
fprintf('  optimized: Cl=%.4f Cd=%.5f Cl/Cd=%.2f Cm=%.4f\n\n', Clo,Cdo,Clo/Cdo,oo.Cm);
end

function L = oaspl_A(f, S_pp)
% A-weighted OASPL of one S_pp contribution (matches evaluate_airfoil).
pref = 20e-6;
Ra = 12194^2*f.^4 ./ ((f.^2+20.6^2).*sqrt((f.^2+107.7^2).*(f.^2+797.9^2)).*(f.^2+12194^2));
A  = 20*log10(Ra) - 20*log10(Ra(f==1000));
spp = pref^2 .* 10.^((10*log10(S_pp/pref^2)+A)'/10);
L = 10*log10(trapz(f, spp')/pref^2);
end

function [xc, cp] = read_cp()
% Read the most recent XFOIL surface-pressure output (x, y, Cp).
D = readmatrix(xfoil_out('XFOIL_CP_Output'), 'FileType','text', 'NumHeaderLines',3);
xc = D(:,1); cp = D(:,3);
end
