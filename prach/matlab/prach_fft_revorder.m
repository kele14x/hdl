function y = prach_fft_revorder(x)
% PRACH_FFT_REVORDER revorder for PRACH FFT

nFFT = length(x);

idx = [bitrevorder(1:nFFT/3); bitrevorder(nFFT/3+1:2*nFFT/3); bitrevorder(2*nFFT/3+1:nFFT)];
idx = idx(:);

y = x(idx);

end
