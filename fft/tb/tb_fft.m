%
clc;
clearvars;
close all;

nFFT = 1024*4;
inv = false;
rev = false;

nFrame = 1:3;
%
file = '../../prj/project_1.sim/sim_1/behav/xsim';

input = readmatrix([file, '/din.txt']);
input = input(:, 1) + 1j * input(:, 2);
input = reshape(input, nFFT, []);
input = input(:, nFrame);

output = readmatrix([file, '/dout.txt']);
output = output(:, 1) + 1j * output(:, 2);
output = reshape(output, nFFT, []);
output = output(:, nFrame);

nStage = ceil(log2(nFFT)/2);

if rev
    input = bitrevorder(input);
end

if inv
    ref = ifft(input) * nFFT;
else
    ref = fft(input);
end

if ~rev
    ref = bitrevorder(ref);
end

ref = ref / 2^(6 - 1);
err = ref - output;

figure();
plot(real([ref, output, err]));
title("Real")

figure();
plot(imag([ref, output, err]));
title("Imag")

figure();
plot(abs([ref, output, err]));
title("Abs")

p_input = 20 * log10(rms(input));
p_output = 20 * log10(rms(output));
p_error = 20 * log10(rms(err));
fprintf("p_input = %.2f dBbit\n", p_input);
fprintf("p_output = %.2f dBbit\n", p_output);
fprintf("p_error = %.2f dBbit\n", p_error);

err_evm = rms(err) / rms(ref);
fprintf("Error EVM = %.2f %%\n", err_evm*100);
