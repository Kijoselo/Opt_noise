function P = setup_problem(varargin)
% SETUP_PROBLEM  Common problem definition shared by every optimisation
% script (single-objective, multi-objective, algorithm comparison).
% Locates the project, builds the CST design space from the base airfoil,
% computes the baseline objective and Cl/Cd, and returns everything in P.
%
% Name/value options:
%   'base'      base airfoil file         (default 'NACA63221.txt')
%   'order'     CST Bernstein order       (default 6)
%   'npts'      points per surface        (default 100)
%   'bw_rel'    bound half-width fraction (default 0.5)
%   'bw_abs'    min bound half-width      (default 0.05)
%   'outdir'    directory for case-specific generated airfoils. Default '':
%               the CST baseline and the candidate file go to
%               results/simulations/cst_baselines/ and the optimized airfoil is
%               looked for in data/optimized/ (where the published optima live).
%               If a folder is given, the three files live there (old behaviour).
%   'write_legacy'
%               also refresh cst_baseline.dat for old plotting scripts (false)
%
% Returns P with fields: ctx, dv0, lb, ub, af, p, J0, clcd0, Cl0, Cd0.

opt = struct('base','NACA63221.txt','order',6,'npts',100, ...
             'bw_rel',0.5,'bw_abs',0.05,'outdir','', ...
             'write_legacy',false);
for k = 1:2:numel(varargin), opt.(varargin{k}) = varargin{k+1}; end

% (reorganizacion) rutas del proyecto; no se cambia de directorio
rutas = proyecto_init();
if isempty(opt.outdir)
    dir_base = fullfile(rutas.simulaciones, 'cst_baselines');
    dir_opt  = rutas.optimizados;
else
    dir_base = opt.outdir; dir_opt = opt.outdir;
end
if ~exist(dir_base,'dir'), mkdir(dir_base); end
base_file = buscar_perfil(opt.base);
case_id   = case_id_from_file(base_file);

[fluid, inputs] = inputs_definition();
inputs.perfil = base_file;
af = load_airfoil(base_file);
p  = cst_fit(af, opt.order);
dv0 = [p.Au(:); p.Al(:)];
nu  = numel(p.Au);

[xb0, yb0, ~, yu0, ~, yl0] = cst_to_coords(p.Au, p.Al, p.yte_u, p.yte_l, opt.npts, p.N1, p.N2);
tmax_base = max(yu0 - yl0);
baseline_file = fullfile(dir_base, sprintf('cst_baseline_%s.dat', case_id));
opt_file      = fullfile(dir_opt,  sprintf('optimized_%s_hardcon.dat', case_id));
tmp_file      = fullfile(dir_base, sprintf('cand_airfoil_%s.dat', case_id));
% Write a case-specific CST baseline. A legacy copy is kept only for backward
% compatibility; new optimisation/plotting code should use ctx.baseline_file.
write_airfoil_dat(baseline_file, xb0, yb0);
if opt.write_legacy
    write_airfoil_dat(fullfile(dir_base, 'cst_baseline.dat'), xb0, yb0);
end

ctx = struct();
ctx.base_file  = base_file;
ctx.case_id    = case_id;
ctx.outdir     = dir_base;
ctx.rutas      = rutas;
ctx.nu        = nu;
ctx.yte_u     = p.yte_u; ctx.yte_l = p.yte_l;
ctx.N1        = p.N1;    ctx.N2    = p.N2;
ctx.npts      = opt.npts;
ctx.cross_tol = 1e-4;
ctx.tmax_min  = 0.5*tmax_base;        % structural floor (not too thin)
ctx.T0        = tmax_base;            % max-thickness cap T <= T0 (Kou et al. 2023)
ctx.t_tol     = 1e-3;                 % tolerance on the thickness cap
ctx.inputs    = inputs;  ctx.fluid = fluid;
ctx.baseline_file = baseline_file;
ctx.legacy_baseline_file = fullfile(dir_base, 'cst_baseline.dat');
ctx.opt_file  = opt_file;
ctx.legacy_opt_file = fullfile(dir_opt, 'optimized_hardcon.dat');
ctx.tmpfile   = tmp_file;
ctx.penalty   = 200;          % dBA, for invalid/non-converged designs
ctx.H_sep     = 2.7;          % reject designs whose suction side separates (H>2.7):
                              % TNO is an attached-BL model, so separated designs
                              % would let the optimiser 'game' the noise prediction.
                              % Baseline suction H=2.50, so this allows only a thin
                              % margin and stays below the H~3 separation threshold.
ctx.Cf_min    = 1.5e-4;       % positive skin-friction floor on the suction side at
                              % the TE. A 21% section naturally has low Cf this far
                              % back (baseline suction Cf=2.1e-4 at x/c=0.99); this
                              % floor sits just below the baseline yet well above the
                              % incipient-separation case (Cf~5e-5) that the optimiser
                              % otherwise exploits where the attached-BL TNO breaks down.
ctx.verbose   = true;         % print evaluator errors (set false during big runs)
ctx.clcd_pen  = 5;            % dBA per unit Cl/Cd deficit (penalty method)

% baseline (start point) objective and aero coefficients
eval_airfoil_cached('reset');
R0 = eval_airfoil_cached(dv0, ctx);
if ~R0.valid
    error('Baseline airfoil failed to evaluate (status: %s).', R0.status);
end
ctx.clcd_min = R0.clcd;       % hard floor = baseline efficiency

% box bounds around the base coefficients
bw = max(opt.bw_abs, opt.bw_rel*abs(dv0));

P = struct('ctx',ctx, 'dv0',dv0, 'lb',dv0-bw, 'ub',dv0+bw, ...
           'af',af, 'p',p, 'base_file',base_file, 'case_id',case_id, ...
           'J0',R0.OASPL_A, 'clcd0',R0.clcd, ...
           'Cl0',R0.Cl, 'Cd0',R0.Cd);
end

function id = case_id_from_file(filename)
[~,id] = fileparts(filename);
id = regexprep(id, '[^A-Za-z0-9]+', '_');
if isempty(id), id = 'airfoil'; end
end
