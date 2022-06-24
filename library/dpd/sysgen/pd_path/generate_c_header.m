function generate_c_header(keys, values)

values = round(values);
curr_time = now;

fid = fopen('output/pd_path_def.h', 'w+t');
fprintf(fid, '// Created at %04d-%02d-%02d,%02d:%02d:%02d\n', round(year(curr_time)), round(month(curr_time)), round(day(curr_time)), round(hour(curr_time)), round(minute(curr_time)), round(second(curr_time)));

for k = 1:length(keys)
    name = keys{k};
    value= values(k);
    fprintf(fid, [strpad(['#define    ', name], 28), '(%d)\n'], value);
end

fclose(fid);

end

function q = strpad(s, num)

cnum = length(s);
if cnum < num
    q = [s, char(ones(1, num-cnum) * double(' '))];
end

end