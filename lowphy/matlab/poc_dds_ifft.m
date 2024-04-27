% File: poc_dds_ifft.m
% Brief: DDS + iFFT

%% Clear
clc;
clearvars;
close all;

% Parameters
rng(12345);
nFFT = 1024;
N = 51*12;

rg = randn(N, 1) + randn(N, 1) * 1j;

%%
x_ref = zeros(nFFT, 1);
x_ref(1:N) = rg;
x_ref = circshift(x_ref, -N/2);

% Symbol to iFFT mapping
y_ref = ifft(x_ref) * sqrt(nFFT);
y_ref = [y_ref(end-87:end); y_ref];

%%
% x1 = zeros(nFFT, 1);
% x1(1:3276) = rg;
% x1 = circshift(x, -1638);
% 
% % Time shift in frequency doamin
% % x = x .* exp(2j*pi*-352*(0:4095).'/4096);
% y1 = ifft(x1) * sqrt(nFFT);
% 
% y1 = [y1; y1(1:352)];

%%
x2 = zeros(nFFT, 1);
x2(1:N) = rg;
% x = circshift(x, -1638);

% Time shift in frequency doamin
x2 = x2 .* exp(2j*pi*-88*(0:1023).'/1024);
y2 = ifft(x2) * sqrt(nFFT);

% Frequency shift
y2 = y2 .* exp(2j*pi*-N/2*(-88:935).'/1024);

% CP Insert
y2 = [y2; y2(1:88)];

%%
figure();
hold on;
plot(abs(y_ref));
plot(abs(y2));
plot(abs(y_ref - y2));

figure();
pwelch([y2, y_ref], [], [], [], 'centered');
