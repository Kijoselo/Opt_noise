function sanity_rel
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
[fluid,inputs]=inputs_definition(); %#ok<ASGLU>
P=setup_problem('base','NACA63218.txt','bw_rel',0.8,'write_legacy',false);
ctx=P.ctx; ctx.T0=1.4*ctx.T0;
[~,d0]=obj_noise_robusto(P.dv0,ctx); R0=d0.oa; ctx.oa0=R0;
fprintf('R0 (base 3-model): TNO %.3f Goody %.3f Kamr %.3f\n',R0(1),R0(2),R0(3));
[J,d]=obj_noise_robusto_rel(P.dv0,ctx);
fprintf('J_rel at dv0 = %.5f (esperado ~0)\n',J);
fprintf('dL = [%.4f %.4f %.4f] (esperado ~0)\n',d.dL(1),d.dL(2),d.dL(3));
fprintf('clcd0=%.2f  valid=%d\n',P.clcd0,d.valid);
fprintf('SANITY_OK\n');
end
