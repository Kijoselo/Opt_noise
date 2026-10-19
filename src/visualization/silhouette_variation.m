%% SILHOUETTE_VARIATION
% Visualise how the airfoil silhouette varies with the CST design variables.
% Geometry only (no XFOIL), so it is instant. Produces:
%   fig_shape_modes_<case>.png       each CST parameter perturbed +/- around base
%   fig_design_envelope_<case>.png   reachable shape space (random samples in bounds)
%   fig_base_vs_optimized_<case>.png base vs optimized silhouette (if result exists)
% Usage:  silhouette_variation
%         silhouette_variation('NACA63218.txt')
function silhouette_variation(basefile)
if nargin < 1 || isempty(basefile), basefile = 'NACA63221.txt'; end
close all; set_pub_defaults(); pc=pub_colors();

P  = setup_problem('base', basefile, 'write_legacy', false);  % one XFOIL call for baseline; gives bounds
nu = P.ctx.nu;
nv = numel(P.dv0);
bw = (P.ub - P.lb)/2;
case_id = P.case_id;

gen = @(dv) cst_to_coords(dv(1:nu), dv(nu+1:end), ...
            P.ctx.yte_u, P.ctx.yte_l, P.ctx.npts, P.ctx.N1, P.ctx.N2);

labels = cell(nv,1);   % LaTeX so \ell renders (MATLAB tex interpreter lacks it)
for i = 1:nu,      labels{i}    = ['$A^{u}_{' num2str(i) '}$']; end
for i = 1:(nv-nu), labels{nu+i} = ['$A^{\ell}_{' num2str(i) '}$']; end

%% --- shape modes: one subplot per CST parameter ---
ncol = 4; nrow = ceil(nv/ncol);
figure('Color','w','Position',[60 60 1100 750]);
for i = 1:nv
    subplot(nrow, ncol, i); hold on; axis equal off;
    [xb,yb] = gen(P.dv0); plot(xb, yb, 'k-', 'LineWidth',1.2);
    for s = [-1 1]
        dv = P.dv0; dv(i) = P.dv0(i) + s*bw(i);
        [xx,yy] = gen(dv);
        col = (s<0)*[0 0.45 0.74] + (s>0)*[0.85 0.33 0.10];
        plot(xx, yy, '-', 'Color', col, 'LineWidth',1.0);
    end
    % label as in-axes text (title() would be stripped by savefig300)
    text(0.5, 1.02, labels{i}, 'Interpreter','latex', 'Units','normalized', ...
         'HorizontalAlignment','center', 'FontSize',11);
end
fig_modes = sprintf('fig_shape_modes_%s', case_id);
savefig300(gcf, fig_modes);          % full set -> appendix
if strcmpi(case_id, 'NACA63221')
    copiar_figura(fig_modes, 'fig_shape_modes');
end

%% --- most influential modes only (for the main body) ---
% Ranking from the sensitivity study: aft suction + aft pressure coefficients.
top = [6 7 13 5 14];                          % A^u_6, A^u_7, A^l_6, A^u_5, A^l_7
figure('Color','w','Position',[60 60 1200 260]);
for j = 1:numel(top)
    i = top(j);
    subplot(1, numel(top), j); hold on; axis equal off;
    [xb,yb] = gen(P.dv0); plot(xb, yb, '-', 'Color',pc.gray, 'LineWidth',1.3);
    for s = [-1 1]
        dv = P.dv0; dv(i) = P.dv0(i) + s*bw(i);
        [xx,yy] = gen(dv);
        col = (s<0)*pc.opt + (s>0)*pc.base;
        plot(xx, yy, '-', 'Color', col, 'LineWidth',1.1);
    end
    text(0.5, 1.04, labels{i}, 'Interpreter','latex', 'Units','normalized', ...
         'HorizontalAlignment','center', 'FontSize',13);
end
fig_modes_top = sprintf('fig_shape_modes_top_%s', case_id);
savefig300(gcf, fig_modes_top, 19);
if strcmpi(case_id, 'NACA63221')
    copiar_figura(fig_modes_top, 'fig_shape_modes_top');
end

%% --- design-space envelope: random samples within the bounds ---
rng(0);
nsamp = 60;
figure('Color','w'); hold on; axis equal; grid on;
for k = 1:nsamp
    dv = P.lb + (P.ub - P.lb).*rand(nv,1);
    [xx,yy] = gen(dv);
    plot(xx, yy, '-', 'Color', [0.6 0.6 0.6 0.25]);
end
[xb,yb] = gen(P.dv0);
plot(xb, yb, 'k-', 'LineWidth',2, 'DisplayName','baseline');
xlabel('x/c'); ylabel('y/c');
title(sprintf('Reachable shape space (%d random designs in bounds)', nsamp));
fig_env = sprintf('fig_design_envelope_%s', case_id);
savefig300(gcf, fig_env);
if strcmpi(case_id, 'NACA63221')
    copiar_figura(fig_env, 'fig_design_envelope');
end

%% --- base vs optimized (if an optimisation result exists for this case) ---
optfile = P.ctx.opt_file;
if exist(optfile,'file')
    M = readmatrix(optfile);
    M = M(all(~isnan(M(:,1:2)),2), 1:2);
    figure('Color','w'); hold on; axis equal; grid on;
    plot(P.af.x, P.af.y, 'k-', 'LineWidth',1.5, 'DisplayName','baseline');
    plot(M(:,1), M(:,2), 'r-', 'LineWidth',1.3, 'DisplayName','optimized');
    % shade the difference for emphasis
    xlabel('x/c'); ylabel('y/c');
    title(sprintf('%s baseline vs optimized silhouette', case_id), 'Interpreter','none');
    legend('Location','best');
    fig_base_opt = sprintf('fig_base_vs_optimized_%s', case_id);
    savefig300(gcf, fig_base_opt);
    if strcmpi(case_id, 'NACA63221')
        copiar_figura(fig_base_opt, 'fig_base_vs_optimized');
    end
else
    fprintf('(%s not found - run run_optimization(''%s'', budget) first for this morph figure.)\n', ...
            optfile, P.base_file);
end

fprintf('Done.\n');
