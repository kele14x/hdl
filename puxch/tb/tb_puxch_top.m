%%
clc;
clearvars;
close all;

nFFT = 2048;
nPRB = 100;

iSym = 5;

%%
cfg = struct('RC', 'A3-7', ...
    'NULRB', 100, ...
    'DuplexMode', 'FDD', ...
    'NCellID', 0, ...
    'RNTI', 1, ...
    'TotSubframes', 10, ...
    'Windowing', 0);

cfg.PUSCH.RVSeq = [0, 2, 3, 1];
cfg = lteRMCUL(cfg);

% input bit source:
in = [1; 0; 0; 1];

% Generation
[waveform, grid, cfg] = lteRMCULTool(cfg, in);

x = waveform(1:30720);
x = round(x/rms(x)*2^15*10^(-15 / 20));

writematrix([dec2hex(imag(x), 4), dec2hex(real(x), 4)], "tb_puxch_top_input.txt");


cplen = repmat([160, 144 * ones(1, 6)], 1, 20);
cplen = circshift(cplen, -1);
% r = x(160+(1:nFFT));
r = x(sum(cplen(1:iSym-1))+nFFT*iSym-nFFT+(1:nFFT));
r = r .* exp(2j*pi*599.5*(0:nFFT - 1)'/nFFT);
r = fft(r) / 2^5;
r = r(1:nPRB*12);

%%
fout = "../../prj/project_1.sim/sim_1/behav/xsim/tb_puxch_top_output.txt";
y = readmatrix(fout);
y = y(:, 1) + 1j * y(:, 2);
y = y(iSym*nPRB*12-nPRB*12+(1:nPRB*12));
% y = bitrevorder(y);

figure();
plot(abs(r));
hold on;
plot(abs(y));
legend("Reference", "Output");

%%
e = y - r;
fprintf("Error EVM: %.2f %%\n", 100*rms(e)/rms(r))

% figure();
% plot(abs(ifft(y(1:1200))));
