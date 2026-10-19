function env_63221
% ENV_63221  Off-design del NACA 63-221 (caso principal, optimo mono-modelo) en
% el MISMO rango AOA que el 63-218 (comentario 6 del comite): alpha -8..+6 deg,
% dos condiciones de flujo. Genera fig_offdesign_NACA63221.png con la paleta
% estandar (base=naranja solido/discontinuo por Re, opt=azul). No toca la fisica.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
set_pub_defaults(); pc=pub_colors();
figdir=rutas.figuras;   % (reorganizacion) antes paper/figures
P=setup_problem('base','NACA63221.txt','write_legacy',false);
base=P.ctx.baseline_file; opt=P.ctx.opt_file;
[fluid,~]=inputs_definition();
alphas=-8:2:6; speeds=[83.31 60];        % Re 3.17e6 y 2.28e6
res=struct();
for u=1:2
  for g=1:2
    dat=base; if g==2, dat=opt; end
    oa=nan(size(alphas));
    for k=1:numel(alphas)
      for f={xfoil_out('POLAR_OUTPUT'),xfoil_out('doesntmatter'),xfoil_out('XFOIL_Output'),xfoil_out('XFOIL_CP_Output')},if exist(f{1},'file'),delete(f{1});end;end
      [~,inp]=inputs_definition(); inp.AoA=alphas(k); inp.U=speeds(u);
      inp.M=inp.U/fluid.c0; inp.Re=inp.chord*inp.U/fluid.ni; inp.model='TNO';
      try,[o,~,~,~]=evaluate_airfoil(dat,inp,fluid); if isfinite(o)&&isreal(o), oa(k)=o; end; catch,end
    end
    res(u,g).oa=oa;
  end
  Re=speeds(u)*0.57/1.5e-5;
  fprintf('Re=%.2fe6: dOASPL(base-opt)= %s\n',Re/1e6,sprintf('%6.2f',res(u,1).oa-res(u,2).oa));
end
save('env_63221.mat','res','alphas','speeds');

Re=speeds*0.57/1.5e-5; sty={'-','--'};
figure('Color','w','Position',[40 40 560 430]); hold on; box on; grid on;
for u=1:2
  plot(alphas,res(u,1).oa,sty{u},'Color',pc.base,'LineWidth',1.5, ...
       'DisplayName',sprintf('base, Re=%.2f\\times10^6',Re(u)/1e6));
  plot(alphas,res(u,2).oa,sty{u},'Color',pc.opt,'LineWidth',1.5, ...
       'DisplayName',sprintf('opt, Re=%.2f\\times10^6',Re(u)/1e6));
end
xline(4,'k:','HandleVisibility','off');
xlabel('\alpha [deg]'); ylabel('OASPL(A) [dBA]'); legend('Location','best','FontSize',7);
savefig300(gcf,fullfile(figdir,'fig_offdesign_NACA63221'),9);
fprintf('OK env_63221\n');
end
