#*****************************************************************************
# Helper script for Coreboard1588 Debug
#*****************************************************************************


#*****************************************************************************
# Modules
#*****************************************************************************

set AXI_TOP      0x00000000
set AXI_QUAD_SPI 0x00000400
set AXI_ADS868X  0x00000C00
set AXI_ADS124X  0x00001000


#*****************************************************************************
# Registers
#*****************************************************************************

# AXI_TOP

set AXI_TOP_PRODUCT_ID         [expr $AXI_TOP + 0x4]
set AXI_TOP_VERSION            [expr $AXI_TOP + 0x8]
set AXI_TOP_BUILD_DATE         [expr $AXI_TOP + 0xC]
set AXI_TOP_BUILD_TIME         [expr $AXI_TOP + 0x10]
set AXI_TOP_SCRATCH            [expr $AXI_TOP + 0x20]
set AXI_TOP_RTC_MODE           [expr $AXI_TOP + 0x40]
set AXI_TOP_RTC_SET_SECOND     [expr $AXI_TOP + 0x44]
set AXI_TOP_RTC_SET_NANOSECOND [expr $AXI_TOP + 0x48]
set AXI_TOP_RTC_SET            [expr $AXI_TOP + 0x4C]
set AXI_TOP_RTC_GET            [expr $AXI_TOP + 0x50]
set AXI_TOP_RTC_GET_SECOND     [expr $AXI_TOP + 0x54]
set AXI_TOP_RTC_GET_NANOSECOND [expr $AXI_TOP + 0x58]
set AXI_TOP_TRIGGER_ENABLE     [expr $AXI_TOP + 0x80]
set AXI_TOP_TRIGGER_SROUCE     [expr $AXI_TOP + 0x84]
set AXI_TOP_TRIGGER_SECOND     [expr $AXI_TOP + 0x88]
set AXI_TOP_TRIGGER_NANOSECOND [expr $AXI_TOP + 0x8C]

# AXI_ADS868X

set AXI_ADS868X_SOFTRESET [expr $AXI_ADS868X + 0x0]
set AXI_ADS868X_POWERDOWN [expr $AXI_ADS868X + 0x4]
set AXI_ADS868X_AUTOSPI   [expr $AXI_ADS868X + 0x8]
set AXI_ADS868X_MUXSEL    [expr $AXI_ADS868X + 0xC]
set AXI_ADS868X_MUXEN     [expr $AXI_ADS868X + 0x10]
set AXI_ADS868X_TXBYTE    [expr $AXI_ADS868X + 0x14]
set AXI_ADS868X_TXDATA    [expr $AXI_ADS868X + 0x18]
set AXI_ADS868X_RXDATA    [expr $AXI_ADS868X + 0x1C]
set AXI_ADS868X_RXVALID   [expr $AXI_ADS868X + 0x20]

# AXI_ADS124X

set AXI_ADS124X_SOFTRESET [expr $AXI_ADS124X + 0x0]
set AXI_ADS124X_OPMODE    [expr $AXI_ADS124X + 0x4]
set AXI_ADS124X_ADSTART   [expr $AXI_ADS124X + 0x8]
set AXI_ADS124X_ADRESET   [expr $AXI_ADS124X + 0xC]
set AXI_ADS124X_ADDRDY    [expr $AXI_ADS124X + 0x10]
set AXI_ADS124X_TXBYTE    [expr $AXI_ADS124X + 0x14]
set AXI_ADS124X_TXDATA    [expr $AXI_ADS124X + 0x18]
set AXI_ADS124X_RXDATA    [expr $AXI_ADS124X + 0x1C]
set AXI_ADS124X_TXVALID   [expr $AXI_ADS124X + 0x20]


#*****************************************************************************
# FPGA Register Access
#*****************************************************************************

proc fpga_readreg {addr} {
	set addrf [format 0x%08X $addr]
	create_hw_axi_txn rd_txn hw_axi_1 -address $addrf -type read -force
	run_hw_axi rd_txn
	set rd_report [report_hw_axi_txn rd_txn -w 32]
	# rd_report is string including read address and read data, we skip read 
	# address here, and return
	return 0x[string range $rd_report 10 18]
}

