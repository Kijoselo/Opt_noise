function fig_mechanism_aero_v2(basefile)
% FIG_MECHANISM_AERO_V2  Revised aerodynamic/acoustic mechanism figure.
% Same baseline-vs-optimized comparison as plot_mechanism, but the two
% surfaces share axes so the frequency crossover is visible:
%   (a) surface pressure coefficient C_p
%   (b) wall-pressure spectrum at x/c = inputs.Mic, suction and pressure side
%   (c) A-weighted far-field contribution of each side in 1/3-octave bands
% Colour = case (baseline orange, optimized blue); line style = surface
% (solid suction, dashed pressure).
% Writes fig_mechanism_aero_v2_<case>.png in the code folder.
if nargin < 1 || isempty(basefile), basefile = 'NACA63221.txt'; end
close all; set_pub_defaults(); pc = pub_colors();
rutas = proyecto_init('workspace','legacy'); %#ok<NASGU>  % rutas del proyecto; cwd = results/simulations/legacy_workspace
pref = 20e-6;
toDB = @(P) 10*log10(P/pref^2);

P = setup_problem('base', basefile, 'write_legacy', false);
fluid = P.ctx.fluid;  inputs = P.ctx.inputs;
files = {P.ctx.baseline_file, P.ctx.opt_file};
cols  = {pc.base, pc.opt};
names = {'Baseline', 'Optimized'};

o = cell(1,2); xcp = cell(1,2); cp = cell(1,2);
for k = 1:2
    [~,~,~,o{k}] = evaluate_airfoil(files{k}, inputs, fluid);
    [xcp{k}, cp{k}] = read_cp();               % read before it is overwritten
end
f = o{1}.f;

% A-weighting (matches evaluate_airfoil)
Ra = 12194^2*f.^4 ./ ((f.^2+20.6^2).*sqrt((f.^2+107.7^2).*(f.^2+797.9^2)).*(f.^2+12194^2));
A  = 20*log10(Ra) - 20*log10(Ra(f==1000));
Lw = @(S) 10*log10(trapz(f, S.*10.^(A/10))/pref^2);

% 1/3-octave bands fully inside the computed range
fc = 1000*2.^((-9:13)/3);
fl = fc*2^(-1/6); fh = fc*2^(1/6);
keep = fl >= f(1) & fh <= f(end);
fc = fc(keep); fl = fl(keep); fh = fh(keep);
band = @(S) arrayfun(@(i) toDB(trapz(f(f>=fl(i) & f<fh(i)), ...
              S(f>=fl(i) & f<fh(i)).*10.^(A(f>=fl(i) & f<fh(i))/10))), 1:numel(fc));

figure('Color','w','Position',[100 100 1400 540]);
tl = tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
xt = [100 1000 10000]; xtl = {'10^2','10^3','10^4'};

% (a) C_p
ax1 = nexttile(tl); hold on; grid on;
for k = 1:2
    plot(xcp{k}, cp{k}, '-', 'Color',cols{k}, 'DisplayName',names{k});
end
set(gca,'YDir','reverse');
xlabel('x/c'); ylabel('C_p');
panel_label(ax1, '(a)');

% (b) wall-pressure spectra, both sides on the same axes
ax2 = nexttile(tl); hold on; grid on;
h = gobjects(1,4);
for k = 1:2
    h(2*k-1) = semilogx(f, toDB(o{k}.Phi_pp_s), '-',  'Color',cols{k}, ...
                        'DisplayName',[names{k} ', suction']);
    h(2*k)   = semilogx(f, toDB(o{k}.Phi_pp_p), '--', 'Color',cols{k}, ...
                        'DisplayName',[names{k} ', pressure']);
    d  = toDB(o{k}.Phi_pp_s) - toDB(o{k}.Phi_pp_p);
    ic = find(diff(sign(d)) ~= 0, 1);
    xline(f(ic), ':', 'Color',cols{k}, 'LineWidth',0.9, 'HandleVisibility','off');
    fprintf('  %s: Phi_pp crossover at %d Hz\n', names{k}, f(ic));
end
set(gca,'XScale','log','XTick',xt,'XTickLabel',xtl); xlim([f(1) f(end)]);
xlabel('Frequency [Hz]'); ylabel('\Phi_{pp} [dB re (20 \muPa)^2/Hz]');
lg = legend(h, 'NumColumns',4); lg.Layout.Tile = 'south';
panel_label(ax2, '(b)');

% (c) A-weighted far-field contribution of each side, 1/3-octave bands
ax3 = nexttile(tl); hold on; grid on;
h = gobjects(1,4); L = zeros(2,2);
for k = 1:2
    Ls = Lw(o{k}.S_pp_s);  Lp = Lw(o{k}.S_pp_p);  L(k,:) = [Ls Lp];
    h(2*k-1) = semilogx(fc, band(o{k}.S_pp_s), '-o',  'Color',cols{k}, 'MarkerSize',3, ...
        'MarkerFaceColor',cols{k}, 'HandleVisibility','off');
    h(2*k)   = semilogx(fc, band(o{k}.S_pp_p), '--s', 'Color',cols{k}, 'MarkerSize',3, ...
        'HandleVisibility','off');
    fprintf('  %s: OASPL(A) suction %.2f  pressure %.2f\n', names{k}, Ls, Lp);
end
set(gca,'XScale','log','XTick',xt,'XTickLabel',xtl); xlim([100 2e4]); ylim([10 62]);
xlabel('1/3-octave band centre frequency [Hz]'); ylabel('SPL_A [dBA]');
text(ax3, 0.34, 0.04, {'OASPL_A, suction / pressure:', ...
     sprintf('Baseline   %.1f / %.1f dBA', L(1,:)), ...
     sprintf('Optimized  %.1f / %.1f dBA', L(2,:))}, ...
     'Units','normalized', 'VerticalAlignment','bottom', 'FontSize',8, ...
     'FontName','Times New Roman', 'BackgroundColor','w');
panel_label(ax3, '(c)');

savefig300(gcf, sprintf('fig_mechanism_aero_v2_%s', P.case_id), 19);
end

function panel_label(ax, s)
text(ax, 0.03, 0.96, s, 'Units','normalized', 'FontWeight','bold', ...
     'VerticalAlignment','top', 'FontName','Times New Roman');
end

function [xc, cp] = read_cp()
D = readmatrix(xfoil_out('XFOIL_CP_Output'), 'FileType','text', 'NumHeaderLines',3);
xc = D(:,1); cp = D(:,3);
end
