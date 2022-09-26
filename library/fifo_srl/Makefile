.PHONY: sim

sim:
	xvlog -sv rtl/fifo_srl.sv
	xvlog -sv tb/tb_fifo_srl.sv
	xvlog -sv ../util/srl.sv
	xelab tb_fifo_srl -cc_type -sbc -s top
	xsim top -R
	xcrg -dir ./xsim.covdb -db_name top -report_dir fc_report -report_format html
	xcrg -cc_db top -cc_fullfile -cc_report cc_report -report_format html
