%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to load the data from Kucukosman et al 2018 to validate the
% surface pressure spectra model
% Laura Botero Bolívar - University of Twente
% l.boterobolivar@utwente.nl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

AoA_0 = load('AoA0_Goody.tsv');
AoA_4_p = load('AoA4_pressureside_Goody.tsv');
AoA_4_s = load('AoA4_suctionside_Goody.tsv');

figure()
semilogx(AoA_0(:,1),AoA_0(:,2))
hold all
semilogx(AoA_4_p(:,1),AoA_4_p(:,2))
semilogx(AoA_4_s(:,1),AoA_4_s(:,2))
xlabel('f [Hz]')
ylabel('\Phi_{pp} [db/Hz]. P_ref = 20\mu Pa')
legend('AoA0','AoA4_p','AoA4_s')