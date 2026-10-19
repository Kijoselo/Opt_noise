%% SENSITIVITY_ANALYSIS
% One-at-a-time (OAT) sensitivity of the OASPL(A) and Cl/Cd to each CST design
% variable, swept across its optimisation bound around the base airfoil.
% Produces, for the article:
%   fig_sensitivity_tornado.png   ranked influence of each parameter on noise
%   fig_sensitivity_curves.png    OASPL(A) & Cl/Cd vs each normalised parameter
%   fig_sensitivity_silhouettes.png  shape change of the most influential params
%
% Cost: ~ nlev * nDV XFOIL evaluations.
% Usage:  sensitivity_analysis           (default 7 levels/case)
%         sensitivity_analysis(9)
%         sensitivity_analysis(9, 'NACA63218.txt')
function sensitivity_analysis(nlev, basefile)
if nargin < 1 || isempty(nlev), nlev = 7; end
if nargin < 2 || isempty(basefile), basefile = 'NACA63221.txt'; end
close all; set_pub_defaults();

P = setup_problem('base', basefile, 'write_legacy', false);
nv   = numel(P.dv0);
nu   = P.ctx.nu;
bw   = (P.ub - P.lb)/2;                     % bound half-width per variable
levels = linspace(-1, 1, nlev);             % normalised perturbation

labels = cell(nv,1);
for i = 1:nu,      labels{i}      = ['$A^{u}_{' num2str(i) '}$']; end   % LaTeX
for i = 1:(nv-nu), labels{nu+i}   = ['$A^{\ell}_{' num2str(i) '}$']; end

fprintf('Case: %s (%s)\n', P.case_id, P.base_file);
fprintf('Baseline OASPL(A) = %.3f dBA, Cl/Cd = %.2f\n', P.J0, P.clcd0);
fprintf('Running OAT sweep: %d params x %d levels ...\n\n', nv, nlev);

OASPL = nan(nv, nlev);
CLCD  = nan(nv, nlev);
for i = 1:nv
    for j = 1:nlev
        dv = P.dv0;
        dv(i) = P.dv0(i) + levels(j)*bw(i);
        R = eval_airfoil_cached(dv, P.ctx);
        if R.valid
            OASPL(i,j) = R.OASPL_A;
            CLCD(i,j)  = R.clcd;
        end
    end
    fprintf('  %-6s  OASPL range = %.3f dBA\n', labels{i}, ...
            max(OASPL(i,:)) - min(OASPL(i,:)));
end

%% --- tornado: ranked OASPL influence ---
infl = max(OASPL,[],2) - min(OASPL,[],2);     % noise span per parameter
[~, order] = sort(infl, 'ascend');            % ascending -> biggest on top
isUpper = (order <= nu);

cUp = [0.31 0.51 0.74];      % muted blue (upper)
cLo = [0.85 0.55 0.30];      % muted orange (lower)
% landscape aspect (~9x6.5 cm at single column) to match the other figures
figure('Color','w','Position',[100 100 600 440]);
b = barh(infl(order), 0.62); b.FaceColor = 'flat';   % thinner bars
b.EdgeColor = [0.3 0.3 0.3]; b.LineWidth = 0.4;
for k = 1:nv
    b.CData(k,:) = isUpper(k)*cUp + ~isUpper(k)*cLo;
end
set(gca,'YTick',1:nv,'YTickLabel',labels(order),'TickLabelInterpreter','latex');
xlabel('OASPL(A) span over the sweep [dBA]');
savefig300(gcf, 'fig_sensitivity_tornado');

%% --- sweep curves ---
figure('Color','w','Position',[100 100 1000 420]);
cmap = lines(nv);
subplot(1,2,1); hold on; grid on;
for i = 1:nv
    plot(levels, OASPL(i,:), '-', 'Color', cmap(i,:));
end
yline(P.J0,'k--');
xlabel('normalised parameter perturbation'); ylabel('OASPL(A) [dBA]');
title('Noise vs each parameter');

subplot(1,2,2); hold on; grid on;
for i = 1:nv
    plot(levels, CLCD(i,:), '-', 'Color', cmap(i,:), 'DisplayName', labels{i});
end
yline(P.clcd0,'k--');
xlabel('normalised parameter perturbation'); ylabel('c_l / c_d');
title('Efficiency vs each parameter');
legend('Location','eastoutside','NumColumns',1,'FontSize',8,'Interpreter','latex');
savefig300(gcf, 'fig_sensitivity_curves');

%% --- silhouettes of the most influential parameters ---
topk = 3;
top  = flipud(order(end-topk+1:end));   % most influential first
figure('Color','w','Position',[100 100 1000 320]);
for t = 1:topk
    i = top(t);
    subplot(1,topk,t); hold on; axis equal; grid on;
    plot(P.af.x, P.af.y, 'k-', 'LineWidth',1.2);
    for s = [-1 1]
        dv = P.dv0; dv(i) = P.dv0(i) + s*bw(i);
        [xx,yy] = cst_to_coords(dv(1:nu), dv(nu+1:end), ...
                  P.ctx.yte_u, P.ctx.yte_l, P.ctx.npts, P.ctx.N1, P.ctx.N2);
        col = (s<0)*[0 0.45 0.74] + (s>0)*[0.85 0.33 0.10];
        plot(xx, yy, '-', 'Color', col);
    end
    title(sprintf('%s  (\\Delta=%.2f dBA)', labels{i}, infl(i)));
    xlabel('x/c');
end
sgtitle('Silhouette change of the most influential parameters');
savefig300(gcf, 'fig_sensitivity_silhouettes');

% (reorganizacion) los datos van al workspace heredado, de donde los lee
% fig_sens_modes_merged; la funcion no cambia de directorio.
mat_out = fullfile(proyecto_rutas().legacy_workspace, 'sensitivity_data.mat');
save(mat_out, 'OASPL', 'CLCD', 'levels', 'labels', 'infl', 'P');
fprintf('\nDone. Data saved: %s\n', mat_out);
