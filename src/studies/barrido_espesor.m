function barrido_espesor
% BARRIDO_ESPESOR  Verificacion NO OPTIMIZADA de la relacion espesor -> ruido.
% Dos pruebas independientes, misma cadena de ruido sin modificar, mismas
% condiciones (inputs_definition). Para cada geometria se reporta ademas la
% capa limite en x/c=0.99 (delta*, H, Cf) que ES la causa fisica del ruido,
% para poder auditar que la tendencia es coherente y no un artefacto.
%
%   Prueba A: familia SIMETRICA NACA 00XX (espesor puro, camber = 0).
%   Prueba B: escalado del ESPESOR del NACA 63-221 real (camber fijo).
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
[fluid, inputs] = inputs_definition();
fprintf('Condiciones: AoA=%g  Re=%.2e  M=%.3f  xtr=%.2f\n\n', ...
        inputs.AoA, inputs.Re, inputs.M, inputs.xtr_s);
outdir = fullfile(rutas.simulaciones,'estudios_previos','verificacion_espesor')   % (reorganizacion);
if ~exist(outdir,'dir'), mkdir(outdir); end

xs = 0.5*(1 - cos(linspace(0,pi,100)'));    % cosine stations

%% ---------- PRUEBA A: NACA 00XX simetricos ----------
tt = [0.08 0.10 0.12 0.15 0.18 0.21 0.24];
A = run_sweep(arrayfun(@(t) sym_naca(xs,t), tt, 'uni',0), ...
              arrayfun(@(t) sprintf('NACA00%02d',round(t*100)), tt,'uni',0), ...
              inputs, fluid, 'A_simetrico');

%% ---------- PRUEBA B: escalado de espesor del 63-221 ----------
[xc, tc, cam] = thickness_camber('cst_baseline_NACA63221.dat', 100);
s = [0.60 0.70 0.80 0.90 1.00 1.10 1.20];
geomB = cell(size(s)); labB = cell(size(s));
for i=1:numel(s)
    yu = interp1(xc, cam + 0.5*s(i)*tc, xs, 'pchip');
    yl = interp1(xc, cam - 0.5*s(i)*tc, xs, 'pchip');
    geomB{i} = {xs,yu,xs,yl};
    labB{i}  = sprintf('63221 x%.2f', s(i));
end
B = run_sweep(geomB, labB, inputs, fluid, 'B_escalado63221');

%% ---------- guardar tablas ----------
write_table(fullfile(outdir,'barrido_A_simetrico.txt'), A, 'NACA 00XX simetricos');
write_table(fullfile(outdir,'barrido_B_escalado.txt'),  B, 'NACA 63-221 espesor escalado');
save(fullfile(outdir,'barrido_espesor.mat'), 'A','B');

%% ---------- figuras ----------
figure('Color','w','Position',[40 40 1150 430]);
subplot(1,2,1); hold on; grid on;
plot(A.tmax*100, A.oaspl,  'ko-','LineWidth',1.4,'MarkerFaceColor','k','DisplayName','OASPL(A)');
plot(A.tmax*100, A.oaspl_lin,'s--','Color',[.5 .5 .5],'LineWidth',1.1,'DisplayName','OASPL sin filtro');
xlabel('espesor maximo t/c [%]'); ylabel('OASPL [dB]');
title('(a) NACA 00XX simetricos'); legend('Location','northwest','FontSize',8);
subplot(1,2,2); hold on; grid on;
plot(B.tmax*100, B.oaspl,  'ro-','LineWidth',1.4,'MarkerFaceColor','r','DisplayName','OASPL(A)');
plot(B.tmax*100, B.oaspl_lin,'s--','Color',[.85 .5 .5],'LineWidth',1.1,'DisplayName','OASPL sin filtro');
xline(21,'k:','63-221 base','HandleVisibility','off');
xlabel('espesor maximo t/c [%]'); ylabel('OASPL [dB]');
title('(b) 63-221 con espesor escalado'); legend('Location','northwest','FontSize',8);
savefig300(gcf, fullfile(outdir,'fig_espesor_vs_ruido'), 19);

% panel mecanistico: delta*_succion y H en el TE vs espesor
figure('Color','w','Position',[40 40 1150 430]);
subplot(1,2,1); hold on; grid on;
plot(A.tmax*100, A.dstar_s*1e3,'ko-','LineWidth',1.3,'DisplayName','simetrico');
plot(B.tmax*100, B.dstar_s*1e3,'ro-','LineWidth',1.3,'DisplayName','63221 escalado');
xlabel('t/c [%]'); ylabel('\delta^*/c succion en x/c=0.99  [\times10^{-3}]');
title('(a) espesor de capa limite en el TE'); legend('Location','northwest','FontSize',8);
subplot(1,2,2); hold on; grid on;
plot(A.tmax*100, A.H_s,'ko-','LineWidth',1.3,'DisplayName','simetrico');
plot(B.tmax*100, B.H_s,'ro-','LineWidth',1.3,'DisplayName','63221 escalado');
yline(2.7,'k:','H_{lim}','HandleVisibility','off');
xlabel('t/c [%]'); ylabel('H succion en x/c=0.99');
title('(b) factor de forma en el TE'); legend('Location','northwest','FontSize',8);
savefig300(gcf, fullfile(outdir,'fig_espesor_capalimite'), 19);

fprintf('\nListo. Resultados en %s\n', outdir);
end

%% ================= helpers =================
function g = sym_naca(xs, t)
yt = naca0012(xs, t);          % formula NACA 4-digitos (estandar)
g = {xs, yt, xs, -yt};         % {xu,yu,xl,yl}, simetrico
end

function T = run_sweep(geoms, labels, inputs, fluid, tag)
n = numel(geoms);
T.label = labels(:); T.tmax=nan(n,1); T.oaspl=nan(n,1); T.oaspl_lin=nan(n,1);
T.Cl=nan(n,1); T.Cd=nan(n,1); T.clcd=nan(n,1);
T.dstar_s=nan(n,1); T.theta_s=nan(n,1); T.H_s=nan(n,1); T.Cf_s=nan(n,1);
T.dstar_p=nan(n,1); T.H_p=nan(n,1); T.status=cell(n,1);
fprintf('==== BARRIDO %s ====\n', tag);
fprintf('%-14s %6s %8s %8s %7s %8s %7s %6s\n', ...
        'geom','tmax%','OASPLA','OASPLlin','Cl/Cd','dstar_s','H_s','Cf_s');
for i = 1:n
    g = geoms{i}; xu=g{1}; yu=g{2}; xl=g{3}; yl=g{4};
    x = [flipud(xu); xl(2:end)]; y = [flipud(yu); yl(2:end)];
    T.tmax(i) = max(interp1(xl,yl,xu,'pchip','extrap')*0 + (yu - interp1(xl,yl,xu,'pchip')));
    fn = 'barrido_cand.dat'; write_airfoil_dat(fn, x, y);
    for f = {xfoil_out('POLAR_OUTPUT'),xfoil_out('doesntmatter'),xfoil_out('XFOIL_Output'),xfoil_out('XFOIL_CP_Output')}
        if exist(f{1},'file'), delete(f{1}); end
    end
    try
        [oa, Cl, Cd, o] = evaluate_airfoil(fn, inputs, fluid);
        T.oaspl(i)=oa; T.oaspl_lin(i)=o.OASPL_lin; T.Cl(i)=Cl; T.Cd(i)=Cd; T.clcd(i)=Cl/Cd;
        bl = read_te_bl(inputs.Mic);
        T.dstar_s(i)=bl.ds*inputs.chord; T.theta_s(i)=bl.ts*inputs.chord;
        T.H_s(i)=bl.Hs; T.Cf_s(i)=bl.Cfs; T.dstar_p(i)=bl.dp*inputs.chord; T.H_p(i)=bl.Hp;
        T.status{i}='ok';
    catch ME
        T.status{i}=['FAIL: ' ME.message];
        fprintf('  [FALLO %s] %s\n', labels{i}, ME.message);
        continue;
    end
    fprintf('%-14s %6.1f %8.3f %8.3f %7.2f %8.5f %7.3f %.5f\n', ...
        labels{i}, 100*T.tmax(i), T.oaspl(i), T.oaspl_lin(i), T.clcd(i), ...
        T.dstar_s(i), T.H_s(i), T.Cf_s(i));
end
% chequeo de monotonia
d = diff(T.oaspl);
if all(d>0), fprintf('  -> OASPL(A) MONOTONO creciente con el espesor.\n');
elseif all(d<0), fprintf('  -> OASPL(A) MONOTONO decreciente con el espesor.\n');
else, fprintf('  -> OASPL(A) NO monotono (revisar puntos): diffs = %s\n', num2str(d','%.3f ')); end
fprintf('\n');
end

function bl = read_te_bl(pos)
% lee delta*, theta, Cf, H en x/c=pos de ambas superficies del DUMP de XFOIL
bl = struct('ds',NaN,'ts',NaN,'Hs',NaN,'Cfs',NaN,'dp',NaN,'Hp',NaN);
if ~exist(xfoil_out('XFOIL_Output'),'file'), return; end
fid=fopen(xfoil_out('XFOIL_Output'),'r');
D=textscan(fid,'%f%f%f%f%f%f%f%f','Delimiter',' ','MultipleDelimsAsOne',true,'CollectOutput',1,'HeaderLines',1);
fclose(fid); D=D{1};
if isempty(D)||size(D,2)<8, return; end
D=D(D(:,2)<=1.0001,:); n=size(D,1); half=1:floor(n/2);
[~,is]=min(abs(D(half,2)-pos));               % succion (primera mitad)
[~,ip]=min(abs(D(half(end)+1:end,2)-pos)); ip=half(end)+ip;
bl.ds=D(is,5); bl.ts=D(is,6); bl.Cfs=D(is,7); bl.Hs=D(is,8);
bl.dp=D(ip,5); bl.Hp=D(ip,8);
if ~isfinite(bl.Hs)||bl.Hs<=0, bl.Hs=D(is,5)/max(D(is,6),1e-9); end
end

function write_table(fname, T, titulo)
fid=fopen(fname,'w');
fprintf(fid,'# %s\n# geometria | tmax/c%% | OASPL(A) | OASPL_lin | Cl | Cd | Cl/Cd | dstar_s/c | theta_s/c | H_s | Cf_s | H_p | estado\n', titulo);
for i=1:numel(T.label)
    fprintf(fid,'%-14s %6.2f %9.3f %9.3f %8.4f %8.5f %7.2f %10.5f %10.5f %6.3f %9.6f %6.3f  %s\n', ...
        T.label{i},100*T.tmax(i),T.oaspl(i),T.oaspl_lin(i),T.Cl(i),T.Cd(i),T.clcd(i), ...
        T.dstar_s(i),T.theta_s(i),T.H_s(i),T.Cf_s(i),T.H_p(i),T.status{i});
end
fclose(fid);
end
