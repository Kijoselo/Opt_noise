function rutas = proyecto_init(varargin)
% PROYECTO_INIT  Inicializa el proyecto: rutas, path de MATLAB y carpetas de resultados.
%
%   rutas = proyecto_init()
%       Añade src/ (recursivo), config/ y tests/ al path, crea las carpetas de
%       resultados si faltan y devuelve la estructura de rutas (ver proyecto_rutas).
%       NO cambia el directorio de trabajo.
%
%   rutas = proyecto_init('workspace','legacy')
%       Además cambia el directorio de trabajo a results/simulations/legacy_workspace.
%       Lo usan los scripts de estudio heredados (src/studies, parte de
%       src/visualization) que leen y escriben archivos por nombre relativo, tal
%       como se ejecutaban en la carpeta original del código.
%
%   rutas = proyecto_init('xfoil_workdir', carpeta)
%       Usa otra carpeta de trabajo para XFOIL (p. ej. para correr dos sesiones de
%       MATLAB en paralelo sin que colisionen los archivos temporales de XFOIL).
%
% La raíz del proyecto es la carpeta que contiene este archivo; no depende del
% directorio desde el que se haya iniciado MATLAB.

opt = struct('workspace', '', 'xfoil_workdir', '', 'verbose', false);
for k = 1:2:numel(varargin), opt.(varargin{k}) = varargin{k+1}; end

raiz = fileparts(mfilename('fullpath'));

% --- path de MATLAB ---
addpath(raiz);
addpath(genpath(fullfile(raiz, 'src')));
addpath(fullfile(raiz, 'config'));
addpath(fullfile(raiz, 'tests'));

% --- directorio de trabajo de XFOIL (opcional) ---
if ~isempty(opt.xfoil_workdir)
    setappdata(0, 'PRP_xfoil_workdir', char(opt.xfoil_workdir));
end

rutas = proyecto_rutas();

% --- carpetas de resultados ---
crear = {rutas.resultados, rutas.figuras, rutas.tablas, rutas.simulaciones, ...
         rutas.exportaciones, rutas.logs, rutas.xfoil_work, rutas.legacy_workspace};
for k = 1:numel(crear)
    if ~exist(crear{k}, 'dir'), mkdir(crear{k}); end
end

% xfoil.exe debe estar junto a los archivos temporales que escribe
for carpeta = {rutas.xfoil_work, rutas.legacy_workspace}
    exe = fullfile(carpeta{1}, 'xfoil.exe');
    if ~exist(exe, 'file'), copyfile(fullfile(rutas.bin, 'xfoil.exe'), exe); end
end

% --- workspace heredado ---
if strcmpi(opt.workspace, 'legacy')
    cd(rutas.legacy_workspace);
end

if opt.verbose
    fprintf('Proyecto inicializado en %s\n', raiz);
end
end
