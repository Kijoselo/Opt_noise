cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise'); addpath('optim'); set_pub_defaults();
d='C:\Users\josea\Desktop\Opti_Param_ruidoio\dominio_expandido';
A=dlmread(fullfile(d,'opt_NACA63218_expandido.dat'));
B=dlmread(fullfile(d,'opt_NACA63221_expandido.dat'));
figure('Color','w','Position',[40 40 720 330]); hold on; grid on;
plot(A(:,1),A(:,2),'-','Color',[0 0.45 0.2],'LineWidth',1.8,'DisplayName','optimo expandido desde 63-218 (18%)');
plot(B(:,1),B(:,2),'--','Color',[0.85 0.1 0.1],'LineWidth',1.6,'DisplayName','optimo expandido desde 63-221 (21%)');
axis equal; xlabel('x/c'); ylabel('y/c'); legend('Location','southoutside','FontSize',8);
title('Ambos convergen a la MISMA geometria (~18.5%, alto camber)');
% metricas
xg=0.5*(1-cos(linspace(0,pi,200)'));
for nm={'A','B'}
  G=eval(nm{1}); [~,iLE]=min(G(:,1));
  [xu,iu]=unique(flipud(G(1:iLE,1))); yu=flipud(G(1:iLE,2)); yu=yu(iu);
  [xl,il]=unique(G(iLE:end,1)); yl=G(iLE:end,2); yl=yl(il);
  yug=interp1(xu,yu,xg,'pchip'); ylg=interp1(xl,yl,xg,'pchip');
  fprintf('%s: tmax=%.4f @x/c=%.2f | camber_max=%.4f @x/c=%.2f\n', nm{1}, ...
    max(yug-ylg), xg(find(yug-ylg==max(yug-ylg),1)), max(0.5*(yug+ylg)), xg(find(0.5*(yug+ylg)==max(0.5*(yug+ylg)),1)));
end
savefig300(gcf,fullfile(d,'fig_convergen_misma_geometria'),13);
fprintf('ok\n'); exit(0);
