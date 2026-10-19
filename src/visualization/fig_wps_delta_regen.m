function fig_wps_delta_regen
% FIG_WPS_DELTA_REGEN  Recrea Fig 14: cambio del espectro de presion de pared en
% x/c=0.99 producido por la optimizacion del 63-221 (DeltaPhi_pp = opt - base)
% segun cada modelo WPS (TNO, Goody, Kamruzzaman), succion (a) y presion (b).
% Deterministico (6 evals XFOIL). Paleta estandar.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
set_pub_defaults(); pc=pub_colors();
figdir=rutas.figuras;   % (reorganizacion) antes paper/figures
base='cst_baseline_NACA63221.dat'; opt='optimized_NACA63221_hardcon.dat';
models={'TNO','Goody','Kamruzzaman'}; cols={pc.opt,pc.base,pc.third};
[fluid,~]=inputs_definition();
toDB=@(P)10*log10(P/(20e-6)^2);
figure('Color','w','Position',[40 40 1150 420]);
for m=1:3
  [~,inp]=inputs_definition(); inp.model=models{m};
  for f={xfoil_out('POLAR_OUTPUT'),xfoil_out('doesntmatter'),xfoil_out('XFOIL_Output'),xfoil_out('XFOIL_CP_Output')},if exist(f{1},'file'),delete(f{1});end;end
  [~,~,~,ob]=evaluate_airfoil(base,inp,fluid);
  for f={xfoil_out('POLAR_OUTPUT'),xfoil_out('doesntmatter'),xfoil_out('XFOIL_Output'),xfoil_out('XFOIL_CP_Output')},if exist(f{1},'file'),delete(f{1});end;end
  [~,~,~,oo]=evaluate_airfoil(opt,inp,fluid);
  ff=ob.f; dS=toDB(oo.Phi_pp_s)-toDB(ob.Phi_pp_s); dP=toDB(oo.Phi_pp_p)-toDB(ob.Phi_pp_p);
  subplot(1,2,1); hold on; grid on; semilogx(ff,dS,'-','Color',cols{m},'LineWidth',1.3,'DisplayName',models{m});
  subplot(1,2,2); hold on; grid on; semilogx(ff,dP,'-','Color',cols{m},'LineWidth',1.3,'DisplayName',models{m});
end
subplot(1,2,1); set(gca,'XScale','log'); yline(0,'k:','HandleVisibility','off');
xlabel('Frequency [Hz]'); ylabel('\Delta\Phi_{pp} suction [dB]'); legend('Location','best','FontSize',7);
text('Units','normalized','Position',[0.03 0.06 0],'String','(a) suction side');
subplot(1,2,2); set(gca,'XScale','log'); yline(0,'k:','HandleVisibility','off');
xlabel('Frequency [Hz]'); ylabel('\Delta\Phi_{pp} pressure [dB]');
text('Units','normalized','Position',[0.03 0.06 0],'String','(b) pressure side');
savefig300(gcf,fullfile(figdir,'fig_wps_delta_NACA63221'),19);
fprintf('OK fig_wps_delta\n');
end
