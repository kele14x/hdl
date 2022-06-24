perval = ravalid(100 : end);
perdat = radata (100 : end);

perdat = perdat(perval == 1);


sim_data = iqsplit(perdat);

sim_ax = sim_data(0*32768 + (1:32768));
sim_bx = sim_data(1*32768 + (1:32768));

sim_rx = sim_data(2*32768 + (1:65536));

% offs = 65622;
offs = 65621;

tar_a = Ai.signals.values(offs + (1:16384)) + 1i*Aq.signals.values(offs + (1:16384));
tar_b = Bi.signals.values(offs + (1:16384)) + 1i*Bq.signals.values(offs + (1:16384));

r0 = tori0.signals.values(offs + (1:16384)) + 1i*torq0.signals.values(offs + (1:16384));
r1 = tori1.signals.values(offs + (1:16384)) + 1i*torq1.signals.values(offs + (1:16384));

tar_r = zeros(32768, 1);
tar_r(1:2:end) = r0;
tar_r(2:2:end) = r1;

figure; plot(abs(tar_a - sim_ax(1:16384)));
figure; plot(abs(tar_b - sim_bx(1:16384)));

figure; plot(abs(tar_r - sim_rx(1:32768)));