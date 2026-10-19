function [DSTRS,DSTRP,THETAS,THETAP,CFS,CFP,x_c,Cp,Ue_s,Ue_p, dcpdx_s, dcpdx_p, Cl, Cd, Cdp, Cm,cf] = XFOIL_new_airfoil(NACADIG,ALPSTAR,Re,Mach,xtr_s,xtr_p,C,pos,Name_file)
% This function calculates the displacement thickness using XFOIL.
% The turbulence intensity is set at 0.07
%
% Entradas: Name_file (archivo de coordenadas; se resuelve con buscar_perfil),
%   ALPSTAR [deg], Re, Mach, xtr_s/xtr_p (x/c; 1 = transicion natural), C cuerda [m],
%   pos = x/c donde se leen las magnitudes de capa limite.
% Salidas: DSTR*, THETA* [m] (ya multiplicados por la cuerda), CF*, Ue* (Ue/Uinf),
%   dcpdx* (dCp/d(x/c)), Cl, Cd, Cdp, Cm, cf (vector Cf de XFOIL).
%
% --- Directorio de trabajo (reorganizacion del proyecto) ---
% XFOIL se ejecuta siempre dentro de xfoil_workdir(); alli quedan xfoil_ifile.txt,
% XFOIL_Output, XFOIL_CP_Output y POLAR_OUTPUT. El perfil se copia con un nombre
% corto porque XFOIL limita la longitud de la ruta en el comando LOAD. Al salir
% se restaura el directorio previo. La fisica y la lectura de XFOIL no cambian.
wd = xfoil_workdir();
ruta_perfil = buscar_perfil(Name_file);
destino = fullfile(wd, 'airfoil_in.dat');
if ~strcmpi(ruta_perfil, destino), copyfile(ruta_perfil, destino); end
Name_file = 'airfoil_in.dat';
dir_previo = cd(wd);
restaurar = onCleanup(@() cd(dir_previo)); %#ok<NASGU>

fid = fopen(['xfoil_ifile.txt'],'w');

fprintf(fid,'PLOP\n');
fprintf(fid,'G F\n\n');
%fprintf(fid,'%s\n',Name_file);
%fprintf(fid,'%s\n',NACADIG);
fprintf(fid,'load\n');
fprintf(fid,'%s\n',Name_file);
fprintf(fid,'new \n');
fprintf(fid,'pane \n');
fprintf(fid,'\n\noper\n');
% Set Reynolds and Mach
fprintf(fid,'visc\n');
fprintf(fid,'%g\n',Re);
fprintf(fid,'mach %g\n',Mach);
fprintf(fid,'iter %g\n',1000);
% Set turbulence intensity
Tu     = 0.07;
N_crit = -8.43-2.4*log(Tu/100);
%N_crit = 1;
fprintf(fid,'vpar\n');
fprintf(fid,['N ' num2str(N_crit) '\n\n']);
if xtr_s==1
else
   fprintf(fid,'vpar\n');
   fprintf(fid,'xtr\n');
   fprintf(fid,'%g\n',xtr_s);
   fprintf(fid,'%g\n\n',xtr_p);
end

fprintf(fid,'pacc\n');
fprintf(fid,'%s\n','POLAR_OUTPUT');
fprintf(fid,'%s\n','doesntmatter');
fprintf(fid,'alfa %g\n',ALPSTAR);
fprintf(fid,'cpwr  %s\n','XFOIL_CP_Output');
fprintf(fid,'DUMP %s\n','XFOIL_Output');

fprintf(fid,'%s\n','quit');
fclose(fid);


% Timed XFOIL call: a hung xfoil.exe (degenerate/non-panelable candidate) is
% killed after a timeout and treated as non-converged, so the optimiser never
% blocks. This only makes the process call robust; the noise physics is unchanged.
if exist('xfoil_stdout.txt','file'), delete('xfoil_stdout.txt'); end
ps = ['$p = Start-Process -FilePath ''.\xfoil.exe'' ' ...
      '-RedirectStandardInput ''xfoil_ifile.txt'' ' ...
      '-RedirectStandardOutput ''xfoil_stdout.txt'' -NoNewWindow -PassThru; ' ...
      'if (-not $p.WaitForExit(20000)) { Stop-Process -Id $p.Id -Force; ' ...
      'Add-Content ''xfoil_stdout.txt'' ''VISCAL: failed (XFOIL timeout)'' }'];
cmd = ['powershell -NoProfile -ExecutionPolicy Bypass -Command "' ps '"'];
[status,~] = system(cmd);
if exist('xfoil_stdout.txt','file'), result = fileread('xfoil_stdout.txt');
else, result = 'failed (no xfoil output)'; end
if numel(result) < 600, result = [blanks(600), result]; end

if contains(result(end-500:end),'failed')
        disp('XFoil Failed to Converge, Please check Input Parameters')
else
    disp('XFoil Converged')
    fid = fopen('XFOIL_Output','r');
    D = textscan(fid,'%f%f%f%f%f%f%f%f','Delimiter',' ','MultipleDelimsAsOne',true,'CollectOutput',1,'HeaderLines',1);
    fclose(fid);
    D = D{1,1};
    DSTAR_all = D(:,5);

    k = strfind(result,'Number of panel nodes');
    n_nodes = str2double(result((k+28):(k+30)));
    s      = D(:,1);
    xc     = D(:,2);
    [~,index] = min(abs(pos-xc(1:n_nodes/2)));
    yc     = D(:,3);
    Ue     = D(:,4);
    theta  = D(:,6);
    THETAS = theta(index)*C;
    THETAP = theta(n_nodes-index+1)*C;
    DSTRS = DSTAR_all(index)*C;
    DSTRP = DSTAR_all(n_nodes-index+1)*C;
    cf     = D(:,7);
    CFS = cf(index);
    CFP = cf(n_nodes-index+1);
    Ue_s = Ue(index);
    Ue_p = -Ue(n_nodes-index+1);
    % Load Cp data
    D2 = dlmread('XFOIL_CP_Output','',3,0);
    Cp = D2(:,3);
    x_c = D2(:,1);
    N_points = n_nodes;

    dcpdx_s = (Cp(index+1)-Cp(index))/(x_c(index+1)-x_c(index));
    dcpdx_p = (Cp(N_points-index+1+1)-Cp(N_points-index+1))...
        /(x_c(N_points-index+1+1)-x_c(N_points-index+1));



E(:,:) = dlmread('POLAR_OUTPUT','',12,0);
    AoA = E(:,1);
    Cl  = E(:,2);
    Cd  = E(:,3);
    Cdp  = E(:,4);
    Cm  = E(:,5);

delete('POLAR_OUTPUT');
delete('doesntmatter');
end
