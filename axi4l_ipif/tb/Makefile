.PHONY: all clean

tb_axi4l_ipif_behav.wdb: src/axi4l_ipif.v tb/tb_axi4l_ipif.sv
	xvlog -sv src/axi4l_ipif.sv
	xvlog -sv tb/tb_axi4l_ipif.sv
	xelab --debug typical --snapshot tb_axi4l_ipif_behav --cc_type sbct --top tb_axi4l_ipif
	xsim tb_axi4l_ipif_behav --tclbatch tb/xsim_config.tcl
	xcrg --cc_db tb_axi4l_ipif_behav

all: tb_axi4l_ipif_behav.wdb

wave: tb_axi4l_ipif_behav.wdb
	xsim --gui tb_axi4l_ipif_behav.wdb

clean:
	-rm -rf .Xil
	-rm -rf xcrg_code_cov_report
	-rm -rf xsim.codeCov
	-rm -rf xsim.dir
	-rm *.jou
	-rm *.log
	-rm *.pb
	-rm *.wdb
