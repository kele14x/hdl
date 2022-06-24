function d = lo_mod_coef

% simu_env

loi = cos(2*pi*(0:1023)/1024);
loq = sin(2*pi*(0:1023)/1024);

loi = round(loi * 2^14);
loq = round(loq * 2^14);

loi(loi < 0) = loi(loi < 0) + 2^16;
loq(loq < 0) = loq(loq < 0) + 2^16;

d = loq * 2^16 + loi;




