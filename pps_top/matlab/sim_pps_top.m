%%
clc;
clearvars;
close all;

%% Settings
Fclk = 122.88e6;
Fs = 30.72e6;

nfft = 1024;
cplen = [88, 72 * ones(1, 13)];

%% Delay sub-sample in Frequency Domain
% The signal
x = randn(nfft,1) + randn(nfft,1) * 1j;
% Number of samples to delay (positive value = delay = cycle pre-fix)
d = -1;
% Delayed signal
x_ref = circshift(x, d);

% Using the frequency domain method
xfft = fft(x);
k = (0:nfft-1)';
xfft_d = xfft .* exp(2j*pi*-d*k/nfft);
x_d = ifft(xfft_d);

% Test RMS error
e = circshift(x, d) - x_d;
rms_err = rms(e) / rms(x);
fprintf('RMS = %.2f%%\n', rms_err * 100);
pinc = mod(2^32*(-d)/1024, 2^32);
fprintf('PINC = %s\n', dec2hex(pinc, 8));

%%
