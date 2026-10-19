cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise');
addpath('optim'); set_pub_defaults();
outdir='C:\Users\josea\Desktop\Opti_Param_ruidoio\auditoria_robusta';
[fluid,inputs]=inputs_definition();
% cross-model completo de los candidatos clave
geoms={'cst_baseline_NACA63218.dat','optimized_NACA63218_smoothA.dat','opt_63218_robusto.dat'};
nom={'base(18%)','delgado(13%)','robusto(15%)'};
modelos={'TNO','Goody','Kamruzzaman','Amiet'};
fprintf('%-14s %8s %8s %13s %8s\n','geometria',modelos{:});
M=nan(3,4);
for i=1:3
  for m=1:4
    for f={'POLAR_OUTPUT','doesntmatter','XFOIL_Output','XFOIL_CP_Output'},if exist(f{1},'file'),delete(f{1});end;end
    inp=inputs; inp.model=modelos{m};
    try,[oa,~,~,~]=evaluate_airfoil(geoms{i},inp,fluid);M(i,m)=oa;catch,end
  end
  fprintf('%-14s %8.2f %8.2f %13.2f %8.2f\n',nom{i},M(i,:));
end
fprintf('\nREDUCCION (base - optimo):\n');
for i=2:3
  fprintf('  %-13s TNO %+.2f | Goody %+.2f | Kamr %+.2f | Amiet %+.2f\n',nom{i},M(1,:)-M(i,:));
end
% silueta
files={'cst_baseline_NACA63218.dat','optimized_NACA63218_smoothA.dat','opt_63218_robusto.dat'};
lab={'base 18%','delgado 13% (solo TNO)','robusto 15% (todos los modelos)'};
col={[0 0 0],[0.85 0.1 0.1],[0 0.45 0.2]}; sty={'-','--','-'};
figure('Color','w','Position',[40 40 720 360]); hold on; grid on;
for i=1:3, D=dlmread(files{i}); plot(D(:,1),D(:,2),sty{i},'Color',col{i},'LineWidth',1.5,'DisplayName',lab{i}); end
axis equal; xlabel('x/c'); ylabel('y/c'); legend('Location','southoutside','FontSize',8);
title('NACA 63-218: base vs optimo robusto');
savefig300(gcf,fullfile(outdir,'fig_silueta_robusto'),13);
fprintf('figura guardada\n'); exit(0);
