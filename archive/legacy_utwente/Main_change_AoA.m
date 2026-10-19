%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the main script to calculate the trailing edge noise at different
% directivity angles based on the theory of Roger-Moreu 2005. 
% In this code, the back scattering effect is also taken into account. 
% Laura Botero Bolívar - University of Twente 
% l.boterobolivar@utwente.nl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set the case
clear all
[fluid,input] = inputs_definition();
R = input.z;
AoA = 1;
%% specifiy frequency
kc = 1;
k = kc/input.chord;
omega_d = k*fluid.c0;

%% Calculate the A filter.
f = 100:20000;
Ra = 12194^2*f.^4./((f.^2+20.6^2).*sqrt((f.^2+107.7^2).*(f.^2+797.9^2)).*(f.^2+12194^2));
A = 20*log10(Ra)-20*log10(Ra(f==1000));

for i = 1: length(AoA)
input.AoA = AoA(i);
%% Trailing edge noise prediction
[omega, S_pp(:,i), Phi_pp(:,i),Cl(i),Cd(i), Cdp(i), Cm(i), Cf(:,i)] = TE_noise_Prediction(input,fluid);

Spp_db = 10*log10(S_pp(:,i)/(20*10^-6)^2);
Spp_db_A =  Spp_db + A';
spp_Pa = (20*10^-6)^2.*10.^(Spp_db_A/10);
Spp_A_Pa(i) = trapz(f,spp_Pa');   
Spp_OASPL(i) = 10*log10(Spp_A_Pa(i)/(20*10^-6)^2);  
end 









