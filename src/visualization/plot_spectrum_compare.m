function plot_spectrum_compare(P, dv_opt, prefix)
% PLOT_SPECTRUM_COMPARE  OASPL spectrum (SPL vs frequency) baseline vs optimized.
% Plots narrowband SPL and 1/3-octave bands for both airfoils on one figure.
%   P      : problem struct from setup_problem (uses P.dv0, P.ctx)
%   dv_opt : optimized design vector
%   prefix : output filename prefix (PNG saved at 300 dpi)
if nargin < 3 || isempty(prefix), prefix = 'spectrum_compare'; end
pref = 20e-6;

Rb = eval_airfoil_cached(P.dv0,  P.ctx);
Ro = eval_airfoil_cached(dv_opt, P.ctx);

f  = Rb.f;
SPLb = 10*log10(Rb.S_pp/pref^2);
SPLo = 10*log10(Ro.S_pp/pref^2);

% 1/3-octave bands (uses the project's NarrowToNthOctave)
[Lb, Fc] = NarrowToNthOctave(f, SPLb, 3);
[Lo, ~ ] = NarrowToNthOctave(f, SPLo, 3);

figure('Color','w','Position',[100 100 1400 380]);

subplot(1,3,1);
semilogx(f, SPLb, 'k-', f, SPLo, 'r-'); grid on;
xlabel('Frequency [Hz]'); ylabel('SPL [dB]');
title('(a) narrowband');
legend(sprintf('baseline (%.2f dBA)',P.J0), ...
       sprintf('optimized (%.2f dBA)',Ro.OASPL_A), 'Location','best');
xlim([f(1) f(end)]);

subplot(1,3,2);
semilogx(Fc, Lb, 'k-o', Fc, Lo, 'r-s'); grid on;
xlabel('1/3-octave band center [Hz]'); ylabel('SPL [dB]');
title('(b) 1/3-octave');
legend('baseline','optimized','Location','best');

subplot(1,3,3);
semilogx(Fc, Lo-Lb, 'b-d', 'MarkerFaceColor','b'); grid on; hold on;
yline(0,'k:');
xlabel('1/3-octave band center [Hz]'); ylabel('\DeltaSPL = opt - base [dB]');
title('(c) band-by-band change');

savefig300(gcf, prefix, 19);
end
