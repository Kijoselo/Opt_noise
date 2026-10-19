function fig_sens_modes_merged
% FIG_SENS_MODES_MERGED  Fusion de la Fig 4 (tornado de sensibilidad) y la
% Fig A.16 (los 14 modos CST) en una sola figura. Solo-plot desde datos
% cacheados (sensitivity_data.mat); sin XFOIL. Paleta estandar.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
set_pub_defaults(); pc=pub_colors();
S=load('sensitivity_data.mat');            % OASPL,CLCD,levels,labels,infl,P
P=S.P; infl=S.infl(:); labels=S.labels; nv=numel(infl); nu=P.ctx.nu;
bw=(P.ub-P.lb)/2;
figdir=rutas.figuras;   % (reorganizacion) antes paper/figures

[~,ord_asc]=sort(infl,'ascend');           % tornado: mayor arriba
isUpper=(ord_asc<=nu);
[~,ord_desc]=sort(infl,'descend');         % modos: mas influyente primero

figure('Color','w','Position',[50 50 1250 430]);
tl=tiledlayout(2,8,'TileSpacing','compact','Padding','compact');

% (a) tornado -- columna izquierda, ambas filas
ax=nexttile(tl,1,[2 1]); hold(ax,'on'); box(ax,'on');
b=barh(ax,infl(ord_asc),0.7); b.FaceColor='flat'; b.EdgeColor=[0.3 0.3 0.3]; b.LineWidth=0.4;
for k=1:nv, b.CData(k,:)=isUpper(k)*pc.opt + ~isUpper(k)*pc.base; end
set(ax,'YTick',1:nv,'YTickLabel',labels(ord_asc),'TickLabelInterpreter','latex','FontSize',8);
xlabel(ax,'OASPL(A) span [dBA]','FontSize',8);

% (b) los 14 modos, ordenados por influencia (mas influyente = primero)
for t=1:nv
  i=ord_desc(t); ax=nexttile(tl); hold(ax,'on'); axis(ax,'equal');
  plot(ax,P.af.x,P.af.y,'-','Color',pc.gray,'LineWidth',0.7);
  for s=[-1 1]
    dv=P.dv0; dv(i)=P.dv0(i)+s*bw(i);
    [xx,yy]=cst_to_coords(dv(1:nu),dv(nu+1:end),P.ctx.yte_u,P.ctx.yte_l,P.ctx.npts,P.ctx.N1,P.ctx.N2);
    col=(s<0)*pc.opt + (s>0)*pc.base;      % - azul, + naranja
    plot(ax,xx,yy,'-','Color',col,'LineWidth',0.9);
  end
  set(ax,'XTick',[],'YTick',[]); xlim(ax,[0 1]);
  ht=text(ax,0,0,labels{i},'Interpreter','latex','FontSize',8,'HorizontalAlignment','center');
  set(ht,'Units','normalized','Position',[0.5 0.90 0],'VerticalAlignment','top');
end
savefig300(gcf,fullfile(figdir,'fig_sensitivity_modes'),19);
fprintf('OK fig_sensitivity_modes\n');
end
