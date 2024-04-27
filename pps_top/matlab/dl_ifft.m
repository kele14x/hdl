function y = dl_ifft(sym, nfft, cp, frac)

x = zeros(nfft, 1);
x(1:length(sym)) = sym;

k = (0:nfft - 1).';

% Time shift in frequency domain
pinc = (-cp + frac) / nfft;
poff = 0;
x = x .* exp(2j*pi*(pinc * k + poff));

y = ifft(x);

% Frequency shift in time domain
pinc = -length(sym) / 2 / nfft;
poff = -length(sym) / 2 * (-cp + frac) / nfft;
y = y .* exp(2j*pi*(pinc * k + poff));

% Add CP
y = [y; y(1:cp)];

end
