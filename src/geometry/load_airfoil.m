function af = load_airfoil(filename)
% LOAD_AIRFOIL  Read a Selig/XFOIL .dat coordinate file and split surfaces.
%   af.x, af.y    : full coordinate loop (TE -> upper -> LE -> lower -> TE)
%   af.xu, af.yu  : upper surface, x ascending from LE(0) to TE(1)
%   af.xl, af.yl  : lower surface, x ascending from LE(0) to TE(1)
%   af.name       : source file name
%
% Assumes the standard Selig ordering used by XFOIL .dat files: the loop
% starts at the trailing edge, runs over the upper surface to the leading
% edge (the point of minimum x), then back along the lower surface.

filename = buscar_perfil(filename);   % (reorganizacion) nombre -> ruta absoluta
raw = readmatrix(filename);
% Keep only the two coordinate columns and drop any header/NaN rows.
raw = raw(all(~isnan(raw(:,1:2)),2), 1:2);

% Some coordinate exports include an airfoil reference point before the actual
% contour loop, commonly x/c=0.5, y/c=0. Drop it when the next point is the
% trailing-edge start of a Selig/XFOIL loop.
if size(raw,1) >= 3 && raw(1,1) > 0.05 && raw(1,1) < 0.95 ...
        && abs(raw(2,1) - 1) < 1e-3
    raw = raw(2:end,:);
end

x = raw(:,1);
y = raw(:,2);

[~, iLE] = min(x);          % leading edge = minimum x

% Upper surface: from LE back to the first point (TE). Flip to ascending x.
xu = flipud(x(1:iLE));
yu = flipud(y(1:iLE));
% Lower surface: from LE to the last point (TE), already ascending x.
xl = x(iLE:end);
yl = y(iLE:end);

af = struct('x', x, 'y', y, 'xu', xu, 'yu', yu, 'xl', xl, 'yl', yl, ...
            'name', filename);
end
