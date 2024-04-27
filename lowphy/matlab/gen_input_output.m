% File: gen_input_output.m
% Brief: Generate iFFT Test input & reference output

%%
clc;
clearvars;
close all;

% Parameters
fftSize = 1024;
SCS = 30e3;
nPRB = 51;
nSymbol = 28;
Pwr = -15;
M = 4;
cpLen = 72 * ones(1, nSymbol);
cpLen(1:14:end) = 88;

% QAM modulation
rng(12345);
rg = randi([0, M - 1], [nPRB * 12, nSymbol]);
rg = qammod(rg, M);

% Normalize power
refconst = qammod(0:M-1, M);
nf = modnorm(refconst, 'avpow', 10^(Pwr / 10));
rg = nf * rg;
rg = round(rg*2^15);

% Symbol to iFFT mapping
x = zeros([fftSize, nSymbol]);
x(1:nPRB*12, :) = rg(1:nPRB*12, :);

% % iFFT
% Y0 = ifft(circshift(x, -1638, 1)) * sqrt(fftSize);
% Y0 = round(Y0);
% 
% % Convert to time domain waveform
% y = zeros(sum(cpLen)+fftSize*nSymbol, 1);
% n = 0;
% for i = 1:nSymbol
%     % CP insertion
%     y(n+1:n+cpLen(i)) = Y0(4096-cpLen(i)+1:4096, i);
%     % Symbol data
%     y(n+cpLen(i)+1:n+cpLen(i)+fftSize) = Y0(:, i);
%     n = n + cpLen(i) + fftSize;
% end

y = ofdmmod(rg, fftSize, cpLen, [1:206, 819:1024].') * sqrt(fftSize);
y = round(y);

figure();
plot(abs(y));
figure();
pwelch(y, [], [], [], fftSize*SCS, 'center');

input = [dec2hex(imag(x(:)),4), dec2hex(real(x(:)),4)];
writematrix(input, 'lowphy_ifft_input.txt');
ref = [dec2hex(imag(y(:)),4), dec2hex(real(y(:)),4)];
writematrix(ref, 'lowphy_ifft_ref.txt');
