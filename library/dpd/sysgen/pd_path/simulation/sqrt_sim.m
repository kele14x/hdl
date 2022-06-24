function sp = sqrt_sim(xi, xq, a1, b1, a2, b2, gScale)
% mapping to sqrt function
% assume sqrt(xi*xi + xq*xq) < 2^14
% y = a + b*x
% 
% using 32 bit unsigned integer in C-code for power mapping

% gScale = 1024;      % default=1, no scaling

xi = round(xi);     % using 16 bits signed IQ
xq = round(xq);

pwr = xi.*xi + xq.*xq;
pwr = floor(pwr / 2^10);    % using high 22 bits
pwr = floor(pwr * gScale / 2^10);   % scaling, default = 1

% saturated to 2^14 * (15/16)
plim = (2^14 * 15/16) ^ 2 / 2^10;       % = 230400
pwr(pwr >= plim) = plim - 1;            % only 18bits effective, 18=2*14 - 10

% final mapping, 4bit + 4bit + 10bit
high4 = floor(pwr / 2^14);
low4  = floor(pwr / 2^10);

frac_high = pwr - high4*2^14;       % & (2^14-1)
frac_low  = pwr - low4 *2^10;       % & (2^10-1)

% sp = zeros(size(pwr));
% 
% sp(high4 ~= 0) = floor((a1(high4(high4 ~= 0) + 1) + b1(high4(high4 ~= 0) + 1) .* frac_high(high4 ~= 0)) / 2^16);
% sp(high4 == 0) = floor((a2(low4(high4 == 0)  + 1) + b2(low4(high4 == 0)  + 1) .* frac_low(high4 == 0) ) / 2^16);

sp = zeros(size(pwr));

low4(low4 >= 15) = 15;
sp_high = floor((a1(high4 + 1) + b1(high4 + 1) .* frac_high) / 2^16);
sp_low  = floor((a2(low4  + 1) + b2(low4  + 1) .* frac_low ) / 2^16);

sp(high4 ~= 0) = sp_high(high4 ~= 0);
sp(high4 == 0) = sp_low(high4 == 0);
end