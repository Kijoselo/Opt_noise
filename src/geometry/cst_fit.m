function p = cst_fit(af, order)
% CST_FIT  Least-squares fit of CST coefficients to an airfoil.
%   order : Bernstein order per surface (order+1 coefficients each).
%   p.Au, p.Al : upper/lower shape coefficients
%   p.yte_u, p.yte_l : trailing-edge offsets (y at x=1)
%   p.N1, p.N2 : class-function exponents
%   p.ndv : number of design variables (2*(order+1))
%
% The class function vanishes at x=0 and x=1, so those endpoints carry no
% information about the shape coefficients and are excluded from the solve.

if nargin < 2, order = 6; end
N1 = 0.5; N2 = 1.0;

p.Au = fit_surface(af.xu, af.yu, order, N1, N2);
p.Al = fit_surface(af.xl, af.yl, order, N1, N2);
p.yte_u = af.yu(end);
p.yte_l = af.yl(end);
p.N1 = N1; p.N2 = N2;
p.order = order;
p.ndv = 2*(order+1);
end

function A = fit_surface(x, y, n, N1, N2)
x = x(:); y = y(:);
C = x.^N1 .* (1-x).^N2;
yte = y(end);                       % trailing-edge offset at x=1
rhs = y - x.*yte;                   % = C(x)*S(x)

B = zeros(numel(x), n+1);           % Bernstein basis scaled by class fn
for i = 0:n
    B(:,i+1) = nchoosek(n,i) * x.^i .* (1-x).^(n-i);
end
M = C .* B;

mask = C > 1e-12;                   % drop x=0 and x=1 rows
A = M(mask,:) \ rhs(mask);
end
