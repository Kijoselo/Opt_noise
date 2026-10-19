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

xtr_s = 0.1:0.1:1;
xtr_p = 0.1:0.1:1;
%% specifiy frequency
kc = 1;
k = kc/input.chord;
omega_d = k*fluid.c0;

count = 0;
for i = 1: length(xtr_s)
input.xtr_s     = xtr_s(i);
input.xtr_p     = xtr_p(i);
count = count+1;
    try
    %% Trailing edge noise prediction
    [omega, S_pp(:,i), Phi_pp(:,i)] = TE_noise_Prediction(input,fluid);
    figure(1)
    semilogx(omega/(2*pi), 10*log10(S_pp(:,i)/(20*10^-5)))
    hold on
    Integral_Spp(count)=abs(trapz(omega/(2*pi),10*log10(S_pp(:,i)/(20*10^-5))));
    figure(2)
    semilogx(omega/(2*pi), 10*log10(Phi_pp(:,i)/(20*10^-5)))
    Integral_Phi_pp(count)=abs(trapz(omega/(2*pi),10*log10(Phi_pp(:,i)/(20*10^-5))));
    hold on
    catch 
      disp(['XFOIL did not converge for transition ' num2str(xtr_s(i))])
             count = count - 1;    
    end 
end 
