
% design tag
c_keys = {'TAG_PD_PAT_SG'};
c_values = [THIS_DATE];

% fraction bit definition
[c_keys, c_values] = put_cval(c_keys, c_values, 'FP_DEF_LUTCOEF', BIT_lut_coef);
[c_keys, c_values] = put_cval(c_keys, c_values, 'FP_DEF_ADDRSCALE', BIT_addr_scale);
[c_keys, c_values] = put_cval(c_keys, c_values, 'FP_DEF_TXGAIN', BIT_out_gain);


% special delay for GMP model
[c_keys, c_values] = put_cval(c_keys, c_values, 'ADR_DELAY_MORE0', adr_special_delay(1));
[c_keys, c_values] = put_cval(c_keys, c_values, 'ADR_DELAY_MORE1', adr_special_delay(2));
[c_keys, c_values] = put_cval(c_keys, c_values, 'ADR_DELAY_MORE2', adr_special_delay(3));
[c_keys, c_values] = put_cval(c_keys, c_values, 'ADR_DELAY_MORE3', adr_special_delay(4));
[c_keys, c_values] = put_cval(c_keys, c_values, 'ADR_DELAY_MORE4', adr_special_delay(5));
[c_keys, c_values] = put_cval(c_keys, c_values, 'ADR_DELAY_MORE5', adr_special_delay(6));
[c_keys, c_values] = put_cval(c_keys, c_values, 'ADR_DELAY_MORE6', adr_special_delay(7));

[c_keys, c_values] = put_cval(c_keys, c_values, 'SIG_DELAY_MORE0', sig_special_delay(1));
[c_keys, c_values] = put_cval(c_keys, c_values, 'SIG_DELAY_MORE1', sig_special_delay(2));
[c_keys, c_values] = put_cval(c_keys, c_values, 'SIG_DELAY_MORE2', sig_special_delay(3));
[c_keys, c_values] = put_cval(c_keys, c_values, 'SIG_DELAY_MORE3', sig_special_delay(4));
[c_keys, c_values] = put_cval(c_keys, c_values, 'SIG_DELAY_MORE4', sig_special_delay(5));
[c_keys, c_values] = put_cval(c_keys, c_values, 'SIG_DELAY_MORE5', sig_special_delay(6));
[c_keys, c_values] = put_cval(c_keys, c_values, 'SIG_DELAY_MORE6', sig_special_delay(7));

[c_keys, c_values] = put_cval(c_keys, c_values, 'SIG_DELAY_MORE6', sig_special_delay(7));


generate_c_header(c_keys, c_values);

fprintf('********\nC head generated.\n********\n');
