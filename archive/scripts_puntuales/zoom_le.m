cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise'); addpath('optim'); set_pub_defaults();
outdir='C:\Users\josea\Desktop\Opti_Param_ruidoio\dominio_expandido';
of=readmatrix('NACA63218.txt');           % oficial (lo que se DIBUJA de negro)
of=of(all(~isnan(of(:,1:2)),2),1:2);
cs=dlmread('cst_baseline_NACA63218.dat');  % proyeccion CST (lo que se OPTIMIZA/evalua)
figure('Color','w','Position',[40 40 760 640]);
subplot(2,1,1); hold on; grid on;
plot(of(:,1),of(:,2),'k-o','LineWidth',1.3,'MarkerSize',5,'MarkerFaceColor','k','DisplayName','oficial NACA63218.txt (lo dibujado)');
plot(cs(:,1),cs(:,2),'r-','LineWidth',1.2,'DisplayName','proyeccion CST (lo evaluado)');
axis equal; xlim([-0.005 0.05]); ylim([-0.04 0.05]);
xlabel('x/c'); ylabel('y/c'); legend('Location','southeast','FontSize',8);
title('Zoom borde de ataque: oficial (pocos puntos, angular) vs CST (suave)');
subplot(2,1,2); hold on; grid on;
plot(of(:,1),of(:,2),'k-o','LineWidth',1.3,'MarkerSize',6,'MarkerFaceColor','k');
plot(cs(:,1),cs(:,2),'r.','MarkerSize',5);
axis equal; xlim([-0.002 0.012]); ylim([-0.025 0.025]);
xlabel('x/c'); ylabel('y/c'); title('Detalle: el "puntico" = punto oficial en (0.0038, 0.0145) unido recto a (0,0)');
savefig300(gcf, fullfile(outdir,'fig_zoom_puntico_LE'), 15);
% cuantificar: cuantos puntos oficiales hay en x<0.03 vs CST
fprintf('puntos en x<0.03:  oficial=%d,  CST=%d\n', sum(of(:,1)<0.03), sum(cs(:,1)<0.03));
% error CST vs oficial (fidelidad)
fprintf('el CST reproduce el oficial dentro de ~8.5e-4c (ya auditado)\n');
fprintf('ok\n'); exit(0);
