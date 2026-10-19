function a = parsec_coeffs(a1, Xm, Zm, Zxx, Zte, te_slope)
% PARSEC_COEFFS  Solve the 6 PARSEC polynomial coefficients for one surface.
%   a1       : leading-edge coefficient  (= +/- sqrt(2*rLE))
%   Xm, Zm   : location and value of the surface extremum
%   Zxx      : second derivative at Xm (curvature)
%   Zte      : trailing-edge y value at x=1
%   te_slope : trailing-edge slope dy/dx at x=1
%
% y(x) = sum a(n) x^(n-1/2). The 6 constraints are:
%   (1) leading-edge coefficient fixed by LE radius
%   (2) y(Xm)   = Zm
%   (3) y'(Xm)  = 0
%   (4) y''(Xm) = Zxx
%   (5) y(1)    = Zte
%   (6) y'(1)   = te_slope

e = (1:6) - 0.5;                       % 0.5 .. 5.5
M = zeros(6,6); b = zeros(6,1);

M(1,:) = [1 0 0 0 0 0];           b(1) = a1;
M(2,:) = Xm.^e;                   b(2) = Zm;
M(3,:) = e .* Xm.^(e-1);          b(3) = 0;
M(4,:) = e .* (e-1) .* Xm.^(e-2); b(4) = Zxx;
M(5,:) = ones(1,6);               b(5) = Zte;          % 1^e = 1
M(6,:) = e;                       b(6) = te_slope;     % e*1^(e-1) = e

a = M \ b;
end
