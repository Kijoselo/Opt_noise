function fig = graficar_prediccion(res, opciones)
% GRAFICAR_PREDICCION  Figura resumen de una predicción (salida de predecir_ruido):
%   (a) espectro de presión de pared en x/c = Mic, succión y presión
%   (b) espectro en campo lejano, total y por lado (sin ponderar)
%   (c) espectro A-ponderado en tercios de octava y OASPL(A) por lado
% Formato 2x2 (c ocupa la fila inferior) pensado para verse dentro del Live Script.
%
%   fig = graficar_prediccion(res)
%   fig = graficar_prediccion(res, struct('titulo', 'Baseline'))
if nargin < 2, opciones = struct(); end
if ~isfield(opciones, 'titulo'), opciones.titulo = res.etiqueta; end
pref = 20e-6; dB = @(x) 10*log10(x/pref^2);
f = res.f;
cS = [0 0.447 0.741]; cP = [0.85 0.325 0.098]; cT = [0.2 0.2 0.2];

fig = figure('Color', 'w', 'Position', [80 80 760 620]);
tl = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile; hold on; grid on;
semilogx(f, dB(res.Phi_pp_s), '-', 'Color', cS, 'LineWidth', 1.3);
semilogx(f, dB(res.Phi_pp_p), '--', 'Color', cP, 'LineWidth', 1.3);
set(gca, 'XScale', 'log'); xlim([f(1) f(end)]);
xlabel('f [Hz]'); ylabel('\Phi_{pp} [dB re (20 \muPa)^2]');
legend('succión', 'presión', 'Location', 'southwest'); title('(a) \Phi_{pp} en x/c = Mic', 'FontSize', 9);

nexttile; hold on; grid on;
semilogx(f, res.SPL_dB, '-', 'Color', cT, 'LineWidth', 1.2);
semilogx(f, dB(res.S_pp_s), '-', 'Color', cS, 'LineWidth', 1.0);
semilogx(f, dB(res.S_pp_p), '--', 'Color', cP, 'LineWidth', 1.0);
set(gca, 'XScale', 'log'); xlim([f(1) f(end)]);
xlabel('f [Hz]'); ylabel('S_{pp} [dB re (20 \muPa)^2/Hz]');
legend('total', 'succión', 'presión', 'Location', 'southwest'); title('(b) campo lejano sin ponderar', 'FontSize', 9);

nexttile([1 2]); hold on; grid on;
[L3, Fc] = NarrowToNthOctave(f, res.SPL_dBA, 3);
semilogx(Fc, L3, '-o', 'Color', cT, 'MarkerFaceColor', cT, 'MarkerSize', 3);
set(gca, 'XScale', 'log'); xlim([100 2e4]);
xlabel('f_c [Hz] (tercios de octava)'); ylabel('SPL_A [dBA]');
title(sprintf('(c) A-ponderado, 1/3 octava: OASPL_A = %.2f dBA (succión %.1f, presión %.1f)', ...
      res.OASPL_A, res.OASPL_A_s, res.OASPL_A_p), 'FontSize', 9);

title(tl, {opciones.titulo, sprintf('U = %.1f m/s, c = %.2f m, AoA = %g°, modelo %s', ...
      res.caso.U, res.caso.chord, res.caso.AoA, res.caso.model)}, 'Interpreter', 'none', 'FontSize', 10);
end
