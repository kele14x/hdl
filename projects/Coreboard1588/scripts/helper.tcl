


#*****************************************************************************
# FPGA Register Access
#*****************************************************************************

proc fpga_readreg {addr} {
	set addrf [format 0x%08X $addr]
	create_hw_axi_txn rd_txn hw_axi_1 -address $addrf -type read -force
	run_hw_axi rd_txn
}

proc fpga_writereg {addr data} {
	set addrf [format 0x%08X $addr]
	set dataf [format 0x%08X $data]
	create_hw_axi_txn wr_txn hw_axi_1 -address $addrf -data $dataf -type write -force
	run_hw_axi wr_txn
}

#*****************************************************************************
# FPGA Register Access
#*****************************************************************************


set AXI_ADS124X_REG 0x00001000

set AXI_ADS124X_REG_SOFTRESET [expr $AXI_ADS124X_REG + 0x0]
set AXI_ADS124X_REG_OPMODE    [expr $AXI_ADS124X_REG + 0x4]
set AXI_ADS124X_REG_ADSTART   [expr $AXI_ADS124X_REG + 0x8]
set AXI_ADS124X_REG_ADRESET   [expr $AXI_ADS124X_REG + 0xC]
set AXI_ADS124X_REG_ADDRDY    [expr $AXI_ADS124X_REG + 0x10]
set AXI_ADS124X_REG_TXBYTE    [expr $AXI_ADS124X_REG + 0x14]
set AXI_ADS124X_REG_TXDATA    [expr $AXI_ADS124X_REG + 0x18]
set AXI_ADS124X_REG_RXDATA    [expr $AXI_ADS124X_REG + 0x1C]
set AXI_ADS124X_REG_TXVALID   [expr $AXI_ADS124X_REG + 0x20]

proc axi_ads124x_softreset { } {
	global AXI_ADS124X_REG_SOFTRESET
	fpga_writereg $AXI_ADS124X_REG_SOFTRESET 1
	fpga_writereg $AXI_ADS124X_REG_SOFTRESET 0
}

proc axi_ads124x_automode { } {
	global AXI_ADS124X_REG_OPMODE
	fpga_writereg $AXI_ADS124X_REG_OPMODE 1
}

proc axi_ads124x_manualmode { } {
	global AXI_ADS124X_REG_OPMODE
	fpga_writereg $AXI_ADS124X_REG_OPMODE 0
}

proc axi_ads124x_start { val } {
	global AXI_ADS124X_REG_ADSTART
	fpga_writereg $AXI_ADS124X_REG_ADSTART $val
}

proc axi_ads124x_reset { val } {
	global AXI_ADS124X_REG_ADRESET
	fpga_writereg $AXI_ADS124X_REG_ADRESET $val
}

proc axi_ads124x_drdy { } {
	global AXI_ADS124X_REG_ADDRDY
	fpga_readreg $AXI_ADS124X_REG_ADDRDY
} 

proc axi_ads124x_spisend { nbyte data } {
	global AXI_ADS124X_REG_TXBYTE
	global AXI_ADS124X_REG_TXDATA
	global AXI_ADS124X_REG_RXDATA
	fpga_writereg $AXI_ADS124X_REG_TXBYTE [expr $nbyte - 1]
	fpga_writereg $AXI_ADS124X_REG_TXDATA $data
	after 1 fpga_readreg $AXI_ADS124X_REG_RXDATA
}

proc axi_ads124x_getdata { } {
	axi_ads124x_spisend 3 0xFFFFFF
}

proc axi_ads124x_readreg {addr} {
	set spi_word [expr 0x2000FF | ($addr << 16)]
	axi_ads124x_spisend 3 $spi_word
}

proc axi_ads124x_writereg {addr data} {
	set spi_word [expr 0x400000 | ($addr << 16) | $data]
	axi_ads124x_spisend 3 $spi_word
}



#*****************************************************************************
# FPGA Register Access
#*****************************************************************************


set AXI_ADS868X_REG 0x00000C00

set AXI_ADS868X_REG_SOFTRESET [expr $AXI_ADS868X_REG + 0x0]
set AXI_ADS868X_REG_POWERDOWN [expr $AXI_ADS868X_REG + 0x4]
set AXI_ADS868X_REG_AUTOSPI   [expr $AXI_ADS868X_REG + 0x8]
set AXI_ADS868X_REG_MUXSEL    [expr $AXI_ADS868X_REG + 0xC]
set AXI_ADS868X_REG_MUXEN     [expr $AXI_ADS868X_REG + 0x10]
set AXI_ADS868X_REG_TXBYTE    [expr $AXI_ADS868X_REG + 0x14]
set AXI_ADS868X_REG_TXDATA    [expr $AXI_ADS868X_REG + 0x18]
set AXI_ADS868X_REG_RXDATA    [expr $AXI_ADS868X_REG + 0x1C]
set AXI_ADS868X_REG_RXVALID   [expr $AXI_ADS868X_REG + 0x20]


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
