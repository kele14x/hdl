
xi = (0:4095);
xq = 2^16 - (1:4096);

f = fopen('data.mem', 'w')

for i = 1:4096
  fprintf(f, '%s%s\n', dec2hex(xq(i), 4), dec2hex(xi(i), 4));
end

fclose(f);