function fig_seed_boxplot_regen
% FIG_SEED_BOXPLOT_REGEN  Re-plot del boxplot de 10 semillas (Fig 10) desde datos
% cacheados (seed_bench_63221.mat). Paleta estandar + leyenda LIMPIA (sin el
% "Table 5" incrustado que senalaron). Sin XFOIL.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
set_pub_defaults(); pc=pub_colors();
D=load('seed_bench_63221.mat'); B=D.B; algos={'GA','PSO','SBO'};
figdir=rutas.figuras;   % (reorganizacion) antes paper/figures
single=[65.94 66.09 66.09];   % valores single-run (GA,PSO,SBO), Tabla de algoritmos
ps_opt=65.82;                 % optimo dedicado de pattern search
ng=size(B,1);

figure('Color','w','Position',[100 100 560 430]); hold on; box on; grid on;
for g=1:ng
  hbox=boxchart(g*ones(1,size(B,2)), B(g,:), 'BoxFaceColor',pc.opt, ...
        'BoxFaceAlpha',0.35,'LineWidth',1.0,'MarkerStyle','none','BoxWidth',0.55);
end
for g=1:ng
  xj=g+0.16*(rand(1,size(B,2))-0.5);
  hs=plot(xj,B(g,:),'.','Color',[0.35 0.35 0.35],'MarkerSize',8);
end
hstar=plot(1:ng,single,'p','Color',pc.base,'MarkerFaceColor',pc.base,'MarkerSize',12,'LineStyle','none');
hline=yline(ps_opt,'--','Color',pc.third,'LineWidth',1.5);
set(gca,'XTick',1:ng,'XTickLabel',algos,'XLim',[0.4 ng+0.6]);
ylabel('best OASPL(A) [dBA]');
yall=[B(:); single(:); ps_opt];
ylim([min(yall)-0.08, max(yall)+0.08]);
% legend OUTSIDE the axes (below), so it can never overlap the data
legend([hbox hs hstar hline],{'seed distribution','individual seeds','single run', ...
        'pattern-search optimum'},'Location','southoutside','NumColumns',2,'FontSize',8);
savefig300(gcf,fullfile(figdir,'fig_seed_boxplot'),9);
fprintf('OK fig_seed_boxplot\n');
end
