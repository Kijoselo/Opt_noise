function historial_expandido
% HISTORIAL_EXPANDIDO  Re-corre las optimizaciones de dominio expandido
% (deterministicas) registrando el HISTORIAL por evaluacion: OASPL peor-caso
% y Cl/Cd. Genera, por caso: (a) OASPL(peor-caso) vs evaluacion con mejor
% acumulado, (b) Cl/Cd vs evaluacion. Objetivo robusto TNO/Goody/Kamruzzaman.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
outdir=fullfile(rutas.simulaciones,'estudios_previos','dominio_expandido')   % (reorganizacion);
global HLOG; %#ok<GVMIS>

casos = {'NACA63218.txt','NACA63221.txt'};
for c = 1:2
    [~,cid]=fileparts(casos{c});
    P=setup_problem('base',casos{c},'bw_rel',0.8,'write_legacy',false);
    ctx=P.ctx; ctx.T0=1.4*ctx.T0;
    HLOG=[];
    opts=optimoptions('patternsearch','Display','off','MaxFunctionEvaluations',800, ...
        'UseCompletePoll',true,'MeshTolerance',1e-4);
    dv=patternsearch(@(d) obj_log(d,ctx), P.dv0, [],[],[],[], P.lb,P.ub, @(d) con_clcd(d,ctx), opts);
    Rc=eval_airfoil_cached(dv,ctx); [~,df]=obj_noise_robusto(dv,ctx);
    fprintf('%s: peor-caso final %.3f dBA | Cl/Cd %.1f | tmax %.4f | %d evals\n', ...
            cid, max(df.oa), Rc.clcd, Rc.tmax, size(HLOG,1));

    H=HLOG; n=size(H,1); idx=(1:n)';
    J=H(:,2); cc=H(:,3); valid=H(:,5)==1;
    Jbest=nan(n,1); b=inf; for k=1:n, if J(k)<b, b=J(k); end; Jbest(k)=b; end
    clcd0=P.clcd0;
    save(fullfile(outdir,sprintf('hist_%s.mat',cid)),'H','Jbest','clcd0');
    real = valid & isfinite(J) & J<150;        % OASPL fisico (no penalizado)
    pen  = J>=150;                             % Goody/Kamr no convergio
    fprintf('  %s: %d evals, %d validas fisicas, %d penalizadas (%.0f%% Goody/Kamr fallan)\n', ...
            cid, n, sum(real), sum(pen), 100*sum(pen)/n);

    figure('Color','w','Position',[40 40 1150 420]);
    subplot(1,2,1); hold on; grid on;
    plot(idx(real), J(real), '.', 'Color',[0.6 0.72 0.9],'MarkerSize',6,'DisplayName','evaluaciones validas');
    plot(idx, Jbest, 'b-','LineWidth',1.8,'DisplayName','mejor acumulado');
    plot(n, Jbest(end),'rp','MarkerSize',13,'MarkerFaceColor','r','DisplayName','optimo');
    lo=min(Jbest)-0.3; hi=prctile(J(real),98);
    if isfinite(lo)&&isfinite(hi)&&hi>lo, ylim([lo hi]); end
    xlabel('Evaluacion'); ylabel('OASPL peor-caso [dBA]'); legend('Location','northeast','FontSize',8);
    title(sprintf('(a) %s: convergencia OASPL', cid),'Interpreter','none');

    subplot(1,2,2); hold on; grid on;
    plot(idx(valid), cc(valid), '.', 'Color',[0.85 0.6 0.5],'MarkerSize',6,'DisplayName','evaluaciones');
    yline(clcd0,'k--','LineWidth',1.1,'DisplayName',sprintf('base Cl/Cd=%.1f (restriccion)',clcd0));
    plot(n, Rc.clcd,'rp','MarkerSize',13,'MarkerFaceColor','r','DisplayName',sprintf('optimo %.1f',Rc.clcd));
    xlabel('Evaluacion'); ylabel('Cl/Cd'); legend('Location','best','FontSize',8);
    title('(b) Cl/Cd (>= base)');
    savefig300(gcf, fullfile(outdir,sprintf('fig_historial_%s',cid)), 19);
end
fprintf('historiales guardados en %s\n', outdir);
end

function J = obj_log(dv, ctx)
global HLOG; %#ok<GVMIS>
[J, d] = obj_noise_robusto(dv, ctx);
cc=NaN; tm=NaN; v=0;
if isfield(d,'clcd') && ~isempty(d.clcd), cc=d.clcd; tm=d.tmax; v=1; end
HLOG(end+1,:) = [size(HLOG,1)+1, J, cc, tm, v];
end
