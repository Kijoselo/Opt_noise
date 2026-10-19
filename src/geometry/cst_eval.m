function y = cst_eval(x, A, yte, N1, N2)
% CST_EVAL  Evaluate a CST (Kulfan) surface.
%   y = C(x) * S(x) + x*yte
%   C(x) = x^N1 * (1-x)^N2          (class function)
%   S(x) = sum_i A(i) * Bernstein_i(x)   (shape function)
% Defaults N1=0.5, N2=1.0 (round leading edge, sharp trailing edge).

if nargin < 4 || isempty(N1), N1 = 0.5; end
if nargin < 5 || isempty(N2), N2 = 1.0; end

x = x(:);
n = numel(A) - 1;                 % Bernstein order
C = x.^N1 .* (1-x).^N2;

S = zeros(size(x));
for i = 0:n
    bin = nchoosek(n, i);
    S = S + A(i+1) * bin * x.^i .* (1-x).^(n-i);
end

y = C .* S + x .* yte;
end
