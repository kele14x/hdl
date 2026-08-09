%%
clc;
clearvars;
close all;

%%
N = 1536;
rng(12345);

% Generate input
x = randn(N, 1) + 1j * randn(N, 1);
x = round(10^(-15/20) * 2^15 * x / rms(x));

% Sequence to reverse order
s2r = [bitrevorder(1:N/3); bitrevorder(N/3+1:2*N/3); bitrevorder(2*N/3+1:N)];
s2r = s2r(:);
xr = x(s2r);
writematrix([dec2hex(imag(xr)), dec2hex(real(xr))], "tb_prach_fft_input.txt");

% Reverse to sequence order
r2s = [bitrevorder(1:3:N)'; bitrevorder(2:3:N)'; bitrevorder(3:3:N)'];
assert(all(s2r(r2s) == (1:N)'));

r = fft(x) / 2^5;

%%
file = '..\..\prj\project_1.sim\sim_1\behav\xsim';

y = readmatrix([file, '\tb_prach_fft_output.txt']);
y = y(:, 1) + 1j * y(:, 2);
y = y(1:N);

e = y - r;

figure();
hold on;
grid on;
plot(abs(y));
plot(abs(r));
plot(abs(e));
legend("Output", "Reference", "Error")

input_power = 20*log10(rms(x));
output_power = 20*log10(rms(y));
error_power = 20*log10(rms(e));
fprintf("Input power: %.2f dBbit\n", input_power);
fprintf("Output power: %.2f dBbit\n", output_power);
fprintf("FFT gain: %.2f dB\n", output_power - input_power);

fprintf("Error power: %.2f dBbit\n", error_power);
fprintf("Error EVM: %.2f %%\n", 100 * rms(e) / rms(r));
