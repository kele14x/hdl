
%% -- input sample check
res = results(x0a, x0b, x1a, x1b, input_samp_bcoef, LUT2D_tx0, LUT2D_tx1, Scale, dnp_a, dnq_a, dnp_b, dnq_b);

% delay cyclesc
comp_offset_start = 6000;
simdl_input_samp = 5;
simdl_addr_map = 8;
simdl_gmp = 33;
simdl_outsw = 4;

comp_num = 3000;

% % compare with {res_xa} and {res_xb}
% 
% res_xa_comp = res_xa(2:end, :);       % align 0&1
% res_xb_comp = res_xb(2:end, :);
% 
% simres_x0ai = res_xa_comp(1:2:end, 1);
% simres_x0aq = res_xa_comp(1:2:end, 2);
% simres_x0ai = simres_x0ai(comp_offset_start + simdl_input_samp + 1:end);
% simres_x0aq = simres_x0aq(comp_offset_start + simdl_input_samp + 1:end);
% 
% simres_x1ai = res_xa_comp(2:2:end, 1);
% simres_x1aq = res_xa_comp(2:2:end, 2);
% simres_x1ai = simres_x1ai(comp_offset_start + simdl_input_samp + 1:end);
% simres_x1aq = simres_x1aq(comp_offset_start + simdl_input_samp + 1:end);
% 
% simres_x0bi = res_xb_comp(1:2:end, 1);
% simres_x0bq = res_xb_comp(1:2:end, 2);
% simres_x0bi = simres_x0bi(comp_offset_start + simdl_input_samp + 1:end);
% simres_x0bq = simres_x0bq(comp_offset_start + simdl_input_samp + 1:end);
% 
% simres_x1bi = res_xb_comp(2:2:end, 1);
% simres_x1bq = res_xb_comp(2:2:end, 2);
% simres_x1bi = simres_x1bi(comp_offset_start + simdl_input_samp + 1:end);
% simres_x1bq = simres_x1bq(comp_offset_start + simdl_input_samp + 1:end);
% 
% tar_x0a = res.x0a(comp_offset_start + 1:end);
% tar_x1a = res.x1a(comp_offset_start + 1:end);
% tar_x0b = res.x0b(comp_offset_start + 1:end);
% tar_x1b = res.x1b(comp_offset_start + 1:end);
% 
% fprintf(1, 'x0a I error is %.5f\n', std_pwr(real(tar_x0a(1:comp_num)) - simres_x0ai(1:comp_num)'));
% fprintf(1, 'x0a Q error is %.5f\n', std_pwr(imag(tar_x0a(1:comp_num)) - simres_x0aq(1:comp_num)'));
% 
% fprintf(1, 'x1a I error is %.5f\n', std_pwr(real(tar_x1a(1:comp_num)) - simres_x1ai(1:comp_num)'));
% fprintf(1, 'x1a Q error is %.5f\n', std_pwr(imag(tar_x1a(1:comp_num)) - simres_x1aq(1:comp_num)'));
% 
% fprintf(1, 'x0b I error is %.5f\n', std_pwr(real(tar_x0b(1:comp_num)) - simres_x0bi(1:comp_num)'));
% fprintf(1, 'x0b Q error is %.5f\n', std_pwr(imag(tar_x0b(1:comp_num)) - simres_x0bq(1:comp_num)'));
% 
% fprintf(1, 'x1b I error is %.5f\n', std_pwr(real(tar_x1b(1:comp_num)) - simres_x1bi(1:comp_num)'));
% fprintf(1, 'x1b Q error is %.5f\n', std_pwr(imag(tar_x1b(1:comp_num)) - simres_x1bq(1:comp_num)'));
% 
% % address compare
% res_addr_acomp = res_addr_a(2:end);
% res_addr_bcomp = res_addr_b(2:end);
% 
% simres_ar0 = res_addr_acomp(1:2:end);
% simres_ar1 = res_addr_acomp(2:2:end);
% 
% simres_br0 = res_addr_bcomp(1:2:end);
% simres_br1 = res_addr_bcomp(2:2:end);
% 
% simres_ar0 = simres_ar0(comp_offset_start + simdl_input_samp + simdl_addr_map + 1:end);
% simres_ar1 = simres_ar1(comp_offset_start + simdl_input_samp + simdl_addr_map + 1:end);
% 
% simres_br0 = simres_br0(comp_offset_start + simdl_input_samp + simdl_addr_map + 1:end);
% simres_br1 = simres_br1(comp_offset_start + simdl_input_samp + simdl_addr_map + 1:end);
% 
% tar_ar0 = res.ar0(comp_offset_start + 1:end);
% tar_ar1 = res.ar1(comp_offset_start + 1:end);
% tar_br0 = res.br0(comp_offset_start + 1:end);
% tar_br1 = res.br1(comp_offset_start + 1:end);
% 
% fprintf(1, 'Addr 0 band-a error is %.5f.\n', std_pwr(tar_ar0(1:comp_num) - simres_ar0(1:comp_num)'));
% fprintf(1, 'Addr 1 band-a error is %.5f.\n', std_pwr(tar_ar1(1:comp_num) - simres_ar1(1:comp_num)'));
% fprintf(1, 'Addr 0 band-b error is %.5f.\n', std_pwr(tar_br0(1:comp_num) - simres_br0(1:comp_num)'));
% fprintf(1, 'Addr 1 band-b error is %.5f.\n', std_pwr(tar_br1(1:comp_num) - simres_br1(1:comp_num)'));
% 
% 
% % GMP model output
% gmp_out_delay = simdl_input_samp + simdl_addr_map + simdl_gmp;
% 
% tar_q0a = floor(res.q0a(comp_offset_start + (1:comp_num)) + 0.5 + 0.5i);
% tar_q0b = floor(res.q0b(comp_offset_start + (1:comp_num)) + 0.5 + 0.5i);
% tar_q1a = floor(res.q1a(comp_offset_start + (1:comp_num)) + 0.5 + 0.5i);
% tar_q1b = floor(res.q1b(comp_offset_start + (1:comp_num)) + 0.5 + 0.5i);
% 
% simres_q0a = ari(1:2:end) + 1i*arq(1:2:end);
% simres_q0a = simres_q0a(comp_offset_start + gmp_out_delay + (1:comp_num));
% % 
% % simres_q1a = rri(2:2:end) + 1i*rrq(2:2:end);
% % simres_q1a = simres_q1a(comp_offset_start + gmp_out_delay + (1:comp_num));
% % 
% % simres_q0b = rri1(1:2:end) + 1i*rrq1(1:2:end);
% % simres_q0b = simres_q0b(comp_offset_start + gmp_out_delay + (1:comp_num));
% % 
% % simres_q1b = rri1(2:2:end) + 1i*rrq1(2:2:end);
% % simres_q1b = simres_q1b(comp_offset_start + gmp_out_delay + (1:comp_num));
% % 
% % 
% fprintf(1, 'TX0A GMP model error is %.3f.\n', std_pwr(tar_q0a - simres_q0a.'));
% % fprintf(1, 'TX1A GMP model error is %.3f.\n', std_pwr(tar_q1a - simres_q1a.'));
% % 
% % fprintf(1, 'TX0B GMP model error is %.3f.\n', std_pwr(tar_q0b - simres_q0b.'));
% % fprintf(1, 'TX1B GMP model error is %.3f.\n', std_pwr(tar_q1b - simres_q1b.'));
% % 
% % 20*log10(1.051 / std_pwr(tar_q0b))

%% PD out A & B

tar_iout0a = res.pd0a(comp_offset_start + (1:comp_num));
tar_iout1a = res.pd1a(comp_offset_start + (1:comp_num));
tar_iout0b = res.pd0b(comp_offset_start + (1:comp_num));
tar_iout1b = res.pd1b(comp_offset_start + (1:comp_num));

dn = simdl_input_samp + simdl_addr_map + simdl_gmp + simdl_outsw;

simres_out0a = aouti(2:2:end) + 1i*aoutq(2:2:end);
simres_out1a = aouti(3:2:end) + 1i*aoutq(3:2:end);
simres_out0b = bouti(2:2:end) + 1i*boutq(2:2:end);
simres_out1b = bouti(3:2:end) + 1i*boutq(3:2:end);

simres_out0a = simres_out0a(comp_offset_start + dn + (1:comp_num));
simres_out1a = simres_out1a(comp_offset_start + dn + (1:comp_num));
simres_out0b = simres_out0b(comp_offset_start + dn + (1:comp_num));
simres_out1b = simres_out1b(comp_offset_start + dn + (1:comp_num));


fprintf(1, 'PD out 0A error is %.3f.\n', std_pwr(tar_iout0a - simres_out0a.'));
fprintf(1, 'PD out 1A error is %.3f.\n', std_pwr(tar_iout1a - simres_out1a.'));
fprintf(1, 'PD out 0B error is %.3f.\n', std_pwr(tar_iout0b - simres_out0b.'));
fprintf(1, 'PD out 1B error is %.3f.\n', std_pwr(tar_iout1b - simres_out1b.'));
