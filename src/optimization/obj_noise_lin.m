function J = obj_noise_lin(dv, ctx)
% OBJ_NOISE_LIN  Un-weighted OASPL (no A-filter) only, for use together with
% a nonlinear constraint (e.g. con_clcd). Same penalty handling as
% obj_noise_pure; only the acoustic metric changes.
R = eval_airfoil_cached(dv, ctx);
if ~R.valid, J = ctx.penalty; else, J = R.OASPL_lin; end
end
