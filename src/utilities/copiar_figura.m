function destino = copiar_figura(origen, destino_nombre)
% COPIAR_FIGURA  Copia una figura PNG ya guardada en results/figures con otro
% nombre (sustituye a los copyfile relativos del código original).
%   copiar_figura('fig_mechanism_aero_NACA63221', 'fig_mechanism_aero')
rutas = proyecto_rutas();
[p, n] = fileparts(origen);
if isempty(p), p = rutas.figuras; end
origen_png = fullfile(p, [n '.png']);
[pd, nd] = fileparts(destino_nombre);
if isempty(pd), pd = rutas.figuras; end
destino = fullfile(pd, [nd '.png']);
if exist(origen_png, 'file')
    copyfile(origen_png, destino);
else
    warning('copiar_figura:noExiste', 'No existe %s', origen_png);
end
end
