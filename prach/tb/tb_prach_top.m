%%
clc;
clearvars;
close all;

%%
ue = [];
ue.NULRB = 100;
ue.NSubframe = 1;

chs = [];
chs.ConfigIdx = 0;
chs.FreqOffset = 0;

debug = true;

% The 1 ms time domain waveform, 1 symbol at 30.72 MHz Fs
x = ltePRACH(ue, chs);
% Sampling rate power scale, may cause by iFFT, 30.72 / 1.92 = 16
x = x * 16;
x = round(x*2^15);

fprintf("Power = %.2f dBBit (%.2f dBFS)\n", ...
    20*log10(rms(x)), 20*log10(rms(x)/2^15));

writematrix([dec2hex(imag(x), 4), dec2hex(real(x), 4)], ...
    "tb_prach_top_input.txt");

if debug
    % For F0, the CP length is 3168 samples, symbol data is 24576 samples
    x_fft = x(3168+(1:24576));
    x_fft = fft(x_fft);
    v = (-12288:12287) / 12;
    figure();
    plot(v, 20*log10(abs(fftshift(x_fft))), '-x');
    xlabel("#RE");
    ylabel("Amplitude")
    title("Spectrum of PRACH");
end

% The waveform at 1.92 MHz Fs, as reference
ue.NULRB = 6;
chs.FreqOffset = 0;
x1 = ltePRACH(ue, chs);
% Sampling rate power scale, 1.92 / 1.92 = 1
x1 = x1 * 1;
% First level NCO constant phase shift
x1 = x1 * exp(2j * pi * 3168 * 564 / 2048);
% Second level NOC frequency shift
x1 = x1 .* exp(2j * pi * (0:length(x1)-1)' * 864 / 2 / 1536);
x1 = round(x1 * 2^15);

% For F0, the CP length is 198 samples, symbol data is 1536 samples

%%
filename = '../../prj/project_1.sim/sim_1/behav/xsim/tb_prach_top_output.txt';
y = readmatrix(filename);
y = y(:, 1) + 1j * y(:, 2);
% y = y(3:4:end);
% y = y(1:length(x1));

% Reverse the bit-revorder
y = [bitrevorder(y(1:3:end)); bitrevorder(y(2:3:end)); bitrevorder(y(3:3:end))];

figure();
plot(abs(x1));
hold on;
plot(198+(1:1536), abs(y));

% Compensate for constant phase
b = y \ x1(198+(1:1536));
e = y * b - x1(198+(1:1536));

figure();
plot(abs([x1(198+(1:1536)), y, e]));
legend("Input", "Output");

figure();
pwelch([x1(198+(1:1536)), y, e], [], [], [], 1.92e6, "centered");
