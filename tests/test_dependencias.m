function R = test_dependencias(verbose)
% TEST_DEPENDENCIAS  Comprueba la integridad del código reorganizado (sin XFOIL):
%   1. todos los .m de src/, config/, tests/ y la raíz pasan checkcode sin errores
%      de sintaxis;
%   2. ningún archivo de src/ o tests/ contiene rutas absolutas (C:\...) ni el
%      antiguo preámbulo cd(parent);
%   3. para los puntos de entrada principales, todas las dependencias que encuentra
%      matlab.codetools.requiredFilesAndProducts están dentro del proyecto, y se
%      listan los toolboxes necesarios.
if nargin < 1, verbose = true; end
rutas = proyecto_init();
nombre = {}; detalle = {}; ok = logical([]);

% 1. sintaxis
archivos = [dir(fullfile(rutas.src, '**', '*.m')); dir(rutas.config); dir(rutas.tests); dir(fullfile(rutas.raiz, '*.m'))];
archivos = archivos(endsWith({archivos.name}, '.m'));
errores = {};
for k = 1:numel(archivos)
    f = fullfile(archivos(k).folder, archivos(k).name);
    msg = checkcode(f, '-id');
    % ENDCT*: 'end' que falta o sobra (p. ej. un 'end' absorbido por un comentario);
    % checkcode lo da como aviso, pero MATLAB no ejecuta el archivo.
    graves = msg(contains({msg.id}, 'SYNER') | strcmp({msg.id}, 'FNDEF') | ...
                 startsWith({msg.id}, 'ENDCT') | contains({msg.message}, 'Parse error'));
    if ~isempty(graves)
        errores{end+1} = sprintf('%s: %s', archivos(k).name, graves(1).message); %#ok<AGROW>
    end
end
nombre{end+1} = sprintf('sintaxis (%d archivos)', numel(archivos)); ok(end+1) = isempty(errores);
detalle{end+1} = strjoin(errores, ' | ');

% 2. rutas absolutas / cd(parent)
malos = {};
for k = 1:numel(archivos)
    if ~contains(archivos(k).folder, {rutas.src, rutas.tests}), continue; end
    if strcmp(archivos(k).name, 'test_dependencias.m'), continue; end   % contiene el patrón buscado
    txt = fileread(fullfile(archivos(k).folder, archivos(k).name));
    lineas = strsplit(txt, newline);
    for L = lineas
        l = strtrim(L{1});
        if startsWith(l, '%'), continue; end
        if ~isempty(regexp(l, 'C:\\|C:/', 'once')) || contains(l, 'cd(parent)')
            malos{end+1} = archivos(k).name; break; %#ok<AGROW>
        end
    end
end
nombre{end+1} = 'sin rutas absolutas ni cd(parent)'; ok(end+1) = isempty(malos); detalle{end+1} = strjoin(malos, ', ');

% 3. dependencias de los puntos de entrada
entradas = {'predecir_ruido', 'evaluate_airfoil', 'setup_problem', 'run_optimization', ...
            'run_multiobjective', 'compare_algorithms', 'sensitivity_analysis', ...
            'validate_naca0012', 'plot_mechanism', 'fig_mechanism_aero_v2', ...
            'boundary_layer_table', 'compare_parameterizations', 'silhouette_variation', ...
            'graficar_comparacion', 'exportar_ejecucion', 'diagnostico_perfil_tno'};
fuera = {}; productos = {};
for e = entradas
    try
        [fl, pl] = matlab.codetools.requiredFilesAndProducts(e{1});
    catch ME
        fuera{end+1} = sprintf('%s (%s)', e{1}, ME.message); continue; %#ok<AGROW>
    end
    ext = fl(~startsWith(fl, rutas.raiz));
    if ~isempty(ext), fuera{end+1} = sprintf('%s -> %s', e{1}, strjoin(ext, ';')); end %#ok<AGROW>
    productos = [productos, {pl.Name}]; %#ok<AGROW>
end
productos = unique(productos);
nombre{end+1} = sprintf('dependencias dentro del proyecto (%d entradas)', numel(entradas)); ok(end+1) = isempty(fuera); detalle{end+1} = strjoin(fuera, ' | ');
nombre{end+1} = 'toolboxes requeridos'; ok(end+1) = true; detalle{end+1} = strjoin(productos, ', ');

% 4. binario y datos clave presentes
req = {fullfile(rutas.bin, 'xfoil.exe'), fullfile(rutas.perfiles, 'NACA63221.txt'), ...
       fullfile(rutas.optimizados, 'optimized_NACA63221_hardcon.dat'), ...
       fullfile(rutas.referencia, 'Ref_fig_SPM', 'AoA0_Goody.tsv')};
falta = req(~cellfun(@(f) exist(f, 'file') == 2, req));
nombre{end+1} = 'binario y datos clave'; ok(end+1) = isempty(falta); detalle{end+1} = strjoin(falta, ', ');

estado = repmat({'FALLA'}, numel(ok), 1); estado(ok) = {'OK'};
R = table(nombre(:), estado, detalle(:), 'VariableNames', {'prueba', 'estado', 'detalle'});
if verbose, fprintf('\n== test_dependencias ==\n'); disp(R); end
end
