foreach {cdc_inst} [get_cells -quiet -hier -filter {(ORIG_REF_NAME == cdc_async_rst || REF_NAME == cdc_async_rst)}] {
    set_false_path -through [get_pins -of $cdc_inst -filter {REF_PIN_NAME == src_arst}]
}
