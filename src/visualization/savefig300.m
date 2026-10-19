function out = savefig300(figh, fname, widthcm)
% SAVEFIG300  Export a figure at journal quality (600-dpi PNG, sized to a
% column width). Single-panel figures default to a single column (9 cm);
% multi-panel figures default to a double column (19 cm). Pass widthcm to
% override.
%
%   savefig300(gcf, 'fig_name')          auto width, 600 dpi PNG
%   savefig300(gcf, 'fig_name', 14)      14 cm wide
%   out = savefig300(...)                full path of the written PNG
%
% (reorganizacion) si fname no lleva carpeta, la figura se guarda en
% results/figures/ (proyecto_rutas().figuras); con carpeta, se respeta.
if nargin < 1 || isempty(figh), figh = gcf; end

nax = numel(findall(figh, 'Type', 'axes'));     % count panels (incl. legends)
nax_real = numel(findall(figh, 'Type', 'axes', '-not', 'Tag', 'legend'));
if nargin < 3 || isempty(widthcm)
    if nax_real > 1, widthcm = 19.0; else, widthcm = 9.0; end
end

% keep current aspect ratio, just rescale to the target width
set(figh, 'Units', 'centimeters');
pos = get(figh, 'Position');
aspect = pos(4)/pos(3);
h = widthcm*aspect;
set(figh, 'Units','centimeters', 'Position',[pos(1) pos(2) widthcm h], ...
          'PaperUnits','centimeters', 'PaperPosition',[0 0 widthcm h], ...
          'PaperSize',[widthcm h]);

% consistent fonts / line weights on every child
set(findall(figh,'-property','FontName'),'FontName','Times New Roman');
set(findall(figh,'Type','axes','-property','FontSize'),'FontSize',9);

% strip titles: journal figures carry their description in the LaTeX caption,
% not inside the figure. Axes titles are cleared; figure-level text (sgtitle)
% is deleted. In-axes annotations (e.g. 'baseline' labels) are kept.
for a = findall(figh,'Type','axes')'
    set(get(a,'Title'),'String','');
end
for t = findall(figh,'Type','text')'
    if isequal(get(t,'Parent'), figh)   % parent is the figure => sgtitle
        delete(t);
    end
end

% remove axes interaction toolbars: if the figure was touched interactively,
% exportgraphics can bake the toolbar icons into the PNG ("Exported image
% displays axes toolbar" warning).
delete(findall(figh, 'Type', 'axestoolbar'));

[p,n,e] = fileparts(fname);
if isempty(e), e = '.png'; end
if isempty(p), p = proyecto_rutas().figuras; end
if ~exist(p,'dir'), mkdir(p); end
out = fullfile(p, [n e]);
try
    lastwarn('');
    exportgraphics(figh, out, 'Resolution', 600);
    % MATLAB can bake the axes toolbar into the first export ("Exported image
    % displays axes toolbar"); per the warning text, a second export is clean.
    if contains(lastwarn, 'toolbar', 'IgnoreCase', true)
        exportgraphics(figh, out, 'Resolution', 600);
    end
catch
    print(figh, out, '-dpng', '-r600');
end
fprintf('  saved %s  (%.1f x %.1f cm, 600 dpi)\n', out, widthcm, h);
end
