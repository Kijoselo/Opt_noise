function audit_optimization(files)
% AUDIT_OPTIMIZATION  Numerical audit of the optimisation chain (read-only on
% the manuscript; only prints). Answers three questions per case:
%
%  1) PARAMETERISATION: can CST(6) represent the geometry family?
%     - fit residual of the baseline coordinates (max/mean |dy| in 1e-4 c)
%     - OASPL of the raw file vs its CST projection (projection error in dB)
%  2) IS THE DESIGN BOX LIMITING? bound activity of the optimum: refit CST to
%     the saved optimum and report each coefficient's normalised position in
%     [lb,ub]. Interior optimum (nothing pegged) => the box/parameterisation is
%     NOT the limiter; the active limits are physical (H, Cf).
%  3) CONSISTENCY: re-evaluate the saved optimum .dat from scratch and compare
%     OASPL/Cl/Cd with the numbers reported during the runs; also report which
%     geometric/BL constraints are active at the optimum.
%
% Usage: audit_optimization                              (both AFnaca cases)
%        audit_optimization({'NACA63221.txt'})
if nargin < 1 || isempty(files)
    files = {'AFnaca633221_Coords.dat','AFnaca633218_Coords.dat'};
end
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace

for i = 1:numel(files)
    f = files{i};
    fprintf('\n================ AUDIT: %s ================\n', f);
    P = setup_problem('base', f, 'write_legacy', false);
    ctx = P.ctx; nu = ctx.nu;
    fprintf('    baseline: J0 = %.3f dBA | Cl/Cd = %.2f | tmax/c = %.4f\n', ...
            P.J0, P.clcd0, ctx.T0);

    %% 1) parameterisation representation error (baseline)
    yu_fit = cst_eval(P.af.xu, P.p.Au, P.p.yte_u, P.p.N1, P.p.N2);
    yl_fit = cst_eval(P.af.xl, P.p.Al, P.p.yte_l, P.p.N1, P.p.N2);
    eu = abs(yu_fit - P.af.yu(:));  el = abs(yl_fit - P.af.yl(:));
    fprintf('\n[1] CST(6) fit of baseline coordinates:\n');
    fprintf('    upper: max |dy| = %.2f e-4 c, mean = %.2f e-4 c\n', 1e4*max(eu), 1e4*mean(eu));
    fprintf('    lower: max |dy| = %.2f e-4 c, mean = %.2f e-4 c\n', 1e4*max(el), 1e4*mean(el));
    try
        clean_xfoil();
        [OA_raw, Cl_raw, Cd_raw] = evaluate_airfoil(P.base_file, ctx.inputs, ctx.fluid);
        fprintf('    OASPL raw file  = %.3f dBA | CST projection = %.3f dBA  (diff %.3f dB)\n', ...
                OA_raw, P.J0, OA_raw - P.J0);
        fprintf('    Cl/Cd raw file  = %.2f       | CST projection = %.2f\n', Cl_raw/Cd_raw, P.clcd0);
    catch ME
        fprintf('    (raw-file evaluation failed: %s)\n', ME.message);
    end

    %% 2) bound activity of the optimum
    opt_file = ctx.opt_file;
    if ~exist(opt_file,'file')
        fprintf('\n[2] optimum %s not found -- skipping.\n', opt_file);
        continue;
    end
    ao  = load_airfoil(opt_file);
    p2  = cst_fit(ao, P.p.order);
    dvh = [p2.Au(:); p2.Al(:)];
    tpos = (dvh - P.lb)./(P.ub - P.lb);          % 0 = at lower bound, 1 = at upper
    lbl = [compose("Au%d",0:nu-1), compose("Al%d",0:nu-1)];
    fprintf('\n[2] optimum position inside the design box (0=lb, 1=ub):\n    ');
    for k = 1:numel(dvh)
        mark = '';
        if tpos(k) < 0.02 || tpos(k) > 0.98, mark = ' <-- AT BOUND'; end
        fprintf('%-4s %6.3f%s', lbl(k), tpos(k), mark);
        if mod(k,4)==0, fprintf('\n    '); end
    end
    nact = sum(tpos < 0.02 | tpos > 0.98);
    fprintf('\n    coefficients at a bound: %d of %d\n', nact, numel(dvh));

    %% 3) consistency + active constraints at the optimum
    fprintf('\n[3] re-evaluation of the saved optimum (%s):\n', opt_file);
    try
        clean_xfoil();
        [OAo, Clo, Cdo] = evaluate_airfoil(opt_file, ctx.inputs, ctx.fluid);
        [Hs, Cfs] = suction_state_local(ctx.inputs.Mic);
        fprintf('    OASPL = %.3f dBA | Cl/Cd = %.2f (Cl %.4f, Cd %.5f)\n', OAo, Clo/Cdo, Clo, Cdo);
        fprintf('    gain vs CST baseline = %.3f dBA\n', P.J0 - OAo);
        fprintf('    suction TE state: H = %.3f (cap %.2f) | Cf = %.5f (floor %.5f)\n', ...
                Hs, ctx.H_sep, Cfs, ctx.Cf_min);
        fprintf('    Cl/Cd margin over floor %.2f: %+.2f\n', ctx.clcd_min, Clo/Cdo - ctx.clcd_min);
    catch ME
        fprintf('    (re-evaluation failed: %s)\n', ME.message);
    end

    [~,~,xu2,yu2,~,yl2] = cst_to_coords(dvh(1:nu), dvh(nu+1:end), ...
                             p2.yte_u, p2.yte_l, ctx.npts, ctx.N1, ctx.N2);
    th = yu2 - yl2; tmax = max(th);
    t_lead = max(th(xu2 <= 0.5)); t_trail = max(th(xu2 > 0.5));
    fprintf('    geometry: tmax = %.4f  (cap %.4f: %s | floor %.4f: %s)\n', ...
        tmax, ctx.T0, actstr(ctx.T0 - tmax, 0.005), ctx.tmax_min, actstr(tmax - ctx.tmax_min, 0.005));
    fprintf('              front-vs-rear margin = %.4f (%s)\n', ...
        t_lead - t_trail, actstr(t_lead - t_trail, 0.005));
