
f = fopen('index.txt', 'w')
for i = 1:4096
  fprintf(f, '%s\n', dec2hex(y(i) - 1, 3))
end 

fclose(f);