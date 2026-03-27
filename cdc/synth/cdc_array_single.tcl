foreach {cdc_inst} [get_cells -quiet -hier -filter {(ORIG_REF_NAME == cdc_array_single || REF_NAME == cdc_array_single)}] {
    set src_clk [get_clocks -quiet -of [get_pins -of $cdc_inst -filter {REF_PIN_NAME == src_clk}]]
    set dest_clk [get_clocks -quiet -of [get_pins -of $cdc_inst -filter {REF_PIN_NAME == dest_clk}]]

    set src_clk_period [get_property -quiet -min PERIOD $src_clk]
    set dest_clk_period [get_property -quiet -min PERIOD $dest_clk]

    if {$src_clk_period == ""} {
        set src_clk_period 1000
    }

    if {$dest_clk_period == ""} {
        set dest_clk_period 1001
    }

    if {$src_clk != $dest_clk || ($src_clk == "" && $dest_clk == "")} {
        # set_max_delay -from [get_cells -quiet -hier src_ff_reg* -filter "PARENT == $cdc_inst"] -to [get_cells -quiet -hier syncstages_ff_reg[0]* -filter "PARENT == $cdc_inst"] [expr min ($src_clk_period, $dest_clk_period)] -datapath_only
        # set_bus_skew  -from [get_cells -quiet -hier src_ff_reg* -filter "PARENT == $cdc_inst"] -to [get_cells -quiet -hier syncstages_ff_reg[0][*] -filter "PARENT == $cdc_inst"] [expr min ($src_clk_period, $dest_clk_period)]
        set_false_path -to [get_cells -quiet -hier syncstages_ff_reg[0]* -filter "PARENT == $cdc_inst"]
    }
}
