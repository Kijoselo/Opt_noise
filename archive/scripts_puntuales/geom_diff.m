cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise');
addpath('optim'); set_pub_defaults();
outdir = 'C:\Users\josea\Desktop\Opti_Param_ruidoio\entrega_pala_NACA63218';

files = {'cst_baseline_NACA63218.dat','optimized_NACA63218_hardcon.dat','optimized_NACA63218_lin.dat'};
lbl   = {'baseline (18%)','optimo OASPL(A)','optimo sin filtro A'};
col   = {[0 0 0],[0.85 0.1 0.1],[0 0.35 0.85]};
sty   = {'-','--','-.'};
xg = 0.5*(1-cos(linspace(0,pi,300)'));   % malla comun coseno

figure('Color','w','Position',[40 40 1250 400]);
for i = 1:3
    D = dlmread(files{i});
    [~,iLE] = min(D(:,1));
    [xu,iu] = unique(flipud(D(1:iLE,1)));  yuv = flipud(D(1:iLE,2));  yu = yuv(iu);
    [xl,il] = unique(D(iLE:end,1));        ylv = D(iLE:end,2);        yl = ylv(il);
    yug = interp1(xu,yu,xg,'pchip');  ylg = interp1(xl,yl,xg,'pchip');
    t = yug - ylg;  cam = 0.5*(yug + ylg);
    [tmax,it_] = max(t);  [cmax,ic_] = max(abs(cam));
    fprintf('%-22s tmax=%.4f @x/c=%.2f | camber_max=%.4f @x/c=%.2f\n', ...
            lbl{i}, tmax, xg(it_), cam(ic_), xg(ic_));
    subplot(1,3,1); hold on; grid on;
    plot([xu; flipud(xl)], [yu; flipud(yl)], sty{i}, 'Color', col{i}, ...
         'LineWidth', 1.4, 'DisplayName', lbl{i});
    subplot(1,3,2); hold on; grid on;
    plot(xg, t, sty{i}, 'Color', col{i}, 'LineWidth', 1.4, 'HandleVisibility','off');
    subplot(1,3,3); hold on; grid on;
    plot(xg, cam, sty{i}, 'Color', col{i}, 'LineWidth', 1.4, 'HandleVisibility','off');
end
subplot(1,3,1); axis equal; xlabel('x/c'); ylabel('y/c');
legend('Location','south','FontSize',7); text(0.03,0.95,'(a) silueta','Units','normalized');
subplot(1,3,2); xlabel('x/c'); ylabel('espesor t/c');
text(0.03,0.95,'(b) espesor','Units','normalized');
subplot(1,3,3); xlabel('x/c'); ylabel('camber y_c/c');
text(0.03,0.95,'(c) curvatura','Units','normalized');
savefig300(gcf, fullfile(outdir,'fig_comparacion_geometrias'), 19);
fprintf('saved fig_comparacion_geometrias.png\n');
exit(0);
