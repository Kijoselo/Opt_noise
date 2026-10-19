cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise'); addpath('optim'); set_pub_defaults();
pkg='C:\Users\josea\Desktop\Opti_Param_ruidoio\paquete_revision_final';
[fluid,inputs]=inputs_definition();
casos={'63218','cst_baseline_NACA63218.dat','opt_NACA63218_expandido.dat';
       '63221','cst_baseline_NACA63221.dat','opt_NACA63221_expandido.dat'};
for c=1:2
  cid=casos{c,1}; od=fullfile(pkg,['NACA' cid]);
  for f={'POLAR_OUTPUT','doesntmatter','XFOIL_Output','XFOIL_CP_Output'},if exist(f{1},'file'),delete(f{1});end;end
  [oaB,~,~,ob]=evaluate_airfoil(casos{c,2},inputs,fluid);
  for f={'POLAR_OUTPUT','doesntmatter','XFOIL_Output','XFOIL_CP_Output'},if exist(f{1},'file'),delete(f{1});end;end
  [oaO,~,~,oo]=evaluate_airfoil(casos{c,3},inputs,fluid);
  f=ob.f; pref=20e-6;
  Sb=10*log10(ob.S_pp/pref^2); So=10*log10(oo.S_pp/pref^2);
  [Lb,Fc]=NarrowToNthOctave(f,Sb,3); [Lo,~]=NarrowToNthOctave(f,So,3);
  figure('Color','w','Position',[40 40 1250 410]);
  subplot(1,3,1); semilogx(f,Sb,'k-','LineWidth',1.2); hold on; semilogx(f,So,'r-','LineWidth',1.2);
  grid on; xlabel('f [Hz]'); ylabel('SPL [dB] (sin filtro A)');
  legend('base','optimo','Location','southwest','FontSize',8);

  text(0.03,0.03,'(a) banda estrecha','Units','normalized','FontSize',8);
  subplot(1,3,2); semilogx(Fc,Lb,'ko-','MarkerSize',3,'LineWidth',1.1); hold on; semilogx(Fc,Lo,'rs-','MarkerSize',3,'LineWidth',1.1);
  grid on; xlabel('f centro 1/3-oct [Hz]'); ylabel('SPL [dB] (sin filtro A)');
  legend('base','optimo','Location','southwest','FontSize',8);
  text(0.03,0.03,'(b) tercio de octava','Units','normalized','FontSize',8);
  subplot(1,3,3); semilogx(Fc,Lo-Lb,'b^-','MarkerSize',3,'LineWidth',1.1); hold on; yline(0,'k:');
  grid on; xlabel('f centro 1/3-oct [Hz]'); ylabel('\Delta SPL = opt - base [dB]');
  text(0.03,0.94,'(c) diferencia por banda','Units','normalized','FontSize',8);
  sgtitle(sprintf('NACA %s  --  OASPL(A) con filtro A: base %.2f, optimo %.2f dBA', cid, oaB, oaO),'FontSize',10);
  savefig300(gcf,fullfile(od,['fig_OASPL_espectro_NACA' cid]),19);
  fprintf('NACA%s espectro regenerado: %.2f -> %.2f dBA\n', cid, oaB, oaO);
end
exit(0);
