function p = parsec_fit(af)
% PARSEC_FIT  Extract PARSEC features from an airfoil and build coefficients.
% PARSEC parameters are geometric features, so we measure them directly from
% the coordinates (the standard, deterministic PARSEC usage) rather than a
% blind least-squares fit. Returns the 6+6 polynomial coefficients plus the
% reported feature set.
%   p.au, p.al : upper/lower polynomial coefficients (for parsec_eval)
%   p.feat     : struct of the 11 classic PARSEC parameters
%   p.ndv      : number of design variables (11)

xu = af.xu(:); yu = af.yu(:);
xl = af.xl(:); yl = af.yl(:);

% --- Leading-edge radius (shared), estimated from upper near-LE points ---
near = xu > 0 & xu < 0.05;
a1u_est = (sqrt(xu(near)) \ yu(near));   % y ~ a1*sqrt(x) near LE
rLE = a1u_est^2 / 2;
a1u =  sqrt(2*rLE);
a1l = -sqrt(2*rLE);

% --- Upper crest: max value, location, curvature ---
[Zup, iu] = max(yu);   Xup = xu(iu);
Zxxup = local_curvature(xu, yu, iu);

% --- Lower crest: min value, location, curvature ---
[Zlo, il] = min(yl);   Xlo = xl(il);
Zxxlo = local_curvature(xl, yl, il);

% --- Trailing edge ---
Zte_u = yu(end);  Zte_l = yl(end);
slope_u = (yu(end)-yu(end-1)) / (xu(end)-xu(end-1));
slope_l = (yl(end)-yl(end-1)) / (xl(end)-xl(end-1));

p.au = parsec_coeffs(a1u, Xup, Zup, Zxxup, Zte_u, slope_u);
p.al = parsec_coeffs(a1l, Xlo, Zlo, Zxxlo, Zte_l, slope_l);

p.feat = struct('rLE',rLE, 'Xup',Xup,'Zup',Zup,'Zxxup',Zxxup, ...
                'Xlo',Xlo,'Zlo',Zlo,'Zxxlo',Zxxlo, ...
                'Zte',(Zte_u+Zte_l)/2, 'dZte',(Zte_u-Zte_l), ...
                'aTE',atan((slope_u+slope_l)/2), 'bTE',atan(slope_u)-atan(slope_l));
p.ndv = 11;

% Least-squares fit on the same x^(n-1/2) basis, ignoring the geometric
% constraints. This measures the representational power of the PARSEC basis
% itself; the classic constrained fit above can diverge on reflexed/highly
% cambered surfaces (single-crest assumption).
p.au_lsq = lsq_basis(xu, yu);
p.al_lsq = lsq_basis(xl, yl);
p.ndv_lsq = 12;
end

function a = lsq_basis(x, y)
e = (1:6) - 0.5;
B = x(:).^e;            % 6 sqrt-power basis columns
a = B \ y(:);
end

function zxx = local_curvature(x, y, i)
% Second derivative from a local quadratic fit around index i.
lo = max(1, i-2); hi = min(numel(x), i+2);
c = polyfit(x(lo:hi), y(lo:hi), 2);
zxx = 2*c(1);
end
