-------------------------------------------------------------------
-- System Generator version 2020.2 VHDL source file.
--
-- Copyright(C) 2020 by Xilinx, Inc.  All rights reserved.  This
-- text/file contains proprietary, confidential information of Xilinx,
-- Inc., is distributed under license from Xilinx, Inc., and may be used,
-- copied and/or disclosed only pursuant to the terms of a valid license
-- agreement with Xilinx, Inc.  Xilinx hereby grants you a license to use
-- this text/file solely for design, simulation, implementation and
-- creation of design files limited to Xilinx devices or technologies.
-- Use with non-Xilinx devices or technologies is expressly prohibited
-- and immediately terminates your license unless covered by a separate
-- agreement.
--
-- Xilinx is providing this design, code, or information "as is" solely
-- for use in developing programs and solutions for Xilinx devices.  By
-- providing this design, code, or information as one possible
-- implementation of this feature, application or standard, Xilinx is
-- making no representation that this implementation is free from any
-- claims of infringement.  You are responsible for obtaining any rights
-- you may require for your implementation.  Xilinx expressly disclaims
-- any warranty whatsoever with respect to the adequacy of the
-- implementation, including but not limited to warranties of
-- merchantability or fitness for a particular purpose.
--
-- Xilinx products are not intended for use in life support appliances,
-- devices, or systems.  Use in such applications is expressly prohibited.
--
-- Any modifications that are made to the source code are done at the user's
-- sole risk and will be unsupported.
--
-- This copyright and support notice must be retained as part of this
-- text at all times.  (c) Copyright 1995-2020 Xilinx, Inc.  All rights
-- reserved.
-------------------------------------------------------------------

library work;
use work.conv_pkg.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity sysgen_concat_98da57e59d is
  port (
    in0 : in std_logic_vector((32 - 1) downto 0);
    in1 : in std_logic_vector((32 - 1) downto 0);
    y : out std_logic_vector((64 - 1) downto 0);
    clk : in std_logic;
    ce : in std_logic;
    clr : in std_logic);
end sysgen_concat_98da57e59d;
architecture behavior of sysgen_concat_98da57e59d
is
  signal in0_1_23: unsigned((32 - 1) downto 0);
  signal in1_1_27: unsigned((32 - 1) downto 0);
  signal y_2_1_concat: unsigned((64 - 1) downto 0);
begin
  in0_1_23 <= std_logic_vector_to_unsigned(in0);
  in1_1_27 <= std_logic_vector_to_unsigned(in1);
  y_2_1_concat <= std_logic_vector_to_unsigned(unsigned_to_std_logic_vector(in0_1_23) & unsigned_to_std_logic_vector(in1_1_27));
  y <= unsigned_to_std_logic_vector(y_2_1_concat);
end behavior;

library work;
use work.conv_pkg.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity sysgen_concat_8587dcc071 is
  port (
    in0 : in std_logic_vector((1 - 1) downto 0);
    in1 : in std_logic_vector((11 - 1) downto 0);
    y : out std_logic_vector((12 - 1) downto 0);
    clk : in std_logic;
    ce : in std_logic;
    clr : in std_logic);
end sysgen_concat_8587dcc071;
architecture behavior of sysgen_concat_8587dcc071
is
  signal in0_1_23: boolean;
  signal in1_1_27: unsigned((11 - 1) downto 0);
  signal y_2_1_concat: unsigned((12 - 1) downto 0);
begin
  in0_1_23 <= ((in0) = "1");
  in1_1_27 <= std_logic_vector_to_unsigned(in1);
  y_2_1_concat <= std_logic_vector_to_unsigned(boolean_to_vector(in0_1_23) & unsigned_to_std_logic_vector(in1_1_27));
  y <= unsigned_to_std_logic_vector(y_2_1_concat);
end behavior;

library work;
use work.conv_pkg.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity sysgen_concat_4a48bd946a is
  port (
    in0 : in std_logic_vector((1 - 1) downto 0);
    in1 : in std_logic_vector((11 - 1) downto 0);
    y : out std_logic_vector((12 - 1) downto 0);
    clk : in std_logic;
    ce : in std_logic;
    clr : in std_logic);
end sysgen_concat_4a48bd946a;
architecture behavior of sysgen_concat_4a48bd946a
is
  signal in0_1_23: unsigned((1 - 1) downto 0);
  signal in1_1_27: unsigned((11 - 1) downto 0);
  signal y_2_1_concat: unsigned((12 - 1) downto 0);
begin
  in0_1_23 <= std_logic_vector_to_unsigned(in0);
  in1_1_27 <= std_logic_vector_to_unsigned(in1);
  y_2_1_concat <= std_logic_vector_to_unsigned(unsigned_to_std_logic_vector(in0_1_23) & unsigned_to_std_logic_vector(in1_1_27));
  y <= unsigned_to_std_logic_vector(y_2_1_concat);
end behavior;

