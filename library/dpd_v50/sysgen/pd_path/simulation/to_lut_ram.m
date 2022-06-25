function d = to_lut_ram(lut2d)
% lut2d: 2-d array , LUT(B, A)
% 
% d(B*32 + A) = LUT(B, A)

d = zeros(1, 1024);

for bb = 1:16
    for aa = 1:16
        d((bb-1)*32 + aa) = lutiq(lut2d(bb, aa));
    end
end

end

function d = lutiq(x)
xi = round(real(x) * 2^12);
xq = round(imag(x) * 2^12);
xi(xi < 0) = xi(xi < 0) + 2^16;
xq(xq < 0) = xq(xq < 0) + 2^16;
d = xq * 2^16 + xi;
end