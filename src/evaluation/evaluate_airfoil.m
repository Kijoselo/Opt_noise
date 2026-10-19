function [OASPL_A, Cl, Cd, out] = evaluate_airfoil(perfil, inputs, fluid)
% EVALUATE_AIRFOIL  Run the trailing-edge-noise pipeline for one airfoil and
% return the A-weighted overall sound pressure level (the design objective).
%
%   perfil : path to the airfoil .dat file (sets inputs.perfil)
%   inputs : inputs struct from inputs_definition (chord, U, AoA, Re, M, ...)
%   fluid  : fluid struct from inputs_definition
%
%   OASPL_A : A-weighted OASPL [dBA]  -> objective to minimise
%   Cl, Cd  : XFOIL force coefficients (for constraints / reporting)
%   out     : struct with f, S_pp and the un-weighted OASPL for diagnostics
%
% This mirrors Main_TE_noise_prediction.m exactly but as a side-effect-free
% function (no clear/close/plots), so an optimiser can call it repeatedly.
%
% NOTE: the parent folder (with wavesnumbers, Radiation_integral*, etc.) and
% xfoil.exe must be on the path / in the working directory.

% (reorganizacion) el nombre del perfil se resuelve a ruta absoluta: acepta
% 'NACA63221.txt', 'optimized_NACA63221_hardcon.dat' o una ruta completa.
inputs.perfil = buscar_perfil(perfil);

%% wave numbers
[f,omega,B,C,K_bar,k_min_bar,mu_bar,S0,K_1_bar,alpha,U_c,K_2_bar] = wavesnumbers(inputs,fluid);

%% transfer functions and radiation integral
[f1] = Radiation_integral1(B,C);
[f2] = Raditation_integral2(B,K_bar,k_min_bar,mu_bar,S0,K_1_bar,alpha,inputs);
[I]  = Radiation_integral(f1,f2);

%% spanwise correlation length
[l_y] = spanwise_corlength(U_c,omega,K_2_bar,inputs);

%% wall pressure PSD (also returns force coefficients)
[Phi_pp_s,Phi_pp_p,Cl,Cd,Cdp,Cm] = surface_pressure_spectrum(omega,inputs,fluid,inputs.model);

%% integrated wavenumber spectral density
[Pi0_s,Pi0_p] = Integrated_WPS(l_y,Phi_pp_s,Phi_pp_p);

%% far-field noise
[S_pp_s,S_pp_p] = farfield_noise(inputs,fluid,omega,S0,I,Pi0_s,Pi0_p);
S_pp = S_pp_s + S_pp_p;

%% A-weighted OASPL  (identical to Main_TE_noise_prediction.m lines 53-60)
Ra = 12194^2*f.^4 ./ ((f.^2+20.6^2).*sqrt((f.^2+107.7^2).*(f.^2+797.9^2)).*(f.^2+12194^2));
A  = 20*log10(Ra) - 20*log10(Ra(f==1000));

Spp_db   = 10*log10(S_pp/(20*10^-6)^2);
Spp_db_A = Spp_db + A;
spp_Pa   = (20*10^-6)^2 .* 10.^(Spp_db_A'/10);
Spp_A_Pa = trapz(f, spp_Pa');
OASPL_A  = 10*log10(Spp_A_Pa/(20*10^-6)^2);

%% un-weighted OASPL for diagnostics
spp_Pa_lin = (20*10^-6)^2 .* 10.^(Spp_db'/10);
OASPL_lin  = 10*log10(trapz(f, spp_Pa_lin')/(20*10^-6)^2);

out = struct('f',f, 'S_pp',S_pp, 'S_pp_s',S_pp_s, 'S_pp_p',S_pp_p, ...
             'OASPL_lin',OASPL_lin, 'Cm',Cm, ...
             'Phi_pp_s',Phi_pp_s, 'Phi_pp_p',Phi_pp_p);
end