library work;
use work.conv_pkg.all;

--$Header: /devl/xcs/repo/env/Jobs/sysgen/src/xbs/blocks/xlconvert/hdl/xlconvert.vhd,v 1.1 2004/11/22 00:17:30 rosty Exp $
---------------------------------------------------------------------
--
--  Filename      : xlconvert.vhd
--
--  Description   : VHDL description of a fixed point converter block that
--                  converts the input to a new output type.

--
---------------------------------------------------------------------


---------------------------------------------------------------------
--
--  Entity        : xlconvert
--
--  Architecture  : behavior
--
--  Description   : Top level VHDL description of fixed point conver block.
--
---------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;


entity convert_func_call_dl_adaptor_data_xlconvert is
    generic (
        din_width    : integer := 16;            -- Width of input
        din_bin_pt   : integer := 4;             -- Binary point of input
        din_arith    : integer := xlUnsigned;    -- Type of arith of input
        dout_width   : integer := 8;             -- Width of output
        dout_bin_pt  : integer := 2;             -- Binary point of output
        dout_arith   : integer := xlUnsigned;    -- Type of arith of output
        quantization : integer := xlTruncate;    -- xlRound or xlTruncate
        overflow     : integer := xlWrap);       -- xlSaturate or xlWrap
    port (
        din : in std_logic_vector (din_width-1 downto 0);
        result : out std_logic_vector (dout_width-1 downto 0));
end convert_func_call_dl_adaptor_data_xlconvert ;

architecture behavior of convert_func_call_dl_adaptor_data_xlconvert is
begin
    -- Convert to output type and do saturation arith.
    result <= convert_type(din, din_width, din_bin_pt, din_arith,
                           dout_width, dout_bin_pt, dout_arith,
                           quantization, overflow);
end behavior;


library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;


entity dl_adaptor_data_xlconvert  is
    generic (
        din_width    : integer := 16;            -- Width of input
        din_bin_pt   : integer := 4;             -- Binary point of input
        din_arith    : integer := xlUnsigned;    -- Type of arith of input
        dout_width   : integer := 8;             -- Width of output
        dout_bin_pt  : integer := 2;             -- Binary point of output
        dout_arith   : integer := xlUnsigned;    -- Type of arith of output
        en_width     : integer := 1;
        en_bin_pt    : integer := 0;
        en_arith     : integer := xlUnsigned;
        bool_conversion : integer :=0;           -- if one, convert ufix_1_0 to
                                                 -- bool
        latency      : integer := 0;             -- Ouput delay clk cycles
        quantization : integer := xlTruncate;    -- xlRound or xlTruncate
        overflow     : integer := xlWrap);       -- xlSaturate or xlWrap
    port (
        din : in std_logic_vector (din_width-1 downto 0);
        en  : in std_logic_vector (en_width-1 downto 0);
        ce  : in std_logic;
        clr : in std_logic;
        clk : in std_logic;
        dout : out std_logic_vector (dout_width-1 downto 0));

end dl_adaptor_data_xlconvert ;

architecture behavior of dl_adaptor_data_xlconvert  is

    component synth_reg
        generic (width       : integer;
                 latency     : integer);
        port (i       : in std_logic_vector(width-1 downto 0);
              ce      : in std_logic;
              clr     : in std_logic;
              clk     : in std_logic;
              o       : out std_logic_vector(width-1 downto 0));
    end component;

    component convert_func_call_dl_adaptor_data_xlconvert 
        generic (
            din_width    : integer := 16;            -- Width of input
            din_bin_pt   : integer := 4;             -- Binary point of input
            din_arith    : integer := xlUnsigned;    -- Type of arith of input
            dout_width   : integer := 8;             -- Width of output
            dout_bin_pt  : integer := 2;             -- Binary point of output
            dout_arith   : integer := xlUnsigned;    -- Type of arith of output
            quantization : integer := xlTruncate;    -- xlRound or xlTruncate
            overflow     : integer := xlWrap);       -- xlSaturate or xlWrap
        port (
            din : in std_logic_vector (din_width-1 downto 0);
            result : out std_logic_vector (dout_width-1 downto 0));
    end component;


    -- synthesis translate_off
--    signal real_din, real_dout : real;    -- For debugging info ports
    -- synthesis translate_on
    signal result : std_logic_vector(dout_width-1 downto 0);
    signal internal_ce : std_logic;

begin

    -- Debugging info for internal full precision variables
    -- synthesis translate_off
