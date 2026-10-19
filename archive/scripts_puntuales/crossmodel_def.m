cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise'); addpath('optim');
[fluid,inputs]=inputs_definition();
m4={'TNO','Goody','Kamruzzaman','Amiet'};
casos={'63218','cst_baseline_NACA63218.dat','opt_NACA63218_definitivo.dat';
       '63221','cst_baseline_NACA63221.dat','opt_NACA63221_definitivo.dat'};
for c=1:2
  fprintf('=== NACA%s (definitivo, malla convergida) ===\n',casos{c,1});
  fprintf('%-13s %8s %8s %13s %8s\n','','TNO','Goody','Kamruzzaman','Amiet');
  Mb=nan(1,4); Mo=nan(1,4);
  for g=1:2
    for m=1:4
      for f={'POLAR_OUTPUT','doesntmatter','XFOIL_Output','XFOIL_CP_Output'},if exist(f{1},'file'),delete(f{1});end;end
      inp=inputs; inp.model=m4{m};
      try,[oa,~,~,~]=evaluate_airfoil(casos{c,g+1},inp,fluid); if isfinite(oa)&&isreal(oa), if g==1,Mb(m)=oa; else,Mo(m)=oa; end; end; catch, end
    end
  end
  fprintf('%-13s %8.2f %8.2f %13.2f %8.2f\n','base',Mb);
  fprintf('%-13s %8.2f %8.2f %13.2f %8.2f\n','optimo',Mo);
  fprintf('%-13s %+8.2f %+8.2f %+13.2f %+8.2f\n','reduccion',Mb-Mo);
  fprintf('  peor-caso(3 modelos gradiente): base %.2f -> opt %.2f dBA\n\n', max(Mb(1:3)), max(Mo(1:3)));
end
exit(0);
