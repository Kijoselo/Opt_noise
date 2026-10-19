function rutas = proyecto_rutas()
% PROYECTO_RUTAS  Estructura con todas las rutas del proyecto (absolutas).
% Se calcula a partir de la ubicación de este archivo (src/utilities), de modo
% que funciona desde cualquier directorio de trabajo.
%
% Campos:
%   raiz, config, src, bin, tests, documentacion
%   datos, perfiles (data/airfoils), optimizados (data/optimized),
%   referencia (data/reference), polares (data/polars), procesados (data/processed)
%   resultados, figuras, tablas, simulaciones, exportaciones, logs
%   xfoil_work        carpeta donde corre xfoil.exe y quedan sus archivos temporales
%   legacy_workspace  copia plana de los datos para los scripts de estudio heredados

raiz = fileparts(fileparts(fileparts(mfilename('fullpath'))));

rutas = struct();
rutas.raiz          = raiz;
rutas.config        = fullfile(raiz, 'config');
rutas.src           = fullfile(raiz, 'src');
rutas.bin           = fullfile(raiz, 'bin');
rutas.tests         = fullfile(raiz, 'tests');
rutas.documentacion = fullfile(raiz, 'documentation');

rutas.datos        = fullfile(raiz, 'data');
rutas.perfiles     = fullfile(raiz, 'data', 'airfoils');
rutas.optimizados  = fullfile(raiz, 'data', 'optimized');
rutas.referencia   = fullfile(raiz, 'data', 'reference');
rutas.polares      = fullfile(raiz, 'data', 'polars');
rutas.procesados   = fullfile(raiz, 'data', 'processed');

rutas.resultados    = fullfile(raiz, 'results');
rutas.figuras       = fullfile(raiz, 'results', 'figures');
rutas.tablas        = fullfile(raiz, 'results', 'tables');
rutas.simulaciones  = fullfile(raiz, 'results', 'simulations');
rutas.exportaciones = fullfile(raiz, 'results', 'exports');
rutas.logs          = fullfile(raiz, 'results', 'logs');

wd = getappdata(0, 'PRP_xfoil_workdir');
if isempty(wd), wd = fullfile(rutas.simulaciones, 'xfoil_work'); end
rutas.xfoil_work       = wd;
rutas.legacy_workspace = fullfile(rutas.simulaciones, 'legacy_workspace');
end
