function fig_cfh_regen
% FIG_CFH_REGEN  Re-plot de Fig 5 (Cf y H chordwise, base vs opt del 63-221) con
% la paleta estandar (succion=azul, presion=naranja; base=solido, opt=discontinuo).
% No toca el off-design. 2 evaluaciones XFOIL.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
set_pub_defaults(); pc=pub_colors();
figdir=rutas.figuras;   % (reorganizacion) antes paper/figures
files={'cst_baseline_NACA63221.dat','optimized_NACA63221_hardcon.dat'};
sty={'-','--'}; lbl={'Baseline','Optimized'}; colS=pc.opt; colP=pc.base;
figure('Color','w','Position',[40 40 1150 420]);
for g=1:2
  [fluid,inputs]=inputs_definition();
  for f={xfoil_out('POLAR_OUTPUT'),xfoil_out('doesntmatter'),xfoil_out('XFOIL_Output'),xfoil_out('XFOIL_CP_Output')},if exist(f{1},'file'),delete(f{1});end;end
  try, evaluate_airfoil(files{g},inputs,fluid); catch, end
  D=read_dump2(); if isempty(D), fprintf('  [warn] no dump %s\n',files{g}); continue; end
  [~,iLE]=min(D(:,2));
  xs=D(1:iLE,2); Cfs=D(1:iLE,7); Hs=D(1:iLE,8);
  xp=D(iLE:end,2); Cfp=D(iLE:end,7); Hp=D(iLE:end,8);
  subplot(1,2,1); hold on; grid on;
  semilogy(xs,max(Cfs,1e-6),sty{g},'Color',colS,'LineWidth',1.2,'DisplayName',sprintf('%s suction',lbl{g}));
  semilogy(xp,max(Cfp,1e-6),sty{g},'Color',colP,'LineWidth',1.2,'DisplayName',sprintf('%s pressure',lbl{g}));
  subplot(1,2,2); hold on; grid on;
  plot(xs,Hs,sty{g},'Color',colS,'LineWidth',1.2,'HandleVisibility','off');
  plot(xp,Hp,sty{g},'Color',colP,'LineWidth',1.2,'HandleVisibility','off');
end
subplot(1,2,1); set(gca,'YScale','log'); yline(1.5e-4,'k:','C_{f,min}','HandleVisibility','off');
xline(0.99,'k:','HandleVisibility','off'); xlabel('x/c'); ylabel('C_f'); xlim([0 1]);
legend('Location','northeast','FontSize',7);
text('Units','normalized','Position',[0.03 0.92 0],'String','(a)');
subplot(1,2,2); yline(2.7,'k:','H_{lim}','HandleVisibility','off'); xline(0.99,'k:','HandleVisibility','off');
xlabel('x/c'); ylabel('H'); xlim([0 1]); ylim([1 3.2]);
text('Units','normalized','Position',[0.03 0.92 0],'String','(b)');
savefig300(gcf,fullfile(figdir,'fig_cfh_NACA63221'),19);
fprintf('OK fig_cfh\n');
end
function D=read_dump2()
D=[]; if ~exist(xfoil_out('XFOIL_Output'),'file'), return; end
try
  fid=fopen(xfoil_out('XFOIL_Output'),'r');
  T=textscan(fid,'%f%f%f%f%f%f%f%f','Delimiter',' ','MultipleDelimsAsOne',true,'CollectOutput',1,'HeaderLines',1);
  fclose(fid); D=T{1}; D=D(D(:,2)<=1.0001,:);
catch
end
end
