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
U = 20:5:45;
%% specifiy frequency
kc = 1;
k = kc/input.chord;
omega_d = k*fluid.c0;

for i = 1: length(U)
input.U = U(i);
%% Trailing edge noise prediction
[omega, S_pp(:,i), Phi_pp(:,i),Cl(i),Cd(i), Cdp(i), Cm(i), Cf(:,i)] = TE_noise_Prediction(input,fluid);

figure(1)
semilogx(omega/(2*pi), 10*log10(S_pp(:,i)/(20*10^-5)))
hold on

figure(2)
semilogx(omega/(2*pi), 10*log10(Phi_pp(:,i)/(20*10^-5)))
hold on
end 

%% scaling
for i=1:length(U)
    i
figure(1)
semilogx(omega/(2*pi)*0.3/U(i),10*log10(S_pp(:,i)/(20*10^-5))-30*log10(U(i)/U(1)))
hold on
ylabel('power 3')

figure(2)
semilogx(omega/(2*pi)*0.3/U(i),10*log10(S_pp(:,i)/(20*10^-5))-40*log10(U(i)/U(1)))
hold on
ylabel('power 4')

figure(3)
semilogx(omega/(2*pi)*0.3/U(i),10*log10(S_pp(:,i)/(20*10^-5))-40*log10(U(i)/U(1)))
hold on
ylabel('power 5')

figure(4)
semilogx(omega/(2*pi)*0.3/U(i),10*log10(S_pp(:,i)/(20*10^-5)))
hold on
ylabel('no scaled')
end 








