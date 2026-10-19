function compare_airfoils_opt(budget)
% COMPARE_AIRFOILS_OPT  Diagnostic only (does NOT touch the manuscript).
% Optimises the official NACA 63-221 and NACA 63-218 coordinate files at the
% SAME operating conditions (whatever inputs_definition sets: U, AoA, chord) and
% prints a side-by-side comparison of baseline vs optimum. The single-objective
% hard-Cl/Cd problem and the attachment constraint are exactly those used in the
% paper, so this shows how each section behaves under the same framework.
%
% Side-effect-safe:
%   - writes each optimum to  opt_<name>.dat   (NOT optimized_hardcon.dat)
%   - does not refresh         cst_baseline.dat
%   - produces NO figures and changes NO manuscript file
%
% Usage:  compare_airfoils_opt          (budget 400)
%         compare_airfoils_opt(1000)    (match the paper's headline budget)
if nargin < 1 || isempty(budget), budget = 400; end
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace

files = {'NACA63221.txt', 'NACA63218.txt'};

fprintf('\n  Optimisation comparison (budget %d, hard Cl/Cd >= baseline, H<=2.7, Cf>=1.5e-4)\n', budget);
fprintf('  %-14s | %8s %7s | %8s %7s | %6s %6s | %6s %8s\n', ...
        'airfoil','base dB','baseLD','opt dB','optLD','gain','%enrg','opt t/c','sucH/Cf');
fprintf('  %s\n', repmat('-',1,86));

for i = 1:numel(files)
    f = files{i};
    P = setup_problem('base', f, 'write_legacy', false);

    opts = optimoptions('patternsearch','Display','off', ...
        'MaxFunctionEvaluations',budget,'UseCompletePoll',true,'MeshTolerance',1e-4);
    dv = patternsearch(@(d) obj_noise_pure(d,P.ctx), P.dv0, [],[],[],[], ...
                       P.lb, P.ub, @(d) con_clcd(d,P.ctx), opts);

    R  = eval_airfoil_cached(dv, P.ctx);
    nu = P.ctx.nu;
    [xo, yo] = cst_to_coords(dv(1:nu), dv(nu+1:end), P.ctx.yte_u, P.ctx.yte_l, ...
                             P.ctx.npts, P.ctx.N1, P.ctx.N2);
    outname = sprintf('opt_%s.dat', erase(f,'.txt'));
    write_airfoil_dat(outname, xo, yo);

    % one clean evaluation of the optimum to refresh XFOIL_Output, then read the
    % suction-side trailing-edge state (verifies the boundary layer is attached)
    try
        evaluate_airfoil(outname, P.ctx.inputs, P.ctx.fluid);
    catch
    end
    [Hs, Cfs] = suction_state(P.ctx.inputs.Mic);

    gain  = P.J0 - R.OASPL_A;
    enrg  = 100*(1 - 10^(-gain/10));
    fprintf('  %-14s | %8.2f %7.2f | %8.2f %7.2f | %6.3f %5.1f%% | %6.3f  %.2f/%.5f\n', ...
            f, P.J0, P.clcd0, R.OASPL_A, R.clcd, gain, enrg, R.tmax, Hs, Cfs);
end

fprintf('  %s\n', repmat('-',1,86));
fprintf('  (optima saved to opt_NACA63221.dat / opt_NACA63218.dat; manuscript files untouched)\n\n');

end

function [H, Cf] = suction_state(pos)
% Suction-side H and Cf at x/c=pos from the last XFOIL DUMP (XFOIL_Output).
% DUMP columns: 1:s 2:x 3:y 4:Ue 5:Dstar 6:Theta 7:Cf 8:H ; suction = first half.
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
