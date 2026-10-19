function registro = registrar_resultado(registro, res, etiqueta)
% REGISTRAR_RESULTADO  Añade una predicción al registro de resultados de la
% sesión (para comparar ejecuciones en Main.mlx).
%
%   registro = registrar_resultado([], res)              % crea el registro
%   registro = registrar_resultado(registro, res, 'AoA 6')
%
% El registro es una estructura con campos:
%   .items   cell de resultados (predecir_ruido)
%   .tabla   tabla resumen actualizada (tabla_resumen)
if nargin < 3 || isempty(etiqueta), etiqueta = res.etiqueta; end
if isempty(registro) || ~isstruct(registro)
    registro = struct('items', {{}}, 'tabla', table());
end
res.etiqueta = char(etiqueta);
registro.items{end+1} = res;
registro.tabla = tabla_resumen(registro.items);
end
