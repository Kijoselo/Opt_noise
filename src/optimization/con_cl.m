function [c, ceq] = con_cl(dv, ctx)
% CON_CL  Nonlinear constraint: keep the lift coefficient at or above the
% baseline value (constant-lift optimisation).
%   c <= 0 is feasible.  c = cl_min - Cl.
% Invalid / non-converged designs are reported as strongly infeasible.
ceq = [];
R = eval_airfoil_cached(dv, ctx);
if ~R.valid
    c = 1e3;
    return;
end
c = ctx.cl_min - R.Cl;
end
