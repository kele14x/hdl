foreach {cdc_inst} [get_cells -quiet -hier -filter {(ORIG_REF_NAME == cdc_sync_rst || REF_NAME == cdc_sync_rst)}] {
    set_false_path -to [get_cells -quiet -hier syncstages_ff_reg[0]* -filter "PARENT == $cdc_inst"]
}
