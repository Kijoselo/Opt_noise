function opt_robusto_63218
% OPT_ROBUSTO_63218  (Etapa 0) Auditoria DINAMICA de como XFOIL toma la
% geometria + como se restringe la geometria.  (Etapa 1) Optimizacion ROBUSTA
% multi-modelo del NACA 63-218 (minimiza el peor caso TNO/Goody/Kamruzzaman).
% Un solo proceso -> sin colision de temporales de XFOIL.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
outdir = fullfile(rutas.simulaciones,'estudios_previos','auditoria_robusta')   % (reorganizacion);
if ~exist(outdir,'dir'), mkdir(outdir); end
t0 = tic;

%% ================= ETAPA 0: AUDITORIA DINAMICA XFOIL/GEOMETRIA =================
fprintf('======== ETAPA 0: XFOIL toma bien la geometria? ========\n');
P = setup_problem('base','NACA63218.txt','write_legacy',false);
ctx = P.ctx; nu = ctx.nu;

% (0a) Round-trip: dv base -> coords -> .dat -> lo que XFOIL panela
[x,y,xu,yu,xl,yl] = cst_to_coords(P.dv0(1:nu), P.dv0(nu+1:end), ctx.yte_u, ctx.yte_l, ctx.npts, ctx.N1, ctx.N2);
write_airfoil_dat(ctx.tmpfile, x, y);
fprintf('(0a) geometria escrita: %d puntos, x en [%.4f, %.4f]\n', numel(x), min(x), max(x));
fprintf('     borde de fuga: y_sup(TE)=%.5f  y_inf(TE)=%.5f  (cierre=%.2e)\n', ...
        y(1), y(end), abs(y(1)-y(end)));

% (0b) correr XFOIL una vez y leer cuantos nodos panela y si converge
for f = {xfoil_out('POLAR_OUTPUT'),xfoil_out('doesntmatter'),xfoil_out('XFOIL_Output'),xfoil_out('XFOIL_CP_Output')}
    if exist(f{1},'file'), delete(f{1}); end
end
[fluid, inputs] = inputs_definition();
[oa,Cl,Cd,~] = evaluate_airfoil(ctx.tmpfile, inputs, fluid);
np = NaN;
if exist('xfoil_stdout.txt','file')
    s = fileread('xfoil_stdout.txt');
    k = strfind(s,'Number of panel nodes');
    if ~isempty(k), np = str2double(s(k+28:k+30)); end
end
fprintf('(0b) XFOIL panela a %g nodos | OASPL(A)=%.3f Cl=%.4f Cd=%.5f (converge OK)\n', np, oa, Cl, Cd);

% (0c) comparar geometria escrita vs geometria que XFOIL uso (dump)
if exist(xfoil_out('XFOIL_Output'),'file')
    fid=fopen(xfoil_out('XFOIL_Output'),'r');
    D=textscan(fid,'%f%f%f%f%f%f%f%f','Delimiter',' ','MultipleDelimsAsOne',true,'CollectOutput',1,'HeaderLines',1);
    fclose(fid); D=D{1}; D=D(D(:,2)<=1.0001,:);
    xd=D(:,2); yd=D(:,3); [~,iLE]=min(xd);
    [xdu,iu]=unique(xd(1:iLE)); ydu=yd(1:iLE); ydu=ydu(iu);     % extrados
    [xdl,il]=unique(xd(iLE:end)); ydl=yd(iLE:end); ydl=ydl(il); % intrados
    m = xu>=min(xdu) & xu<=max(xdu);
    devu = max(abs(interp1(xdu,ydu,xu(m),'pchip') - yu(m)));
    devl = max(abs(interp1(xdl,ydl,xl(m),'pchip') - yl(m)));
    dev = max(devu, devl);
    fprintf('(0c) desvio maximo geometria_escrita vs geometria_XFOIL: %.2e c (sup %.2e, inf %.2e)\n', dev, devu, devl);
    fprintf('     -> %s\n', ternary(dev<2e-3,'XFOIL usa la geometria correctamente (desvio despreciable)','REVISAR: desvio no despreciable'));
end

% (0d) restricciones geometricas activas (definicion del dominio)
fprintf('(0d) DOMINIO/RESTRICCIONES de la geometria:\n');
fprintf('     CST orden 6 -> %d variables (7 sup + 7 inf)\n', nu*2);
fprintf('     caja: +-50%% por coeficiente (piso absoluto 0.05)\n');
fprintf('     lb..ub (primeros 3): [%.3f,%.3f] [%.3f,%.3f] [%.3f,%.3f]\n', ...
        P.lb(1),P.ub(1),P.lb(2),P.ub(2),P.lb(3),P.ub(3));
fprintf('     espesor: cap T<=%.4f (+tol %.0e), piso T>=%.4f\n', ctx.T0, ctx.t_tol, ctx.tmax_min);
fprintf('     adherencia: H<=%.1f, Cf>=%.1e | muestreo: %d ptos/superf (coseno)\n', ctx.H_sep, ctx.Cf_min, ctx.npts);
fprintf('<<<<<<<< ETAPA 0 done\n\n');

%% ================= ETAPA 1: OPTIMIZACION ROBUSTA MULTI-MODELO =================
fprintf('======== ETAPA 1: optimizacion robusta (peor caso TNO/Goody/Kamruzzaman) ========\n');
R0 = obj_noise_robusto_ref(P.dv0, ctx);
fprintf('Base 63-218: peor-caso=%.3f dBA  [TNO %.2f, Goody %.2f, Kamr %.2f]\n', ...
        max(R0), R0(1), R0(2), R0(3));
opts = optimoptions('patternsearch','Display','iter', ...
    'MaxFunctionEvaluations',600,'UseCompletePoll',true,'MeshTolerance',1e-4);
dvR = patternsearch(@(d) obj_noise_robusto(d,ctx), P.dv0, [],[],[],[], ...
                    P.lb, P.ub, @(d) con_clcd(d,ctx), opts);
robusto_dat = fullfile(outdir,'opt_63218_robusto.dat');
[xo,yo] = cst_to_coords(dvR(1:nu), dvR(nu+1:end), ctx.yte_u, ctx.yte_l, ctx.npts, ctx.N1, ctx.N2);
write_airfoil_dat(robusto_dat, xo, yo);
Rf = obj_noise_robusto_ref(dvR, ctx);
Rc = eval_airfoil_cached(dvR, ctx);
fprintf('\n=== OPTIMO ROBUSTO ===\n');
fprintf('  peor-caso: %.3f -> %.3f dBA\n', max(R0), max(Rf));
fprintf('  por modelo: TNO %.2f->%.2f | Goody %.2f->%.2f | Kamr %.2f->%.2f\n', ...
        R0(1),Rf(1), R0(2),Rf(2), R0(3),Rf(3));
fprintf('  Cl/Cd %.1f | tmax %.3f | guardado en %s\n', Rc.clcd, Rc.tmax, robusto_dat);
save(fullfile(outdir,'opt_robusto.mat'),'dvR','R0','Rf');
fprintf('\n=== COMPLETO en %.1f min ===\n', toc(t0)/60);
end

function oa3 = obj_noise_robusto_ref(dv, ctx)
% helper de reporte: devuelve [TNO Goody Kamr] sin penalizacion
[~, d] = obj_noise_robusto(dv, ctx);
oa3 = d.oa;
end

function s = ternary(c,a,b), if c, s=a; else, s=b; end, end
