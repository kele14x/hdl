function y = diffft3(x, K)
assert(K <= length(x));
assert(rem(length(x), K) == 0);

W = @(N, k)(exp(-2j*pi*k/N));
y = zeros(size(x));

for i = 1:length(x) / K
    idx = (i - 1) * K + 1:i * K;
    xs = x(idx);

    xs1 = xs(1:K/3);
    xs2 = xs(K/3+1:2*K/3);
    xs3 = xs(2*K/3+1:end);

    y1 = xs1 + W(3, 0) * xs2 + W(3, 0) * xs3;
    y2 = xs1 + W(3, 1) * xs2 + W(3, 2) * xs3;
    y3 = xs1 + W(3, 2) * xs2 + W(3, 4) * xs3;

    wx2 = W(K, 0:(K / 3 - 1));
    wx3 = W(K, 0:2:(2 * K / 3 - 1));

    y(idx) = [y1, y2 .* wx2, y3 .* wx3];
end

end
