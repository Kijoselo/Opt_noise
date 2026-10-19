function informe = ejecutar_pruebas()
% EJECUTAR_PRUEBAS  Corre todas las pruebas del proyecto y escribe un informe en
% results/logs/informe_pruebas_<fecha>.txt.
%
%   informe = ejecutar_pruebas()
%
% Pruebas: test_dependencias (sin XFOIL), test_geometria (sin XFOIL),
% test_reproducibilidad (5 evaluaciones de XFOIL, ~1 min).
rutas = proyecto_init();
t0 = tic;
informe = struct();
informe.dependencias    = test_dependencias(true);
informe.geometria       = test_geometria(true);
informe.reproducibilidad = test_reproducibilidad(true);
informe.duracion_s = toc(t0);

todo_ok = all(strcmp(informe.dependencias.estado, 'OK')) && ...
          all(strcmp(informe.geometria.estado, 'OK')) && ...
          all(strcmp(informe.reproducibilidad.estado, 'OK'));
informe.todo_ok = todo_ok;

archivo = fullfile(rutas.logs, sprintf('informe_pruebas_%s.txt', datestr(now, 'yyyymmdd_HHMMSS')));
fid = fopen(archivo, 'w');
fprintf(fid, 'Informe de pruebas  %s  (%.0f s)\nResultado global: %s\n\n', datestr(now), informe.duracion_s, char(string(todo_ok)));
for c = {'dependencias', 'geometria', 'reproducibilidad'}
    fprintf(fid, '== %s ==\n', c{1});
    fprintf(fid, '%s\n\n', evalc('disp(informe.(c{1}))'));
end
fclose(fid);
fprintf('\nResultado global: %s   (informe en %s)\n', char(string(todo_ok)), archivo);
end
