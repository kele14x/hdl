function q = gmp_sim(sig, ap, bp, adr_scale, lut2d, dnp, dnq)
% lut2d, m*16*16
% 
q = zeros(size(sig));

for k = 1 : length(dnp)    
    ak = sigdelay(ap, dnp(k));
    bk = sigdelay(bp, dnp(k));
    
    sk = sigdelay(sig, dnq(k));
    
    [ia, fa] = linear_map(ak, adr_scale(1));
    [ib, fb] = linear_map(bk, adr_scale(2));
    
    lutiq = reshape(squeeze(lut2d(k, :, :)) .', 1, 16*16);

    coef = lut4x(lutiq, ia, fa, ib, fb);
    coef = floor(coef*2^12 + 0.5 + 0.5i) / 2^12;
    
    q = q + coef .* sk;
end

end

function [iaddr, faddr] = linear_map(x, scale)

[a1, b1, a2, b2] = addr_map_coef;
ax = sqrt_sim(real(x), imag(x), a1, b1, a2, b2, scale*2^10);

% ax = round(abs(x) * scale);

iaddr = floor(ax / 2^10);
faddr = floor( (ax - iaddr * 2^10) / 2^4 ) / 2^6;

end