--     real_din <= to_real(din, din_bin_pt, din_arith);
--     real_dout <= to_real(dout, dout_bin_pt, dout_arith);
    -- synthesis translate_on

    internal_ce <= ce and en(0);

    bool_conversion_generate : if (bool_conversion = 1)
    generate
      result <= din;
    end generate; --bool_conversion_generate

    std_conversion_generate : if (bool_conversion = 0)
    generate
      -- Workaround for XST bug
      convert : convert_func_call_dl_adaptor_data_xlconvert 
        generic map (
          din_width   => din_width,
          din_bin_pt  => din_bin_pt,
          din_arith   => din_arith,
          dout_width  => dout_width,
          dout_bin_pt => dout_bin_pt,
          dout_arith  => dout_arith,
          quantization => quantization,
          overflow     => overflow)
        port map (
          din => din,
          result => result);
    end generate; --std_conversion_generate

    latency_test : if (latency > 0) generate
        reg : synth_reg
            generic map (
              width => dout_width,
              latency => latency
            )
            port map (
              i => result,
              ce => internal_ce,
              clr => clr,
              clk => clk,
              o => dout
            );
    end generate;

    latency0 : if (latency = 0)
    generate
        dout <= result;
    end generate latency0;

end  behavior;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all ; 
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity dl_adaptor_data_xltdpram is
   generic(width_addr        : integer := -1;
           width             : integer := -1;
           addr_width_b      : integer := -1;
           data_width_b      : integer := -1;
           mem_size          : integer := 0;
           write_mode_a      : string := "no_change";
           write_mode_b      : string := "no_change";
           mem_init_file     : string := "none";
           mem_type          : string := "auto";
           clocking_mode     : string  := "common_clock";
           read_reset_a    : string  := "0";
           read_reset_b    : string  := "0";
           latency           : integer := 0);
   port(dina: in std_logic_vector(width-1 downto 0);
        addra: in std_logic_vector(width_addr-1 downto 0);
        wea: in std_logic_vector(0 downto 0);
        ena: in std_logic_vector(0 downto 0);
        rsta: in std_logic_vector(0 downto 0);
        a_ce: in std_logic;
        a_clk: in std_logic;
        douta: out std_logic_vector(width-1 downto 0);
        dinb: in std_logic_vector(data_width_b-1 downto 0);
        addrb: in std_logic_vector(addr_width_b-1 downto 0);
        web: in std_logic_vector(0 downto 0);
        enb: in std_logic_vector(0 downto 0);
        rstb: in std_logic_vector(0 downto 0);
        b_ce: in std_logic;
        b_clk: in std_logic;
        doutb: out std_logic_vector(data_width_b-1 downto 0)
);

end dl_adaptor_data_xltdpram;

architecture behavior of dl_adaptor_data_xltdpram is

-- signal b_en: std_logic_vector(0 downto 0);
-- signal a_en: std_logic_vector(0 downto 0);
-- signal a_rst: std_logic_vector(0 downto 0);
-- signal b_rst: std_logic_vector(0 downto 0);
-- signal a_we: std_logic_vector(0 downto 0);
-- signal b_we: std_logic_vector(0 downto 0);
signal  buf_clk          : std_logic;
signal  buf_ena          : std_logic;
signal  buf_wea          : std_logic_vector(0 downto 0);
signal  buf_addra        : std_logic_vector(22 downto 0);
signal  buf_dina         : std_logic_vector(71 downto 0);
signal  buf_douta        : std_logic_vector(71 downto 0);
signal  buf_bwea         : std_logic_vector(8 downto 0);
signal  buf_enb          : std_logic;
signal  buf_web          : std_logic_vector(0 downto 0);
signal  buf_addrb        : std_logic_vector(22 downto 0);
signal  buf_dinb         : std_logic_vector(71 downto 0);
signal  buf_doutb        : std_logic_vector(71 downto 0);
signal  buf_bweb         : std_logic_vector(8 downto 0);

begin
    buf_clk      <=  a_clk;
    buf_ena      <=  '1';
    buf_wea      <=  wea;
    buf_addra    <=  "00000000000" & addra;
    buf_dina     <=  "00000000" & dina;
    buf_bwea     <=  "000001111" when (enb="0" and ena="0") else "011110000" when (enb="0" and ena="1") else "011111111";
    buf_enb      <=  '1';
    buf_web      <=  "0" when (enb="0") else web;
    buf_addrb    <=  "00000000000" & addrb;
    buf_dinb     <=  "00000000" & dinb;
    buf_bweb    <=  "011111111";
    douta       <= buf_douta(63 downto 0);
    doutb       <= buf_doutb(63 downto 0);
    
-- b_en(0) <= enb(0) and b_ce;
-- a_en(0) <= ena(0) and a_ce;
-- b_rst(0) <= rstb(0) and b_ce;
-- a_rst(0) <= rsta(0) and a_ce;
-- b_we(0) <= web(0) and b_ce;
-- a_we(0) <= wea(0) and a_ce;

 -- xpm_memory_tdpram_inst : xpm_memory_tdpram

