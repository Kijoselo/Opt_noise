cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise');
addpath('optim');
S = compare_algorithms_seeds(10, 150, 'NACA63221.txt');
B = S.best;                 % rows = algos, cols = seeds
save('seed_bench_63221.mat','S','B');
fprintf('\n===== FULL STATISTICS (10 seeds, budget 150) =====\n');
fprintf('%-16s %8s %8s %8s %8s %8s %8s\n','algo','median','mean','std','min','max','IQR');
for a = 1:numel(S.algos)
    r = B(a,:);
    fprintf('%-16s %8.3f %8.3f %8.3f %8.3f %8.3f %8.3f\n', S.algos{a}, ...
        median(r), mean(r), std(r), min(r), max(r), iqr(r));
end
exit(0);
