%%
clc;
clearvars;
close all;

nFFT = 2048;
nSym = 2;
cplen = [160, 144 * ones(1, nSym-1)];

%
fout = '../../prj/project_1.sim/sim_1/behav/xsim/pdxch_channel_input.txt';
x = readmatrix(fout);
x = x(:, 1) + 1j * x(:, 2);
x = x(1:nFFT*nSym);
x = reshape(x, nFFT, []);

%
r = bitrevorder(x);
r = ofdmmod(fftshift(r, 1), nFFT, cplen);
r = r * nFFT / 2^5;
r = round(r);

%
fout = '../../prj/project_1.sim/sim_1/behav/xsim/pdxch_channel_output.txt';
y = readmatrix(fout);
y = y(:, 1) + 1j * y(:, 2);
y = y(1:length(r));

e = r - y;

%%
figure();
plot(abs([r, y, e]));

fprintf("Input power %.2f dBFS\n", 20*log10(rms(x)/2^15));
fprintf("Output power %.2f dBFS\n", 20*log10(rms(y)/2^15));

err_evm = rms(e) / rms(y);
fprintf("Error EVM: %.2f%%\n", err_evm*100);

% pwelch(x/2^15, [], [], [], 30.72e6, "centered", "power");