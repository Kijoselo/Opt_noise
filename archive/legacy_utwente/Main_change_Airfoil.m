%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the main script to calculate the trailing edge noise at different
% directivity angles based on the theory of Roger-Moreu 2005. 
% In this code, the back scattering effect is also taken into account. 
% Laura Botero Bol?var - University of Twente 
% l.boterobolivar@utwente.nl
% modified E.Ferrer
%Modified LBB 13/04/2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set the case
clear all
[fluid,input] = inputs_definition();
R = input.z;

naca_1 = 0:1:6;
naca_2 = 0:1:4;
naca_3 = 1:1:2;
naca_4 = 1:1:8;
%% specifiy frequency
kc = 1;
k = kc/input.chord;
omega_d = k*fluid.c0;
count=0;
Airfoils{1} = 'Naca0000';
for i = 1: length(naca_1)
  for j = 1: length(naca_2)
    for ii = 1: length(naca_3)
      for jj = 1: length(naca_4)

naca=strcat('Naca',num2str(naca_1(i)),num2str(naca_2(j)),num2str(naca_3(ii)),num2str(naca_4(jj)));
input.perfil    = naca;

if ~any(strcmp(Airfoils,naca))
       count=count+1;
        try
        %% Trailing edge noise prediction
        [omega, S_pp(:,count), Phi_pp(:,count)] = TE_noise_Prediction(input,fluid);
        figure(1)
        semilogx(omega/(2*pi), 10*log10(S_pp(:,count)/(20*10^-5)));
        hold on
        Integral_Spp(count)=abs(trapz(omega/(2*pi),10*log10(S_pp(:,count)/(20*10^-5))));
        figure(2)
        semilogx(omega/(2*pi), 10*log10(Phi_pp(:,count)/(20*10^-5)));
        hold on
        Integral_Phi_pp(count)=abs(trapz(omega/(2*pi),10*log10(Phi_pp(:,count)/(20*10^-5))));
        catch 
            disp(['XFOIL did not converge for ' naca])
             Airfoils{count+1} = naca;
             count = count - 1; 
        end 
else
continue
end
        end 
    end 
  end 
end 












