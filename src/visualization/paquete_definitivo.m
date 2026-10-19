function paquete_definitivo
% PAQUETE_DEFINITIVO  Ensambla el paquete final con la geometria DEFINITIVA
% (robusta, malla convergida). Por caso: coordenadas, polares +-180 (XFOIL+
% Viterna) base vs optimo, espectro OASPL, historial convergido, geometria.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
pkg=fullfile(rutas.exportaciones,'paquete_definitivo');                          % (reorganizacion)
defdir=fullfile(rutas.simulaciones,'estudios_previos','definitivo_robusto');
[fluid,inputs]=inputs_definition();
casos={'63218','cst_baseline_NACA63218.dat','opt_NACA63218_definitivo.dat';
       '63221','cst_baseline_NACA63221.dat','opt_NACA63221_definitivo.dat'};
for c=1:2
  cid=casos{c,1}; baseD=casos{c,2}; optD=casos{c,3};
  od=fullfile(pkg,['NACA' cid]); if ~exist(od,'dir'), mkdir(od); end
  fprintf('=== NACA%s ===\n',cid);
  copyfile(baseD, fullfile(od,['coord_base_NACA' cid '.dat']));
  copyfile(optD,  fullfile(od,['coord_optimo_NACA' cid '.dat']));

  %% polares +-180 (Viterna)
  sid=cid(end-2:end);                    % sufijo corto de los polares (218/221)
  Pb=readpol(['pdef_base' sid '_up.txt'],['pdef_base' sid '_dn.txt']);
  Po=readpol(['pdef_opt'  sid '_up.txt'],['pdef_opt'  sid '_dn.txt']);
  [gb,gcb,gdb]=viterna(Pb(:,1),Pb(:,2),Pb(:,3));
  [go,gco,gdo]=viterna(Po(:,1),Po(:,2),Po(:,3));
  wpol(fullfile(od,['polar360_base_NACA'   cid '.txt']),[gb gcb gdb]);
  wpol(fullfile(od,['polar360_optimo_NACA' cid '.txt']),[go gco gdo]);
  % figura: rango XFOIL (Cl,Cd,Cl/Cd,Cm) + panel +-180
  figure('Color','w','Position',[40 40 1050 760]);
  pp={@(P)P(:,2),@(P)P(:,3),@(P)P(:,2)./P(:,3),@(P)P(:,5)}; yl={'c_l','c_d','c_l/c_d','c_m'};
  for k=1:4
    subplot(2,2,k); hold on; grid on;
    plot(Pb(:,1),pp{k}(Pb),'k-o','MarkerSize',3,'LineWidth',1.1,'DisplayName','base');
    plot(Po(:,1),pp{k}(Po),'r-s','MarkerSize',3,'LineWidth',1.1,'DisplayName','optimo');
    xlabel('\alpha [deg]'); ylabel(yl{k}); if k==2, set(gca,'YScale','log'); end
    if k==1, legend('Location','southeast','FontSize',8); end
    if k==3, xline(4,'k:','HandleVisibility','off'); end
    text(0.03,0.94,sprintf('(%c)','a'+k-1),'Units','normalized');
  end
  savefig300(gcf,fullfile(od,['fig_polar_base_vs_optimo_NACA' cid]),17);
  figure('Color','w','Position',[40 40 1150 430]);
  subplot(1,2,1); hold on; grid on;
  plot(gb,gcb,'k-','LineWidth',1.1,'DisplayName','base'); plot(go,gco,'r-','LineWidth',1.1,'DisplayName','optimo');
  plot(Pb(:,1),Pb(:,2),'k.',Po(:,1),Po(:,2),'r.','MarkerSize',5,'HandleVisibility','off');
  xlim([-180 180]); xticks(-180:60:180); xlabel('\alpha [deg]'); ylabel('c_l'); legend('Location','south','FontSize',7);
  subplot(1,2,2); hold on; grid on;
  plot(gb,gdb,'k-','LineWidth',1.1); plot(go,gdo,'r-','LineWidth',1.1);
  xlim([-180 180]); xticks(-180:60:180); xlabel('\alpha [deg]'); ylabel('c_d');
  savefig300(gcf,fullfile(od,['fig_polar360_NACA' cid]),19);

  %% espectro OASPL base vs optimo
  cx; [oaB,~,~,ob]=evaluate_airfoil(baseD,inputs,fluid);
  cx; [oaO,~,~,oo]=evaluate_airfoil(optD,inputs,fluid);
  f=ob.f; pref=20e-6; Sb=10*log10(ob.S_pp/pref^2); So=10*log10(oo.S_pp/pref^2);
  [Lb,Fc]=NarrowToNthOctave(f,Sb,3); [Lo,~]=NarrowToNthOctave(f,So,3);
  figure('Color','w','Position',[40 40 1250 410]);
  subplot(1,3,1); semilogx(f,Sb,'k-',f,So,'r-','LineWidth',1.2); grid on;
  xlabel('f [Hz]'); ylabel('SPL [dB] (sin filtro A)'); legend('base','optimo','Location','southwest','FontSize',8);
  text(0.03,0.03,'(a) banda estrecha','Units','normalized','FontSize',8);
  subplot(1,3,2); semilogx(Fc,Lb,'ko-',Fc,Lo,'rs-','MarkerSize',3,'LineWidth',1.1); grid on;
  xlabel('f centro 1/3-oct [Hz]'); ylabel('SPL [dB] (sin filtro A)'); legend('base','optimo','Location','southwest','FontSize',8);
  text(0.03,0.03,'(b) tercio de octava','Units','normalized','FontSize',8);
  subplot(1,3,3); semilogx(Fc,Lo-Lb,'b^-','MarkerSize',3,'LineWidth',1.1); hold on; yline(0,'k:'); grid on;
  xlabel('f centro 1/3-oct [Hz]'); ylabel('\Delta SPL = opt - base [dB]');
  text(0.03,0.94,'(c) diferencia por banda','Units','normalized','FontSize',8);
  sgtitle(sprintf('NACA %s  --  OASPL(A) con filtro A: base %.2f, optimo %.2f dBA',cid,oaB,oaO),'FontSize',10);
  savefig300(gcf,fullfile(od,['fig_OASPL_espectro_NACA' cid]),19);

  %% historial convergido
  S=load(fullfile(defdir,['def_NACA' cid '.mat']));  % HLOG, R0, Rf, oa4b, oa4o
  H=S.HLOG; J=H(:,2); cc=H(:,3); n=size(H,1); idx=(1:n)';
  Jbest=nan(n,1); b=inf; for k=1:n, if J(k)<b,b=J(k);end; Jbest(k)=b; end
  real=H(:,5)==1 & isfinite(J) & J<150;
  figure('Color','w','Position',[40 40 1150 420]);
  subplot(1,2,1); hold on; grid on;
  plot(idx(real),J(real),'.','Color',[0.6 0.72 0.9],'MarkerSize',5,'DisplayName','evaluaciones');
  plot(idx,Jbest,'b-','LineWidth',1.8,'DisplayName','mejor acumulado');
  plot(n,Jbest(end),'rp','MarkerSize',13,'MarkerFaceColor','r','DisplayName','optimo');
  lo=min(Jbest)-0.3; hi=prctile(J(real),98); if isfinite(lo)&&isfinite(hi)&&hi>lo, ylim([lo hi]); end
  xlabel('Evaluacion'); ylabel('OASPL peor-caso [dBA]'); legend('Location','northeast','FontSize',8);
  text(0.03,0.94,'(a) convergencia OASPL','Units','normalized');
  subplot(1,2,2); hold on; grid on;
  plot(idx(real),cc(real),'.','Color',[0.85 0.6 0.5],'MarkerSize',5,'DisplayName','evaluaciones');
  yline(max(interp1(1:n,cc,1)),'k--','HandleVisibility','off');
  xlabel('Evaluacion'); ylabel('Cl/Cd'); text(0.03,0.94,'(b) Cl/Cd','Units','normalized');
  savefig300(gcf,fullfile(od,['fig_historial_NACA' cid]),19);

  %% geometria
  figure('Color','w','Position',[40 40 720 320]); hold on; grid on;
  Db=dlmread(baseD); Do=dlmread(optD);
  plot(Db(:,1),Db(:,2),'k-','LineWidth',1.5,'DisplayName','base');
  plot(Do(:,1),Do(:,2),'r-','LineWidth',1.5,'DisplayName','optimo definitivo');
  axis equal; xlabel('x/c'); ylabel('y/c'); legend('Location','southoutside','FontSize',8);
  savefig300(gcf,fullfile(od,['fig_geometria_NACA' cid]),13);
  fprintf('  paquete NACA%s listo (OASPL %.2f->%.2f, Cl/Cd@4 base %.1f opt %.1f)\n', ...
          cid, oaB, oaO, interp1(Pb(:,1),Pb(:,2)./Pb(:,3),4,'pchip'), interp1(Po(:,1),Po(:,2)./Po(:,3),4,'pchip'));
