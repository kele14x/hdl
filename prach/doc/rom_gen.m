%%
clc;
clearvars;
close all;

w = 18;
%%
for size = 3 * 2.^(1:9)
    vcos = round((2^(w - 1)-2)*cos(2*pi*(0:size / 2 - 1)'/size));
    vcos(vcos < 0) = vcos(vcos < 0) + 2^w;
    vsin = round((2^(w - 1)-2)*-sin(2*pi*(0:size / 2 - 1)'/size));
    vsin(vsin < 0) = vsin(vsin < 0) + 2^w;
    hex = vsin * 2^w + vcos;
    hex = dec2hex(hex, w/2);
    writematrix(hex, sprintf("prach_fft_%d.mem", size), "FileType", "text");
end
