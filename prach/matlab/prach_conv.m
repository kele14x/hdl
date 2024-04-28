function y = prach_conv(x)
% PRACH_CONV Bit accurate prach_conv model

kv = (0:length(x) - 1).';

% Mixer
phase = kv * 432;
nco = round(2^14*exp(2j*pi*phase/1536));

x_mixer = x .* nco;
x_mixer = floor((x_mixer + 2^13 + 1j * 2^13)/2^14);

y = x_mixer;

end
