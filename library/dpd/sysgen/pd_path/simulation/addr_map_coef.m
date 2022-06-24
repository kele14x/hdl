function [a1, b1, a2, b2] = addr_map_coef
% y = (a + b*x) / 2^10;
% a1 + b1*2^14, a1 + b2*2^10
% 18bit range
% 

% high 4 bit
d1 = (0:16) * 2^14;
r1 = round(sqrt(d1 * 2^10));
r1(15) = r1(15) - 5;

a1 = r1(1:16) * 2^16;
b1 = round((r1(2:17) - r1(1:16)) / 2^14 * 2^16);

% low 4bit
d2 = (0:16) * 2^10;
r2 = round(sqrt(d2 * 2^10));
r2(15) = r2(15) - 5;

a2 = r2(1:16) * 2^16;
b2 = round((r2(2:17) - r2(1:16)) / 2^10 * 2^16);

end