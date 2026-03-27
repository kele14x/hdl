foreach {inst} [get_cells -quiet -hier -filter {(ORIG_REF_NAME == phase_comp || REF_NAME == phase_comp)}] {
    set_false_path -quiet -from [get_pins -of \
        [get_cells -hier -filter "name=~$inst/i_ram/mem_reg*/RAM*"] \
        -filter {REF_PIN_NAME == CLK}] \
        -to [get_pins -of \
        [get_cells -hier -filter "name=~$inst/i_ram/regb_reg*"] \
        -filter {REF_PIN_NAME == D}]
}
