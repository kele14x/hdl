function q = iqsplit(d32)

sq = floor(d32 / 2^16);
si = mod(d32, 2^16);

si(si > 2^15) = si(si > 2^15) - 2^16;
sq(sq > 2^15) = sq(sq > 2^15) - 2^16;

q = si + 1i * sq;
end