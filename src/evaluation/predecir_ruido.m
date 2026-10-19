function res = predecir_ruido(perfil, cfg, etiqueta)
% PREDECIR_RUIDO  Predicción completa de ruido de borde de fuga de un perfil.
% Envuelve evaluate_airfoil (XFOIL -> capa límite -> espectro de presión de pared
% -> Amiet/Roger-Moreau -> campo lejano) y devuelve todo lo necesario para
% analizar, graficar, tabular y exportar el resultado.
%
%   res = predecir_ruido('NACA63221.txt', cfg)
%   res = predecir_ruido('optimized_NACA63221_hardcon.dat', cfg, 'optimizado')
%
% Entradas
%   perfil    nombre o ruta del archivo de coordenadas (ver buscar_perfil)
%   cfg       estructura de configuracion_general (usa cfg.caso y cfg.fluido)
%   etiqueta  texto identificador (opcional; por defecto el nombre del archivo)
%
% Salida: estructura res con
%   etiqueta, perfil (ruta), fecha, caso (inputs usados), fluido
%   f [Hz], S_pp, S_pp_s, S_pp_p   PSD de presión acústica en el observador [Pa^2/Hz]
%   Phi_pp_s, Phi_pp_p             espectro de presión de pared en x/c = Mic
%                                  (cada lado; mismas unidades que el código original)
%   OASPL_A [dBA], OASPL_lin [dB]  niveles globales (total)
%   OASPL_A_s, OASPL_A_p           contribución A-ponderada de cada lado
%   Cl, Cd, Cm, clcd               coeficientes aerodinámicos de XFOIL
%   capa_limite                    tabla (lado, dstar_c, theta_c, H, Cf, Ue_Uinf,
%                                  Phi_pk_dB) leída en x/c = Mic
%   SPL_dB, SPL_dBA                espectro en dB re (20 uPa)^2/Hz, sin y con filtro A
if nargin < 3 || isempty(etiqueta)
    [~, etiqueta] = fileparts(char(perfil));
end
inputs = cfg.caso; fluido = cfg.fluido;
pref = 20e-6;

ruta = buscar_perfil(perfil);
[OASPL_A, Cl, Cd, o] = evaluate_airfoil(ruta, inputs, fluido);

f = o.f;
A = ponderacion_A(f);
nivel_A = @(S) 10*log10(trapz(f, S.*10.^(A/10))/pref^2);

res = struct();
res.etiqueta  = char(etiqueta);
res.perfil    = ruta;
res.fecha     = datestr(now);
res.caso      = inputs;
res.fluido    = fluido;
res.f         = f;
res.S_pp      = o.S_pp;   res.S_pp_s = o.S_pp_s;   res.S_pp_p = o.S_pp_p;
res.Phi_pp_s  = o.Phi_pp_s; res.Phi_pp_p = o.Phi_pp_p;
res.OASPL_A   = OASPL_A;
res.OASPL_lin = o.OASPL_lin;
res.OASPL_A_s = nivel_A(o.S_pp_s);
res.OASPL_A_p = nivel_A(o.S_pp_p);
res.Cl = Cl; res.Cd = Cd; res.Cm = o.Cm; res.clcd = Cl/Cd;
res.SPL_dB  = 10*log10(o.S_pp/pref^2);
res.SPL_dBA = res.SPL_dB + A;
res.capa_limite = leer_capa_limite(inputs, o);
end

function A = ponderacion_A(f)
% Curva de ponderación A (IEC 61672), normalizada a 0 dB en 1 kHz.
Ra = 12194^2*f.^4 ./ ((f.^2+20.6^2).*sqrt((f.^2+107.7^2).*(f.^2+797.9^2)).*(f.^2+12194^2));
A  = 20*log10(Ra) - 20*log10(Ra(f==1000));
end

function T = leer_capa_limite(inputs, o)
% Parámetros de capa límite en x/c = inputs.Mic de la última corrida de XFOIL
% (misma lectura que XFOIL_new_airfoil: fila 'index' = succión, n-index+1 = presión).
pref = 20e-6;
T = table();
try
    txt = fileread(xfoil_out('xfoil_stdout.txt'));
    k = strfind(txt, 'Number of panel nodes');
    n_nodes = str2double(txt((k+28):(k+30)));
    fid = fopen(xfoil_out('XFOIL_Output'), 'r');
    D = textscan(fid, '%f%f%f%f%f%f%f%f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true, ...
                 'CollectOutput', 1, 'HeaderLines', 1);
    fclose(fid); D = D{1};
    xc = D(:,2);
    [~, i] = min(abs(inputs.Mic - xc(1:n_nodes/2)));
    j = n_nodes - i + 1;
    filas = [i j];
    lado = {'succion'; 'presion'};
    dstar_c = D(filas,5); theta_c = D(filas,6); Cf = D(filas,7); H = dstar_c./theta_c;
    Ue_Uinf = abs(D(filas,4));
    Phi_pk_dB = [10*log10(max(o.Phi_pp_s)/pref^2); 10*log10(max(o.Phi_pp_p)/pref^2)];
    T = table(lado, dstar_c, theta_c, H, Cf, Ue_Uinf, Phi_pk_dB);
catch ME
    warning('predecir_ruido:capaLimite', 'No se pudo leer la capa límite de XFOIL: %s', ME.message);
end
end
