function [carpeta, etiqueta] = carpeta_ejecucion(nombre, base)
% CARPETA_EJECUCION  Crea una carpeta nueva con marca de tiempo para guardar los
% resultados de una ejecución sin sobrescribir ejecuciones anteriores.
%
%   carpeta = carpeta_ejecucion('opt_NACA63221')
%       -> results/simulations/20261019_153012_opt_NACA63221/
%   carpeta = carpeta_ejecucion('prediccion', rutas.exportaciones)
%       -> results/exports/20261019_153012_prediccion/
if nargin < 2 || isempty(base), base = proyecto_rutas().simulaciones; end
nombre = regexprep(char(nombre), '[^A-Za-z0-9_\-]+', '_');
etiqueta = sprintf('%s_%s', datestr(now, 'yyyymmdd_HHMMSS'), nombre);
carpeta = fullfile(base, etiqueta);
if ~exist(carpeta, 'dir'), mkdir(carpeta); end
end
