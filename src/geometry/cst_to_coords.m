function [x, y, xu, yu, xl, yl] = cst_to_coords(Au, Al, yte_u, yte_l, npts, N1, N2)
% CST_TO_COORDS  Build a full airfoil coordinate loop from CST coefficients.
%   Au, Al         : upper/lower shape coefficients
%   yte_u, yte_l   : trailing-edge offsets
%   npts           : points per surface (cosine spaced), default 100
%   N1, N2         : class-function exponents (default 0.5, 1.0)
%
%   x, y   : full Selig loop (TE -> upper -> LE -> lower -> TE), as XFOIL wants
%   xu..yl : the individual surfaces, x ascending from LE to TE

if nargin < 5 || isempty(npts), npts = 100; end
if nargin < 6 || isempty(N1), N1 = 0.5; end
if nargin < 7 || isempty(N2), N2 = 1.0; end

% Cosine spacing clusters points near LE and TE for good resolution.
beta = linspace(0, pi, npts)';
xs = 0.5*(1 - cos(beta));

xu = xs; yu = cst_eval(xs, Au, yte_u, N1, N2);
xl = xs; yl = cst_eval(xs, Al, yte_l, N1, N2);

% Loop: upper from TE to LE, then lower from LE to TE (skip duplicate LE).
x = [flipud(xu); xl(2:end)];
y = [flipud(yu); yl(2:end)];
end
