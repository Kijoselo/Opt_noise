function yt = naca0012(x, t)
% NACA0012  Half-thickness of a NACA 00xx airfoil (default t=0.12).
%   Returns the (positive) thickness y_t at stations x in [0,1].
if nargin < 2, t = 0.12; end
x = x(:);
yt = 5*t*(0.2969*sqrt(x) - 0.1260*x - 0.3516*x.^2 ...
        + 0.2843*x.^3 - 0.1015*x.^4);
end
