function [J, detalle] = obj_noise_robusto_rel(dv, ctx)
% OBJ_NOISE_ROBUSTO_REL  Objetivo ROBUSTO RELATIVO: minimiza el PEOR CAMBIO
% respecto al baseline de CADA modelo, quitando los offsets absolutos entre
% modelos (revisor, punto C3):
%
%   J = max_m [ L_m(dv) - L_m(baseline) ],   con ctx.oa0 = [L_TNO0 L_Goody0 L_Kamr0]
%
% Identica cadena fisica que obj_noise_robusto (TNO por cache con todas las
% guardas; Goody/Kamruzzaman por evaluacion directa sobre la MISMA geometria).
% NO modifica la fisica: solo cambia como se combinan las salidas.
modelos = {'TNO','Goody','Kamruzzaman'};
detalle = struct('oa',nan(1,3),'modelos',{modelos},'valid',false);

% --- 1) TNO con todas las guardas (cache) ---
ctxT = ctx; ctxT.inputs.model = 'TNO';
R = eval_airfoil_cached(dv, ctxT);
if ~R.valid
    J = ctx.penalty; return;                      % geometria/adherencia invalida
end
detalle.oa(1) = R.OASPL_A;

% --- 2) Goody y Kamruzzaman por evaluacion directa sobre la MISMA geometria ---
[fluid, inp] = deal(ctx.fluid, ctx.inputs);
[xg, yg] = cst_to_coords(dv(1:ctx.nu), dv(ctx.nu+1:end), ...
                         ctx.yte_u, ctx.yte_l, ctx.npts, ctx.N1, ctx.N2);
geomfile = 'robusto_rel_cand.dat';
write_airfoil_dat(geomfile, xg, yg);
for m = 2:3
    for f = {xfoil_out('POLAR_OUTPUT'),xfoil_out('doesntmatter'),xfoil_out('XFOIL_Output'),xfoil_out('XFOIL_CP_Output')}
        if exist(f{1},'file'), delete(f{1}); end
    end
    inp.model = modelos{m};
    try
        oa = evaluate_airfoil(geomfile, inp, fluid);
        if isfinite(oa) && isreal(oa), detalle.oa(m) = oa; end
    catch
    end
end

% --- 3) peor CAMBIO respecto al baseline de cada modelo ---
oa = detalle.oa;
oa(~isfinite(oa)) = ctx.penalty;                   % si un modelo fallo, castigar
dL = oa - ctx.oa0(:).';                            % L_m(a) - L_m(a0) por modelo
J  = max(dL);                                      % peor caso del CAMBIO
if isfield(ctx,'clcd_min') && R.clcd < ctx.clcd_min
    J = J + ctx.clcd_pen*(ctx.clcd_min - R.clcd);
end
detalle.valid = true; detalle.clcd = R.clcd; detalle.tmax = R.tmax; detalle.dL = dL;
end
