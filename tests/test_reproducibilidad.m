function R = test_reproducibilidad(verbose)
% TEST_REPRODUCIBILIDAD  Comprueba que la cadena de ruido reorganizada reproduce
% los niveles de referencia del código original (valores obtenidos con el código
% del zip de UTwente + inputs del manuscrito, 2026-10-15/19).
%
%   R = test_reproducibilidad()   -> tabla con valor esperado, obtenido y estado
%
% Coste: 6 evaluaciones de XFOIL (~1 min). Tolerancia 0.02 dB.
% Los valores de referencia se verificaron el 2026-10-19 ejecutando el código
% original (work/Amiet-Theory-for-TE-Noise) y el reorganizado en la misma sesión.
if nargin < 1, verbose = true; end
proyecto_init();
cfg = configuracion_general();
tol = 0.02;

casos = { ...  % perfil, OASPL_A esperado, succión esperada, presión esperada
    'NACA63221.txt',                   67.11, 60.96, 65.90;
    'cst_baseline_NACA63221.dat',      67.10,   NaN,   NaN;
    'optimized_NACA63221_hardcon.dat', 65.81, 56.84, 65.23;
    'NACA63218.txt',                   67.75, 63.46, 65.73;
    'cst_baseline_NACA63218.dat',      67.82, 63.61, 65.74;
    'opt_NACA63218_definitivo.dat',    65.64, 56.88, 65.02};

n = size(casos,1);
perfil = casos(:,1); esperado = cell2mat(casos(:,2));
obtenido = nan(n,1); succion = nan(n,1); presion = nan(n,1); ok = false(n,1);
for k = 1:n
    try
        r = predecir_ruido(perfil{k}, cfg);
        obtenido(k) = r.OASPL_A; succion(k) = r.OASPL_A_s; presion(k) = r.OASPL_A_p;
        ok(k) = abs(obtenido(k) - esperado(k)) <= tol ...
             && (isnan(casos{k,3}) || abs(succion(k) - casos{k,3}) <= tol) ...
             && (isnan(casos{k,4}) || abs(presion(k) - casos{k,4}) <= tol);
    catch ME
        if verbose, fprintf(2, '  [%s] error: %s\n', perfil{k}, ME.message); end
    end
end
estado = repmat({'FALLA'}, n, 1); estado(ok) = {'OK'};
R = table(perfil, esperado, obtenido, succion, presion, estado);
if verbose
    fprintf('\n== test_reproducibilidad (tolerancia %.2f dB) ==\n', tol); disp(R);
end
end
