cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise');
addpath('optim'); set_pub_defaults();
L = load('seed_bench_63221.mat'); B = L.B; names = {'GA','PSO','SBO'};
figure('Color','w','Position',[50 50 560 430]); hold on; grid on;
w = 0.28; col = [0.3 0.5 0.8];
for k = 1:3
    r = sort(B(k,:)); q1 = prctile2(r,25); q2 = median(r); q3 = prctile2(r,75);
    lo = min(r); hi = max(r);
    % box
    patch([k-w k+w k+w k-w],[q1 q1 q3 q3],col,'FaceAlpha',0.35,'EdgeColor',[0.2 0.3 0.5]);
    plot([k-w k+w],[q2 q2],'-','Color',[0.1 0.2 0.4],'LineWidth',1.8);          % median
    plot([k k],[q3 hi],'k-'); plot([k k],[lo q1],'k-');                          % whiskers
    plot([k-w/2 k+w/2],[hi hi],'k-'); plot([k-w/2 k+w/2],[lo lo],'k-');
    plot(k+0.05*randn(1,numel(r)), r, '.', 'Color',[0.4 0.4 0.4],'MarkerSize',7);% points
end
single = [65.94, 66.09, 66.09]; hleg=gobjects(2,1);
for k=1:3, hh=plot(k, single(k), 'rp','MarkerSize',12,'MarkerFaceColor','r'); if k==1, hleg(1)=hh; end; end
hleg(2)=yline(65.82,'b--','LineWidth',1.1);
set(gca,'XTick',1:3,'XTickLabel',names); xlim([0.5 3.5]);
ylabel('OASPL(A) [dBA]');
legend(hleg,{'single run (Table 5)','PS dedicated budget'},'Location','south','FontSize',7,'Box','off');
savefig300(gcf, fullfile('paper','figures','fig_seed_boxplot'), 9);
fprintf('saved\n'); exit(0);
function p = prctile2(x,q)
    x=sort(x); n=numel(x); idx=(q/100)*(n-1)+1; lo=floor(idx); hi=ceil(idx);
    if lo==hi, p=x(lo); else, p=x(lo)+(idx-lo)*(x(hi)-x(lo)); end
end
