function res = results(x0a, x0b, x1a, x1b, b0coef, lut_tx0, lut_tx1, scale, dnp_a, dnq_a, dnp_b, dnq_b)

res = [];

% up-sample
x0a = upsample(x0a(1:2:end), 2, 0);
x0b = upsample(x0b(1:2:end), 2, 0);

x1a = upsample(x1a(1:2:end), 2, 0);
x1b = upsample(x1b(1:2:end), 2, 0);

x0a = input2samp(x0a, b0coef);
x0b = input2samp(x0b, b0coef);

x1a = input2samp(x1a, b0coef);
x1b = input2samp(x1b, b0coef);

% 2x input signal
res.x0a = x0a;
res.x0b = x0b;

res.x1a = x1a;
res.x1b = x1b;


% address mapping
[a1, b1, a2, b2] = addr_map_coef;
ar0 = sqrt_sim(real(x0a), imag(x0a), a1, b1, a2, b2, round(scale(1)) * 2^10);
ar1 = sqrt_sim(real(x1a), imag(x1a), a1, b1, a2, b2, round(scale(1)) * 2^10);

br0 = sqrt_sim(real(x0b), imag(x0b), a1, b1, a2, b2, round(scale(2)) * 2^10);
br1 = sqrt_sim(real(x1b), imag(x1b), a1, b1, a2, b2, round(scale(2)) * 2^10);

res.ar0 = floor(ar0 / 2^4);
res.br0 = floor(br0 / 2^4);

res.ar1 = floor(ar1 / 2^4);
res.br1 = floor(br1 / 2^4);

% LUT & GMP model
q0a = gmp_sim(x0a, x0a, x0b, scale, squeeze(lut_tx0(1, :, :, :)), dnp_a, dnq_a);
q1a = gmp_sim(x1a, x1a, x1b, scale, squeeze(lut_tx1(1, :, :, :)), dnp_a, dnq_a);

q0b = gmp_sim(x0b, x0a, x0b, scale, squeeze(lut_tx0(2, :, :, :)), dnp_b, dnq_b);
q1b = gmp_sim(x1b, x1a, x1b, scale, squeeze(lut_tx1(2, :, :, :)), dnp_b, dnq_b);

res.q0a = q0a;
res.q0b = q0b;

res.q1a = q1a;
res.q1b = q1b;

res.pd0a = q0a + x0a;
res.pd1a = q1a + x1a;

res.pd0b = q0b + x0b;
res.pd1b = q1b + x1b;

end

function y = input2samp(x, b)
y = filter(b, 1, x);
y = floor(y / 2^17 + 0.5 + 0.5i);
end