function J = obj_noise_pure(dv, ctx)
% OBJ_NOISE_PURE  OASPL(A) only (no Cl/Cd penalty), for use together with
% con_clcd as a true nonlinear constraint in constrained solvers.
R = eval_airfoil_cached(dv, ctx);
if ~R.valid, J = ctx.penalty; else, J = R.OASPL_A; end
end
