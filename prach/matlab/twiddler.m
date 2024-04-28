function w = twiddler(N, k)
% Twiddler get FFT twiddle factor

w = round(2^16 * exp(-2j*pi*k/N));
w = w(:);

end
