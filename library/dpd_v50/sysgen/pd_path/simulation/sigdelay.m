function y = sigdelay(x, dn)
% y = sigdelay(x, dn)
% 
% assume signal is round padded
% both integer and fractional delay with 1/64 step

n = length(x); 
[idn, fdn] = delaydiv(dn);

% integer delay
addn = abs(idn);

xt = [x(:, end - addn + 1 : end), x, x(:, 1 : addn)];
x1 = xt(:, addn - idn + (1:n));

% fractional delay
if fdn == 33
    y = x1;
    return;
end

df = load('frac_coef');

addn = size(df.b, 2);
xt = [x1(:, end - addn + 1 : end), x1, x1(:, 1 : addn)];

fdcoef = df.b(fdn, :);

xt = filter(fdcoef, 1, xt')';
x2 = xt(:, addn + df.grpn + (1:n));

% output result
y = x2;





%% small functions
function [dn, df] = delaydiv(d)
% df is in [1, 64]

md = abs(round(d)) + 2;

d2 = d + md;        % make positive
d2 = round(d2 * 64);

dn = round(d2 / 64);

df = d2 - dn * 64 + 33;     % df starts from 1 to 64

dn = dn - md;
