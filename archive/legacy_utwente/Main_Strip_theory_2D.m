%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the main script to calculate the trailing edge noise of an airfoil
% using strip theory of a 2D airofil.
% The trailing edge noise is calculated based on
% the theory of Roger-Moreu 2005. 
% In this code, the back scattering effect is also taken into account. 
% Laura Botero Bolívar - University of Twente 
% l.boterobolivar@utwente.nl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
clear all

%% Inputs for the strip theory
[Strip,fluid,input] = inputs_definition_StripTheory();

%% divide the span in the number of sections 
input.span       = input.span_total/Strip.n;

%% Calculate the noise of each strip
for j = 1:Strip.n
[f, S_pp(j,:)] = TE_noise_Prediction(input,fluid);
end 

%% Sum Each part 
if Strip.n == 1
    S_pp_total = S_pp;
else 
S_pp_total = sum(S_pp);
end 

%% plots
plots_striptheory(f,S_pp_total,Strip);