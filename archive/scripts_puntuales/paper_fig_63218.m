cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise');
addpath('optim'); set_pub_defaults();
files = {'cst_baseline_NACA63218.dat','optimized_NACA63218_smoothA.dat','optimized_NACA63218_smoothLin.dat'};
lbl = {'baseline','OASPL(A) optimum','unweighted-OASPL optimum'};
col = {[0 0 0],[0.85 0.1 0.1],[0 0.35 0.85]};
sty = {'-','--','-.'};
xg = 0.5*(1-cos(linspace(0,pi,300)'));
figure('Color','w','Position',[40 40 1250 400]);
for i = 1:3
    D = dlmread(files{i});
    [~,iLE] = min(D(:,1));
    [xu,iu] = unique(flipud(D(1:iLE,1)));  yv = flipud(D(1:iLE,2));  yu = yv(iu);
    [xl,il] = unique(D(iLE:end,1));        yv = D(iLE:end,2);        yl = yv(il);
    yug = interp1(xu,yu,xg,'pchip');  ylg = interp1(xl,yl,xg,'pchip');
    subplot(1,3,1); hold on; grid on;
    plot([xu; flipud(xl)], [yu; flipud(yl)], sty{i}, 'Color', col{i}, 'LineWidth', 1.3, 'DisplayName', lbl{i});
    subplot(1,3,2); hold on; grid on;
    plot(xg, yug-ylg, sty{i}, 'Color', col{i}, 'LineWidth', 1.3, 'HandleVisibility','off');
    subplot(1,3,3); hold on; grid on;
    plot(xg, 0.5*(yug+ylg), sty{i}, 'Color', col{i}, 'LineWidth', 1.3, 'HandleVisibility','off');
end
subplot(1,3,1); axis equal; xlabel('x/c'); ylabel('y/c');
legend('Location','south','FontSize',7); text(0.03,0.95,'(a)','Units','normalized');
subplot(1,3,2); xlabel('x/c'); ylabel('t/c'); text(0.03,0.95,'(b)','Units','normalized');
subplot(1,3,3); xlabel('x/c'); ylabel('y_c/c'); text(0.03,0.95,'(c)','Units','normalized');
savefig300(gcf, fullfile('paper','figures','fig_63218_geometry'), 19);
fprintf('done\n'); exit(0);
