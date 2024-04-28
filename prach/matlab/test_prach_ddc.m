%
clc;
clearvars;
close all;

nFFT = 1536;
x = prach_source();
x = upsample(x, 2);

%% TC-0
y = prach_ddc(x);
y = y(1:nFFT);

t = (0:length(x)-1).';
r = x .* exp(2j * pi * t * 6768 * 1.25e3 / 61.44e6);
r = downsample(r, 32) / 2;
t = (0:length(r)-1).';
r = r .* exp(2j * pi * t * 432 * 1.25e3 / 1.92e6);
r = r(1:nFFT);

y_ = y * (y \ r);
e = y_ - r;

figure();
plot(abs(fft(r)));
hold on;
plot(abs(fft(y)));

writematrix([real(x), imag(x)], './test/prach_ddc_in.txt');
writematrix([real(y), imag(y)], './test/prach_ddc_out.txt');

evm = rms(e) / rms(r);
assert(evm < 0.01);
