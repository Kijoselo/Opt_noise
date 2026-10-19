function opt_expandido(basefile, cap_factor, bw)
% OPT_EXPANDIDO  Optimizacion con DOMINIO EXPANDIDO: permite que el perfil
% ENGROSE por encima del base (cap subido) y da mas rango a los coeficientes
% (caja mas ancha). Objetivo ROBUSTO (peor caso TNO/Goody/Kamruzzaman).
% No toca la fisica: solo sube el cap de espesor (ctx.T0) y la caja (bw_rel).
%
%   opt_expandido('NACA63218.txt', 1.4, 0.8)   % cap hasta 1.4*T0, caja +-80%
if nargin<1||isempty(basefile), basefile='NACA63218.txt'; end
if nargin<2||isempty(cap_factor), cap_factor=1.4; end
if nargin<3||isempty(bw), bw=0.8; end
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
outdir=fullfile(rutas.simulaciones,'estudios_previos','dominio_expandido')   % (reorganizacion);
if ~exist(outdir,'dir'), mkdir(outdir); end
t0=tic; [~,cid]=fileparts(basefile);

P = setup_problem('base',basefile,'bw_rel',bw,'write_legacy',false);
ctx=P.ctx; nu=ctx.nu;
T0_orig = ctx.T0;
ctx.T0 = cap_factor*T0_orig;                 % <- SUBE EL CAP: permite engrosar
fprintf('=== DOMINIO EXPANDIDO: %s ===\n', cid);
fprintf('  caja: +-%.0f%% (antes +-50%%)\n', 100*bw);
fprintf('  espesor permitido: [%.3f, %.3f]  (antes cap era %.3f = base)\n', ...
        ctx.tmax_min, ctx.T0, T0_orig);

R0 = ref3(P.dv0, ctx);
fprintf('  base: peor-caso %.3f dBA [TNO %.2f Goody %.2f Kamr %.2f], tmax %.3f\n\n', ...
        max(R0), R0(1),R0(2),R0(3), T0_orig);

opts=optimoptions('patternsearch','Display','iter','MaxFunctionEvaluations',800, ...
    'UseCompletePoll',true,'MeshTolerance',1e-4);
dv=patternsearch(@(d) obj_noise_robusto(d,ctx), P.dv0, [],[],[],[], ...
                 P.lb, P.ub, @(d) con_clcd(d,ctx), opts);

dat=fullfile(outdir,sprintf('opt_%s_expandido.dat',cid));
[xo,yo]=cst_to_coords(dv(1:nu),dv(nu+1:end),ctx.yte_u,ctx.yte_l,ctx.npts,ctx.N1,ctx.N2);
write_airfoil_dat(dat,xo,yo);
Rf=ref3(dv,ctx); Rc=eval_airfoil_cached(dv,ctx);
fprintf('\n=== OPTIMO (dominio expandido, robusto) ===\n');
fprintf('  peor-caso: %.3f -> %.3f dBA\n', max(R0), max(Rf));
fprintf('  TNO %.2f->%.2f | Goody %.2f->%.2f | Kamr %.2f->%.2f\n', ...
        R0(1),Rf(1),R0(2),Rf(2),R0(3),Rf(3));
fprintf('  Cl/Cd %.1f | tmax %.4f (base %.4f) | %s\n', Rc.clcd, Rc.tmax, T0_orig, ...
        ternary(Rc.tmax>T0_orig,'ENGROSO respecto al base','no engroso'));
fprintf('  guardado: %s\n', dat);

% --- banda alcanzable expandida + siluetas ---
xs=0.5*(1-cos(linspace(0,pi,200)'));
uMax=cst_eval(xs,P.ub(1:nu),ctx.yte_u,ctx.N1,ctx.N2);
uMin=cst_eval(xs,P.lb(1:nu),ctx.yte_u,ctx.N1,ctx.N2);
lMax=cst_eval(xs,P.ub(nu+1:end),ctx.yte_l,ctx.N1,ctx.N2);
lMin=cst_eval(xs,P.lb(nu+1:end),ctx.yte_l,ctx.N1,ctx.N2);
figure('Color','w','Position',[40 40 760 420]); hold on; grid on;
fill([xs;flipud(xs)],[uMax;flipud(uMin)],[.8 .85 .95],'EdgeColor',[.4 .55 .8],'FaceAlpha',.5,'DisplayName','rango extrados (expandido)');
fill([xs;flipud(xs)],[lMax;flipud(lMin)],[.97 .9 .82],'EdgeColor',[.8 .55 .35],'FaceAlpha',.5,'DisplayName','rango intrados (expandido)');
ab=load_airfoil(P.base_file);
plot(ab.xu,ab.yu,'k-','LineWidth',1.6,'DisplayName','baseline');
plot(ab.xl,ab.yl,'k-','LineWidth',1.6,'HandleVisibility','off');
plot(xo,yo,'r-','LineWidth',1.6,'DisplayName','optimo expandido');
axis equal; xlabel('x/c'); ylabel('y/c'); legend('Location','northeast','FontSize',8);
title(sprintf('%s: dominio expandido (caja +-%.0f%%, cap %.1fxT0)',cid,100*bw,cap_factor));
savefig300(gcf,fullfile(outdir,sprintf('fig_dominio_expandido_%s',cid)),15);

save(fullfile(outdir,sprintf('exp_%s.mat',cid)),'dv','R0','Rf');
fprintf('\n=== COMPLETO en %.1f min ===\n', toc(t0)/60);
end

function oa3=ref3(dv,ctx), [~,d]=obj_noise_robusto(dv,ctx); oa3=d.oa; end
function s=ternary(c,a,b), if c,s=a; else,s=b; end, end
