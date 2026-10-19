function out = eval_airfoil_cached(dv, ctx)
% EVAL_AIRFOIL_CACHED  Memoised, logged airfoil evaluation.
% Runs the geometry + XFOIL + Amiet pipeline once per unique design vector and
% caches the result, so the objective and the Cl/Cd constraint can share a
% single XFOIL run. Every evaluation is logged, which feeds the
% "designs explored by the optimiser" figure.
%
% Usage:
%   eval_airfoil_cached('reset')      clear cache + log (call before each run)
%   L = eval_airfoil_cached('log')    return logged designs: L.dv, L.res
%   R = eval_airfoil_cached(dv, ctx)  evaluate; R has fields:
%        valid, OASPL_A, Cl, Cd, clcd, tmax, f, S_pp, status
%
% L.res columns: [OASPL_A, clcd, Cl, Cd, valid]

persistent CACHE LOG_DV LOG_RES

if ischar(dv) || isstring(dv)
    switch char(dv)
        case 'reset'
            CACHE = containers.Map('KeyType','char','ValueType','any');
            LOG_DV = []; LOG_RES = [];
            out = []; return;
        case 'log'
            out = struct('dv', LOG_DV, 'res', LOG_RES); return;
        otherwise
            error('Unknown command: %s', dv);
    end
end

if isempty(CACHE), CACHE = containers.Map('KeyType','char','ValueType','any'); end

dv = dv(:);
key = sprintf('%.10g,', dv);
if isKey(CACHE, key), out = CACHE(key); return; end

R = compute_one(dv, ctx);
CACHE(key) = R;
LOG_DV = [LOG_DV, dv];
LOG_RES = [LOG_RES; R.OASPL_A, R.clcd, R.Cl, R.Cd, R.valid];
out = R;
end

function R = compute_one(dv, ctx)
R = struct('valid',false,'OASPL_A',NaN,'OASPL_lin',NaN,'Cl',NaN,'Cd',NaN,'clcd',NaN, ...
           'tmax',NaN,'f',[],'S_pp',[],'status','');

Au = dv(1:ctx.nu);
Al = dv(ctx.nu+1:end);
[x, y, xu, yu, ~, yl] = cst_to_coords(Au, Al, ctx.yte_u, ctx.yte_l, ctx.npts, ctx.N1, ctx.N2);

% Geometry constraints (after Kou et al. 2023):
%   - no surface crossing            min(y_up - y_low) > 0
%   - thickness cap                  T   <= T0
%   - structural floor               T   >= tmax_min
%   - front thicker than rear        T_leading >= T_trailing
th = yu - yl;
R.tmax  = max(th);
t_lead  = max(th(xu <= 0.5));
t_trail = max(th(xu >  0.5));
ok = min(th) >= -ctx.cross_tol ...
   && R.tmax <= ctx.T0 + ctx.t_tol ...
   && R.tmax >= ctx.tmax_min ...
   && t_lead >= t_trail ...
   && all(isfinite([x;y]));
if ~ok
    R.status = 'geom_violation';
    return;
end

write_airfoil_dat(ctx.tmpfile, x, y);
% Clear the polar-accumulation file before each run. XFOIL's PACC prompts to
% overwrite if POLAR_OUTPUT already exists, which desynchronises the command
% stream so the DUMP/CPWR outputs never get written. A previous run that
% failed mid-way leaves this file behind, breaking every later evaluation.
% (Do NOT delete XFOIL_Output/XFOIL_CP_Output: XFOIL writes those fresh.)
for f = {xfoil_out('POLAR_OUTPUT'),xfoil_out('doesntmatter')}
    if exist(f{1},'file'), delete(f{1}); end
end
try
    [OASPL_A, Cl, Cd, o] = evaluate_airfoil(ctx.tmpfile, ctx.inputs, ctx.fluid);
catch ME
    R.status = ['xfoil_fail: ' ME.message];
    if isfield(ctx,'verbose') && ctx.verbose
        fprintf(2, '  [eval error] %s\n', getReport(ME, 'basic'));
    end
    return;
end

if ~isfinite(OASPL_A) || ~isreal(OASPL_A) || Cd <= 0
    R.status = 'bad_output';
    return;
end

% Reject designs whose suction side is separated OR near incipient
% separation at the trailing edge. The TNO model assumes an attached
% turbulent boundary layer; without this the optimiser drives the suction
% side toward separation (H -> high, Cf -> 0) to artificially lower the
% predicted wall pressure. Two guards keep the optimum comfortably attached:
%   H   <= ctx.H_sep   (shape-factor cap)
%   Cf  >= ctx.Cf_min  (positive skin-friction floor, no incipient sep.)
if isfield(ctx,'H_sep')
    [Hsuc, Cfsuc] = suction_bl_state(ctx.inputs.Mic);
    if isnan(Hsuc) || Hsuc > ctx.H_sep
        R.status = sprintf('suction_separated (H=%.2f)', Hsuc);
        return;
    end
    if isfield(ctx,'Cf_min') && (isnan(Cfsuc) || Cfsuc < ctx.Cf_min)
        R.status = sprintf('suction_incipient_sep (Cf=%.5f)', Cfsuc);
        return;
    end
end

R.valid = true;
R.OASPL_A = OASPL_A;
R.OASPL_lin = o.OASPL_lin;
R.Cl = Cl; R.Cd = Cd; R.clcd = Cl/Cd;
R.f = o.f; R.S_pp = o.S_pp;
R.status = 'ok';
end

function [H, Cf] = suction_bl_state(pos)
% Shape factor H and skin-friction Cf of the SUCTION side at x/c=pos, read
% from XFOIL's DUMP (XFOIL_Output) written by the last evaluation. Suction
% side = first half of the panel list (XFOIL DUMP convention). H>~3 and/or
% Cf->0 indicate (incipient) separation. DUMP columns:
%   1:s  2:x  3:y  4:Ue/Vinf  5:Dstar  6:Theta  7:Cf  8:H
H = NaN; Cf = NaN;
if ~exist(xfoil_out('XFOIL_Output'),'file'), return; end
try
    fid = fopen(xfoil_out('XFOIL_Output'),'r');
    D = textscan(fid,'%f%f%f%f%f%f%f%f','Delimiter',' ', ...
                 'MultipleDelimsAsOne',true,'CollectOutput',1,'HeaderLines',1);
    fclose(fid);
    D = D{1};
catch
    return;
end
if isempty(D) || size(D,2) < 8 || size(D,1) < 10, return; end
D = D(D(:,2) <= 1.0001, :);            % airfoil points only (drop the wake, x>1)
if size(D,1) < 10, return; end
x = D(:,2); Dstar = D(:,5); Theta = D(:,6); Cfcol = D(:,7); Hcol = D(:,8);
half = 1:floor(size(D,1)/2);          % suction side (upper) = first half
[~,i] = min(abs(x(half) - pos));
H = Hcol(i);  Cf = Cfcol(i);
if ~isfinite(H) || H <= 0, H = Dstar(i)/max(Theta(i),1e-9); end
end
