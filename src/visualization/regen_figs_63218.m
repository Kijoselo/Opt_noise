function regen_figs_63218()
% REGEN_FIGS_63218  Regenerate the two NACA 63-218 paper figures for the
% ROBUST optimum (plot-only, no XFOIL): geometry (base vs robust vs single-model
% thin) and off-design OASPL(A) vs alpha. House style via set_pub_defaults.
rutas = proyecto_init();                                   % (reorganizacion)
root = fullfile(rutas.simulaciones,'estudios_previos');   % copias de las carpetas de resultados originales
set_pub_defaults();
figdir = rutas.figuras;

base=fullfile(root,'paquete_definitivo','NACA63218','coord_base_NACA63218.dat');
ropt=fullfile(root,'paquete_definitivo','NACA63218','coord_optimo_NACA63218.dat');

pc=pub_colors(); cB=pc.base; cR=pc.opt;   % base=naranja, optimo=azul (paleta estandar)
xs=linspace(0,1,240)';
[tb,cb]=tc(base,xs); [tr,cr]=tc(ropt,xs);
Db=dlmread(base); Dr=dlmread(ropt);

%% ---- Figure 1: geometry (3 panels) ----
figure('Color','w','Position',[40 40 1150 330]);
subplot(1,3,1); hold on; box on;
plot(Db(:,1),Db(:,2),'-','Color',cB,'LineWidth',1.3,'DisplayName','baseline');
plot(Dr(:,1),Dr(:,2),'-','Color',cR,'LineWidth',1.6,'DisplayName','robust optimum');
axis equal; xlim([0 1]); xlabel('x/c'); ylabel('y/c');
legend('Location','south','FontSize',7);
text(0.02,0.93,'(a)','Units','normalized','FontSize',9);

subplot(1,3,2); hold on; box on; grid on;
plot(xs,tb,'-','Color',cB,'LineWidth',1.3);
plot(xs,tr,'-','Color',cR,'LineWidth',1.6);
xlabel('x/c'); ylabel('t/c'); xlim([0 1]);
text(0.02,0.93,'(b) thickness','Units','normalized','FontSize',9);

subplot(1,3,3); hold on; box on; grid on;
plot(xs,cb,'-','Color',cB,'LineWidth',1.3);
plot(xs,cr,'-','Color',cR,'LineWidth',1.6);
xlabel('x/c'); ylabel('camber y_c/c'); xlim([0 1]);
text(0.02,0.93,'(c) camber','Units','normalized','FontSize',9);
savefig300(gcf,fullfile(figdir,'fig_63218_geometry'),19);

%% ---- Figure 2: off-design OASPL(A) vs alpha ----
S=load(fullfile(root,'sensibilidad_63218','env.mat'));  % res(2,2), alphas, speeds
a=S.alphas(:); keep=a<=6;                 % drop alpha=+8 (opt non-converged outlier)
Re=S.speeds*0.57/1.5e-5;
sty={'-','--'};                            % color=base/opt (naranja/azul); estilo=Re
figure('Color','w','Position',[40 40 560 430]); hold on; box on; grid on;
for u=1:2
  ob=S.res(u,1).oa(:); oo=S.res(u,2).oa(:);
  plot(a(keep),ob(keep),sty{u},'Color',cB,'LineWidth',1.5, ...
       'DisplayName',sprintf('base, Re=%.2f\\times10^6',Re(u)/1e6));
  plot(a(keep),oo(keep),sty{u},'Color',cR,'LineWidth',1.5, ...
       'DisplayName',sprintf('opt, Re=%.2f\\times10^6',Re(u)/1e6));
end
xline(4,'k:','HandleVisibility','off');
xlabel('\alpha [deg]'); ylabel('OASPL(A) [dBA]');
legend('Location','northwest','FontSize',7);
savefig300(gcf,fullfile(figdir,'fig_offdesign_NACA63218'),9);
fprintf('REGEN OK\n');
end

function [t,cam]=tc(f,xs)
D=dlmread(f); x=D(:,1); y=D(:,2);
[~,i]=min(x);
xu=x(1:i); yu=y(1:i);       % TE -> LE (x decreasing)
xl=x(i:end); yl=y(i:end);   % LE -> TE (x increasing)
[xu,ku]=unique(xu); yu=yu(ku);
[xl,kl]=unique(xl); yl=yl(kl);
YU=interp1(xu,yu,xs,'pchip'); YL=interp1(xl,yl,xs,'pchip');
t=YU-YL; cam=(YU+YL)/2;
end
