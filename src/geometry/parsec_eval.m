function y = parsec_eval(x, a)
% PARSEC_EVAL  Evaluate a PARSEC surface polynomial.
%   y(x) = sum_{n=1..6} a(n) * x^(n-1/2)
x = x(:);
e = (1:6) - 0.5;            % exponents 0.5,1.5,...,5.5
y = zeros(size(x));
for n = 1:6
    y = y + a(n) * x.^e(n);
end
end
