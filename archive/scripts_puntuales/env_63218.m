cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise'); addpath('optim'); set_pub_defaults();
outdir='C:\Users\josea\Desktop\Opti_Param_ruidoio\sensibilidad_63218'; if ~exist(outdir,'dir'),mkdir(outdir);end
base='cst_baseline_NACA63218.dat'; opt='opt_NACA63218_definitivo.dat';
alphas=-8:2:8; speeds=[83.31 60];  % Re 3.17e6 y 2.28e6
[fluid,~]=inputs_definition();
res=struct();
for u=1:2
  for g=1:2
    dat=base; if g==2, dat=opt; end
    oa=nan(size(alphas)); cl=oa; cd=oa;
    for k=1:numel(alphas)
      for f={'POLAR_OUTPUT','doesntmatter','XFOIL_Output','XFOIL_CP_Output'},if exist(f{1},'file'),delete(f{1});end;end
      [~,inp]=inputs_definition(); inp.AoA=alphas(k); inp.U=speeds(u);
      inp.M=inp.U/fluid.c0; inp.Re=inp.chord*inp.U/fluid.ni;
      try,[o,Cl,Cd,~]=evaluate_airfoil(dat,inp,fluid); if isfinite(o), oa(k)=o; cl(k)=Cl; cd(k)=Cd; end; catch,end
    end
    res(u,g).oa=oa; res(u,g).cl=cl; res(u,g).cd=cd;
  end
  Re=speeds(u)*0.57/1.5e-5;
  fprintf('Re=%.2fe6:\n a:   %s\n dOASPL(base-opt): %s\n', Re/1e6, sprintf('%6.0f',alphas), sprintf('%6.2f',res(u,1).oa-res(u,2).oa));
end
save(fullfile(outdir,'env.mat'),'res','alphas','speeds');
% figura
figure('Color','w','Position',[40 40 1150 420]);
col={[0 0 0],[0 0.4 0.8]}; Re=speeds*0.57/1.5e-5;
subplot(1,2,1); hold on; grid on;
for u=1:2, plot(alphas,res(u,1).oa-res(u,2).oa,'-o','Color',col{u},'LineWidth',1.4,'DisplayName',sprintf('Re=%.1fe6',Re(u)/1e6)); end
yline(0,'k:','HandleVisibility','off'); xline(4,'k--','diseno','HandleVisibility','off');
xlabel('\alpha [deg]'); ylabel('\Delta OASPL(A) = base - opt [dBA]'); legend('Location','best','FontSize',8);
title('(a) reduccion vs angulo de operacion');
subplot(1,2,2); hold on; grid on;
for u=1:2
  plot(alphas,res(u,1).cl./res(u,1).cd,'--','Color',col{u},'LineWidth',1.2,'DisplayName',sprintf('base Re=%.1fe6',Re(u)/1e6));
  plot(alphas,res(u,2).cl./res(u,2).cd,'-','Color',col{u},'LineWidth',1.4,'DisplayName',sprintf('opt Re=%.1fe6',Re(u)/1e6));
end
xlabel('\alpha [deg]'); ylabel('Cl/Cd'); legend('Location','best','FontSize',7);
title('(b) eficiencia vs angulo');
savefig300(gcf,fullfile(outdir,'fig_sensibilidad_operacion_63218'),19);
fprintf('listo\n'); exit(0);
