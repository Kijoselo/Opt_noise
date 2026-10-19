function fig_param_variables
% FIG_PARAM_VARIABLES  Figura didactica (comentario 3 del comite): muestra COMO
% y DONDE actuan las variables de diseno de cada parametrizacion sobre el perfil,
% para los tres casos aplicados (CST, PARSEC, Hicks-Henne). Sin XFOIL.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
set_pub_defaults(); pc=pub_colors();
af=load_airfoil('NACA63221.txt'); order=6;
HH=hh_fit(af);
figdir=rutas.figuras;   % (reorganizacion) antes paper/figures

figure('Color','w','Position',[40 40 1320 330]);

%% (a) CST: 7 coeficientes Bernstein por superficie, en su ubicacion de pico x=i/order
subplot(1,3,1); hold on; box on; axis equal
plot(af.x,af.y,'-','Color',pc.gray,'LineWidth',1.3);
xk=(0:order)/order;
yu=interp1(af.xu,af.yu,xk,'pchip'); yl=interp1(af.xl,af.yl,xk,'pchip');
plot(xk,yu,'o','Color',pc.opt,'MarkerFaceColor',pc.opt,'MarkerSize',5);
plot(xk,yl,'s','Color',pc.base,'MarkerFaceColor',pc.base,'MarkerSize',5);
for i=1:numel(xk)
  text(xk(i),yu(i)+0.035,sprintf('$A^{u}_{%d}$',i-1),'Interpreter','latex','FontSize',6.5,'HorizontalAlignment','center');
  text(xk(i),yl(i)-0.045,sprintf('$A^{\\ell}_{%d}$',i-1),'Interpreter','latex','FontSize',6.5,'HorizontalAlignment','center');
end
xlim([0 1]); ylim([-0.19 0.22]); xlabel('x/c'); ylabel('y/c'); panel('(a)');

%% (b) PARSEC: features geometricos
subplot(1,3,2); hold on; box on; axis equal
plot(af.x,af.y,'-','Color',pc.gray,'LineWidth',1.3);
[zu,iu]=max(af.yu); xcu=af.xu(iu); [zl,il]=min(af.yl); xcl=af.xl(il);
plot(xcu,zu,'o','Color',pc.opt,'MarkerFaceColor',pc.opt,'MarkerSize',5);
plot(xcl,zl,'s','Color',pc.base,'MarkerFaceColor',pc.base,'MarkerSize',5);
plot(0,0,'k^','MarkerFaceColor','k','MarkerSize',5);
plot(1,mean([af.yu(end) af.yl(end)]),'kd','MarkerFaceColor','k','MarkerSize',5);
text(xcu,zu+0.045,'$x_{up},z_{up},z_{xx}^{up}$','Interpreter','latex','FontSize',6.5,'HorizontalAlignment','center');
text(xcl,zl-0.05,'$x_{lo},z_{lo},z_{xx}^{lo}$','Interpreter','latex','FontSize',6.5,'HorizontalAlignment','center');
text(0.02,0.10,'$r_{LE}$','Interpreter','latex','FontSize',7);
text(0.60,0.13,'$z_{TE},\Delta z_{TE},\alpha_{TE},\beta_{TE}$','Interpreter','latex','FontSize',6.5);
xlim([0 1]); ylim([-0.19 0.22]); xlabel('x/c'); panel('(b)');

%% (c) Hicks-Henne: ubicacion de las bump functions
subplot(1,3,3); hold on; box on; axis equal
plot(af.x,af.y,'-','Color',pc.gray,'LineWidth',1.3);
xk=HH.xk(:)';
yu=interp1(af.xu,af.yu,xk,'pchip'); yl=interp1(af.xl,af.yl,xk,'pchip');
plot(xk,yu,'o','Color',pc.opt,'MarkerFaceColor',pc.opt,'MarkerSize',4);
plot(xk,yl,'s','Color',pc.base,'MarkerFaceColor',pc.base,'MarkerSize',4);
for j=1:numel(xk), xline(xk(j),':','Color',[0.7 0.7 0.7]); end
xlim([0 1]); ylim([-0.19 0.22]); xlabel('x/c'); panel('(c)');

savefig300(gcf,fullfile(figdir,'fig_param_variables'),19);
fprintf('OK fig_param_variables\n');
end

function panel(str)   % etiqueta de panel (savefig300 borra los title de ejes)
h=text(0,0,str,'FontSize',9); set(h,'Units','normalized','Position',[0.03 0.97 0], ...
   'HorizontalAlignment','left','VerticalAlignment','top');
end
