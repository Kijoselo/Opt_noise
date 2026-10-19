function crossmodel_rel
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
[fluid,inputs]=inputs_definition();
% (reorganizacion) los optimos de los estudios previos estan en results/simulations/estudios_previos
root=fullfile(rutas.simulaciones,'estudios_previos');
copyfile(fullfile(root,'definitivo_robusto','opt_NACA63218_definitivo.dat'),'abs_opt.dat');
copyfile(fullfile(root,'chequeo_relativo','opt_NACA63218_relativo.dat'),'rel_opt.dat');
geoms={'NACA63218.txt','abs_opt.dat','rel_opt.dat'}; lab={'base','abs-opt','rel-opt'};
m4={'TNO','Goody','Kamruzzaman','Amiet'};
OA=nan(3,4);
for g=1:3, for m=1:4
  for f={xfoil_out('POLAR_OUTPUT'),xfoil_out('doesntmatter'),xfoil_out('XFOIL_Output'),xfoil_out('XFOIL_CP_Output')},if exist(f{1},'file'),delete(f{1});end;end
  inp=inputs; inp.model=m4{m};
  try,[oa,~,~,~]=evaluate_airfoil(geoms{g},inp,fluid); if isfinite(oa)&&isreal(oa),OA(g,m)=oa;end; catch,end
end, end
fprintf('\n===== CROSS-MODEL 63-218: absoluto vs relativo =====\n');
fprintf('%-12s %8s %8s %8s %8s\n','geometria',m4{:});
for g=1:3, fprintf('%-12s %8.2f %8.2f %8.2f %8.2f\n',lab{g},OA(g,:)); end
fprintf('\nREDUCCION (base - opt), + = mas silencioso:\n');
fprintf('%-12s %8s %8s %8s %8s %10s\n','opt','TNO','Goody','Kamr','Amiet','MIN(3grad)');
for g=2:3, r=OA(1,:)-OA(g,:); fprintf('%-12s %+8.2f %+8.2f %+8.2f %+8.2f %10.2f\n',lab{g},r,min(r(1:3))); end
% tmax con lector robusto (salta encabezados no numericos)
tm=nan(1,3);
for g=1:3
  txt=fileread(geoms{g}); L=regexp(txt,'\r?\n','split'); XY=[];
  for i=1:numel(L), v=sscanf(L{i},'%f'); if numel(v)>=2, XY=[XY; v(1:2)']; end; end
  [~,i]=min(XY(:,1)); xu=XY(1:i,1);yu=XY(1:i,2);xl=XY(i:end,1);yl=XY(i:end,2);
  [xu,ku]=unique(xu);yu=yu(ku);[xl,kl]=unique(xl);yl=yl(kl); xs=linspace(0,1,300)';
  tm(g)=max(interp1(xu,yu,xs,'pchip')-interp1(xl,yl,xs,'pchip'));
end
fprintf('\nESPESOR tmax/c: base %.4f | abs-opt %.4f | rel-opt %.4f\n',tm(1),tm(2),tm(3));
save([root 'chequeo_relativo\crossmodel.mat'],'OA','tm','m4','lab');
fprintf('OK\n');
end
