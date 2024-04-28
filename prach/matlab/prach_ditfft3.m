function y = prach_ditfft3(x)
assert(iscolumn(x));
assert(rem(length(x), 3) == 0);

RND1 = @(x)(floor(x + 0.5 + 1j * 0.5));
RND2 = @(x)(floor((x + 2^15 + 1j * 2^15) / 2^16));

xs = reshape(x, 3, []).';
w = round(cos(pi/6) * 2^16 * 1j);

xs = [xs(:,1), xs(:,2) + xs(:,3), -xs(:,2) + xs(:,3)];
xs = [xs(:,1) + xs(:,2), RND1(xs(:,1)  - 0.5 * xs(:,2)), RND2(w * xs(:,3))];
xs = [xs(:,1), xs(:,2) + xs(:,3), xs(:,2) - xs(:,3)];

y = xs.';
y = y(:);

end
