function y = prach_fft(x)
% PRACH_FFT is bit accurate PRACH FFT model
nFFT = length(x);
nStage = log2(nFFT/3) + 1;

K = 3 * 2.^(1:log2(nFFT/3));

t = zeros(nFFT, nStage);

% Stage 1
t(:, 1) = prach_ditfft3(x);

% Stage 2 ~ N
for i = 1:log2(nFFT/3)
    n = K(i);
    t(:, i+1) = prach_ditfft2(t(:, i), n, rem(i, 2) == 1);
end

y = t(:, nStage);

end
