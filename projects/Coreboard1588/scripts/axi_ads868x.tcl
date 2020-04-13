
set AXI_ADS868X_REG_SOFTRESET 0x00000c00
set AXI_ADS868X_REG_POWERDOWN 0x00000c04
set AXI_ADS868X_REG_AUTOSPI   0x00000c08
set AXI_ADS868X_REG_MUXSEL    0x00000c0c
set AXI_ADS868X_REG_MUXEN     0x00000c10
set AXI_ADS868X_REG_TXBYTE    0x00000c14
set AXI_ADS868X_REG_TXDATA    0x00000c18
set AXI_ADS868X_REG_RXDATA    0x00000c1c
set AXI_ADS868X_REG_RXVALID   0x00000c20


proc axi_ads868x_softreset { } {
    global AXI_ADS868X_REG_SOFTRESET 
    create_hw_axi_txn wr_txn hw_axi_1 -address $AXI_ADS868X_REG_SOFTRESET -data 0x00000001 -type write -force
    run_hw_axi wr_txn
    create_hw_axi_txn wr_txn hw_axi_1 -address $AXI_ADS868X_REG_SOFTRESET -data 0x00000000 -type write -force
    run_hw_axi wr_txn
}

# Turn on AUTO SPI
proc axi_ads868x_autospi_on { } {
    global AXI_ADS868X_REG_AUTOSPI 
    create_hw_axi_txn wr_txn hw_axi_1 -address $AXI_ADS868X_REG_AUTOSPI -data 0x00000001 -type write -force
    run_hw_axi wr_txn
}

# Turn off AUTO SPI
proc axi_ads868x_autospi_off { } {
    global AXI_ADS868X_REG_AUTOSPI 
    create_hw_axi_txn wr_txn hw_axi_1 -address $AXI_ADS868X_REG_AUTOSPI -data 0x00000000 -type write -force
    run_hw_axi wr_txn
}

proc axi_ads868x_spi_tx { nbyte data } {
    global AXI_ADS868X_REG_TXBYTE 
	global AXI_ADS868X_REG_TXDATA
	# if { $nbyte == 1 } {
	    # set d 0x00000000
	# } elseif { $nbyte == 2 } {
		# set d 0x00000001
	# } elseif { $nbyte == 3 } {
		# set d 0x00000002
	# } elseif { $nbyte == 4 } {
		# set d 0x00000003
	# }
	create_hw_axi_txn wr_txn hw_axi_1 -address $AXI_ADS868X_REG_TXBYTE -data $nbyte -type write -force
    run_hw_axi wr_txn
    create_hw_axi_txn wr_txn hw_axi_1 -address $AXI_ADS868X_REG_TXDATA -data $data -type write -force
    run_hw_axi wr_txn
}

proc axi_ads868x_powerdown {} {
	global AXI_ADS868X_REG_POWERDOWN
	create_hw_axi_txn wr_txn hw_axi_1 -address $AXI_ADS868X_REG_POWERDOWN -data 0x00000001 -type write -force
    run_hw_axi wr_txn
}

proc axi_ads868x_powerup {} {
	global AXI_ADS868X_REG_POWERDOWN
	create_hw_axi_txn wr_txn hw_axi_1 -address $AXI_ADS868X_REG_POWERDOWN -data 0x00000000 -type write -force
    run_hw_axi wr_txn
}
