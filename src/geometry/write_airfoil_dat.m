function write_airfoil_dat(filename, x, y)
% WRITE_AIRFOIL_DAT  Write coordinates to an XFOIL/Selig .dat file.
%   Matches the header-less, two-column format of the proven-working
%   perfil2.dat so XFOIL's LOAD reads it the same way.
fid = fopen(filename, 'w');
if fid < 0, error('Cannot open %s for writing.', filename); end
for i = 1:numel(x)
    fprintf(fid, '%9.5f %9.5f\n', x(i), y(i));
end
fclose(fid);
end
