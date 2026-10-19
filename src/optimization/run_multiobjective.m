%% RUN_MULTIOBJECTIVE  (Case 2: Pareto front noise vs efficiency)
% Trade-off between A-weighted OASPL and Cl/Cd using gamultiobj.
%   objectives : [ OASPL(A) , -Cl/Cd ]   (minimise both)
%   variables  : 14 CST coefficients [Au; Al]
% Produces the Pareto front and overlays a few representative silhouettes.
%
% Requires the Global Optimization Toolbox.
% Usage:  run_multiobjective              (defaults)
%         [oaspl,clcd] = run_multiobjective(40,30)
%         [oaspl,clcd] = run_multiobjective(40,30,'NACA63218.txt')
function [oaspl, clcd] = run_multiobjective(popsize, gens, basefile)
if nargin < 1 || isempty(popsize), popsize = 40; end
if nargin < 2 || isempty(gens),    gens    = 30; end
if nargin < 3 || isempty(basefile), basefile = 'NACA63221.txt'; end
close all; set_pub_defaults(); rng(0); pc=pub_colors();

P = setup_problem('base', basefile, 'write_legacy', false);
% (reorganizacion) salidas en carpeta propia con marca de tiempo
rundir = carpeta_ejecucion(sprintf('pareto_%s', P.case_id));

fprintf('Case: %s (%s)\n', P.case_id, P.base_file);
fprintf('Baseline: OASPL(A) = %.3f dBA | Cl/Cd = %.2f\n', P.J0, P.clcd0);
fprintf('Running gamultiobj (this calls XFOIL many times) ...\n\n');

objfun = @(dv) obj_multi(dv, P.ctx);

opts = optimoptions('gamultiobj', 'Display','iter', ...
    'PopulationSize', popsize, 'MaxGenerations', gens, ...
    'InitialPopulationMatrix', P.dv0');

[dv_par, F_par] = gamultiobj(objfun, numel(P.dv0), [],[],[],[], P.lb, P.ub, opts);

% F_par(:,1) = OASPL(A), F_par(:,2) = -Cl/Cd
oaspl = F_par(:,1);
clcd  = -F_par(:,2);
[oaspl, idx] = sort(oaspl);
clcd  = clcd(idx);
dv_par = dv_par(idx,:);

%% --- Pareto figure ---
col = pc.opt;   % azul de la paleta
figure('Color','w');
plot(oaspl, clcd, '-o', 'Color',col, 'MarkerFaceColor',col, ...
     'MarkerSize',4, 'LineWidth',1.0, 'DisplayName','Pareto front');
grid on; hold on;
plot(P.J0, P.clcd0, 'ks', 'MarkerSize',8, 'MarkerFaceColor','w', ...
     'LineWidth',1.2, 'HandleVisibility','off');
text(P.J0-0.06, P.clcd0, 'Baseline', 'HorizontalAlignment','right', ...
     'VerticalAlignment','middle', 'FontSize',9);
xlabel('OASPL(A) [dBA]'); ylabel('c_l / c_d');
legend('Location','northwest');           % top-left is empty (front rises to the right)
fig_pf = fullfile(rundir, sprintf('fig_pareto_front_%s', P.case_id));
savefig300(gcf, fig_pf);

%% --- three representative designs: min-noise, intermediate, max-efficiency ---
npick = min(3, size(dv_par,1));
pick  = round(linspace(1, size(dv_par,1), npick));   % sorted by OASPL ascending
plabel = {'min-noise','intermediate','max-efficiency'};
nu = P.ctx.nu;

figure('Color','w'); hold on; axis equal; grid on;
plot(P.af.x, P.af.y, 'k-', 'DisplayName','baseline');
cmap = lines(npick);

% collect metrics: row 1 = baseline, rows 2..npick+1 = representative designs
% columns: OASPL, Cl, Cd, Cl/Cd, tmax/c, Cm
labels = ['baseline', plabel];
M = nan(npick+1, 6);
[OAb, Clb, Cdb, ob_] = evaluate_airfoil(P.ctx.baseline_file, P.ctx.inputs, P.ctx.fluid);
[~, tcb] = thickness_camber(P.ctx.baseline_file);
M(1,:) = [OAb, Clb, Cdb, Clb/Cdb, max(tcb), ob_.Cm];
for j = 1:npick
    dv = dv_par(pick(j),:)';
    [xx, yy, ~, yu, ~, yl] = cst_to_coords(dv(1:nu), dv(nu+1:end), ...
                             P.ctx.yte_u, P.ctx.yte_l, P.ctx.npts, P.ctx.N1, P.ctx.N2);
    write_airfoil_dat(P.ctx.tmpfile, xx, yy);
    [OA, Cl, Cd, o] = evaluate_airfoil(P.ctx.tmpfile, P.ctx.inputs, P.ctx.fluid);
    M(j+1,:) = [OA, Cl, Cd, Cl/Cd, max(yu-yl), o.Cm];
    plot(xx, yy, '-', 'Color', cmap(j,:), ...
        'DisplayName', sprintf('%s (%.2f dBA)', plabel{j}, OA));
end
legend('Location','best'); xlabel('x/c'); ylabel('y/c');
fig_ps = fullfile(rundir, sprintf('fig_pareto_silhouettes_%s', P.case_id));
savefig300(gcf, fig_ps);

%% --- report table (console + LaTeX fragment for \input) ---
fprintf('\n  %-15s %8s %7s %8s %7s %8s %8s\n', ...
        'design','OASPL','Cl','Cd','Cl/Cd','tmax/c','Cm');
fprintf('  %s\n', repmat('-',1,66));
tex_path = fullfile(rundir, sprintf('pareto_designs_%s.tex', P.case_id));
fid = fopen(tex_path,'w');
for r = 1:size(M,1)
    fprintf('  %-15s %8.2f %7.4f %8.5f %7.2f %8.3f %8.4f\n', labels{r}, M(r,:));
    nm = labels{r}; if r==1, nm = sprintf('\\textbf{%s}', nm); end
    if r>1, fprintf(fid, '\n'); end          % newline BEFORE each row (no trailing
    fprintf(fid, '%s & %.2f & %.4f & %.5f & %.2f & %.3f & %.4f \\\\', ...
            nm, M(r,1), M(r,2), M(r,3), M(r,4), M(r,5), M(r,6));   % blank line)
end
fclose(fid);
% (reorganizacion) antes se copiaba a paper/pareto_designs.tex y a un CSV
% generico; ahora todo queda en la carpeta de la corrida.
csv_path = fullfile(rundir, sprintf('pareto_front_%s.csv', P.case_id));
writematrix([oaspl, clcd], csv_path);
save(fullfile(rundir, 'resultado_pareto.mat'), 'dv_par', 'oaspl', 'clcd', 'M', 'labels', 'P');
fprintf('\nPareto front + designs saved in %s\n', rundir);
