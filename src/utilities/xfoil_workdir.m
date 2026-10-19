function wd = xfoil_workdir()
% XFOIL_WORKDIR  Carpeta de trabajo de XFOIL (donde está xfoil.exe y donde
% quedan xfoil_ifile.txt, XFOIL_Output, XFOIL_CP_Output, POLAR_OUTPUT, ...).
% Por defecto results/simulations/xfoil_work; se puede cambiar con
% proyecto_init('xfoil_workdir', carpeta). Se crea si no existe y se copia
% xfoil.exe desde bin/ si falta.
rutas = proyecto_rutas();
wd = rutas.xfoil_work;
if ~exist(wd, 'dir'), mkdir(wd); end
exe = fullfile(wd, 'xfoil.exe');
if ~exist(exe, 'file')
    copyfile(fullfile(rutas.bin, 'xfoil.exe'), exe);
end
end
