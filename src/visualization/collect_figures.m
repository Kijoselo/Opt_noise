function collect_figures()
% COLLECT_FIGURES  Copy the 8 final manuscript figures into paper/figures/.
rutas = proyecto_init();
dst = fullfile(rutas.exportaciones, 'figuras_paper');   % (reorganizacion) antes paper/figures
if ~exist(dst,'dir'), mkdir(dst); end
figs = {'fig_validation_farfield','fig_validation_wps', ...
        'parameterization_comparison','fig_sensitivity_tornado', ...
        'fig_mechanism_geom','fig_shape_modes_top','fig_shape_modes', ...
        'fig_mechanism_aero','fig_spectrum_hardcon', ...
        'fig_algo_convergence','fig_algo_exploration','fig_pareto_front'};
for k = 1:numel(figs)
    src = fullfile(rutas.figuras, [figs{k} '.png']);
    if exist(src,'file')
        copyfile(src, dst); fprintf('  copied %s.png\n', figs{k});
    else
        fprintf('  MISSING %s.png (regenerate it)\n', figs{k});
    end
end
fprintf('Figures collected in %s\n', dst);
end
