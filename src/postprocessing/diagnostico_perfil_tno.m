function [T, resultados, fig] = diagnostico_perfil_tno(perfil, cfg)
% DIAGNOSTICO_PERFIL_TNO  Compara, para un perfil, el espectro de presión de
% pared TNO con el perfil de velocidad original del código (cfg.caso.tno_perfil
% = 'original') y con el cierre de Coles ('coles', U(delta) = Ue).
%
%   [T, res, fig] = diagnostico_perfil_tno('NACA63221.txt', cfg)
%
% Esta función es de DIAGNÓSTICO: el modo 'coles' no está validado frente a
% medidas y no interviene en ningún resultado publicado. Ver
% documentation/HALLAZGO_TNO.md para el contexto (2026-10-16).
modos = {'original', 'coles'};
resultados = cell(1, 2);
[~, nombre] = fileparts(char(perfil));
for k = 1:2
    c = cfg; c.caso.model = 'TNO'; c.caso.tno_perfil = modos{k};
    resultados{k} = predecir_ruido(perfil, c, sprintf('%s [TNO %s]', nombre, modos{k}));
end
T = tabla_resumen(resultados);
fig = graficar_comparacion(resultados, struct('titulo', ...
      sprintf('%s: TNO original vs cierre de Coles (diagnóstico)', nombre)));
end
