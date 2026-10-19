function domain_and_history_63218
% DOMAIN_AND_HISTORY_63218
%  (1) Search-domain figure (CST +-50% reachable band) with the smooth
%      optimum overlaid.
%  (2) Deterministic re-run of the smooth A-weighted optimization capturing
%      the FULL per-evaluation log, then: OASPL(A) vs evaluation index with
%      running best + inset histogram of the stored near-minimum candidates.
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
outdir = fullfile(rutas.exportaciones,'entrega_pala_NACA63218'); if ~exist(outdir,'dir'), mkdir(outdir); end   % (reorganizacion)

%% (1) geometric search domain
plot_search_domain('NACA63218.txt', 'optimized_NACA63218_smoothA.dat');
copyfile('fig_search_domain_NACA63218.png', fullfile(outdir,'fig_dominio_geometrico.png'));
fprintf('domain figure copied\n');

%% (2) deterministic re-run with eval logging
P  = setup_problem('base', 'NACA63218.txt', 'write_legacy', false);
nu = P.ctx.nu;
Au0 = P.dv0(1:nu); Al0 = P.dv0(nu+1:end);
du = 1.5*max(abs(diff(Au0)));  dl = 1.5*max(abs(diff(Al0)));
D = zeros(nu-1, nu);
for i = 1:nu-1, D(i,i) = 1; D(i,i+1) = -1; end
Alin = [blkdiag(D,D); -blkdiag(D,D)];
blin = [du*ones(nu-1,1); dl*ones(nu-1,1); du*ones(nu-1,1); dl*ones(nu-1,1)];
opts = optimoptions('patternsearch','Display','off', ...
    'MaxFunctionEvaluations', 2000, 'UseCompletePoll', true, 'MeshTolerance', 1e-4);

dv2 = patternsearch(@(d) obj_noise_pure(d,P.ctx), P.dv0, Alin, blin, [],[], ...
                    P.lb, P.ub, @(d) con_clcd(d,P.ctx), opts);
R = eval_airfoil_cached(dv2, P.ctx);
fprintf('re-run result: %.3f dBA (esperado 65.762)\n', R.OASPL_A);

L = eval_airfoil_cached('log');
save('log_evals_smoothA.mat', 'L', 'dv2');

oa    = L.res(:,1);
valid = L.res(:,5) == 1 & isfinite(oa);
n     = numel(oa);
idx   = (1:n)';
rb = nan(n,1); b = inf;
for k = 1:n
    if valid(k) && oa(k) < b, b = oa(k); end
    rb(k) = b;
end
bestv = min(oa(valid));
thr   = bestv + 0.3;
pool  = oa(valid & oa <= thr);
fprintf('evaluaciones unicas: %d | validas: %d | penalizadas: %d | pool <= best+0.3dB: %d\n', ...
        n, sum(valid), n - sum(valid), numel(pool));

set_pub_defaults();
figure('Color','w','Position',[40 40 950 520]); hold on; grid on;
plot(idx(valid), oa(valid), '.', 'Color', [0.62 0.74 0.90], 'MarkerSize', 6, ...
     'DisplayName', sprintf('evaluaciones validas (%d)', sum(valid)));
plot(idx, rb, 'b-', 'LineWidth', 1.9, 'DisplayName', 'mejor acumulado');
yline(P.J0, 'k--', 'LineWidth', 1.1, 'DisplayName', sprintf('baseline %.2f dBA', P.J0));
plot(n, rb(end), 'rp', 'MarkerSize', 13, 'MarkerFaceColor', 'r', ...
     'DisplayName', sprintf('optimo %.2f dBA', rb(end)));
ylim([bestv - 0.25, P.J0 + 0.9]);
xlabel('Evaluacion de funcion'); ylabel('OASPL(A) [dBA]');
legend('Location','northeast','FontSize',8);

axInset = axes('Position', [0.58 0.28 0.30 0.30]); %#ok<NASGU>
histogram(pool, 20, 'FaceColor', [0.2 0.45 0.75]); grid on;
xlabel('OASPL(A) [dBA]', 'FontSize', 8); ylabel('n disenos', 'FontSize', 8);
text(0.03, 1.10, sprintf('candidatos a minimo global (\\leq mejor+0.3 dB): %d', numel(pool)), ...
     'Units','normalized','FontSize',8);
savefig300(gcf, fullfile(outdir,'fig_historial_evaluaciones'), 17);
fprintf('history figure saved\n');
end
