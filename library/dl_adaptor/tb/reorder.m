function y = reorder(x)

assert(length(x) == 4096);

idx = zeros(4, 1024);

for sb = 1:4
    idx(sb, 104:922) = ((1:819) + sb * 819 - 819).';
    idx(sb,:) = bitrevorder(fftshift(idx(sb,:)));
end

idx = idx(:);
idx(idx == 0) = 4096;

y = x(idx);

end
