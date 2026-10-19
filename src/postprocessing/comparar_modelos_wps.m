function [T, resultados] = comparar_modelos_wps(perfil, cfg, modelos)
% COMPARAR_MODELOS_WPS  Evalúa un perfil con varios modelos de espectro de
% presión de pared (misma geometría, misma capa límite de XFOIL).
%
%   [T, res] = comparar_modelos_wps('NACA63221.txt', cfg)
%   [T, res] = comparar_modelos_wps(perfil, cfg, {'TNO','Goody','Kamruzzaman'})
%
% T: tabla resumen (tabla_resumen) con una fila por modelo; res: cell de
% resultados de predecir_ruido. Advertencia: el modelo Kamruzzaman del código
% original lleva u_tau fijo (ver documentation/HALLAZGO_TNO.md).
if nargin < 3 || isempty(modelos), modelos = {'TNO', 'Goody', 'Kamruzzaman', 'Amiet'}; end
resultados = cell(1, numel(modelos));
for k = 1:numel(modelos)
    c = cfg; c.caso.model = modelos{k};
    [~, nombre] = fileparts(char(perfil));
    resultados{k} = predecir_ruido(perfil, c, sprintf('%s [%s]', nombre, modelos{k}));
end
T = tabla_resumen(resultados);
end
