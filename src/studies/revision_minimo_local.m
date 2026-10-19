function revision_minimo_local
% REVISION_MINIMO_LOCAL  Verifica si el optimo delgado del NACA 63-218 es un
% minimo local, SIN tocar la fisica (Amiet/TNO). Solo cambia parametros de la
% capa de optimizacion: punto de arranque, cotas de restriccion y modelo WPS.
%
%   Exp A: re-optimizacion con ESPESOR FORZADO ALTO (piso 0.95*T0).
%   Exp B: OTRO optimizador (PSO global) + dominio mas amplio (+-70%).
%   Exp C: cross-check con los 4 modelos ya en el codigo (TNO/Goody/
%          Kamruzzaman/Amiet) por evaluacion DIRECTA (sin cache).
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
outdir = fullfile(rutas.simulaciones,'estudios_previos','revision_minimo_local')   % (reorganizacion);
if ~exist(outdir,'dir'), mkdir(outdir); end
t0 = tic;

base_dat    = 'cst_baseline_NACA63218.dat';
delgado_dat = 'optimized_NACA63218_smoothA.dat';   % optimo delgado (65.76)

%% ---------- referencia ----------
[fluid, inputs] = inputs_definition();
oaB = direct_eval(base_dat,    inputs, fluid);
oaD = direct_eval(delgado_dat, inputs, fluid);
fprintf('\n=== REFERENCIA (modelo TNO) ===\n');
fprintf('  base 63-218 (18%%)     : %.3f dBA\n', oaB.oa);
fprintf('  optimo delgado (13%%)  : %.3f dBA  (Cl/Cd %.1f, tmax %.3f)\n\n', ...
        oaD.oa, oaD.clcd, oaD.tmax);

%% ---------- EXP A: espesor forzado alto ----------
fprintf('>>>>>>>> EXP A: re-optimizacion con espesor forzado alto\n');
PA = setup_problem('base','NACA63218.txt','write_legacy',false);
PA.ctx.tmax_min = 0.95*PA.ctx.T0;              % <- fuerza espesor en [17.1%,18%]
fprintf('  espesor bloqueado en [%.3f, %.3f]\n', PA.ctx.tmax_min, PA.ctx.T0);
optsPS = optimoptions('patternsearch','Display','off', ...
    'MaxFunctionEvaluations',1200,'UseCompletePoll',true,'MeshTolerance',1e-4);
dvA = patternsearch(@(d) obj_noise_pure(d,PA.ctx), PA.dv0, [],[],[],[], ...
                    PA.lb, PA.ub, @(d) con_clcd(d,PA.ctx), optsPS);
grueso_dat = fullfile(outdir,'opt_63218_grueso.dat');
save_geom(dvA, PA.ctx, grueso_dat);
rA = geom_report(dvA, PA.ctx);
fprintf('  RESULTADO grueso: %.3f dBA | Cl/Cd %.1f | tmax %.3f | camber %.4f | H %.2f | Cf %.5f\n', ...
        rA.oa, rA.clcd, rA.tmax, rA.camber, rA.H, rA.Cf);
fprintf('  vs delgado 65.76: %s\n', veredicto(rA.oa, oaD.oa));
fprintf('<<<<<<<< EXP A done\n\n');

