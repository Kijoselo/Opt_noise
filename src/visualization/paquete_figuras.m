function paquete_figuras
% PAQUETE_FIGURAS  Genera, para 63218 y 63221, la comparacion base vs optimo:
% polares (tabla + figura 4 paneles), espectro OASPL (3 paneles) e histograma
% de la meseta. Requiere que los barridos XFOIL (pol_*_up/dn.txt) ya existan.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
pkg=fullfile(rutas.simulaciones,'estudios_previos','paquete_revision_final')   % (reorganizacion);
[fluid,inputs]=inputs_definition();
casos={'63218','cst_baseline_NACA63218.dat','opt_NACA63218_expandido.dat';
       '63221','cst_baseline_NACA63221.dat','opt_NACA63221_expandido.dat'};

for c=1:2
  cid=casos{c,1}; baseD=casos{c,2}; optD=casos{c,3}; od=fullfile(pkg,['NACA' cid]);
  sid=cid(end-2:end);                 % sufijo corto de los polares (218 / 221)
  fprintf('=== NACA%s ===\n', cid);

  %% ---------- POLARES ----------
  Pb=readpolar(['pol_base' sid '_up.txt'],['pol_base' sid '_dn.txt']);
  Po=readpolar(['pol_opt'  sid '_up.txt'],['pol_opt'  sid '_dn.txt']);
  if isempty(Pb)||isempty(Po), fprintf('  [aviso] polar vacio, se omite figura polar\n'); else
  writepolar(fullfile(od,['polar_base_NACA'   cid '.txt']),Pb,['base NACA' cid]);
  writepolar(fullfile(od,['polar_optimo_NACA' cid '.txt']),Po,['optimo NACA' cid]);
  figure('Color','w','Position',[40 40 1050 760]);
  pp={@(P)P(:,2),@(P)P(:,3),@(P)P(:,2)./P(:,3),@(P)P(:,5)};
  yl={'c_l','c_d','c_l/c_d','c_m'};
  for k=1:4
    subplot(2,2,k); hold on; grid on;
    plot(Pb(:,1),pp{k}(Pb),'k-o','MarkerSize',3,'LineWidth',1.1,'DisplayName','base');
    plot(Po(:,1),pp{k}(Po),'r-s','MarkerSize',3,'LineWidth',1.1,'DisplayName','optimo');
    xlabel('\alpha [deg]'); ylabel(yl{k});
    if k==2, set(gca,'YScale','log'); end
    if k==1, legend('Location','southeast','FontSize',8); end
    if k==3, xline(4,'k:','HandleVisibility','off'); end
    text(0.03,0.94,sprintf('(%c)','a'+k-1),'Units','normalized');
  end
  savefig300(gcf,fullfile(od,['fig_polar_base_vs_optimo_NACA' cid]),17);
  fprintf('  polar Cl/Cd@4: base %.1f | optimo %.1f\n', ...
    interp1(Pb(:,1),Pb(:,2)./Pb(:,3),4,'pchip'), interp1(Po(:,1),Po(:,2)./Po(:,3),4,'pchip'));
  end

  %% ---------- ESPECTRO OASPL ----------
  cleanx; [oaB,~,~,ob]=evaluate_airfoil(baseD,inputs,fluid);
  cleanx; [oaO,~,~,oo]=evaluate_airfoil(optD,inputs,fluid);
  f=ob.f; pref=20e-6;
  Sb=10*log10(ob.S_pp/pref^2); So=10*log10(oo.S_pp/pref^2);
  [Lb,Fc]=NarrowToNthOctave(f,Sb,3); [Lo,~]=NarrowToNthOctave(f,So,3);
  figure('Color','w','Position',[40 40 1250 400]);
  subplot(1,3,1); semilogx(f,Sb,'k-','LineWidth',1.2); hold on; semilogx(f,So,'r-','LineWidth',1.2);
  grid on; xlabel('f [Hz]'); ylabel('SPL [dB]');
  legend(sprintf('base (%.2f dBA)',oaB),sprintf('optimo (%.2f dBA)',oaO),'Location','southwest','FontSize',7);
  text(0.03,0.06,'(a) banda estrecha','Units','normalized','FontSize',8);
  subplot(1,3,2); semilogx(Fc,Lb,'ko-','MarkerSize',3,'LineWidth',1.1); hold on; semilogx(Fc,Lo,'rs-','MarkerSize',3,'LineWidth',1.1);
  grid on; xlabel('f centro 1/3-oct [Hz]'); ylabel('SPL [dB]');
  legend('base','optimo','Location','southwest','FontSize',7);
  text(0.03,0.06,'(b) tercio de octava','Units','normalized','FontSize',8);
  subplot(1,3,3); semilogx(Fc,Lo-Lb,'b^-','MarkerSize',3,'LineWidth',1.1); hold on; yline(0,'k:');
  grid on; xlabel('f centro 1/3-oct [Hz]'); ylabel('\Delta SPL = opt - base [dB]');
  text(0.03,0.94,'(c) diferencia por banda','Units','normalized','FontSize',8);
  savefig300(gcf,fullfile(od,['fig_OASPL_espectro_NACA' cid]),19);
  fprintf('  OASPL(A): base %.3f -> optimo %.3f dBA (TNO)\n', oaB, oaO);

  %% ---------- HISTOGRAMA (meseta) ----------
  S=load(fullfile(od,['hist_NACA' cid '.mat']));  % copiado al paquete: H, Jbest
  H=S.H; J=H(:,2); valid=H(:,5)==1 & isfinite(J) & J<150;
  Jv=J(valid); best=min(Jv); thr=best+0.5; pool=Jv(Jv<=thr);
  figure('Color','w','Position',[40 40 620 400]); hold on; grid on;
  histogram(pool,25,'FaceColor',[0.2 0.45 0.75]);
  xline(best,'r--','LineWidth',1.4,'DisplayName',sprintf('optimo %.2f',best));
  xlabel('OASPL peor-caso [dBA]'); ylabel('n disenos');
  legend('Location','northeast','FontSize',8);
  title(sprintf('NACA%s: %d disenos a <=0.5 dB del optimo (de %d validos)',cid,numel(pool),numel(Jv)));
  savefig300(gcf,fullfile(od,['fig_histograma_NACA' cid]),12);
  fprintf('  histograma: %d disenos <=best+0.5 de %d validos\n', numel(pool), numel(Jv));
