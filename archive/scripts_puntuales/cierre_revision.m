cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise');
addpath('optim'); set_pub_defaults();
outdir='C:\Users\josea\Desktop\Opti_Param_ruidoio\revision_minimo_local';
[fluid,inputs]=inputs_definition();
modelos={'TNO','Goody','Kamruzzaman','Amiet'};
geoms={'opt_63218_grueso.dat','opt_63218_libre.dat'};
nom={'grueso-A(17%)','libre-B(16.5%)'};
fprintf('%-16s %9s %9s %13s %9s\n','geometria',modelos{:});
for i=1:2
  row=nan(1,4);
  for m=1:4
    for f={'POLAR_OUTPUT','doesntmatter','XFOIL_Output','XFOIL_CP_Output'}, if exist(f{1},'file'),delete(f{1});end;end
    inp=inputs; inp.model=modelos{m};
    try, [oa,~,~,~]=evaluate_airfoil(geoms{i},inp,fluid); row(m)=oa; catch, end
  end
  fprintf('%-16s %9.3f %9.3f %13.3f %9.3f\n',nom{i},row);
end
% siluetas
files={'cst_baseline_NACA63218.dat','optimized_NACA63218_smoothA.dat','opt_63218_grueso.dat','opt_63218_libre.dat'};
lab={'base (18%)','delgado 13% (65.76)','grueso-A 17% (66.23)','libre-B 16.5% (65.07)'};
col={[0 0 0],[0.85 0.1 0.1],[0.2 0.5 0.2],[0 0.35 0.85]};
sty={'-','--','-.','-'};
figure('Color','w','Position',[40 40 720 380]); hold on; grid on;
for i=1:4
  D=dlmread(files{i}); plot(D(:,1),D(:,2),sty{i},'Color',col{i},'LineWidth',1.4,'DisplayName',lab{i});
end
axis equal; xlabel('x/c'); ylabel('y/c'); legend('Location','southoutside','NumColumns',2,'FontSize',8);
title('NACA 63-218: base vs optimos');
savefig300(gcf,fullfile(outdir,'fig_siluetas_revision'),13);
fprintf('figura guardada\n'); exit(0);
