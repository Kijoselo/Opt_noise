cd('C:\Users\josea\Desktop\Opti_Param_ruidoio\work\Amiet-Theory-for-TE-Noise');
addpath('optim'); set_pub_defaults();
models = {'TNO','Goody','Kamruzzaman'};
col = {[0 0 0],[0 0.45 0.8],[0.85 0.1 0.1]};
G = {'cst_baseline_NACA63221.dat','optimized_NACA63221_hardcon.dat'};
S = cell(2,3); P = cell(2,3); f = [];
for g = 1:2
  for m = 1:3
    for c = {'POLAR_OUTPUT','doesntmatter'}, if exist(c{1},'file'), delete(c{1}); end; end
    [fluid, inputs] = inputs_definition(); inputs.model = models{m};
    [~,~,~,o] = evaluate_airfoil(G{g}, inputs, fluid);
    S{g,m} = 10*log10(o.Phi_pp_s/(20e-6)^2);
    P{g,m} = 10*log10(o.Phi_pp_p/(20e-6)^2);
    f = o.f;
  end
end
figure('Color','w','Position',[40 40 1150 420]);
subplot(1,2,1); hold on; grid on;
for m = 1:3
  semilogx(f, S{2,m}-S{1,m}, '-', 'Color', col{m}, 'LineWidth', 1.4, 'DisplayName', models{m});
end
set(gca,'XScale','log'); yline(0,'k:','HandleVisibility','off');
xlabel('f [Hz]'); ylabel('\Delta\Phi_{pp} = opt - base [dB]');
legend('Location','southwest','FontSize',8);
text(0.03,0.94,'(a) suction','Units','normalized');
subplot(1,2,2); hold on; grid on;
for m = 1:3
  semilogx(f, P{2,m}-P{1,m}, '-', 'Color', col{m}, 'LineWidth', 1.4, 'HandleVisibility','off');
end
set(gca,'XScale','log'); yline(0,'k:','HandleVisibility','off');
xlabel('f [Hz]'); ylabel('\Delta\Phi_{pp} = opt - base [dB]');
text(0.03,0.94,'(b) pressure','Units','normalized');
savefig300(gcf, fullfile('paper','figures','fig_wps_delta_NACA63221'), 19);
fprintf('done\n'); exit(0);