end
fprintf('\nPaquete de figuras completo.\n');
end

%% ---- helpers ----
function P=readpolar(up,dn)
% lector a prueba de balas: parsea linea por linea, solo filas con >=5 numeros
P=[];
for fn={up,dn}
  if ~exist(fn{1},'file'), continue; end
  txt=fileread(fn{1});
  lineas=regexp(txt,'\r?\n','split');
  for i=1:numel(lineas)
    v=sscanf(lineas{i},'%f');
    if numel(v)>=5, P=[P; v(1:5)']; end
  end
end
if ~isempty(P), P=sortrows(unique(P,'rows'),1); end
end
function writepolar(fname,P,titulo)
fid=fopen(fname,'w');
fprintf(fid,'# Polar analizada XFOIL: %s\n# Re=3.166e6 Mach=0.242 xtr=0.05 N_crit=8.9\n',titulo);
fprintf(fid,'# %8s %8s %9s %8s %8s\n','alpha','Cl','Cd','Cdp','Cm');
fprintf(fid,'%10.2f %8.4f %9.5f %8.5f %8.4f\n',P');
fclose(fid);
end
function cleanx
for f={xfoil_out('POLAR_OUTPUT'),xfoil_out('doesntmatter'),xfoil_out('XFOIL_Output'),xfoil_out('XFOIL_CP_Output')}
  if exist(f{1},'file'), delete(f{1}); end
end
end