-- generic map (
   -- -- Common module generics
     -- MEMORY_SIZE        => mem_size,        --positive integer
     -- MEMORY_PRIMITIVE   => mem_type,
     -- MEMORY_INIT_FILE   => mem_init_file,
     -- CLOCKING_MODE      => clocking_mode,
     -- MEMORY_INIT_PARAM  => "",
     -- USE_MEM_INIT       => 1,
     -- WAKEUP_TIME        => "disable_sleep",
     -- MESSAGE_CONTROL    => 0,

     -- -- Port A module generics
     -- WRITE_DATA_WIDTH_A => width,
     -- READ_DATA_WIDTH_A  => width,
     -- BYTE_WRITE_WIDTH_A => width,
     -- ADDR_WIDTH_A       => width_addr,
     -- READ_RESET_VALUE_A => read_reset_a,
     -- READ_LATENCY_A     => latency,
     -- WRITE_MODE_A       => write_mode_a,
     -- -- Port A module generics
     -- WRITE_DATA_WIDTH_B => data_width_b,
     -- READ_DATA_WIDTH_B  => data_width_b,
     -- BYTE_WRITE_WIDTH_B => data_width_b,
     -- ADDR_WIDTH_B       => addr_width_b,
     -- READ_RESET_VALUE_B => read_reset_b,
     -- READ_LATENCY_B     => latency,
     -- WRITE_MODE_B       => write_mode_b
 -- )
 -- port map (
     -- -- Common module ports
     -- sleep          =>  '0',
     -- -- Port A module ports
     -- clka           =>  a_clk,
     -- rsta           =>  a_rst(0),
     -- ena            =>  a_en(0),
     -- regcea         =>  a_ce,
	  -- wea            =>  a_we,
	  -- addra          =>  addra,
	  -- dina           =>  dina,
	  -- injectsbiterra =>  '0',  --do not change
	  -- injectdbiterra =>  '0',  --do not change
	  -- douta          =>  douta,
	  -- sbiterra       =>  open, --do not change
	  -- dbiterra       =>  open,  --do not change
 
     -- -- Port B module ports
     -- clkb           =>  b_clk,
     -- rstb           =>  b_rst(0),
     -- enb            =>  b_en(0),
     -- regceb         =>  b_ce,
	  -- web            =>  b_we,
	  -- addrb          =>  addrb,
	  -- dinb           =>  dinb,
	  -- injectsbiterrb =>  '0',  --do not change
	  -- injectdbiterrb =>  '0',  --do not change
	  -- doutb          =>  doutb,
	  -- sbiterrb       =>  open, --do not change
	  -- dbiterrb       =>  open  --do not change
-- );
URAM288_inst0 : URAM288
generic map (
    AUTO_SLEEP_LATENCY            => 8,                   
    AVG_CONS_INACTIVE_CYCLES      => 10,                  
    BWE_MODE_A                    => "PARITY_INTERLEAVED",
    BWE_MODE_B                    => "PARITY_INTERLEAVED",
    CASCADE_ORDER_A               => "NONE",             
    CASCADE_ORDER_B               => "NONE",             
    EN_AUTO_SLEEP_MODE            => "FALSE",             
    EN_ECC_RD_A                   => "FALSE",             
    EN_ECC_RD_B                   => "FALSE",             
    EN_ECC_WR_A                   => "FALSE",             
    EN_ECC_WR_B                   => "FALSE",             
    IREG_PRE_A                    => "FALSE",              
    IREG_PRE_B                    => "FALSE",              
    IS_CLK_INVERTED               => '0',                 
    IS_EN_A_INVERTED              => '0',                 
    IS_EN_B_INVERTED              => '0',                 
    IS_RDB_WR_A_INVERTED          => '0',                 
    IS_RDB_WR_B_INVERTED          => '0',                 
    IS_RST_A_INVERTED             => '0',                 
    IS_RST_B_INVERTED             => '0',                 
    MATRIX_ID                     => "NONE",            
    NUM_UNIQUE_SELF_ADDR_A        => 1,                   
    NUM_UNIQUE_SELF_ADDR_B        => 1,                   
    NUM_URAM_IN_MATRIX            => 1,                   
    OREG_A                        => "TRUE",              
    OREG_B                        => "TRUE",              
    OREG_ECC_A                    => "FALSE",              
    OREG_ECC_B                    => "FALSE",              
    REG_CAS_A                     => "FALSE",              
    REG_CAS_B                     => "FALSE",              
    RST_MODE_A                    => "SYNC",              
    RST_MODE_B                    => "SYNC",              
    SELF_ADDR_A                   => "000"&X"00",         
    SELF_ADDR_B                   => "000"&X"00",         
    SELF_MASK_A                   => "111"&X"ff",         
    SELF_MASK_B                   => "111"&X"ff",         
    USE_EXT_CE_A                  => "FALSE",             
    USE_EXT_CE_B                  => "FALSE"              
)
port map (
    CAS_OUT_ADDR_A        => open, 
    CAS_OUT_ADDR_B        => open, 
    CAS_OUT_BWE_A         => open, 
    CAS_OUT_BWE_B         => open, 
    CAS_OUT_DBITERR_A     => open, 
    CAS_OUT_DBITERR_B     => open, 
    CAS_OUT_DIN_A         => open, 
    CAS_OUT_DIN_B         => open, 
    CAS_OUT_DOUT_A        => open, 
    CAS_OUT_DOUT_B        => open, 
    CAS_OUT_EN_A          => open, 
    CAS_OUT_EN_B          => open, 
    CAS_OUT_RDACCESS_A    => open, 
    CAS_OUT_RDACCESS_B    => open, 
    CAS_OUT_RDB_WR_A      => open, 
    CAS_OUT_RDB_WR_B      => open, 
    CAS_OUT_SBITERR_A     => open, 
    CAS_OUT_SBITERR_B     => open, 
    DBITERR_A             => open,                        
    DBITERR_B             => open,                        
    DOUT_A                => buf_douta,                        
    DOUT_B                => buf_doutb,                        
    RDACCESS_A            => open,                        
    RDACCESS_B            => open,                        
    SBITERR_A             => open,                        
    SBITERR_B             => open,                        
    ADDR_A                => buf_addra,                   
    ADDR_B                => buf_addrb,                   
    BWE_A                 => buf_bwea,                
    BWE_B                 => buf_bweb,                 
    CAS_IN_ADDR_A         => (others=>'0'),               
    CAS_IN_ADDR_B         => (others=>'0'),               
    CAS_IN_BWE_A          => (others=>'0'),               
    CAS_IN_BWE_B          => (others=>'0'),               
    CAS_IN_DBITERR_A      => '0'          ,               
    CAS_IN_DBITERR_B      => '0'          ,               
    CAS_IN_DIN_A          => (others=>'0'),               
    CAS_IN_DIN_B          => (others=>'0'),               
    CAS_IN_DOUT_A         => (others=>'0'),               
    CAS_IN_DOUT_B         => (others=>'0'),               
    CAS_IN_EN_A           => '0'          ,               
    CAS_IN_EN_B           => '0'          ,               
    CAS_IN_RDACCESS_A     => '0'          ,               
    CAS_IN_RDACCESS_B     => '0'          ,               
    CAS_IN_RDB_WR_A       => '0'          ,               
    CAS_IN_RDB_WR_B       => '0'          ,               
    CAS_IN_SBITERR_A      => '0'          ,               
    CAS_IN_SBITERR_B      => '0'          ,               
    CLK                   => buf_clk,                     
    DIN_A                 => buf_dina,                    
    DIN_B                 => buf_dinb,               
    EN_A                  => buf_ena,                     
    EN_B                  => buf_enb,                     
    INJECT_DBITERR_A      => '0',                         
    INJECT_DBITERR_B      => '0',                         
    INJECT_SBITERR_A      => '0',                         
    INJECT_SBITERR_B      => '0',                         
    OREG_CE_A             => '1',                         
    OREG_CE_B             => '1',                         
    OREG_ECC_CE_A         => '1',                         
    OREG_ECC_CE_B         => '1',                         
    RDB_WR_A              => buf_wea(0),                  
    RDB_WR_B              => buf_web(0),                        
    RST_A                 => '0',                          
    RST_B                 => '0',                         
    SLEEP                 => '0'                          
);
end behavior;
library work;
use work.conv_pkg.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity sysgen_inverter_38e6051e94 is
  port (
    ip : in std_logic_vector((1 - 1) downto 0);
    op : out std_logic_vector((1 - 1) downto 0);
    clk : in std_logic;
    ce : in std_logic;
    clr : in std_logic);