end
fprintf('\n================ audit complete ================\n');
end

function s = actstr(margin, tol)
if margin < tol, s = 'ACTIVE'; else, s = sprintf('slack %.4f', margin); end
end

function clean_xfoil()
% Full XFOIL artifact cleanup before a DIRECT evaluate_airfoil call. A failed
% previous run (e.g. non-converged raw file) leaves truncated/stale output
% files and possibly a hung xfoil.exe that poison the next evaluation.
try, system('taskkill /IM xfoil.exe /F >nul 2>&1'); end %#ok<TRYNC>
for f = {xfoil_out('POLAR_OUTPUT'),xfoil_out('doesntmatter'),xfoil_out('XFOIL_Output'),xfoil_out('XFOIL_CP_Output')}
    if exist(f{1},'file'), delete(f{1}); end
end
end

function [H, Cf] = suction_state_local(pos)
H = NaN; Cf = NaN;
if ~exist(xfoil_out('XFOIL_Output'),'file'), return; end
try
    fid = fopen(xfoil_out('XFOIL_Output'),'r');
    D = textscan(fid,'%f%f%f%f%f%f%f%f','Delimiter',' ', ...
                 'MultipleDelimsAsOne',true,'CollectOutput',1,'HeaderLines',1);
    fclose(fid); D = D{1};
catch
    return;
end
if isempty(D) || size(D,2) < 8 || size(D,1) < 10, return; end
D = D(D(:,2) <= 1.0001, :);
if size(D,1) < 10, return; end
x = D(:,2); half = 1:floor(size(D,1)/2);
[~,k] = min(abs(x(half) - pos));
H = D(k,8); Cf = D(k,7);
end
