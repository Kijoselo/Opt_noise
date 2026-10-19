%% RUN_OPTIMIZATION  (Case 1: hard Cl/Cd constraint)
% Minimise A-weighted OASPL over the CST silhouette subject to a HARD
% constraint that Cl/Cd stays at or above the baseline value.
%
%   variables  : 14 CST coefficients [Au; Al]
%   objective  : OASPL(A)                         (obj_noise_pure)
%   constraints: Cl/Cd >= baseline                (con_clcd, nonlinear)
%                + no surface crossing / min thickness (inside the evaluator)
%   optimiser  : patternsearch (supports nonlinear constraints)
%
% Requires the Global Optimization Toolbox.
% Usage:  run_optimization                    (default case/budget)
%         dv_opt = run_optimization(200)      (budget only)
%         dv_opt = run_optimization('NACA63218.txt', 200)
%         dv_opt = run_optimization(200, 'NACA63218.txt')
function dv_opt = run_optimization(varargin)
[budget, basefile] = parse_inputs(varargin{:});
close all; set_pub_defaults();

P = setup_problem('base', basefile, 'write_legacy', false);  % builds ctx, dv0, bounds; resets cache

fprintf('Case: %s (%s)\n', P.case_id, P.base_file);
fprintf('Baseline: OASPL(A) = %.3f dBA | Cl/Cd = %.2f (Cl %.4f, Cd %.5f)\n\n', ...
        P.J0, P.clcd0, P.Cl0, P.Cd0);

objfun = @(dv) obj_noise_pure(dv, P.ctx);
confun = @(dv) con_clcd(dv, P.ctx);

opts = optimoptions('patternsearch', 'Display','iter', ...
    'MaxFunctionEvaluations', budget, 'UseCompletePoll', true, ...
    'MeshTolerance', 1e-4);

[dv_opt, ~] = patternsearch(objfun, P.dv0, [],[],[],[], P.lb, P.ub, confun, opts);

%% --- result ---
% (reorganizacion) cada corrida escribe en su propia carpeta con marca de tiempo
% (results/simulations/<fecha>_opt_<caso>/) y NO sobrescribe el optimo publicado
% de data/optimized. Para adoptar un nuevo optimo como el del caso, copie el .dat
% generado a P.ctx.opt_file.
Ro = eval_airfoil_cached(dv_opt, P.ctx);
nu = P.ctx.nu;
[xo, yo] = cst_to_coords(dv_opt(1:nu), dv_opt(nu+1:end), ...
                         P.ctx.yte_u, P.ctx.yte_l, P.ctx.npts, P.ctx.N1, P.ctx.N2);
rundir  = carpeta_ejecucion(sprintf('opt_%s', P.case_id));
opt_out = fullfile(rundir, sprintf('optimized_%s_hardcon.dat', P.case_id));
write_airfoil_dat(opt_out, xo, yo);
L = eval_airfoil_cached('log');
info = struct('caso', P.case_id, 'base_file', P.base_file, 'budget', budget, ...
              'J0', P.J0, 'clcd0', P.clcd0, 'OASPL_A', Ro.OASPL_A, 'clcd', Ro.clcd, ...
              'inputs', P.ctx.inputs, 'fluid', P.ctx.fluid, 'fecha', datestr(now)); %#ok<NASGU>
save(fullfile(rundir, 'resultado_optimizacion.mat'), 'dv_opt', 'Ro', 'P', 'L', 'info');

fprintf('\n==== Result (hard Cl/Cd constraint) ====\n');
fprintf('  OASPL(A): %.3f -> %.3f dBA   (gain %.3f dBA)\n', P.J0, Ro.OASPL_A, P.J0-Ro.OASPL_A);
fprintf('  Cl/Cd   : %.2f -> %.2f       (must not drop below %.2f)\n', P.clcd0, Ro.clcd, P.ctx.clcd_min);
fprintf('  Saved: %s\n', opt_out);
fprintf('  (optimo publicado del caso, sin modificar: %s)\n', P.ctx.opt_file);

%% --- figures ---
figure('Color','w');
plot(P.af.x, P.af.y, 'k-', xo, yo, 'r-'); axis equal; grid on;
legend('baseline','optimized','Location','best');
title(sprintf('%s silhouette  %.2f \rightarrow %.2f dBA', P.case_id, P.J0, Ro.OASPL_A), ...
      'Interpreter','none');
xlabel('x/c'); ylabel('y/c');
sil_prefix  = fullfile(rundir, sprintf('fig_silhouette_hardcon_%s', P.case_id));
spec_prefix = fullfile(rundir, sprintf('fig_spectrum_hardcon_%s', P.case_id));
savefig300(gcf, sil_prefix);
plot_spectrum_compare(P, dv_opt, spec_prefix);

end

function [budget, basefile] = parse_inputs(varargin)
budget = 60;
basefile = 'NACA63221.txt';
if nargin == 0, return; end
if nargin == 1
    if isnumeric(varargin{1})
        budget = varargin{1};
    else
        basefile = char(varargin{1});
    end
    return;
end
if isnumeric(varargin{1})
    budget = varargin{1};
    basefile = char(varargin{2});
else
    basefile = char(varargin{1});
    budget = varargin{2};
end
end
