cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise');
addpath('optim'); set_pub_defaults();
outdir = 'C:\Users\josea\Desktop\Opti_Param_ruidoio\entrega_pala_NACA63218';

% Parse log manually
logfile = 'opt_NACA63218_full.log';
fid = fopen(logfile, 'r');
lines = {}; 
while ~feof(fid), lines{end+1} = fgetl(fid); end
fclose(fid);

iter = []; f_val = []; mesh = [];
for i = 1:numel(lines)
    line = lines{i};
    if contains(line, 'Iter') && i < numel(lines)
        % Next lines have data
        for j = i+1:min(i+20, numel(lines))
            parts = strsplit(strtrim(lines{j}));
            if numel(parts) >= 3
                try
                    it = str2double(parts{1});
                    fv = str2double(parts{3});
                    if ~isnan(it) && ~isnan(fv) && it >= 0 && fv > 60 && fv < 80
                        iter = [iter; it];
                        f_val = [f_val; fv];
                        if numel(parts) >= 4
                            m = str2double(parts{4});
                            if ~isnan(m), mesh = [mesh; m]; end
                        end
                    end
                end
            end
        end
        break;
    end
end

if isempty(f_val)
    % Try simpler parse: just find all lines with OASPL
    for i = 1:numel(lines)
        if contains(lines{i}, '67.') || contains(lines{i}, '65.')
            parts = strsplit(strtrim(lines{i}));
            for k = 1:numel(parts)
                val = str2double(parts{k});
                if ~isnan(val) && val > 65 && val < 68
                    f_val = [f_val; val];
                    iter = [iter; numel(f_val)-1];
                end
            end
        end
    end
end

if ~isempty(f_val)
    figure('Color','w','Position',[50 50 1000 350]);
    
    subplot(1,2,1);
    semilogy(iter, f_val, 'b.-', 'LineWidth', 2, 'MarkerSize', 8);
    hold on;
    plot(0, f_val(1), 'go', 'MarkerSize', 12, 'DisplayName', 'baseline');
    plot(iter(end), f_val(end), 'r*', 'MarkerSize', 16, 'DisplayName', 'optimizado');
    grid on; xlabel('Iteración'); ylabel('OASPL(A) [dBA]');
    legend; title('Convergencia de la optimización');
    text(0.02, 0.97, '(a)', 'Units', 'normalized', 'VerticalAlignment', 'top');
    
    subplot(1,2,2);
    gain = f_val(1) - f_val;
    semilogy(iter, gain + 1e-3, 'g.-', 'LineWidth', 2, 'MarkerSize', 8);
    grid on; xlabel('Iteración'); ylabel('Mejora acumulada [dBA]');
    title('Progreso (log scale)');
    text(0.02, 0.97, '(b)', 'Units', 'normalized', 'VerticalAlignment', 'top');
    
    savefig300(gcf, fullfile(outdir, 'fig_opt_history'), 15);
    
    fprintf('Optimization Summary:\n');
    fprintf('  Baseline:   %.2f dBA\n', f_val(1));
    fprintf('  Optimized:  %.2f dBA\n', f_val(end));
    fprintf('  Reduction:  %.2f dBA\n', f_val(1) - f_val(end));
    fprintf('  Iterations: %d\n', numel(iter));
else
    fprintf('Could not parse optimization data from log.\n');
end

fprintf('Done.\n');
exit(0);
