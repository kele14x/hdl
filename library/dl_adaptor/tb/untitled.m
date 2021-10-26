a = (1:4096);
b = reorder(a);

writematrix(dec2hex(b.', 8), 'index.txt')