function [J, detalle] = obj_noise_robusto(dv, ctx)
% OBJ_NOISE_ROBUSTO  Objetivo ROBUSTO multi-modelo: minimiza el PEOR caso del
% OASPL(A) sobre los modelos de presion de pared que YA tiene el codigo
% (TNO, Goody, Kamruzzaman). No modifica la fisica: solo cambia inputs.model y
% combina las salidas. Asi el optimo baja en TODOS los modelos, no solo en TNO.
%
%   J = max( OASPL_TNO, OASPL_Goody, OASPL_Kamruzzaman )
%   Disenos invalidos / no adheridos -> penalizacion (via la guarda de TNO).
%
% Estrategia de costo: la primera evaluacion (TNO) pasa por eval_airfoil_cached,
% que aplica TODAS las guardas (geometria, adherencia H<=2.7, Cf>=1.5e-4) y deja
% la geometria escrita en ctx.tmpfile. Goody y Kamruzzaman se evaluan por
% evaluate_airfoil directo sobre esa misma geometria (misma capa limite fisica).
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
% Se reescribe la geometria desde dv (no se confia en ctx.tmpfile, que en un
% cache-hit puede contener otro candidato) -> correccion garantizada.
[fluid, inp] = deal(ctx.fluid, ctx.inputs);
[xg, yg] = cst_to_coords(dv(1:ctx.nu), dv(ctx.nu+1:end), ...
                         ctx.yte_u, ctx.yte_l, ctx.npts, ctx.N1, ctx.N2);
geomfile = 'robusto_cand.dat';
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

% --- 3) peor caso (con penalizacion suave por deficit de Cl/Cd, como el resto) ---
oa = detalle.oa;
oa(~isfinite(oa)) = ctx.penalty;                   % si un modelo fallo, castigar
J = max(oa);
if isfield(ctx,'clcd_min') && R.clcd < ctx.clcd_min
    J = J + ctx.clcd_pen*(ctx.clcd_min - R.clcd);
end
detalle.valid = true; detalle.clcd = R.clcd; detalle.tmax = R.tmax;
end
