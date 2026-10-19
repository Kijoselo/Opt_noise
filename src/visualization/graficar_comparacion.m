function fig = graficar_comparacion(resultados, opciones)
% GRAFICAR_COMPARACION  Compara varias predicciones (salidas de predecir_ruido):
%   (a) siluetas de los perfiles (fila superior)
%   (b) espectro de presión de pared, succión (sólido) y presión (discontinuo)
%   (c) espectro A-ponderado en tercios de octava (total)
% Formato 2x2 pensado para verse dentro del Live Script.
%
%   fig = graficar_comparacion({res_base, res_opt})
%   fig = graficar_comparacion({res_base, res_opt}, struct('titulo', 'NACA 63-221'))
if nargin < 2, opciones = struct(); end
if ~iscell(resultados), resultados = {resultados}; end
if ~isfield(opciones, 'titulo'), opciones.titulo = 'Comparación'; end
pref = 20e-6; dB = @(x) 10*log10(x/pref^2);
n = numel(resultados);
pc = pub_colors(); colores = pc.order;
if n > size(colores, 1), colores = lines(n); end

fig = figure('Color', 'w', 'Position', [80 80 760 720]);
tl = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile([1 2]); hold(ax1, 'on'); grid(ax1, 'on'); axis(ax1, 'equal');
ax2 = nexttile; hold(ax2, 'on'); grid(ax2, 'on');
ax3 = nexttile; hold(ax3, 'on'); grid(ax3, 'on');
h2 = gobjects(1, 2*n); h3 = gobjects(1, n);
for k = 1:n
    r = resultados{k}; c = colores(k, :);
    af = load_airfoil(r.perfil);
    plot(ax1, af.x, af.y, '-', 'Color', c, 'LineWidth', 1.2, 'DisplayName', r.etiqueta);
    h2(2*k-1) = semilogx(ax2, r.f, dB(r.Phi_pp_s), '-',  'Color', c, 'LineWidth', 1.2, ...
                         'DisplayName', [r.etiqueta ', succión']);
    h2(2*k)   = semilogx(ax2, r.f, dB(r.Phi_pp_p), '--', 'Color', c, 'LineWidth', 1.2, ...
                         'DisplayName', [r.etiqueta ', presión']);
    [L3, Fc] = NarrowToNthOctave(r.f, r.SPL_dBA, 3);
    h3(k) = semilogx(ax3, Fc, L3, '-o', 'Color', c, 'MarkerFaceColor', c, 'MarkerSize', 3, ...
                     'DisplayName', sprintf('%s (%.2f dBA)', r.etiqueta, r.OASPL_A));
end
xlabel(ax1, 'x/c'); ylabel(ax1, 'y/c'); xlim(ax1, [-0.02 1.02]);
legend(ax1, 'Location', 'eastoutside'); title(ax1, {opciones.titulo, '(a) geometría'}, 'Interpreter', 'none', 'FontSize', 10);
set(ax2, 'XScale', 'log'); xlim(ax2, [100 2e4]);
xlabel(ax2, 'f [Hz]'); ylabel(ax2, '\Phi_{pp} [dB re (20 \muPa)^2]');
legend(h2, 'Location', 'southoutside', 'NumColumns', 2, 'FontSize', 7); title(ax2, '(b) \Phi_{pp} en x/c = Mic', 'FontSize', 9);
set(ax3, 'XScale', 'log'); xlim(ax3, [100 2e4]);
xlabel(ax3, 'f_c [Hz]'); ylabel(ax3, 'SPL_A [dBA], tercios de octava');
legend(h3, 'Location', 'southoutside', 'NumColumns', 1, 'FontSize', 7); title(ax3, '(c) SPL_A, 1/3 octava', 'FontSize', 9);
end
