function review_studies
% REVIEW_STUDIES  Three studies requested by the review (critical issue #3):
%   B1: WPS-model sensitivity (TNO vs Goody vs Kamruzzaman) for baseline and
%       optimum of both cases -> does the predicted reduction survive a model swap?
%   B3: full chordwise Cf(x) and H(x) distributions, both surfaces, baseline
%       vs optimum -> supports the pointwise attachment constraint.
%   B4: off-design sweep (AoA 2-6 deg, two Reynolds numbers) of baseline and
%       optimum -> does the gain persist away from the design point?
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
figdir = rutas.figuras;   % (reorganizacion) antes paper/figures
t0 = tic;

CASES = {
  'cst_baseline_NACA63221.dat', 'optimized_NACA63221_hardcon.dat', 'NACA63221';
  'cst_baseline_NACA63218.dat', 'optimized_NACA63218_smoothA.dat', 'NACA63218'};

%% ---------- B1: WPS-model sensitivity ----------
fprintf('\n>>>>>>>> B1: WPS-model sensitivity\n');
models = {'TNO','Goody','Kamruzzaman'};
fprintf('%-10s %-12s %9s %9s %9s\n','case','model','base','optimum','reduction');
for c = 1:2
    for m = 1:3
        [fluid, inputs] = inputs_definition();
        inputs.model = models{m};
        oaB = safe_eval(CASES{c,1}, inputs, fluid);
        oaO = safe_eval(CASES{c,2}, inputs, fluid);
        fprintf('%-10s %-12s %9.3f %9.3f %9.3f\n', CASES{c,3}, models{m}, oaB, oaO, oaB-oaO);
    end
end
fprintf('<<<<<<<< B1 done\n');

%% ---------- B3: Cf(x) and H(x) distributions ----------
fprintf('\n>>>>>>>> B3: Cf/H distributions\n');
for c = 1:2
    figure('Color','w','Position',[40 40 1150 420]);
    sty = {'-','--'}; lbl = {'baseline','optimum'};
    colS = [0 0 0]; colP = [0.85 0.1 0.1];
    for g = 1:2
        [fluid, inputs] = inputs_definition();
        safe_eval(CASES{c,g}, inputs, fluid);          % leaves XFOIL_Output dump
        D = read_dump();
        if isempty(D), fprintf('  [warn] no dump for %s\n', CASES{c,g}); continue; end
        [~,iLE] = min(D(:,2));
        xs = D(1:iLE,2);  Cfs = D(1:iLE,7);  Hs = D(1:iLE,8);      % suction
        xp = D(iLE:end,2); Cfp = D(iLE:end,7); Hp = D(iLE:end,8);  % pressure
        subplot(1,2,1); hold on; grid on;
        semilogy(xs, max(Cfs,1e-6), sty{g}, 'Color', colS, 'LineWidth', 1.2, ...
                 'DisplayName', sprintf('%s suction', lbl{g}));
        semilogy(xp, max(Cfp,1e-6), sty{g}, 'Color', colP, 'LineWidth', 1.2, ...
                 'DisplayName', sprintf('%s pressure', lbl{g}));
        subplot(1,2,2); hold on; grid on;
        plot(xs, Hs, sty{g}, 'Color', colS, 'LineWidth', 1.2, 'HandleVisibility','off');
        plot(xp, Hp, sty{g}, 'Color', colP, 'LineWidth', 1.2, 'HandleVisibility','off');
    end
    subplot(1,2,1); set(gca,'YScale','log');
    yline(1.5e-4, 'k:', 'C_{f,min}', 'HandleVisibility','off');
    xline(0.99, 'k:', 'HandleVisibility','off');
    xlabel('x/c'); ylabel('C_f'); xlim([0 1]);
    legend('Location','northeast','FontSize',7);
    text(0.03,0.08,'(a)','Units','normalized');
    subplot(1,2,2);
    yline(2.7, 'k:', 'H_{lim}', 'HandleVisibility','off');
    xline(0.99, 'k:', 'HandleVisibility','off');
    xlabel('x/c'); ylabel('H'); xlim([0 1]); ylim([1 3.2]);
    text(0.03,0.08,'(b)','Units','normalized');
    savefig300(gcf, fullfile(figdir, sprintf('fig_cfh_%s', CASES{c,3})), 19);
end
fprintf('<<<<<<<< B3 done\n');

%% ---------- B4: off-design sweep ----------
fprintf('\n>>>>>>>> B4: off-design sweep\n');
alphas = 2:1:6;
speeds = [83.31, 60.0];                 % m/s -> Re 3.17e6 and 2.28e6
for c = 1:2
    figure('Color','w','Position',[40 40 620 430]); hold on; grid on;
    colR = {[0 0 0],[0 0.4 0.8]};
    for u = 1:2
        oaB = nan(size(alphas)); oaO = nan(size(alphas));
        for k = 1:numel(alphas)
            [fluid, inputs] = inputs_definition();
            inputs.AoA = alphas(k);
            inputs.U   = speeds(u);
            inputs.M   = inputs.U/fluid.c0;
            inputs.Re  = inputs.chord*inputs.U/fluid.ni;
            oaB(k) = safe_eval(CASES{c,1}, inputs, fluid);
            oaO(k) = safe_eval(CASES{c,2}, inputs, fluid);
        end
        Re = speeds(u)*0.57/1.5e-5;
        plot(alphas, oaB, '-o',  'Color', colR{u}, 'LineWidth', 1.3, 'MarkerSize', 4, ...
             'DisplayName', sprintf('baseline, Re=%.1fe6', Re/1e6));
        plot(alphas, oaO, '--s', 'Color', colR{u}, 'LineWidth', 1.3, 'MarkerSize', 4, ...
             'DisplayName', sprintf('optimum,  Re=%.1fe6', Re/1e6));
        fprintf('%s  Re=%.2fe6:\n', CASES{c,3}, Re/1e6);
        fprintf('   AoA:   %s\n', sprintf('%7.1f', alphas));
        fprintf('   base:  %s\n', sprintf('%7.2f', oaB));
        fprintf('   opt:   %s\n', sprintf('%7.2f', oaO));
        fprintf('   gain:  %s\n', sprintf('%7.2f', oaB-oaO));
    end
    xlabel('\alpha [deg]'); ylabel('OASPL(A) [dBA]');
    legend('Location','northwest','FontSize',7);
    savefig300(gcf, fullfile(figdir, sprintf('fig_offdesign_%s', CASES{c,3})), 12);
end
fprintf('<<<<<<<< B4 done\n');

fprintf('\n=== REVIEW STUDIES COMPLETE in %.1f min ===\n', toc(t0)/60);
end

%% ---------------- helpers ----------------
function oa = safe_eval(datfile, inputs, fluid)
for f = {xfoil_out('POLAR_OUTPUT'),xfoil_out('doesntmatter')}
    if exist(f{1},'file'), delete(f{1}); end
end
try
    oa = evaluate_airfoil(datfile, inputs, fluid);
catch ME
    fprintf('  [eval fail] %s (%s | model %s | AoA %g | U %g)\n', ...
            ME.message, datfile, inputs.model, inputs.AoA, inputs.U);
    oa = NaN;
end
end

function D = read_dump()
D = [];
if ~exist(xfoil_out('XFOIL_Output'),'file'), return; end
try
    fid = fopen(xfoil_out('XFOIL_Output'),'r');
    T = textscan(fid,'%f%f%f%f%f%f%f%f','Delimiter',' ', ...
                 'MultipleDelimsAsOne',true,'CollectOutput',1,'HeaderLines',1);
    fclose(fid);
    D = T{1};
    D = D(D(:,2) <= 1.0001, :);   % drop wake
catch
end
end
