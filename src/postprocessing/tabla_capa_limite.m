function T = tabla_capa_limite(resultados)
% TABLA_CAPA_LIMITE  Parámetros de capa límite en x/c = Mic (ambos lados) de
% varias predicciones (salidas de predecir_ruido). Equivale a la tabla de
% capa límite del manuscrito.
%
%   T = tabla_capa_limite({res_base, res_opt})
%
% Columnas: caso, lado, dstar_c, theta_c, H, Cf, Ue_Uinf, Phi_pk_dB
if ~iscell(resultados), resultados = {resultados}; end
T = table();
for k = 1:numel(resultados)
    r = resultados{k};
    if isempty(r.capa_limite), continue; end
    t = r.capa_limite;
    t = addvars(t, repmat({r.etiqueta}, height(t), 1), 'Before', 1, 'NewVariableNames', 'caso');
    T = [T; t]; %#ok<AGROW>
end
end
