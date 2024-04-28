%
clc;
clearvars;
close all;

nFFT = 1536;
cpLength = 3168;

x = prach_source();
x = upsample(x, 2);
% Delay the signal for 512 samples so HB filters has enough time to be
% stable
x = circshift(x, 512);

%% TC-0
y = prach_ddc(x);
y = y(cpLength/16+(1:nFFT));
y = prach_fft(prach_fft_revorder(y));
y = y(1:72*12);

writematrix([real(x), imag(x)], './test/prach_top_in.txt');
writematrix([real(y), imag(y)], './test/prach_top_out.txt');
