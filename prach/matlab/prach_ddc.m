function y = prach_ddc(x, fcw)
% PRACH_DDC Bit accurate prach_ddc model

if nargin < 2
    fcw = 13536;
end

% Mixer
x_mixer = prach_mixer(x, fcw);

% HB Coefficients
[hb1, hb2, hb3, hb4, hb5] = prach_hbx();

% HB1
x_hb1 = filter(hb1, 1, x_mixer);
x_hb1 = floor((x_hb1 + 2^16 + 1j * 2^16)/2^17);
x_hb1 = downsample(x_hb1, 2, 1);

% HB2
x_hb2 = filter(hb2, 1, x_hb1);
x_hb2 = floor((x_hb2 + 2^16 + 1j * 2^16)/2^17);
x_hb2 = downsample(x_hb2, 2, 1);

% HB3
x_hb3 = filter(hb3, 1, x_hb2);
x_hb3 = floor((x_hb3 + 2^16 + 1j * 2^16)/2^17);
x_hb3 = downsample(x_hb3, 2, 1);

% HB4
x_hb4 = filter(hb4, 1, x_hb3);
x_hb4 = floor((x_hb4 + 2^16 + 1j * 2^16)/2^17);
x_hb4 = downsample(x_hb4, 2, 1);

% HB5
x_hb5 = filter(hb5, 1, x_hb4);
x_hb5 = floor((x_hb5 + 2^16 + 1j * 2^16)/2^17);
x_hb5 = downsample(x_hb5, 2, 1);

% Conv
x_conv = prach_conv(x_hb5);

y = x_conv;

end
