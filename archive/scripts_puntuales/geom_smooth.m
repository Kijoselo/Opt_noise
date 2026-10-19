cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise');
addpath('optim'); set_pub_defaults();
outdir = 'C:\Users\josea\Desktop\Opti_Param_ruidoio\entrega_pala_NACA63218';
xg = 0.5*(1-cos(linspace(0,pi,300)'));

grp = {
  {'cst_baseline_NACA63218.dat','optimized_NACA63218_hardcon.dat','smoothed_NACA63218_hardcon.dat'}, ...
  {'baseline','optimo original','optimo suavizado'}, 'Familia OASPL(A)';
  {'cst_baseline_NACA63218.dat','optimized_NACA63218_lin.dat','smoothed_NACA63218_lin.dat'}, ...
  {'baseline','optimo original','optimo suavizado'}, 'Familia sin filtro A'};
col = {[0 0 0],[0.85 0.1 0.1],[0 0.55 0.25]};
sty = {'-','--','-'};
lw  = [1.3 1.2 1.6];

figure('Color','w','Position',[30 30 1250 640]);
for g = 1:2
    files = grp{g,1}; lbl = grp{g,2};
    for i = 1:3
        D = dlmread(files{i});
        [~,iLE] = min(D(:,1));
        [xu,iu] = unique(flipud(D(1:iLE,1)));  yv = flipud(D(1:iLE,2));  yu = yv(iu);
        [xl,il] = unique(D(iLE:end,1));        yv = D(iLE:end,2);        yl = yv(il);
        yug = interp1(xu,yu,xg,'pchip');  ylg = interp1(xl,yl,xg,'pchip');
        t = yug-ylg;  cam = 0.5*(yug+ylg);
        [tm,ii] = max(t); [cm,jj] = max(abs(cam));
        fprintf('%-22s %-18s tmax=%.4f @%.2f | camber=%.4f @%.2f\n', ...
                grp{g,3}, lbl{i}, tm, xg(ii), cam(jj), xg(jj));
        subplot(2,3,(g-1)*3+1); hold on; grid on;
        plot([xu; flipud(xl)], [yu; flipud(yl)], sty{i}, 'Color', col{i}, ...
             'LineWidth', lw(i), 'DisplayName', lbl{i});
        subplot(2,3,(g-1)*3+2); hold on; grid on;
        plot(xg, t, sty{i}, 'Color', col{i}, 'LineWidth', lw(i), 'HandleVisibility','off');
        subplot(2,3,(g-1)*3+3); hold on; grid on;
        plot(xg, cam, sty{i}, 'Color', col{i}, 'LineWidth', lw(i), 'HandleVisibility','off');
    end
    subplot(2,3,(g-1)*3+1); axis equal; xlabel('x/c'); ylabel('y/c');
    legend('Location','south','FontSize',7);
    text(0.03,0.92,grp{g,3},'Units','normalized','FontSize',9,'FontWeight','bold');
    subplot(2,3,(g-1)*3+2); xlabel('x/c'); ylabel('t/c'); text(0.75,0.92,'espesor','Units','normalized','FontSize',8);
    subplot(2,3,(g-1)*3+3); xlabel('x/c'); ylabel('y_c/c'); text(0.70,0.92,'curvatura','Units','normalized','FontSize',8);
end
savefig300(gcf, fullfile(outdir,'fig_geometrias_suavizadas'), 19);
fprintf('saved fig_geometrias_suavizadas.png\n');
exit(0);
