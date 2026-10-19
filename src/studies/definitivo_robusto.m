function definitivo_robusto
% DEFINITIVO_ROBUSTO  Corrida DEFINITIVA: optimizacion robusta (peor caso
% TNO/Goody/Kamruzzaman) a presupuesto 2000 (malla convergida 1e-4), dominio
% expandido (caja +-80%, cap de espesor liberado). Para 63218 y 63221.
% Guarda geometria definitiva, historial y comparacion cross-model (4 modelos).
% No toca la fisica.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
outdir=fullfile(rutas.simulaciones,'estudios_previos','definitivo_robusto')   % (reorganizacion);
if ~exist(outdir,'dir'), mkdir(outdir); end
global HLOG; %#ok<GVMIS>
[fluid,inputs]=inputs_definition();
casos={'NACA63218.txt','NACA63221.txt'};

for c=1:2
  [~,cid]=fileparts(casos{c}); tt=tic;
  fprintf('\n============ DEFINITIVO %s (presupuesto 2000) ============\n', cid);
  P=setup_problem('base',casos{c},'bw_rel',0.8,'write_legacy',false);
  ctx=P.ctx; ctx.T0=1.4*ctx.T0; nu=ctx.nu;
  R0=ref3(P.dv0,ctx);
  fprintf('base: peor-caso %.3f [TNO %.2f Goody %.2f Kamr %.2f]\n', max(R0),R0(1),R0(2),R0(3));

  HLOG=[];
  opts=optimoptions('patternsearch','Display','iter','MaxFunctionEvaluations',2000, ...
      'UseCompletePoll',true,'MeshTolerance',1e-4);
  dv=patternsearch(@(d) obj_log(d,ctx), P.dv0, [],[],[],[], P.lb,P.ub, @(d) con_clcd(d,ctx), opts);

  dat=fullfile(outdir,sprintf('opt_%s_definitivo.dat',cid));
  [xo,yo]=cst_to_coords(dv(1:nu),dv(nu+1:end),ctx.yte_u,ctx.yte_l,ctx.npts,ctx.N1,ctx.N2);
  write_airfoil_dat(dat,xo,yo);
  Rf=ref3(dv,ctx); Rc=eval_airfoil_cached(dv,ctx);
  % cross-model incl Amiet (evaluacion directa sobre el .dat)
  m4={'TNO','Goody','Kamruzzaman','Amiet'}; oa4b=nan(1,4); oa4o=nan(1,4);
  for m=1:4
    inp=inputs; inp.model=m4{m};
    oa4b(m)=directe(casos{c},inp,fluid); oa4o(m)=directe(dat,inp,fluid);
  end
  fprintf('\n=== OPTIMO DEFINITIVO %s ===\n', cid);
  fprintf('  peor-caso(TNO/Goody/Kamr): %.3f -> %.3f dBA\n', max(R0), max(Rf));
  fprintf('  cross-model  base -> optimo (reduccion):\n');
  for m=1:4, fprintf('    %-12s %.2f -> %.2f  (%+.2f)\n', m4{m}, oa4b(m), oa4o(m), oa4b(m)-oa4o(m)); end
  fprintf('  Cl/Cd %.1f (base %.1f) | tmax %.4f (base %.4f) | %d evals | %.1f min\n', ...
          Rc.clcd, P.clcd0, Rc.tmax, P.ctx.T0/1.4, size(HLOG,1), toc(tt)/60);

  save(fullfile(outdir,sprintf('def_%s.mat',cid)),'dv','HLOG','R0','Rf','oa4b','oa4o','m4');
end
fprintf('\n=== DEFINITIVO COMPLETO ===\n');
end

function oa3=ref3(dv,ctx), [~,d]=obj_noise_robusto(dv,ctx); oa3=d.oa; end
function J=obj_log(dv,ctx)
global HLOG; [J,d]=obj_noise_robusto(dv,ctx);
cc=NaN;tm=NaN;v=0; if isfield(d,'clcd')&&~isempty(d.clcd), cc=d.clcd; tm=d.tmax; v=1; end
HLOG(end+1,:)=[size(HLOG,1)+1,J,cc,tm,v];
end
function oa=directe(datfile,inputs,fluid)
for f={xfoil_out('POLAR_OUTPUT'),xfoil_out('doesntmatter'),xfoil_out('XFOIL_Output'),xfoil_out('XFOIL_CP_Output')}, if exist(f{1},'file'),delete(f{1});end; end
oa=NaN; try, [oa,~,~,~]=evaluate_airfoil(datfile,inputs,fluid); catch, end
if ~isfinite(oa)||~isreal(oa), oa=NaN; end
end
