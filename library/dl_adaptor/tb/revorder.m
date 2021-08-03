function y = revorder(x)

assert(length(x) == 4096);

idx = reorder(1:4096);
[~, revidx] = sort(idx);

y = revidx(x);

end