function validate_naca0012()
% VALIDATE_NACA0012  Validate the present noise framework against the standard
% NACA0012 benchmark used by Kou et al. (2023) and Kucukosman et al. (2018).
% Produces two figures and the integrated-band OASPL for the manuscript:
%   fig_validation_farfield.png  far-field 1/3-octave spectrum
%   fig_validation_wps.png       wall-pressure spectrum vs RANS reference (.tsv)
% and prints the OASPL in the 1000-6300 Hz band to compare with the literature
% (Kou 68.87 dB, RANS 68.81 dB, experiments 67.67-68.83 dB).
close all; set_pub_defaults();
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
pref = 20e-6;

%% --- NACA0012 geometry (cosine spaced, sharp-ish TE) ---
beta = linspace(0,pi,100)'; xs = 0.5*(1-cos(beta));
yt = naca0012(xs);
x = [flipud(xs); xs(2:end)];
y = [flipud(yt); -yt(2:end)];
write_airfoil_dat('naca0012_valid.dat', x, y);

%% --- validation conditions (Kou et al. 2023 / Botero) ---
[fluid, inputs] = inputs_definition();
inputs.perfil   = 'naca0012_valid.dat';
inputs.chord    = 0.4;  inputs.semichord = 0.2;  inputs.span = 1;
inputs.U        = 56;   inputs.AoA = 0;
inputs.xtr_s    = 0.06; inputs.xtr_p = 0.06;
inputs.x = 0; inputs.y = 0; inputs.z = 1; inputs.Mic = 0.99;
inputs.Ky = NaN;
inputs.M  = inputs.U/fluid.c0;
inputs.Re = inputs.chord*inputs.U/fluid.ni;
inputs.model = 'TNO';

%% --- far-field spectrum ---
[OASPL_A, Cl, Cd, o] = evaluate_airfoil('naca0012_valid.dat', inputs, fluid);
f = o.f; S_pp = o.S_pp;
SPL = 10*log10(S_pp/pref^2);
[L3, Fc] = NarrowToNthOctave(f, SPL, 3);

% integrated OASPL in the 1000-6300 Hz band (un-weighted), as in Kou Table 1
band = f >= 1000 & f <= 6300;
OASPL_band = 10*log10( trapz(f(band), S_pp(band)) / pref^2 );

% diagnostics: full-band un-weighted OASPL and where the energy sits
OASPL_full = 10*log10( trapz(f, S_pp)/pref^2 );          % 100-20000 Hz, no A
[~, ipk] = max(S_pp); f_peak = f(ipk);
e_below1k = trapz(f(f<1000), S_pp(f<1000)) / trapz(f, S_pp) * 100;

fprintf('\n=== NACA0012 validation (AoA=0, U=56 m/s, Re=%.2e, M=%.3f) ===\n', ...
        inputs.Re, inputs.M);
fprintf('  OASPL 1000-6300 Hz : %.2f dB   (present work)\n', OASPL_band);
fprintf('  reference          : 68.87 (Kou), 68.81 (RANS), 67.67-68.83 (exp)\n');
fprintf('  --- diagnostics ---\n');
fprintf('  OASPL full band    : %.2f dB  (un-weighted, 100-20000 Hz)\n', OASPL_full);
fprintf('  full-band OASPL(A) : %.2f dBA | Cl=%.3f Cd=%.5f\n', OASPL_A, Cl, Cd);
fprintf('  spectral peak at   : %.0f Hz | energy below 1 kHz = %.0f%%\n\n', f_peak, e_below1k);

figure('Color','w');
semilogx(Fc, L3, 'k-o'); grid on;
xlabel('1/3-octave band center frequency [Hz]'); ylabel('SPL [dB]');
xlim([100 1e4]);
% --- to overlay digitized far-field experiments (Herr et al. 2012), drop a
%     two-column [f, SPL] file here and uncomment: ---
% ref = load('Ref_fig_SPM/herr_naca0012.tsv');
% hold on; semilogx(ref(:,1), ref(:,2), 'rs'); legend('present','Herr et al.');
savefig300(gcf, 'fig_validation_farfield');

%% --- wall-pressure spectrum vs Kucukosman et al. 2018 RANS (.tsv) ---
omega = 2*pi*f;
[Phi_pp_s, Phi_pp_p] = surface_pressure_spectrum(omega, inputs, fluid, inputs.model);
Phi_s_dB = 10*log10(Phi_pp_s/pref^2);    % per-rad PSD; check 2*pi factor if offset

if exist('Ref_fig_SPM/AoA0_Goody.tsv','file')
    ref = load('Ref_fig_SPM/AoA0_Goody.tsv');
    figure('Color','w');
    semilogx(f, Phi_s_dB, 'k-'); hold on; grid on;
    semilogx(ref(:,1), ref(:,2), 'ro', 'MarkerFaceColor','r');
    xlabel('Frequency [Hz]'); ylabel('\Phi_{pp} [dB/Hz]  (P_{ref}=20\muPa)');
    legend('present (TNO, suction side)','RANS (Kucukosman et al. 2018)', ...
           'Location','best');
    xlim([100 1e4]);
    savefig300(gcf, 'fig_validation_wps');
    fprintf('  NOTE: if the wall-pressure curve is offset by a constant, it is\n');
    fprintf('  the per-Hz vs per-rad convention (Phi(f)=2*pi*Phi(omega)); adjust.\n\n');
else
    fprintf('  (Ref_fig_SPM/AoA0_Goody.tsv not found; skipped WPS overlay.)\n');
end
end
