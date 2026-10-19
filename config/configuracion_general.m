function cfg = configuracion_general()
% CONFIGURACION_GENERAL  Parámetros centrales del proyecto en una sola estructura.
%
%   cfg = configuracion_general();
%
% Campos:
%   cfg.fluido   propiedades del aire (de inputs_definition): T [C], rho [kg/m^3],
%                ni [m^2/s], c0 [m/s], ...
%   cfg.caso     caso de operación y observador (= estructura "inputs" que usa toda
%                la cadena de ruido): perfil, chord [m], span [m], U [m/s], AoA [deg],
%                xtr_s/xtr_p (transición forzada x/c; 1 = natural), Mic (x/c donde se
%                evalúa Phi_pp), x/y/z [m] observador, model (TNO|Goody|Kamruzzaman|Amiet),
%                M, Re, semichord (derivados: ver actualizar_caso).
%   cfg.caso.tno_perfil  'original' (código UTwente, valor por defecto, reproduce el
%                paper) | 'coles' (cierre de Coles U(delta)=Ue; opción de diagnóstico,
%                NO validada; ver documentation/HALLAZGO_TNO.md).
%   cfg.perfiles archivos de coordenadas del caso principal (se resuelven con buscar_perfil).
%   cfg.exportar opciones de exportación de figuras/tablas.
%   cfg.rutas    rutas del proyecto (proyecto_rutas).
%
% Los valores físicos por defecto son los del manuscrito (NACA 63-221, c = 0.57 m,
% U = 83.31 m/s, AoA = 4 deg, transición 0.05, observador a 1 m sobre el borde de fuga).
% Para cambiarlos, edítelos en Main.mlx (sección "Parámetros generales") y llame a
% actualizar_caso(cfg).

[fluido, caso] = inputs_definition();     % valores originales del código de ruido

cfg = struct();
cfg.fluido = fluido;
cfg.caso   = caso;
cfg.caso.perfil     = 'NACA63221.txt';
cfg.caso.tno_perfil = 'original';

cfg.perfiles = struct( ...
    'base',       'NACA63221.txt', ...                  % coordenadas oficiales (61 pts)
    'base_cst',   'cst_baseline_NACA63221.dat', ...     % proyección CST (baseline real de la optimización)
    'optimizado', 'optimized_NACA63221_hardcon.dat', ...% óptimo mono-modelo del paper
    'base_218',   'NACA63218.txt', ...
    'optimizado_218', 'opt_NACA63218_definitivo.dat');  % óptimo robusto del paper (Tabla 63-218)

cfg.exportar = struct('dpi', 300, 'formatos', {{'png'}}, 'ancho_cm', 19, ...
                      'guardar_mat', true, 'guardar_csv', true);

cfg.rutas = proyecto_rutas();
cfg = actualizar_caso(cfg);
end
