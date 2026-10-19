function p = hh_fit(af, xk)
% HH_FIT  Fit Hicks-Henne bumps over a NACA0012 baseline to reproduce af.
% Hicks-Henne is a *perturbation* scheme, so it needs a baseline. We use a
% symmetric NACA0012 and least-squares fit the bump amplitudes that morph it
% into the target airfoil. This makes its reconstruction error comparable to
% the full parameterizations (CST, PARSEC).
%   p.au, p.al : bump amplitudes (upper/lower)
%   p.xk       : bump locations
%   p.width    : bump width exponent
%   p.ndv      : number of design variables (2*numel(xk))

if nargin < 2 || isempty(xk)
    xk = [0.10 0.25 0.40 0.55 0.70 0.85];
end
width = 3;

p.au = fit_side(af.xu, af.yu, xk, width, false);   % upper -> +NACA baseline
p.al = fit_side(af.xl, af.yl, xk, width, true);    % lower -> -NACA baseline
p.xk = xk;
p.width = width;
p.ndv = 2*numel(xk);
end

function a = fit_side(x, y, xk, width, lower)
% Use an explicit surface flag (NOT the sign of the mean) so the fit baseline
% matches hh_eval exactly. A mean-based guess fails on reflexed lower surfaces
% (whose mean can be positive), giving a fit/eval baseline mismatch.
x = x(:); y = y(:);
base = naca0012(x);
if lower, base = -base; end
B = hh_bumps(x, xk, width);
a = B \ (y - base);
end
