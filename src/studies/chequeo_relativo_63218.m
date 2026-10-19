function chequeo_relativo_63218
% CHEQUEO_RELATIVO_63218  Punto C3 del revisor: reoptimiza el NACA 63-218 con el
% objetivo ROBUSTO RELATIVO  min max_m [L_m(a)-L_m(a0)]  (quita offsets entre
% modelos), con el MISMO dominio (+-80%, cap 1.4*T0), restricciones y presupuesto
% que la corrida definitiva absoluta. Compara el optimo relativo con el absoluto.
% No toca la fisica.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
outdir=fullfile(rutas.simulaciones,'estudios_previos','chequeo_relativo')   % (reorganizacion);
if ~exist(outdir,'dir'), mkdir(outdir); end
global HLOG; %#ok<GVMIS>
[fluid,inputs]=inputs_definition();
caso='NACA63218.txt'; [~,cid]=fileparts(caso); tt=tic;

P=setup_problem('base',caso,'bw_rel',0.8,'write_legacy',false);
ctx=P.ctx; ctx.T0=1.4*ctx.T0; nu=ctx.nu;
R0=ref3(P.dv0,ctx);                 % baseline 3-model levels [TNO Goody Kamr]
ctx.oa0=R0;
fprintf('base 3-model (CST proj): TNO %.2f Goody %.2f Kamr %.2f\n', R0(1),R0(2),R0(3));

HLOG=[];
opts=optimoptions('patternsearch','Display','iter','MaxFunctionEvaluations',2000, ...
    'UseCompletePoll',true,'MeshTolerance',1e-4);
dv=patternsearch(@(d) obj_log_rel(d,ctx), P.dv0, [],[],[],[], P.lb,P.ub, @(d) con_clcd(d,ctx), opts);

dat=fullfile(outdir,sprintf('opt_%s_relativo.dat',cid));
[xo,yo]=cst_to_coords(dv(1:nu),dv(nu+1:end),ctx.yte_u,ctx.yte_l,ctx.npts,ctx.N1,ctx.N2);
write_airfoil_dat(dat,xo,yo);
Rc=eval_airfoil_cached(dv,ctx);

% cross-model (4) para: baseline crudo, optimo ABSOLUTO (existente), optimo RELATIVO (nuevo)
absdat=fullfile(fullfile(rutas.simulaciones,'estudios_previos','definitivo_robusto'),'opt_NACA63218_definitivo.dat');
m4={'TNO','Goody','Kamruzzaman','Amiet'}; oaB=nan(1,4); oaA=nan(1,4); oaR=nan(1,4);
for m=1:4
  inp=inputs; inp.model=m4{m};
  oaB(m)=directe(caso,inp,fluid);
  oaA(m)=directe(absdat,inp,fluid);
  oaR(m)=directe(dat,inp,fluid);
end

fprintf('\n=== CHEQUEO RELATIVO 63-218 (objetivo min max dL) ===\n');
fprintf('  %-12s %8s %8s %8s\n','modelo','base','abs-opt','rel-opt');
for m=1:4
  fprintf('  %-12s %8.2f %8.2f %8.2f   red: abs %+.2f | rel %+.2f\n', ...
    m4{m}, oaB(m), oaA(m), oaR(m), oaB(m)-oaA(m), oaB(m)-oaR(m));
end
fprintf('  MIN reduccion (peor de los 3 grad-models): abs %.2f | rel %.2f\n', ...
  min(oaB(1:3)-oaA(1:3)), min(oaB(1:3)-oaR(1:3)));
fprintf('  Cl/Cd rel %.1f (base %.1f) | tmax rel %.4f | %d evals | %.1f min\n', ...
  Rc.clcd, P.clcd0, Rc.tmax, size(HLOG,1), toc(tt)/60);

save(fullfile(outdir,sprintf('rel_%s.mat',cid)),'dv','HLOG','R0','oaB','oaA','oaR','m4','Rc');
fprintf('=== FIN CHEQUEO RELATIVO ===\n');
end

function oa3=ref3(dv,ctx), [~,d]=obj_noise_robusto(dv,ctx); oa3=d.oa; end
function J=obj_log_rel(dv,ctx)
global HLOG; [J,d]=obj_noise_robusto_rel(dv,ctx);
cc=NaN;tm=NaN;v=0; if isfield(d,'clcd')&&~isempty(d.clcd), cc=d.clcd; tm=d.tmax; v=1; end
HLOG(end+1,:)=[size(HLOG,1)+1,J,cc,tm,v];
end
function oa=directe(datfile,inputs,fluid)
for f={xfoil_out('POLAR_OUTPUT'),xfoil_out('doesntmatter'),xfoil_out('XFOIL_Output'),xfoil_out('XFOIL_CP_Output')}, if exist(f{1},'file'),delete(f{1});end; end
oa=NaN; try, [oa,~,~,~]=evaluate_airfoil(datfile,inputs,fluid); catch, end
if ~isfinite(oa)||~isreal(oa), oa=NaN; end
end
