# Rename Auto-Derived Clocks
## MMCM 50
create_generated_clock -name A7_GCLK_fb -source [get_pins i_ccr/i_clk_wiz_50/inst/mmcm_adv_inst/CLKIN1] -master_clock [get_clocks A7_GCLK] [get_pins i_ccr/i_clk_wiz_50/inst/mmcm_adv_inst/CLKFBOUT]
create_generated_clock -name aclk -source [get_pins i_ccr/i_clk_wiz_50/inst/mmcm_adv_inst/CLKIN1] -master_clock [get_clocks A7_GCLK] [get_pins i_ccr/i_clk_wiz_50/inst/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name ext_spi_clk -source [get_pins i_ccr/i_clk_wiz_50/inst/mmcm_adv_inst/CLKIN1] -master_clock [get_clocks A7_GCLK] [get_pins i_ccr/i_clk_wiz_50/inst/mmcm_adv_inst/CLKOUT1]
## MMCM PTP
create_generated_clock -name PTP_CLK_OUT_fb -source [get_pins i_ccr/i_clk_wiz_ptp/inst/mmcm_adv_inst/CLKIN1] -master_clock [get_clocks PTP_CLK_OUT] [get_pins i_ccr/i_clk_wiz_ptp/inst/mmcm_adv_inst/CLKFBOUT]
create_generated_clock -name clk_ptp -source [get_pins i_ccr/i_clk_wiz_ptp/inst/mmcm_adv_inst/CLKIN1] -master_clock [get_clocks PTP_CLK_OUT] [get_pins i_ccr/i_clk_wiz_ptp/inst/mmcm_adv_inst/CLKOUT0]
