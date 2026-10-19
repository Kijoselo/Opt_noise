function S = study_cases(budget, airfoils)
% STUDY_CASES  Exploration (NOT yet part of the paper). Optimises the two
% official airfoils (NACA 63-221 and NACA 63-218) under THREE single-objective
% formulations and produces article-quality figures.
%
%   Formulations (all also keep the geometric + attachment constraints):
%     'cl'    min OASPL(A)  s.t.  c_l    >= c_{l,base}        (constant lift)
%     'clcd'  min OASPL(A)  s.t.  c_l/c_d>= (c_l/c_d)_base    (constant efficiency)
%     'mono'  min OASPL(A)  with no aerodynamic constraint     (pure noise)
%
% Self-contained and NON-DESTRUCTIVE: writes only inside study_cases/ (optimum
% .dat files, figures, a LaTeX table fragment) and does not refresh cst_baseline.dat.
% The manuscript and its figures are not touched.
%
% Usage:  study_cases            (budget 400, quick)
%         study_cases(1000)      (match the paper's headline budget)
if nargin < 1 || isempty(budget), budget = 400; end
if nargin < 2 || isempty(airfoils), airfoils = {'NACA63221.txt','NACA63218.txt'}; end
if ischar(airfoils) || isstring(airfoils), airfoils = cellstr(airfoils); end
close all; set_pub_defaults();
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace

outdir = 'study_cases';
if ~exist(outdir,'dir'), mkdir(outdir); end

afshort  = cell(1, numel(airfoils));   % short label per case, filled from P.case_id
forms    = {'cl','clcd','mono'};
formlab  = {'c_l \geq base','c_l/c_d \geq base','unconstrained'};
cols     = [0.85 0.33 0.10;     % cl   - orange
            0.00 0.45 0.74;     % clcd - blue
            0.47 0.67 0.19];    % mono - green

S = struct('airfoil',{},'form',{},'J0',{},'clcd0',{},'Cl0',{}, ...
           'OASPL',{},'clcd',{},'Cl',{},'Cd',{},'tmax',{},'gain',{});
A = struct('P',{},'f',{},'base',{},'opt',{},'xy',{},'oaspl',{},'clcd',{});

for ai = 1:numel(airfoils)
    P = setup_problem('base', airfoils{ai}, 'outdir', outdir, 'write_legacy', false);
    afshort{ai} = P.case_id;
    ctx = P.ctx;  ctx.cl_min = P.Cl0;        % lift floor for the 'cl' case
    opts = optimoptions('patternsearch','Display','off', ...
        'MaxFunctionEvaluations',budget,'UseCompletePoll',true,'MeshTolerance',1e-4);

    Rb = eval_airfoil_cached(P.dv0, ctx);    % baseline spectrum
    A(ai).P = P;  A(ai).f = Rb.f;  A(ai).base = Rb.S_pp;

    for fi = 1:numel(forms)
        switch forms{fi}
            case 'cl',   confun = @(d) con_cl(d,ctx);
            case 'clcd', confun = @(d) con_clcd(d,ctx);
            case 'mono', confun = [];
        end
        try
            dv = patternsearch(@(d) obj_noise_pure(d,ctx), P.dv0, [],[],[],[], ...
                               P.lb, P.ub, confun, opts);
        catch ME
            fprintf('  [%s / %s] solver failed: %s\n', airfoils{ai}, forms{fi}, ME.message);
            dv = P.dv0;
        end
        R  = eval_airfoil_cached(dv, ctx);
        nu = ctx.nu;
        [xo,yo] = cst_to_coords(dv(1:nu),dv(nu+1:end),ctx.yte_u,ctx.yte_l, ...
                                ctx.npts,ctx.N1,ctx.N2);
        write_airfoil_dat(fullfile(outdir, sprintf('opt_%s_%s.dat', ...
            P.case_id, forms{fi})), xo, yo);

        A(ai).opt{fi}   = R.S_pp;
        A(ai).xy{fi}    = [xo(:) yo(:)];
        A(ai).oaspl(fi) = R.OASPL_A;
        A(ai).clcd(fi)  = R.clcd;

        k = numel(S)+1;
        S(k) = struct('airfoil',afshort{ai},'form',forms{fi}, ...
            'J0',P.J0,'clcd0',P.clcd0,'Cl0',P.Cl0, ...
            'OASPL',R.OASPL_A,'clcd',R.clcd,'Cl',R.Cl,'Cd',R.Cd, ...
            'tmax',R.tmax,'gain',P.J0-R.OASPL_A);
    end
end

%% ---- console table + LaTeX fragment ----
fprintf('\n  Case study (budget %d) -- both official airfoils, 3 formulations\n', budget);
fprintf('  %-12s %-16s %8s %7s | %8s %7s %7s %7s | %6s\n', ...
  'airfoil','formulation','base dB','baseLD','opt dB','optLD','Cl','t/c','gain');
fprintf('  %s\n', repmat('-',1,92));
for k = 1:numel(S)
  fprintf('  %-12s %-16s %8.2f %7.2f | %8.2f %7.2f %7.4f %7.4f | %6.3f\n', ...
    S(k).airfoil,S(k).form,S(k).J0,S(k).clcd0,S(k).OASPL,S(k).clcd,S(k).Cl,S(k).tmax,S(k).gain);
end
fid = fopen(fullfile(outdir,'study_cases.tex'),'w');
for k = 1:numel(S)
  fprintf(fid,'%s & %s & %.2f & %.2f & %.2f & %.1f & %.3f \\\\\n', ...
    S(k).airfoil, S(k).form, S(k).J0, S(k).OASPL, S(k).gain, S(k).clcd, S(k).tmax);
end
fclose(fid);

%% ---- per-airfoil figure: (a) silhouettes  (b) 1/3-octave spectra ----
pref = 20e-6;
for ai = 1:numel(airfoils)
    P = A(ai).P;  f = A(ai).f;
    figure('Color','w','Position',[100 100 1400 470]);

    subplot(1,2,1); hold on; axis equal; grid on;
    [xb,yb] = cst_to_coords(P.dv0(1:P.ctx.nu),P.dv0(P.ctx.nu+1:end), ...
        P.ctx.yte_u,P.ctx.yte_l,P.ctx.npts,P.ctx.N1,P.ctx.N2);
    plot(xb,yb,'k-','LineWidth',1.4,'DisplayName','baseline');
    for fi = 1:numel(forms)
        xy = A(ai).xy{fi};
        plot(xy(:,1),xy(:,2),'-','Color',cols(fi,:),'LineWidth',1.1, ...
             'DisplayName',formlab{fi});
    end
    xlabel('x/c'); ylabel('y/c');
    legend('Location','south','Interpreter','tex','FontSize',7);
    text(0.02,0.96,'(a)','Units','normalized','VerticalAlignment','top','FontSize',9);

    subplot(1,2,2); hold on; grid on; set(gca,'XScale','log');
    [Lb,Fc] = NarrowToNthOctave(f, 10*log10(A(ai).base/pref^2), 3);
    plot(Fc,Lb,'k-o','LineWidth',1.3,'MarkerSize',3, ...
         'DisplayName',sprintf('baseline (%.1f dBA)',P.J0));
    for fi = 1:numel(forms)
        [Lo,~] = NarrowToNthOctave(f, 10*log10(A(ai).opt{fi}/pref^2), 3);
        plot(Fc,Lo,'-','Color',cols(fi,:),'LineWidth',1.1, ...
             'DisplayName',sprintf('%s (%.1f dBA)',formlab{fi},A(ai).oaspl(fi)));
    end
    xlabel('1/3-octave band center [Hz]'); ylabel('SPL [dB]');
    legend('Location','southwest','Interpreter','tex','FontSize',7);
    text(0.02,0.96,'(b)','Units','normalized','VerticalAlignment','top','FontSize',9);

    savefig300(gcf, fullfile(outdir, sprintf('fig_cases_%s', ...
        P.case_id)), 19);
end

%% ---- summary: noise vs efficiency across all formulations ----
figure('Color','w'); hold on; grid on;
mk = {'o','s'};
for k = 1:numel(S)
    ai = strcmp(afshort, S(k).airfoil);
    fi = strcmp(forms,  S(k).form);
    plot(S(k).OASPL, S(k).clcd, mk{ai}, 'MarkerSize',8, ...
         'MarkerFaceColor',cols(fi,:), 'MarkerEdgeColor','k', ...
         'DisplayName',sprintf('%s, %s',S(k).airfoil,formlab{fi}));
end
for ai = 1:numel(airfoils)
    P = A(ai).P;
    plot(P.J0,P.clcd0, mk{ai}, 'MarkerSize',9, 'MarkerFaceColor','w', ...
         'MarkerEdgeColor','k', 'LineWidth',1.2, ...
         'DisplayName',sprintf('%s baseline',afshort{ai}));
end
xlabel('OASPL(A) [dBA]'); ylabel('c_l / c_d');
legend('Location','eastoutside','Interpreter','tex','FontSize',7);
savefig300(gcf, fullfile(outdir,'fig_cases_summary'), 16);

fprintf('\n  Saved in %s/: fig_cases_<case>.png (per airfoil),\n', outdir);
fprintf('  fig_cases_summary.png, opt_<case>_<form>.dat, study_cases.tex.  Manuscript untouched.\n\n');
end
