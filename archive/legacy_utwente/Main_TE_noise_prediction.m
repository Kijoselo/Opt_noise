%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the main script to calculate the trailing edge noise based on
% the theory of Roger-Moreu 2005. 
% In this code, the back scattering effect is also taken into account. 
% Laura Botero Bolívar - University of Twente 
% l.boterobolivar@utwente.nl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
clear all
close all
%hold all

%% inputs
[fluid,inputs] = inputs_definition();
inputs.perfil= 'perfil2.dat';


%% Define waves number
[f,omega,B,C,K_bar,k_min_bar,mu_bar,S0,K_1_bar,alpha,U_c,K_2_bar] = wavesnumbers(inputs,fluid);

%% transfer function f1 (identical to Amiet)
[f1] = Radiation_integral1(B,C);

%% Transfer function f2 (for the Back-scattering effect)
[f2] = Raditation_integral2(B,K_bar,k_min_bar,mu_bar,S0,K_1_bar,alpha,inputs);

%% Radiation integral total
[I] = Radiation_integral(f1,f2);

%% Spanwise correlation length 
[l_y] = spanwise_corlength(U_c,omega,K_2_bar,inputs);

%% Wall pressure PSD
[Phi_pp_s,Phi_pp_p,Cl,Cd, Cdp, Cm] = surface_pressure_spectrum(omega,inputs,fluid,inputs.model);

%% Stream-wise integrated wavenumber spectral density of wall-pressure fluctuations
[Pi0_s,Pi0_p] = Integrated_WPS(l_y,Phi_pp_s,Phi_pp_p);

%% far-field noise
[S_pp_s,S_pp_p] = farfield_noise(inputs,fluid,omega,S0,I,Pi0_s,Pi0_p);
S_pp = S_pp_s + S_pp_p;

%% convert to 1/3 octave
[sortedData,Fc,Flow,Fhigh] = NarrowToNthOctave(f,10*log10(S_pp_s),3);
sortedData_Pa2_db=10*log10(8*pi*10.^(sortedData/10)/(20*10^-6)^2);

%% plots
plots(f,I,Phi_pp_s,Phi_pp_p,S_pp,S_pp_s,S_pp_p)

%% calculate OASPL
Ra = 12194^2*f.^4./((f.^2+20.6^2).*sqrt((f.^2+107.7^2).*(f.^2+797.9^2)).*(f.^2+12194^2));
A = 20*log10(Ra)-20*log10(Ra(f==1000));

Spp_db = 10*log10(S_pp/(20*10^-6)^2);
Spp_db_A =  Spp_db + A;
spp_Pa = (20*10^-6)^2.*10.^(Spp_db_A'/10);
Spp_A_Pa = trapz(f,spp_Pa');   
Spp_OASPL = 10*log10(Spp_A_Pa/(20*10^-6)^2)