%% ---------- EXP B: PSO global + caja +-70% ----------
fprintf('>>>>>>>> EXP B: PSO global, dominio +-70%%\n');
PB = setup_problem('base','NACA63218.txt','bw_rel',0.7,'write_legacy',false);
n = numel(PB.dv0);
optsPSO = optimoptions('particleswarm','Display','off','SwarmSize',40, ...
    'MaxIterations',25,'InitialSwarmMatrix',PB.dv0');
rng(1);
dvB = particleswarm(@(d) obj_noise(d,PB.ctx), n, PB.lb, PB.ub, optsPSO);
libre_dat = fullfile(outdir,'opt_63218_libre.dat');
save_geom(dvB, PB.ctx, libre_dat);
rB = geom_report(dvB, PB.ctx);
fprintf('  RESULTADO libre: %.3f dBA | Cl/Cd %.1f | tmax %.3f | camber %.4f | H %.2f | Cf %.5f\n', ...
        rB.oa, rB.clcd, rB.tmax, rB.camber, rB.H, rB.Cf);
fprintf('  vs delgado 65.76: %s\n', veredicto(rB.oa, oaD.oa));
fprintf('<<<<<<<< EXP B done\n\n');

%% ---------- EXP C: cross-model (4 modelos del codigo) ----------
fprintf('>>>>>>>> EXP C: cross-check con TNO/Goody/Kamruzzaman/Amiet\n');
geoms  = {base_dat, delgado_dat, grueso_dat, libre_dat};
nombres= {'base(18%)','delgado(13%)','grueso-A','libre-B'};
modelos= {'TNO','Goody','Kamruzzaman','Amiet'};
M = nan(numel(geoms), numel(modelos));
fprintf('%-14s %9s %9s %13s %9s\n', 'geometria', modelos{:});
for i = 1:numel(geoms)
    for m = 1:numel(modelos)
        inp = inputs; inp.model = modelos{m};
        r = direct_eval(geoms{i}, inp, fluid);
        M(i,m) = r.oa;
    end
    fprintf('%-14s %9.3f %9.3f %13.3f %9.3f\n', nombres{i}, M(i,:));
end
fprintf('<<<<<<<< EXP C done\n');

save(fullfile(outdir,'revision.mat'),'rA','rB','oaB','oaD','M','nombres','modelos');
fprintf('\n=== REVISION COMPLETA en %.1f min. Resultados en %s ===\n', toc(t0)/60, outdir);
end

%% ================= helpers =================
function r = direct_eval(datfile, inputs, fluid)
% evaluacion DIRECTA (sin cache) para poder variar el modelo con seguridad
for f = {xfoil_out('POLAR_OUTPUT'),xfoil_out('doesntmatter'),xfoil_out('XFOIL_Output'),xfoil_out('XFOIL_CP_Output')}
    if exist(f{1},'file'), delete(f{1}); end
end
r = struct('oa',NaN,'clcd',NaN,'tmax',NaN);
try
    [oa,Cl,Cd,~] = evaluate_airfoil(datfile, inputs, fluid);
    r.oa=oa; r.clcd=Cl/Cd;
    a = load_airfoil(datfile);
    xg = 0.5*(1-cos(linspace(0,pi,200)'));
    r.tmax = max(interp1(a.xu,a.yu,xg,'pchip') - interp1(a.xl,a.yl,xg,'pchip'));
catch ME
    fprintf('  [eval fail] %s: %s\n', datfile, ME.message);
end
end

function r = geom_report(dv, ctx)
R = eval_airfoil_cached(dv, ctx);
nu = ctx.nu;
[~,~,xu,yu,xl,yl] = cst_to_coords(dv(1:nu), dv(nu+1:end), ...
    ctx.yte_u, ctx.yte_l, ctx.npts, ctx.N1, ctx.N2);
xg = 0.5*(1-cos(linspace(0,pi,200)'));
yug = interp1(xu,yu,xg,'pchip'); ylg = interp1(xl,yl,xg,'pchip');
r.oa = R.OASPL_A; r.clcd = R.clcd; r.tmax = R.tmax;
r.camber = max(abs(0.5*(yug+ylg)));
[Hs,Cfs] = suction_bl_probe(ctx.inputs.Mic);
r.H = Hs; r.Cf = Cfs;
end

function [H,Cf] = suction_bl_probe(pos)
H=NaN; Cf=NaN;
if ~exist(xfoil_out('XFOIL_Output'),'file'), return; end
try
    fid=fopen(xfoil_out('XFOIL_Output'),'r');
    D=textscan(fid,'%f%f%f%f%f%f%f%f','Delimiter',' ','MultipleDelimsAsOne',true,'CollectOutput',1,'HeaderLines',1);
    fclose(fid); D=D{1}; D=D(D(:,2)<=1.0001,:);
    half=1:floor(size(D,1)/2); [~,i]=min(abs(D(half,2)-pos));
    H=D(i,8); Cf=D(i,7);
catch, end
end

function save_geom(dv, ctx, fname)
nu = ctx.nu;
[x,y] = cst_to_coords(dv(1:nu), dv(nu+1:end), ctx.yte_u, ctx.yte_l, ctx.npts, ctx.N1, ctx.N2);
write_airfoil_dat(fname, x, y);
end

function s = veredicto(oa_nuevo, oa_delgado)
if oa_nuevo <= oa_delgado + 0.01
    s = sprintf('IGUAL O MEJOR (%.3f <= %.3f) -> el delgado NO era unico/optimo', oa_nuevo, oa_delgado);
else
    s = sprintf('peor (%.3f > %.3f) -> el delgado se sostiene', oa_nuevo, oa_delgado);
end
end
