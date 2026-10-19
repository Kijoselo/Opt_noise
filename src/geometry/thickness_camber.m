function [xc, tc, camber] = thickness_camber(datfile, n)
% THICKNESS_CAMBER  Thickness and camber distributions of an airfoil .dat file.
%   xc     : cosine-spaced chord stations [0,1]
%   tc     : thickness  t/c = y_upper - y_lower
%   camber : camber line (y_upper + y_lower)/2
if nargin < 2, n = 200; end
af = load_airfoil(datfile);
beta = linspace(0, pi, n)';
xc = 0.5*(1 - cos(beta));
yu = interp1(af.xu, af.yu, xc, 'pchip');
yl = interp1(af.xl, af.yl, xc, 'pchip');
tc = yu - yl;
camber = (yu + yl)/2;
end
