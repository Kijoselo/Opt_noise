function boundary_layer_table(basefile)
% BOUNDARY_LAYER_TABLE  Boundary-layer parameters at the wall-pressure sampling
% location (x/c = inputs.Mic, i.e. 0.99) for the baseline and optimized airfoils,
% on both surfaces. These are the quantities that feed the TNO--Blake model, so
% the table closes the geometry -> boundary layer -> wall pressure -> noise chain.
% Prints a console table and a LaTeX fragment for the manuscript.
if nargin < 1 || isempty(basefile), basefile = 'NACA63221.txt'; end
close all;
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
P = setup_problem('base', basefile, 'write_legacy', false);
fluid = P.ctx.fluid;
inputs = P.ctx.inputs;
pref = 20e-6; c = inputs.chord;

base = P.ctx.baseline_file; opt = P.ctx.opt_file;
if ~exist(opt,'file')
    error('Need matching optimized airfoil %s. Run run_optimization(''%s'', budget) first.', ...
          opt, P.base_file);
end
files = {base, opt};  names = {'baseline','optimized'};

fprintf('\n  Boundary-layer parameters at x/c = %.2f\n', inputs.Mic);
fprintf('  %-10s %-9s %9s %9s %6s %10s %8s %10s\n', ...
        'case','surface','d*/c','theta/c','H','Cf','Ue/Uinf','Phipp_pk');
fprintf('  %s\n', repmat('-',1,78));

rows = {};
for k = 1:2
    [DSTRS,DSTRP,THETAS,THETAP,CFS,CFP,~,~,Ue_s,Ue_p] = XFOIL_new_airfoil( ...
        files{k}, inputs.AoA, inputs.Re, inputs.M, inputs.xtr_s, inputs.xtr_p, ...
        inputs.chord, inputs.Mic, files{k});
    [~,~,~,o] = evaluate_airfoil(files{k}, inputs, fluid);
    phipk_s = max(10*log10(o.Phi_pp_s/pref^2));
    phipk_p = max(10*log10(o.Phi_pp_p/pref^2));
    % DSTR/THETA are returned multiplied by chord -> divide by c to normalise
    dat = [ DSTRS/c, THETAS/c, DSTRS/THETAS, CFS, Ue_s,        phipk_s;   % suction
            DSTRP/c, THETAP/c, DSTRP/THETAP, CFP, abs(Ue_p),   phipk_p ]; % pressure
    surf = {'suction','pressure'};
    for s = 1:2
        fprintf('  %-10s %-9s %9.4f %9.4f %6.2f %10.5f %8.3f %10.1f\n', ...
                names{k}, surf{s}, dat(s,:));
        rows{end+1} = sprintf('%s & %s & %.4f & %.4f & %.2f & %.5f & %.3f & %.1f \\\\', ...
                names{k}, surf{s}, dat(s,:)); %#ok<AGROW>
    end
end

fprintf('\n  --- LaTeX rows (paste into the boundary-layer table) ---\n');
for r = 1:numel(rows), fprintf('  %s\n', rows{r}); end
fprintf('\n');
end
