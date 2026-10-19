%% RUN_OPTIMIZATION_LIN  (variant: un-weighted OASPL objective)
% Same problem as run_optimization (hard Cl/Cd constraint, geometry and
% attachment guards unchanged) but the objective is the UN-WEIGHTED OASPL
% (no A-filter), obj_noise_lin. The A-weighted OASPL(A) is still reported
% for cross-comparison. Writes optimized_<case>_lin.dat (does not touch the
% A-weighted optimum optimized_<case>_hardcon.dat).
%
% Usage:  dv_opt = run_optimization_lin(2000, 'NACA63218.txt')
function dv_opt = run_optimization_lin(varargin)
[budget, basefile] = parse_inputs(varargin{:});
close all; set_pub_defaults();

P = setup_problem('base', basefile, 'write_legacy', false);

R0 = eval_airfoil_cached(P.dv0, P.ctx);            % baseline (cached)
fprintf('Case: %s (%s)  [objective: OASPL sin filtro A]\n', P.case_id, P.base_file);
fprintf('Baseline: OASPL = %.3f dB | OASPL(A) = %.3f dBA | Cl/Cd = %.2f\n\n', ...
        R0.OASPL_lin, P.J0, P.clcd0);

objfun = @(dv) obj_noise_lin(dv, P.ctx);
confun = @(dv) con_clcd(dv, P.ctx);

opts = optimoptions('patternsearch', 'Display','iter', ...
    'MaxFunctionEvaluations', budget, 'UseCompletePoll', true, ...
    'MeshTolerance', 1e-4);

[dv_opt, ~] = patternsearch(objfun, P.dv0, [],[],[],[], P.lb, P.ub, confun, opts);

%% --- result ---
Ro = eval_airfoil_cached(dv_opt, P.ctx);
nu = P.ctx.nu;
[xo, yo] = cst_to_coords(dv_opt(1:nu), dv_opt(nu+1:end), ...
                         P.ctx.yte_u, P.ctx.yte_l, P.ctx.npts, P.ctx.N1, P.ctx.N2);
opt_file = sprintf('optimized_%s_lin.dat', P.case_id);
write_airfoil_dat(opt_file, xo, yo);

fprintf('\n==== Result (objetivo OASPL sin filtro A, restriccion dura Cl/Cd) ====\n');
fprintf('  OASPL    : %.3f -> %.3f dB    (gain %.3f dB)   <- objetivo\n', ...
        R0.OASPL_lin, Ro.OASPL_lin, R0.OASPL_lin - Ro.OASPL_lin);
fprintf('  OASPL(A) : %.3f -> %.3f dBA   (gain %.3f dBA)  <- diagnostico\n', ...
        P.J0, Ro.OASPL_A, P.J0 - Ro.OASPL_A);
fprintf('  Cl/Cd    : %.2f -> %.2f       (must not drop below %.2f)\n', ...
        P.clcd0, Ro.clcd, P.ctx.clcd_min);
fprintf('  tmax/c   : %.4f -> %.4f  (cap %.4f)\n', P.ctx.T0, Ro.tmax, P.ctx.T0);
fprintf('  Saved: %s\n', opt_file);

%% --- figures ---
figure('Color','w');
plot(P.af.x, P.af.y, 'k-', xo, yo, 'r-'); axis equal; grid on;
legend('baseline','optimized (OASPL lin)','Location','best');
title(sprintf('%s silhouette  %.2f \\rightarrow %.2f dB (sin filtro A)', ...
      P.case_id, R0.OASPL_lin, Ro.OASPL_lin), 'Interpreter','none');
xlabel('x/c'); ylabel('y/c');
savefig300(gcf, sprintf('fig_silhouette_lin_%s', P.case_id));

plot_spectrum_compare(P, dv_opt, sprintf('fig_spectrum_lin_%s', P.case_id));
end

function [budget, basefile] = parse_inputs(varargin)
budget = 60;
basefile = 'NACA63218.txt';
if nargin == 0, return; end
if nargin == 1
    if isnumeric(varargin{1}), budget = varargin{1};
    else, basefile = char(varargin{1}); end
    return;
end
if isnumeric(varargin{1})
    budget = varargin{1};  basefile = char(varargin{2});
else
    basefile = char(varargin{1});  budget = varargin{2};
end
end
