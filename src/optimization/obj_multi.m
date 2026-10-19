function F = obj_multi(dv, ctx)
% OBJ_MULTI  Multi-objective vector for gamultiobj.
%   F(1) = OASPL(A)        (minimise noise)
%   F(2) = -Cl/Cd          (maximise lift-to-drag -> minimise its negative)
% Invalid designs are pushed to a dominated corner.
R = eval_airfoil_cached(dv, ctx);
if ~R.valid
    F = [ctx.penalty, 0];     % loud and zero efficiency: dominated
    return;
end
F = [R.OASPL_A, -R.clcd];
end
