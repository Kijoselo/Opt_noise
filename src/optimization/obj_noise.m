function J = obj_noise(dv, ctx)
% OBJ_NOISE  Single-objective noise objective with a Cl/Cd penalty.
% Penalty method (uniform across all algorithms, including those without
% nonlinear-constraint support such as particleswarm): OASPL(A) plus a
% penalty whenever the lift-to-drag ratio drops below the baseline floor.
R = eval_airfoil_cached(dv, ctx);
if ~R.valid
    J = ctx.penalty;
    return;
end
J = R.OASPL_A;
if isfield(ctx,'clcd_min') && ~isempty(ctx.clcd_min) && R.clcd < ctx.clcd_min
    J = J + ctx.clcd_pen * (ctx.clcd_min - R.clcd);
end
end
