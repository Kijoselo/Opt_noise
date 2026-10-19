function [c, ceq] = con_clcd(dv, ctx)
% CON_CLCD  Nonlinear constraint: keep Cl/Cd at or above the baseline.
%   c <= 0 is feasible.  c = clcd_min - clcd.
% Invalid / non-converged designs are reported as strongly infeasible.
ceq = [];
R = eval_airfoil_cached(dv, ctx);
if ~R.valid
    c = 1e3;
    return;
end
c = ctx.clcd_min - R.clcd;
end
