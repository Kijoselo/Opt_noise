function plot_search_domain(basefile, optfile)
% PLOT_SEARCH_DOMAIN  Visualise the CST design box (search domain) of the
% optimiser for a given base airfoil. Because each surface is linear in its CST
% coefficients and the Bernstein basis is non-negative on [0,1], the extreme
% reachable surfaces are obtained by putting ALL coefficients at their lower or
% upper bound -- so the shaded band is exactly the region every candidate shape
% must lie within. Overlays the baseline and, optionally, an optimised airfoil.
%
% Non-destructive: does not refresh cst_baseline.dat; writes a case-specific PNG.
%
% Usage:  plot_search_domain                                  % NACA63221.txt
%         plot_search_domain('NACA63218.txt')
%         plot_search_domain('NACA63221.txt','study_cases/opt_NACA63221_clcd.dat')
if nargin < 1 || isempty(basefile), basefile = 'NACA63221.txt'; end
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace

P = setup_problem('base', basefile, 'write_legacy', false);

ctx = P.ctx; nu = ctx.nu;
xs = 0.5*(1 - cos(linspace(0,pi,200)'));             % cosine-spaced x/c

% exact reachable envelope (all coefficients at a bound; Bernstein >= 0)
uppMax = cst_eval(xs, P.ub(1:nu),       ctx.yte_u, ctx.N1, ctx.N2);
uppMin = cst_eval(xs, P.lb(1:nu),       ctx.yte_u, ctx.N1, ctx.N2);
lowMax = cst_eval(xs, P.ub(nu+1:end),   ctx.yte_l, ctx.N1, ctx.N2);
lowMin = cst_eval(xs, P.lb(nu+1:end),   ctx.yte_l, ctx.N1, ctx.N2);

[~,~,xb,ybu,~,ybl] = cst_to_coords(P.dv0(1:nu), P.dv0(nu+1:end), ...
                                   ctx.yte_u, ctx.yte_l, ctx.npts, ctx.N1, ctx.N2);

figure('Color','w'); hold on; axis equal; grid on;
fill([xs;flipud(xs)], [uppMax;flipud(uppMin)], [0.20 0.45 0.74], ...
     'FaceAlpha',0.12, 'EdgeColor','none', 'DisplayName','upper-surface reach');
fill([xs;flipud(xs)], [lowMax;flipud(lowMin)], [0.85 0.45 0.20], ...
     'FaceAlpha',0.12, 'EdgeColor','none', 'DisplayName','lower-surface reach');
plot(xs,uppMax,'-','Color',[0.4 0.55 0.78],'HandleVisibility','off');
plot(xs,uppMin,'-','Color',[0.4 0.55 0.78],'HandleVisibility','off');
plot(xs,lowMax,'-','Color',[0.82 0.52 0.30],'HandleVisibility','off');
plot(xs,lowMin,'-','Color',[0.82 0.52 0.30],'HandleVisibility','off');
plot(xb,ybu,'k-','LineWidth',1.6,'DisplayName','baseline');
plot(xb,ybl,'k-','LineWidth',1.6,'HandleVisibility','off');

if nargin >= 2 && ~isempty(optfile) && exist(optfile,'file')
    ao = load_airfoil(optfile);
    plot(ao.xu,ao.yu,'r-','LineWidth',1.5,'DisplayName','optimum');
    plot(ao.xl,ao.yl,'r-','LineWidth',1.5,'HandleVisibility','off');
end

xlabel('x/c'); ylabel('y/c'); legend('Location','northeast');
text(0.02,0.96,strrep(basefile,'_','\_'),'Units','normalized', ...
     'VerticalAlignment','top','FontSize',9);
fig_prefix = sprintf('fig_search_domain_%s', P.case_id);
savefig300(gcf, fig_prefix, 12);
if strcmpi(P.case_id, 'NACA63221')
    copiar_figura(fig_prefix, 'fig_search_domain');
end
fprintf('  saved %s.png  (search box for %s)\n', fig_prefix, basefile);
end
