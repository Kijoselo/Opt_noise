%% MAKE_ALL_FIGURES
% One-shot driver that produces every final figure for the article.
% Each stage is a toggle; XFOIL-in-the-loop stages dominate the runtime, so
% start with small budgets to validate, then raise for production quality.
%
% Outputs (all 300-dpi PNG in the project folder):
%   parameterization_comparison.png        (Module 1)
%   fig_shape_modes / fig_design_envelope   (silhouette variation, geometry only)
%   fig_sensitivity_tornado / _curves / _silhouettes
%   fig_silhouette_hardcon / fig_spectrum_hardcon / fig_base_vs_optimized (Case 1)
%   fig_pareto_front / fig_pareto_silhouettes                            (Case 2)
%   fig_algo_convergence / _exploration / _silhouettes                  (algorithms)
clear; close all; clc;

addpath(fileparts(mfilename('fullpath')));   % make optim/ functions resolvable

%% ----- toggles & budgets -----
basefile   = 'NACA63221.txt';
do_param   = true;    % Module 1: parameterization comparison   (cheap)
do_shape   = true;    % silhouette variation                    (cheap)
do_sens    = true;    % sensitivity analysis    (~ nlev*14 XFOIL evals)
do_case1   = true;    % single-objective, hard Cl/Cd constraint
do_case2   = true;    % multi-objective Pareto
do_algos   = true;    % algorithm comparison

budget_case1 = 200;   % evals for patternsearch (Case 1)
budget_algos = 150;   % evals per algorithm (comparison)
% (Case 2 / sensitivity budgets are set inside their own scripts.)

t_start = tic;

%% ----- Module 1: parameterization comparison (cheap, no XFOIL loop) -----
if do_param
    fprintf('\n==== [1/6] Parameterization comparison ====\n');
    compare_parameterizations(basefile);
    close all;
end

%% ----- silhouette variation (geometry only) -----
if do_shape
    fprintf('\n==== [2/6] Silhouette variation ====\n');
    silhouette_variation(basefile);
    close all;
end

%% ----- sensitivity analysis -----
if do_sens
    fprintf('\n==== [3/6] Sensitivity analysis ====\n');
    sensitivity_analysis([], basefile);
    close all;
end

%% ----- Case 1: hard Cl/Cd constraint -----
if do_case1
    fprintf('\n==== [4/6] Case 1: hard-constraint optimization ====\n');
    run_optimization(budget_case1, basefile);
    close all;
end

%% ----- Case 2: Pareto -----
if do_case2
    fprintf('\n==== [5/6] Case 2: multi-objective Pareto ====\n');
    run_multiobjective([], [], basefile);
    close all;
end

%% ----- algorithm comparison -----
if do_algos
    fprintf('\n==== [6/6] Algorithm comparison ====\n');
    compare_algorithms(budget_algos, basefile);
    close all;
end

fprintf('\nAll requested figures generated in %.1f min.\n', toc(t_start)/60);
fprintf('PNG files are in: %s\n', pwd);