end
fprintf('PAQUETE DEFINITIVO COMPLETO\n');
end

function P=readpol(up,dn)
P=[]; for fn={up,dn}
  if exist(fn{1},'file'), txt=fileread(fn{1}); L=regexp(txt,'\r?\n','split');
    for i=1:numel(L), v=sscanf(L{i},'%f'); if numel(v)>=5, P=[P; v(1:5)']; end; end
  end
end
if ~isempty(P), P=sortrows(unique(P,'rows'),1); end
end
function wpol(fname,M)
fid=fopen(fname,'w'); fprintf(fid,'# alpha[deg] Cl Cd  (XFOIL + Viterna +-180)\n');
fprintf(fid,'%10.2f %9.4f %9.5f\n',M'); fclose(fid);
end
function [ga,gcl,gcd]=viterna(a,cl,cd)
cd_max=1.3; cl_adj=0.7; ah=deg2rad(a(end)); clh=cl(end); cdh=cd(end);
A2=(clh-cd_max*sin(ah)*cos(ah))*sin(ah)/cos(ah)^2; B2=(cdh-cd_max*sin(ah)^2)/cos(ah);
vcl=@(r)cd_max/2*sin(2*r)+A2*cos(r).^2./max(sin(r),1e-9); vcd=@(r)cd_max*sin(r).^2+B2*cos(r);
aH=a(end); aL=a(1); ga=(-180:1:180)'; gcl=nan(size(ga)); gcd=nan(size(ga)); cf=max(min(cd),1e-3);
for k=1:numel(ga), x=ga(k); r=deg2rad(x);
  if x>=aL&&x<=aH, gcl(k)=interp1(a,cl,x,'pchip'); gcd(k)=interp1(a,cd,x,'pchip');
  elseif x>aH&&x<=90, gcl(k)=vcl(r); gcd(k)=vcd(r);
  elseif x>90&&x<=180-aH, gcl(k)=-cl_adj*vcl(deg2rad(180-x)); gcd(k)=vcd(deg2rad(180-x));
  elseif x>180-aH, gcl(k)=cl_adj*clh*(x-180)/aH; gcd(k)=vcd(deg2rad(180-x));
  elseif x<aL&&x>=-90, gcl(k)=-cl_adj*vcl(deg2rad(-x)); gcd(k)=vcd(deg2rad(-x));
  elseif x<-90&&x>=-(180-aH), gcl(k)=cl_adj*vcl(deg2rad(180+x)); gcd(k)=vcd(deg2rad(180+x));
  else, gcl(k)=cl_adj*clh*(x+180)/aH; gcd(k)=vcd(deg2rad(180+x)); end
  if x<aL||x>aH, gcd(k)=max(gcd(k),cf); end
end
end
function cx
for f={xfoil_out('POLAR_OUTPUT'),xfoil_out('doesntmatter'),xfoil_out('XFOIL_Output'),xfoil_out('XFOIL_CP_Output')}, if exist(f{1},'file'),delete(f{1});end; end
end