proc fpga_writereg {addr data} {
	set addrf [format 0x%08X $addr]
	set dataf [format 0x%08X $data]
	create_hw_axi_txn wr_txn hw_axi_1 -address $addrf -data $dataf -type write -force
	run_hw_axi wr_txn
}


#*****************************************************************************
# AXI_ADS868X Functions
#*****************************************************************************

proc fpga_get_id { } {
	set id [fpga_readreg $::AXI_TOP_PRODUCT_ID]
	puts $id
}

proc fpga_get_version { } {
	set version [fpga_readreg $::AXI_TOP_VERSION]
	puts $version
}

proc fpga_rtc_gettime { } {
	fpga_writereg $::AXI_TOP_RTC_GET 1
	set second [fpga_readreg $::AXI_TOP_RTC_GET_SECOND]
	set nanosecond [fpga_readreg $::AXI_TOP_RTC_GET_NANOSECOND]
	puts [format "Time is %d:%d" $second $nanosecond]
}

proc fpga_rtc_settime { second nanosecond } {
	fpga_writereg $::AXI_TOP_RTC_SET_SECOND $second
	fpga_writereg $::AXI_TOP_RTC_SET_NANOSECOND $nanosecond
	fpga_writereg $::AXI_TOP_RTC_SET 1
}

#*****************************************************************************
# AXI_ADS868X Functions
#*****************************************************************************

proc axi_ads868x_softreset { rst } {
    global AXI_ADS868X_SOFTRESET 
    fpga_writereg $AXI_ADS868X_SOFTRESET 1
    fpga_writereg $AXI_ADS868X_SOFTRESET 0
}

proc axi_ads868x_autospi { onoff } {
    global AXI_ADS868X_AUTOSPI 
    fpga_writereg $AXI_ADS868X_AUTOSPI $onoff
}

proc axi_ads868x_spisend { nbyte data } {
    global AXI_ADS868X_TXBYTE 
    global AXI_ADS868X_TXDATA
    global AXI_ADS868X_RXDATA
    fpga_writereg $AXI_ADS868X_TXBYTE [expr $nbyte - 1]
    fpga_writereg $AXI_ADS868X_TXDATA $data
    after 1 fpga_readreg $AXI_ADS868X_RXDATA
}

proc axi_ads868x_powerdown { powerdown } {
	global AXI_ADS868X_POWERDOWN
	fpga_writereg $AXI_ADS868X_POWERDOWN $powerdown
}


#*****************************************************************************
# AXI_ADS124X Functions
#*****************************************************************************

proc axi_ads124x_softreset { } {
	global AXI_ADS124X_SOFTRESET
	fpga_writereg $AXI_ADS124X_SOFTRESET 1
	fpga_writereg $AXI_ADS124X_SOFTRESET 0
}

proc axi_ads124x_automode { } {
	global AXI_ADS124X_OPMODE
	fpga_writereg $AXI_ADS124X_OPMODE 1
}

proc axi_ads124x_manualmode { } {
	global AXI_ADS124X_OPMODE
	fpga_writereg $AXI_ADS124X_OPMODE 0
}

proc axi_ads124x_start { val } {
	global AXI_ADS124X_ADSTART
	fpga_writereg $AXI_ADS124X_ADSTART $val
}

proc axi_ads124x_reset { val } {
	global AXI_ADS124X_ADRESET
	fpga_writereg $AXI_ADS124X_ADRESET $val
}

proc axi_ads124x_drdy { } {
	global AXI_ADS124X_ADDRDY
	fpga_readreg $AXI_ADS124X_ADDRDY
} 

proc axi_ads124x_spisend { nbyte data } {
	global AXI_ADS124X_TXBYTE
	global AXI_ADS124X_TXDATA
	global AXI_ADS124X_RXDATA
	fpga_writereg $AXI_ADS124X_TXBYTE [expr $nbyte - 1]
	fpga_writereg $AXI_ADS124X_TXDATA $data
	after 1 fpga_readreg $AXI_ADS124X_RXDATA
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

# EOF
