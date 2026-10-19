function carpeta = exportar_ejecucion(resultados, cfg, nombre, figuras)
% EXPORTAR_EJECUCION  Guarda una o varias predicciones con sus parámetros,
% tablas, espectros y figuras en una carpeta nueva con marca de tiempo dentro
% de results/exports/ (nunca sobrescribe exportaciones anteriores).
%
%   carpeta = exportar_ejecucion(res, cfg, 'baseline')
%   carpeta = exportar_ejecucion({res_base, res_opt}, cfg, 'base_vs_opt', [fig1 fig2])
%
% Contenido de la carpeta:
%   resultados.mat          cell de resultados + cfg
%   resumen.csv             tabla_resumen
%   capa_limite.csv         tabla_capa_limite
%   espectro_<etiqueta>.csv f, SPL_dB, SPL_dBA, Phi_pp_s, Phi_pp_p, S_pp_s, S_pp_p
%   parametros.txt          caso de operación, fluido, modelo, perfiles, fecha, versión de MATLAB
%   fig_*.png               figuras pasadas en 'figuras' (dpi de cfg.exportar)
if ~iscell(resultados), resultados = {resultados}; end
if nargin < 3 || isempty(nombre), nombre = 'ejecucion'; end
if nargin < 4, figuras = []; end
carpeta = carpeta_ejecucion(nombre, cfg.rutas.exportaciones);

if cfg.exportar.guardar_mat
    save(fullfile(carpeta, 'resultados.mat'), 'resultados', 'cfg');
end
if cfg.exportar.guardar_csv
    writetable(tabla_resumen(resultados), fullfile(carpeta, 'resumen.csv'));
    Tbl = tabla_capa_limite(resultados);
    if ~isempty(Tbl), writetable(Tbl, fullfile(carpeta, 'capa_limite.csv')); end
    for k = 1:numel(resultados)
        r = resultados{k};
        E = table(r.f(:), r.SPL_dB(:), r.SPL_dBA(:), r.Phi_pp_s(:), r.Phi_pp_p(:), r.S_pp_s(:), r.S_pp_p(:), ...
                  'VariableNames', {'f_Hz','SPL_dB','SPL_dBA','Phi_pp_s','Phi_pp_p','S_pp_s','S_pp_p'});
        writetable(E, fullfile(carpeta, sprintf('espectro_%s.csv', regexprep(r.etiqueta,'[^\w\-]+','_'))));
    end
end

% parámetros y metadatos
fid = fopen(fullfile(carpeta, 'parametros.txt'), 'w');
fprintf(fid, 'Exportacion: %s\nFecha: %s\nMATLAB: %s\nProyecto: %s\n\n', nombre, datestr(now), version, cfg.rutas.raiz);
fprintf(fid, '[caso]\n'); escribir_struct(fid, cfg.caso);
fprintf(fid, '\n[fluido]\n'); escribir_struct(fid, cfg.fluido);
fprintf(fid, '\n[perfiles]\n');
for k = 1:numel(resultados)
    fprintf(fid, '%s = %s\n', resultados{k}.etiqueta, resultados{k}.perfil);
end
fclose(fid);

% figuras
for k = 1:numel(figuras)
    if ~isgraphics(figuras(k)), continue; end
    for fmt = cfg.exportar.formatos
        exportgraphics(figuras(k), fullfile(carpeta, sprintf('fig_%d.%s', k, fmt{1})), 'Resolution', cfg.exportar.dpi);
    end
end
fprintf('Exportado en %s\n', carpeta);
end

function escribir_struct(fid, s)
c = fieldnames(s);
for i = 1:numel(c)
    v = s.(c{i});
    if isnumeric(v) || islogical(v), fprintf(fid, '%s = %s\n', c{i}, mat2str(v, 6));
    elseif ischar(v) || isstring(v), fprintf(fid, '%s = %s\n', c{i}, char(v));
    end
end
end
