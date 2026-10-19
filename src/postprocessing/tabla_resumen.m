function T = tabla_resumen(resultados)
% TABLA_RESUMEN  Tabla con los niveles globales y coeficientes de varias
% predicciones (salidas de predecir_ruido), una fila por perfil.
%
%   T = tabla_resumen({res_base, res_opt})
%
% Columnas: etiqueta, OASPL_A [dBA], OASPL_lin [dB], OASPL_A_succion, OASPL_A_presion,
%           Cl, Cd, Cl_Cd, Cm, modelo, AoA, U, chord
if ~iscell(resultados), resultados = {resultados}; end
n = numel(resultados);
etiqueta = cell(n,1); modelo = cell(n,1);
[OASPL_A, OASPL_lin, OASPL_A_succion, OASPL_A_presion, Cl, Cd, Cl_Cd, Cm, AoA, U, chord] = deal(nan(n,1));
for k = 1:n
    r = resultados{k};
    etiqueta{k} = r.etiqueta; modelo{k} = r.caso.model;
    OASPL_A(k) = r.OASPL_A; OASPL_lin(k) = r.OASPL_lin;
    OASPL_A_succion(k) = r.OASPL_A_s; OASPL_A_presion(k) = r.OASPL_A_p;
    Cl(k) = r.Cl; Cd(k) = r.Cd; Cl_Cd(k) = r.clcd; Cm(k) = r.Cm;
    AoA(k) = r.caso.AoA; U(k) = r.caso.U; chord(k) = r.caso.chord;
end
T = table(etiqueta, OASPL_A, OASPL_lin, OASPL_A_succion, OASPL_A_presion, Cl, Cd, Cl_Cd, Cm, modelo, AoA, U, chord);
end
