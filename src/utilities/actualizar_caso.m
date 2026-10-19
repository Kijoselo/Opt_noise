function cfg = actualizar_caso(cfg)
% ACTUALIZAR_CASO  Recalcula las magnitudes derivadas del caso de operación
% después de editar cfg.caso (cuerda, U, ...) o cfg.fluido:
%   semicuerda b = c/2 [m], Mach M = U/c0, Reynolds Re = c*U/nu.
% Debe llamarse siempre que se modifiquen cfg.caso.chord, cfg.caso.U o el fluido.
cfg.caso.semichord = cfg.caso.chord/2;
cfg.caso.M  = cfg.caso.U/cfg.fluido.c0;
cfg.caso.Re = cfg.caso.chord*cfg.caso.U/cfg.fluido.ni;
end
