function R = test_geometria(verbose)
% TEST_GEOMETRIA  Pruebas rápidas (sin XFOIL) del módulo de geometría:
%   - lectura de perfiles (load_airfoil, buscar_perfil)
%   - ajuste CST de orden 6 y reconstrucción (error rms < 1e-3 c)
%   - escritura/lectura de un .dat (write_airfoil_dat) en una carpeta temporal
%   - espesor y curvatura (thickness_camber)
if nargin < 1, verbose = true; end
rutas = proyecto_init();
nombre = {}; valor = []; limite = []; ok = logical([]);

for perfil = {'NACA63221.txt', 'NACA63218.txt'}
    af = load_airfoil(perfil{1});
    p  = cst_fit(af, 6);
    [~, ~, xu, yu, xl, yl] = cst_to_coords(p.Au, p.Al, p.yte_u, p.yte_l, 200, p.N1, p.N2);
    eu = interp1(xu, yu, af.xu, 'pchip') - af.yu;
    el = interp1(xl, yl, af.xl, 'pchip') - af.yl;
    rms = sqrt(mean([eu; el].^2));
    nombre{end+1} = sprintf('rms CST(6) %s', perfil{1}); valor(end+1) = rms; limite(end+1) = 1e-3; ok(end+1) = rms < 1e-3; %#ok<AGROW>
end

% escritura y relectura
tmp = fullfile(rutas.simulaciones, 'tmp_test_geometria.dat');
[x, y] = cst_to_coords(p.Au, p.Al, p.yte_u, p.yte_l, 100, p.N1, p.N2);
write_airfoil_dat(tmp, x, y);
af2 = load_airfoil(tmp);
d = max(abs(af2.x - x(:))) + max(abs(af2.y - y(:)));
nombre{end+1} = 'write/read .dat'; valor(end+1) = d; limite(end+1) = 1e-5; ok(end+1) = d < 1e-5;
delete(tmp);

% espesor máximo del 63-221 (21 %)
[~, tc] = thickness_camber('NACA63221.txt', 200);
nombre{end+1} = 'tmax/c NACA63221'; valor(end+1) = max(tc); limite(end+1) = 0.21; ok(end+1) = abs(max(tc) - 0.21) < 0.005;

% buscar_perfil resuelve nombres sin extensión / minúsculas
r = buscar_perfil('naca63221');
nombre{end+1} = 'buscar_perfil(''naca63221'')'; valor(end+1) = double(~isempty(r)); limite(end+1) = 1; ok(end+1) = ~isempty(r);

estado = repmat({'FALLA'}, numel(ok), 1); estado(ok) = {'OK'};
R = table(nombre(:), valor(:), limite(:), estado, 'VariableNames', {'prueba','valor','limite','estado'});
if verbose, fprintf('\n== test_geometria ==\n'); disp(R); end
end
