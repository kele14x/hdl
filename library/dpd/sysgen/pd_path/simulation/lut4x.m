function q = lut4x(c, ani, anf, bni, bnf)
% q = lut4x(c, ani, anf, bni, bnf)
% 
% 4x LUT interpolation
% ani = 0 ~ 15, anf = 0/64 ~ 63/64
% bni = 0 ~ 15, bnf = 0/64 ~ 63/64
%
% c = {b*16 + a}, two bands A & B

q0 = c( (bni + 0)*16 + ani + 1);
q1 = c( (bni + 0)*16 + (ani + 1) + 1);

q2 = c( (bni + 1)*16 + ani + 1);
q3 = c( (bni + 1)*16 + (ani + 1) + 1);

r0 = q0 + (q1 - q0) .* anf;
r1 = q2 + (q3 - q2) .* anf;

q = r0 + (r1 - r0) .* bnf;

end