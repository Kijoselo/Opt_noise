function regen_optimum_spectrum(basefile)
% REGEN_OPTIMUM_SPECTRUM  Rebuild the case-specific hard-constraint spectrum from the saved
% airfoils, WITHOUT re-running the 400-evaluation optimization. Uses only two
% XFOIL evaluations: the case-specific CST baseline and optimized airfoil.
if nargin < 1 || isempty(basefile), basefile = 'NACA63221.txt'; end
close all; set_pub_defaults(); pc=pub_colors();  % base=naranja, opt=azul
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace

P = setup_problem('base', basefile, 'write_legacy', false);
base_file = P.ctx.baseline_file;
opt_file  = P.ctx.opt_file;
if ~exist(base_file,'file') || ~exist(opt_file,'file')
    error('Need matching case files %s and %s. Run run_optimization(''%s'', budget) first.', ...
          base_file, opt_file, P.base_file);
end

fluid = P.ctx.fluid;
inputs = P.ctx.inputs;
pref = 20e-6;

[Jb, ~, ~, ob] = evaluate_airfoil(base_file, inputs, fluid);
[Jo, ~, ~, oo] = evaluate_airfoil(opt_file,  inputs, fluid);

f = ob.f;
SPLb = 10*log10(ob.S_pp/pref^2);
SPLo = 10*log10(oo.S_pp/pref^2);
[Lb, Fc] = NarrowToNthOctave(f, SPLb, 3);
[Lo, ~ ] = NarrowToNthOctave(f, SPLo, 3);

figure('Color','w','Position',[100 100 1400 380]);
subplot(1,3,1); hold on; grid on;
semilogx(f, SPLb, '-', 'Color',pc.base,'LineWidth',1.3,'DisplayName','Baseline');
semilogx(f, SPLo, '-', 'Color',pc.opt, 'LineWidth',1.3,'DisplayName','Optimized');
set(gca,'XScale','log'); xlabel('Frequency [Hz]'); ylabel('SPL [dB]');
legend('Location','best'); xlim([f(1) f(end)]);
text('Units','normalized','Position',[0.03 0.96 0],'String','(a) narrowband','VerticalAlignment','top');

subplot(1,3,2); hold on; grid on;
semilogx(Fc, Lb, '-o', 'Color',pc.base,'MarkerFaceColor',pc.base,'MarkerSize',3,'DisplayName','Baseline');
semilogx(Fc, Lo, '-s', 'Color',pc.opt, 'MarkerFaceColor',pc.opt, 'MarkerSize',3,'DisplayName','Optimized');
set(gca,'XScale','log'); xlabel('1/3-octave band center [Hz]'); ylabel('SPL [dB]');
legend('Location','best');
text('Units','normalized','Position',[0.03 0.96 0],'String','(b) 1/3-octave','VerticalAlignment','top');

subplot(1,3,3); hold on; grid on;
semilogx(Fc, Lo-Lb, '-d', 'Color',pc.third,'MarkerFaceColor',pc.third,'MarkerSize',3);
set(gca,'XScale','log'); yline(0,'k:');
xlabel('1/3-octave band center [Hz]'); ylabel('\DeltaSPL = opt - base [dB]');
text('Units','normalized','Position',[0.03 0.96 0],'String','(c) band-by-band change','VerticalAlignment','top');

fig_prefix = sprintf('fig_spectrum_hardcon_%s', P.case_id);
savefig300(gcf, fig_prefix, 19);
if strcmpi(P.case_id, 'NACA63221')
    copiar_figura(fig_prefix, 'fig_spectrum_hardcon');
end
fprintf('Rebuilt %s.png (baseline %.2f -> optimized %.2f dBA)\n', fig_prefix, Jb, Jo);
end
