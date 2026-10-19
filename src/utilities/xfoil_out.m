function p = xfoil_out(nombre)
% XFOIL_OUT  Ruta completa de un archivo de salida/temporal de XFOIL dentro de
% la carpeta de trabajo de XFOIL (ver xfoil_workdir). Nombres habituales:
% XFOIL_Output (DUMP de capa limite), XFOIL_CP_Output (Cp), POLAR_OUTPUT,
% doesntmatter, xfoil_ifile.txt, xfoil_stdout.txt.
p = fullfile(xfoil_workdir(), nombre);
end
