function y = prach_ditfft2(x, K, s)
assert(iscolumn(x));
assert(K <= length(x));
assert(rem(length(x), K) == 0);

RND = @(x)(floor((x + 2^15 + 1j * 2^15) / 2^16));

y = zeros(size(x));

for i = 1:length(x) / K
    idx = (i - 1) * K + 1:i * K;
    xs = x(idx);

    xs1 = xs(1:K/2);
    xs2 = xs(K/2+1:end);

    wx = twiddler(K, 0:K/2-1);

    y1 = xs1 + RND(xs2 .* wx);
    y2 = xs1 - RND(xs2 .* wx);

    if (s)
        y1 = floor(y1 / 2 + 0.5 + 0.5j);
        y2 = floor(y2 / 2 + 0.5 + 0.5j);
    end 

    y(idx) = [y1; y2];
end

end
