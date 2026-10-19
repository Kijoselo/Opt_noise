function ruta = buscar_perfil(nombre, silencioso)
% BUSCAR_PERFIL  Resuelve el nombre de un archivo de coordenadas a una ruta absoluta.
%
%   ruta = buscar_perfil('NACA63221.txt')
%   ruta = buscar_perfil('optimized_NACA63221_hardcon.dat')
%   ruta = buscar_perfil(nombre, true)   -> devuelve '' en vez de error si no existe
%
% Orden de búsqueda: ruta tal cual (absoluta o relativa al directorio actual),
% data/airfoils, data/optimized, results/simulations (recursivo un nivel),
% carpeta de trabajo de XFOIL. Si no hay coincidencia exacta se prueba con la
% extensión alternativa (.dat/.txt) y sin distinguir mayúsculas.
if nargin < 2, silencioso = false; end
nombre = char(nombre);
rutas = proyecto_rutas();

carpetas = {'', rutas.perfiles, rutas.optimizados, rutas.simulaciones, ...
            fullfile(rutas.simulaciones, 'cst_baselines'), rutas.legacy_workspace, ...
            rutas.xfoil_work};
[carpeta_nombre, base, ext] = fileparts(nombre);
exts = unique({ext, '.dat', '.txt', ''}, 'stable');

% 1) coincidencia exacta
for c = carpetas
    cand = fullfile(c{1}, nombre);
    if exist(cand, 'file') == 2
        ruta = absoluta(cand); return;
    end
end
% 2) otra extensión / mayúsculas
for c = carpetas
    if ~isempty(carpeta_nombre), c{1} = fullfile(c{1}, carpeta_nombre); end %#ok<FXSET>
    if ~exist(c{1}, 'dir') && ~isempty(c{1}), continue; end
    lista = dir(fullfile(c{1}, '*'));
    for e = exts
        objetivo = lower([base e{1}]);
        idx = find(strcmpi({lista.name}, objetivo), 1);
        if ~isempty(idx)
            ruta = fullfile(lista(idx).folder, lista(idx).name); return;
        end
    end
end
if silencioso
    ruta = '';
else
    error('buscar_perfil:noEncontrado', ...
        'No se encontró el perfil "%s" en data/airfoils, data/optimized ni en el directorio actual.', nombre);
end
end

function p = absoluta(p)
if ~(numel(p) > 1 && (p(2) == ':' || p(1) == '/' || p(1) == '\'))
    p = fullfile(pwd, p);
end
d = dir(p);
if ~isempty(d), p = fullfile(d(1).folder, d(1).name); end
end