end sysgen_inverter_38e6051e94;
architecture behavior of sysgen_inverter_38e6051e94
is
  signal ip_1_26: boolean;
  type array_type_op_mem_22_20 is array (0 to (1 - 1)) of boolean;
  signal op_mem_22_20: array_type_op_mem_22_20 := (
    0 => false);
  signal op_mem_22_20_front_din: boolean;
  signal op_mem_22_20_back: boolean;
  signal op_mem_22_20_push_front_pop_back_en: std_logic;
  signal internal_ip_12_1_bitnot: boolean;
begin
  ip_1_26 <= ((ip) = "1");
  op_mem_22_20_back <= op_mem_22_20(0);
  proc_op_mem_22_20: process (clk)
  is
    variable i: integer;
  begin
    if (clk'event and (clk = '1')) then
      if ((ce = '1') and (op_mem_22_20_push_front_pop_back_en = '1')) then
        op_mem_22_20(0) <= op_mem_22_20_front_din;
      end if;
    end if;
  end process proc_op_mem_22_20;
  internal_ip_12_1_bitnot <= ((not boolean_to_vector(ip_1_26)) = "1");
  op_mem_22_20_push_front_pop_back_en <= '0';
  op <= boolean_to_vector(internal_ip_12_1_bitnot);
end behavior;

library work;
use work.conv_pkg.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity sysgen_inverter_263288122f is
  port (
    ip : in std_logic_vector((1 - 1) downto 0);
    op : out std_logic_vector((1 - 1) downto 0);
    clk : in std_logic;
    ce : in std_logic;
    clr : in std_logic);
end sysgen_inverter_263288122f;
architecture behavior of sysgen_inverter_263288122f
is
  signal ip_1_26: boolean;
  type array_type_op_mem_22_20 is array (0 to (1 - 1)) of boolean;
  signal op_mem_22_20: array_type_op_mem_22_20 := (
    0 => false);
  signal op_mem_22_20_front_din: boolean;
  signal op_mem_22_20_back: boolean;
  signal op_mem_22_20_push_front_pop_back_en: std_logic;
  signal internal_ip_12_1_bitnot: boolean;
begin
  ip_1_26 <= ((ip) = "1");
  op_mem_22_20_back <= op_mem_22_20(0);
  proc_op_mem_22_20: process (clk)
  is
    variable i: integer;
  begin
    if (clk'event and (clk = '1')) then
      if ((ce = '1') and (op_mem_22_20_push_front_pop_back_en = '1')) then
        op_mem_22_20(0) <= op_mem_22_20_front_din;
      end if;
    end if;
  end process proc_op_mem_22_20;
  internal_ip_12_1_bitnot <= ((not boolean_to_vector(ip_1_26)) = "1");
  op_mem_22_20_front_din <= internal_ip_12_1_bitnot;
  op_mem_22_20_push_front_pop_back_en <= '1';
  op <= boolean_to_vector(op_mem_22_20_back);
end behavior;

library work;
use work.conv_pkg.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity sysgen_logical_41cf778f30 is
  port (
    d0 : in std_logic_vector((1 - 1) downto 0);
    d1 : in std_logic_vector((1 - 1) downto 0);
    y : out std_logic_vector((1 - 1) downto 0);
    clk : in std_logic;
    ce : in std_logic;
    clr : in std_logic);
end sysgen_logical_41cf778f30;
architecture behavior of sysgen_logical_41cf778f30
is
  signal d0_1_24: std_logic;
  signal d1_1_27: std_logic;
  signal fully_2_1_bit: std_logic;
begin
  d0_1_24 <= d0(0);
  d1_1_27 <= d1(0);
  fully_2_1_bit <= d0_1_24 or d1_1_27;
  y <= std_logic_to_vector(fully_2_1_bit);
end behavior;

library work;
use work.conv_pkg.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity sysgen_mux_a1fa2a1f98 is
  port (
    sel : in std_logic_vector((1 - 1) downto 0);
    d0 : in std_logic_vector((32 - 1) downto 0);
    d1 : in std_logic_vector((32 - 1) downto 0);
    y : out std_logic_vector((32 - 1) downto 0);
    clk : in std_logic;
    ce : in std_logic;
    clr : in std_logic);
end sysgen_mux_a1fa2a1f98;
architecture behavior of sysgen_mux_a1fa2a1f98
is
  signal sel_1_20: std_logic;
  signal d0_1_24: std_logic_vector((32 - 1) downto 0);
  signal d1_1_27: std_logic_vector((32 - 1) downto 0);
  signal sel_internal_2_1_convert: std_logic_vector((1 - 1) downto 0);
  signal unregy_join_6_1: std_logic_vector((32 - 1) downto 0);
begin
  sel_1_20 <= sel(0);
  d0_1_24 <= d0;
  d1_1_27 <= d1;
  sel_internal_2_1_convert <= cast(std_logic_to_vector(sel_1_20), 0, 1, 0, xlUnsigned);
  proc_switch_6_1: process (d0_1_24, d1_1_27, sel_internal_2_1_convert)
  is
  begin
    case sel_internal_2_1_convert is 
      when "0" =>
        unregy_join_6_1 <= d0_1_24;
      when others =>
        unregy_join_6_1 <= d1_1_27;
    end case;
  end process proc_switch_6_1;
  y <= unregy_join_6_1;
end behavior;

library work;
use work.conv_pkg.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity sysgen_mux_3c72f0c869 is
  port (
    sel : in std_logic_vector((1 - 1) downto 0);
    d0 : in std_logic_vector((64 - 1) downto 0);
    d1 : in std_logic_vector((64 - 1) downto 0);
    y : out std_logic_vector((64 - 1) downto 0);
    clk : in std_logic;
    ce : in std_logic;
    clr : in std_logic);
end sysgen_mux_3c72f0c869;
architecture behavior of sysgen_mux_3c72f0c869
is
  signal sel_1_20: std_logic_vector((1 - 1) downto 0);
  signal d0_1_24: std_logic_vector((64 - 1) downto 0);
  signal d1_1_27: std_logic_vector((64 - 1) downto 0);
  signal unregy_join_6_1: std_logic_vector((64 - 1) downto 0);
begin
  sel_1_20 <= sel;
  d0_1_24 <= d0;
  d1_1_27 <= d1;
  proc_switch_6_1: process (d0_1_24, d1_1_27, sel_1_20)
  is
  begin
    case sel_1_20 is 
      when "0" =>
        unregy_join_6_1 <= d0_1_24;
      when others =>
        unregy_join_6_1 <= d1_1_27;
    end case;
  end process proc_switch_6_1;
  y <= unregy_join_6_1;
end behavior;

library work;
use work.conv_pkg.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity sysgen_mux_044f62bcb9 is
  port (
    sel : in std_logic_vector((1 - 1) downto 0);
    d0 : in std_logic_vector((12 - 1) downto 0);
    d1 : in std_logic_vector((12 - 1) downto 0);
    y : out std_logic_vector((12 - 1) downto 0);
    clk : in std_logic;
    ce : in std_logic;
    clr : in std_logic);
end sysgen_mux_044f62bcb9;
architecture behavior of sysgen_mux_044f62bcb9
is
  signal sel_1_20: std_logic_vector((1 - 1) downto 0);
  signal d0_1_24: std_logic_vector((12 - 1) downto 0);
  signal d1_1_27: std_logic_vector((12 - 1) downto 0);
  signal unregy_join_6_1: std_logic_vector((12 - 1) downto 0);
begin
  sel_1_20 <= sel;
  d0_1_24 <= d0;
  d1_1_27 <= d1;
  proc_switch_6_1: process (d0_1_24, d1_1_27, sel_1_20)
  is
  begin
    case sel_1_20 is 
      when "0" =>
        unregy_join_6_1 <= d0_1_24;
      when others =>
        unregy_join_6_1 <= d1_1_27;
    end case;
  end process proc_switch_6_1;
  y <= unregy_join_6_1;
end behavior;

library work;
use work.conv_pkg.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity sysgen_mux_5b770c3875 is
  port (
    sel : in std_logic_vector((1 - 1) downto 0);
    d0 : in std_logic_vector((1 - 1) downto 0);
    d1 : in std_logic_vector((1 - 1) downto 0);
    y : out std_logic_vector((1 - 1) downto 0);
    clk : in std_logic;
    ce : in std_logic;
    clr : in std_logic);
end sysgen_mux_5b770c3875;
architecture behavior of sysgen_mux_5b770c3875
is
  signal sel_1_20: std_logic_vector((1 - 1) downto 0);
  signal d0_1_24: std_logic;
  signal d1_1_27: std_logic;
  signal unregy_join_6_1: std_logic;
begin
  sel_1_20 <= sel;
  d0_1_24 <= d0(0);
  d1_1_27 <= d1(0);
  proc_switch_6_1: process (d0_1_24, d1_1_27, sel_1_20)
  is
  begin
    case sel_1_20 is 
      when "0" =>
        unregy_join_6_1 <= d0_1_24;
      when others =>
        unregy_join_6_1 <= d1_1_27;
    end case;
  end process proc_switch_6_1;
  y <= std_logic_to_vector(unregy_join_6_1);
end behavior;

library work;
use work.conv_pkg.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity sysgen_mux_ff6eacdf66 is
  port (
    sel : in std_logic_vector((1 - 1) downto 0);
    d0 : in std_logic_vector((32 - 1) downto 0);
    d1 : in std_logic_vector((32 - 1) downto 0);
    y : out std_logic_vector((32 - 1) downto 0);
    clk : in std_logic;
    ce : in std_logic;
    clr : in std_logic);
end sysgen_mux_ff6eacdf66;
architecture behavior of sysgen_mux_ff6eacdf66
is
  signal sel_1_20: std_logic_vector((1 - 1) downto 0);
  signal d0_1_24: std_logic_vector((32 - 1) downto 0);
  signal d1_1_27: std_logic_vector((32 - 1) downto 0);
  signal unregy_join_6_1: std_logic_vector((32 - 1) downto 0);
begin
  sel_1_20 <= sel;
  d0_1_24 <= d0;
  d1_1_27 <= d1;
  proc_switch_6_1: process (d0_1_24, d1_1_27, sel_1_20)
  is
  begin
    case sel_1_20 is 
      when "0" =>
        unregy_join_6_1 <= d0_1_24;
      when others =>
        unregy_join_6_1 <= d1_1_27;
    end case;
  end process proc_switch_6_1;
  y <= unregy_join_6_1;
end behavior;

library work;
use work.conv_pkg.all;

---------------------------------------------------------------------
--
--  Filename      : xlregister.vhd
--
--  Description   : VHDL description of an arbitrary wide register.
--                  Unlike the delay block, an initial value is
--                  specified and is considered valid at the start
--                  of simulation.  The register is only one word
--                  deep.
--
--  Mod. History  : Removed valid bit logic from wrapper.
--                : Changed VHDL to use a bit_vector generic for its
--
---------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;


entity dl_adaptor_data_xlregister is

   generic (d_width          : integer := 5;          -- Width of d input
            init_value       : bit_vector := b"00");  -- Binary init value string

   port (d   : in std_logic_vector (d_width-1 downto 0);
         rst : in std_logic_vector(0 downto 0) := "0";
         en  : in std_logic_vector(0 downto 0) := "1";
         ce  : in std_logic;
         clk : in std_logic;
         q   : out std_logic_vector (d_width-1 downto 0));

end dl_adaptor_data_xlregister;

architecture behavior of dl_adaptor_data_xlregister is

   component synth_reg_w_init
      generic (width      : integer;
               init_index : integer;
               init_value : bit_vector;
               latency    : integer);
      port (i   : in std_logic_vector(width-1 downto 0);
            ce  : in std_logic;
            clr : in std_logic;
            clk : in std_logic;
            o   : out std_logic_vector(width-1 downto 0));
   end component; -- end synth_reg_w_init

   -- synthesis translate_off
   signal real_d, real_q           : real;    -- For debugging info ports
   -- synthesis translate_on
   signal internal_clr             : std_logic;
   signal internal_ce              : std_logic;

begin

   internal_clr <= rst(0) and ce;
   internal_ce  <= en(0) and ce;

   -- Synthesizable behavioral model
   synth_reg_inst : synth_reg_w_init
      generic map (width      => d_width,
                   init_index => 2,
                   init_value => init_value,
                   latency    => 1)
      port map (i   => d,
                ce  => internal_ce,
                clr => internal_clr,
                clk => clk,
                o   => q);

end architecture behavior;


library work;
use work.conv_pkg.all;

---------------------------------------------------------------------
--
--  Filename      : xlslice.vhd
--
--  Description   : VHDL description of a block that sets the output to a
--                  specified range of the input bits. The output is always
--                  set to an unsigned type with it's binary point at zero.
--
---------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
library work;
use work.conv_pkg.all;


entity dl_adaptor_data_xlslice is
    generic (
        new_msb      : integer := 9;           -- position of new msb
        new_lsb      : integer := 1;           -- position of new lsb
        x_width      : integer := 16;          -- Width of x input
        y_width      : integer := 8);          -- Width of y output
    port (
        x : in std_logic_vector (x_width-1 downto 0);
        y : out std_logic_vector (y_width-1 downto 0));
end dl_adaptor_data_xlslice;

architecture behavior of dl_adaptor_data_xlslice is
begin
    y <= x(new_msb downto new_lsb);
end  behavior;

library work;
use work.conv_pkg.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity sysgen_counter_5f3bbd2578 is
  port (
    rst : in std_logic_vector((1 - 1) downto 0);
    en : in std_logic_vector((1 - 1) downto 0);
    op : out std_logic_vector((1 - 1) downto 0);
    clk : in std_logic;
    ce : in std_logic;
    clr : in std_logic);
end sysgen_counter_5f3bbd2578;
architecture behavior of sysgen_counter_5f3bbd2578
is
  signal rst_1_40: boolean;
  signal en_1_45: boolean;
  signal count_reg_20_23: unsigned((1 - 1) downto 0) := "1";
  signal count_reg_20_23_rst: std_logic;
  signal count_reg_20_23_en: std_logic;
  signal bool_44_4: boolean;
  signal rst_limit_join_44_1: boolean;
  signal count_reg_join_44_1: unsigned((2 - 1) downto 0);
  signal count_reg_join_44_1_en: std_logic;
  signal count_reg_join_44_1_rst: std_logic;
begin
  rst_1_40 <= ((rst) = "1");
  en_1_45 <= ((en) = "1");
  proc_count_reg_20_23: process (clk)
  is
  begin
    if (clk'event and (clk = '1')) then
      if ((ce = '1') and (count_reg_20_23_rst = '1')) then
        count_reg_20_23 <= "1";
      elsif ((ce = '1') and (count_reg_20_23_en = '1')) then 
        count_reg_20_23 <= count_reg_20_23 + std_logic_vector_to_unsigned("1");
      end if;
    end if;
  end process proc_count_reg_20_23;
  bool_44_4 <= rst_1_40 or false;
  proc_if_44_1: process (bool_44_4, count_reg_20_23, en_1_45)
  is
  begin
    if bool_44_4 then
      count_reg_join_44_1_rst <= '1';
    elsif en_1_45 then
      count_reg_join_44_1_rst <= '0';
    else 
      count_reg_join_44_1_rst <= '0';
    end if;
    if en_1_45 then
      count_reg_join_44_1_en <= '1';
    else 
      count_reg_join_44_1_en <= '0';
    end if;
    if bool_44_4 then
      rst_limit_join_44_1 <= false;
    elsif en_1_45 then
      rst_limit_join_44_1 <= false;
    else 
      rst_limit_join_44_1 <= false;
    end if;
  end process proc_if_44_1;
  count_reg_20_23_rst <= count_reg_join_44_1_rst;
  count_reg_20_23_en <= count_reg_join_44_1_en;
  op <= unsigned_to_std_logic_vector(count_reg_20_23);
end behavior;

