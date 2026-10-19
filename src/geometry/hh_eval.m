function y = hh_eval(x, a, xk, width, lower)
% HH_EVAL  Evaluate a Hicks-Henne surface = NACA0012 baseline + bumps.
%   lower : true for the lower surface (negative baseline).
if nargin < 4 || isempty(width), width = 3; end
if nargin < 5, lower = false; end
x = x(:);
base = naca0012(x);
if lower, base = -base; end
y = base + hh_bumps(x, xk, width) * a(:);
end
