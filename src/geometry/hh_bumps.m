function B = hh_bumps(x, xk, width)
% HH_BUMPS  Hicks-Henne bump basis matrix.
%   b_k(x) = sin( pi * x^(log(0.5)/log(xk)) )^width
% Each bump peaks at x = xk. Returns B(:,k) = b_k(x).
if nargin < 3, width = 3; end
x = x(:);
xk = xk(:)';
B = zeros(numel(x), numel(xk));
for k = 1:numel(xk)
    m = log(0.5) / log(xk(k));
    B(:,k) = sin(pi * x.^m).^width;
end
end
