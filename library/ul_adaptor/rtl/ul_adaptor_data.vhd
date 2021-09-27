-- Generated from Simulink block ul_adaptor_data_struct
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity ul_adaptor_data_struct is
  port (
    buffer_mem_addr_i : in std_logic_vector( 12-1 downto 0 );
    buffer_mem_ctrl_en : in std_logic_vector( 2-1 downto 0 );
    buffer_mem_data_i : in std_logic_vector( 32-1 downto 0 );
    buffer_mem_we : in std_logic_vector( 1-1 downto 0 );
    buffer_rd_addr_i : in std_logic_vector( 13-1 downto 0 );
    buffer_rd_en_i : in std_logic_vector( 1-1 downto 0 );
    buffer_wr_ctrl_i : in std_logic_vector( 14-1 downto 0 );
    idata_i : in std_logic_vector( 16-1 downto 0 );
    qdata_i : in std_logic_vector( 16-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    buffer_mem_data_o : out std_logic_vector( 32-1 downto 0 );
    data_o : out std_logic_vector( 64-1 downto 0 );
    sop_o : out std_logic_vector( 1-1 downto 0 );
    valid_o : out std_logic_vector( 1-1 downto 0 )
  );
end ul_adaptor_data_struct;
architecture structural of ul_adaptor_data_struct is 
  signal buffer_mem_data_i_net : std_logic_vector( 32-1 downto 0 );
  signal buffer_mem_we_net : std_logic_vector( 1-1 downto 0 );
  signal buffer_mem_addr_i_net : std_logic_vector( 12-1 downto 0 );
  signal buffer_rd_addr_i_net : std_logic_vector( 13-1 downto 0 );
  signal buffer_mem_ctrl_en_net : std_logic_vector( 2-1 downto 0 );
  signal mux5_y_net : std_logic_vector( 32-1 downto 0 );
  signal buffer_rd_en_i_net : std_logic_vector( 1-1 downto 0 );
  signal buffer_wr_ctrl_i_net : std_logic_vector( 14-1 downto 0 );
  signal concat_y_net : std_logic_vector( 32-1 downto 0 );
  signal reinterpret_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal qdata_i_net : std_logic_vector( 16-1 downto 0 );
  signal idata_i_net : std_logic_vector( 16-1 downto 0 );
  signal register12_q_net : std_logic_vector( 1-1 downto 0 );
  signal a_clk_net : std_logic;
  signal register2_q_net : std_logic_vector( 64-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal register8_q_net : std_logic_vector( 1-1 downto 0 );
  signal a_ce_net : std_logic;
  signal constant28_op_net : std_logic_vector( 64-1 downto 0 );
  signal constant1_op_net : std_logic_vector( 1-1 downto 0 );
  signal dual_port_ram_douta_net : std_logic_vector( 64-1 downto 0 );
  signal register11_q_net : std_logic_vector( 13-1 downto 0 );
  signal register13_q_net : std_logic_vector( 1-1 downto 0 );
  signal constant2_op_net : std_logic_vector( 1-1 downto 0 );
  signal dual_port_ram_doutb_net : std_logic_vector( 64-1 downto 0 );
  signal constant7_op_net : std_logic_vector( 13-1 downto 0 );
  signal register5_q_net : std_logic_vector( 32-1 downto 0 );
  signal constant4_op_net : std_logic_vector( 32-1 downto 0 );
  signal concat6_y_net : std_logic_vector( 64-1 downto 0 );
  signal concat11_y_net : std_logic_vector( 13-1 downto 0 );
  signal logical5_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice3_y_net : std_logic_vector( 13-1 downto 0 );
  signal mux20_y_net : std_logic_vector( 13-1 downto 0 );
  signal mux21_y_net : std_logic_vector( 1-1 downto 0 );
  signal relational6_op_net : std_logic_vector( 1-1 downto 0 );
  signal mux17_y_net : std_logic_vector( 32-1 downto 0 );
  signal register9_q_net : std_logic_vector( 1-1 downto 0 );
  signal register7_q_net : std_logic_vector( 1-1 downto 0 );
  signal slice53_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice1_y_net : std_logic_vector( 1-1 downto 0 );
  signal inverter2_op_net : std_logic_vector( 1-1 downto 0 );
  signal register3_q_net : std_logic_vector( 1-1 downto 0 );
  signal slice54_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice39_y_net : std_logic_vector( 32-1 downto 0 );
  signal slice17_y_net : std_logic_vector( 32-1 downto 0 );
begin
  buffer_mem_addr_i_net <= buffer_mem_addr_i;
  buffer_mem_ctrl_en_net <= buffer_mem_ctrl_en;
  buffer_mem_data_i_net <= buffer_mem_data_i;
  buffer_mem_data_o <= mux5_y_net;
  buffer_mem_we_net <= buffer_mem_we;
  buffer_rd_addr_i_net <= buffer_rd_addr_i;
  buffer_rd_en_i_net <= buffer_rd_en_i;
  buffer_wr_ctrl_i_net <= buffer_wr_ctrl_i;
  data_o <= register2_q_net;
  idata_i_net <= idata_i;
  qdata_i_net <= qdata_i;
  sop_o <= register8_q_net;
  valid_o <= register12_q_net;
  a_clk_net <= clk_1;
  a_ce_net <= ce_1;
  concat : entity work.sysgen_concat_b1c3bbd87b 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => reinterpret1_output_port_net,
    in1 => reinterpret_output_port_net,
    y => concat_y_net
  );
  concat6 : entity work.sysgen_concat_b72c79c9a0 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => constant4_op_net,
    in1 => register5_q_net,
    y => concat6_y_net
  );
  constant1 : entity work.sysgen_constant_02181da817 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant1_op_net
  );
  constant2 : entity work.sysgen_constant_0970d2da26 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant2_op_net
  );
  constant28 : entity work.sysgen_constant_80cea43ee5 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant28_op_net
  );
  constant4 : entity work.sysgen_constant_42dc75a5c0 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant4_op_net
  );
  constant7 : entity work.sysgen_constant_5091d17fcd 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant7_op_net
  );
  dual_port_ram : entity work.ul_adaptor_data_xldpram 
  generic map (
    c_address_width_a => 13,
    c_address_width_b => 13,
    c_width_a => 64,
    c_width_b => 64,
    core_name0 => "ul_adaptor_data_blk_mem_gen_i0",
    latency => 0
  )
  port map (
    rsta => "0",
    rstb => "0",
    addra => register11_q_net,
    dina => concat6_y_net,
    wea => register13_q_net,
    addrb => buffer_rd_addr_i_net,
    dinb => constant28_op_net,
    web => constant1_op_net,
    ena => constant2_op_net,
    enb => constant2_op_net,
    a_clk => a_clk_net,
    a_ce => a_ce_net,
    b_clk => a_clk_net,
    b_ce => a_ce_net,
    douta => dual_port_ram_douta_net,
    doutb => dual_port_ram_doutb_net
  );
  inverter2 : entity work.sysgen_inverter_8097943fb7 
  port map (
    clr => '0',
    ip => register7_q_net,
    clk => a_clk_net,
    ce => a_ce_net,
    op => inverter2_op_net
  );
  logical5 : entity work.sysgen_logical_ace5b7c05e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    d0 => register9_q_net,
    d1 => relational6_op_net,
    y => logical5_y_net
  );
  mux17 : entity work.sysgen_mux_331e9dd55f 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => slice53_y_net,
    d0 => concat_y_net,
    d1 => buffer_mem_data_i_net,
    y => mux17_y_net
  );
  mux20 : entity work.sysgen_mux_19687b5d2a 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => slice53_y_net,
    d0 => slice3_y_net,
    d1 => concat11_y_net,
    y => mux20_y_net
  );
  mux21 : entity work.sysgen_mux_22ee4e6f07 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => slice53_y_net,
    d0 => slice1_y_net,
    d1 => buffer_mem_we_net,
    y => mux21_y_net
  );
  register11 : entity work.ul_adaptor_data_xlregister 
  generic map (
    d_width => 13,
    init_value => b"0000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => mux20_y_net,
    clk => a_clk_net,
    ce => a_ce_net,
    q => register11_q_net
  );
  register12 : entity work.ul_adaptor_data_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => register9_q_net,
    clk => a_clk_net,
    ce => a_ce_net,
    q => register12_q_net
  );
  register13 : entity work.ul_adaptor_data_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => mux21_y_net,
    clk => a_clk_net,
    ce => a_ce_net,
    q => register13_q_net
  );
  register2 : entity work.ul_adaptor_data_xlregister 
  generic map (
    d_width => 64,
    init_value => b"0000000000000000000000000000000000000000000000000000000000000000"
  )
  port map (
    d => dual_port_ram_doutb_net,
    rst => register3_q_net,
    en => register9_q_net,
    clk => a_clk_net,
    ce => a_ce_net,
    q => register2_q_net
  );
  register3 : entity work.ul_adaptor_data_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => inverter2_op_net,
    clk => a_clk_net,
    ce => a_ce_net,
    q => register3_q_net
  );
  register5 : entity work.ul_adaptor_data_xlregister 
  generic map (
    d_width => 32,
    init_value => b"00000000000000000000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => mux17_y_net,
    clk => a_clk_net,
    ce => a_ce_net,
    q => register5_q_net
  );
  register7 : entity work.ul_adaptor_data_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => buffer_rd_en_i_net,
    clk => a_clk_net,
    ce => a_ce_net,
    q => register7_q_net
  );
  register8 : entity work.ul_adaptor_data_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => logical5_y_net,
    clk => a_clk_net,
    ce => a_ce_net,
    q => register8_q_net
  );
  register9 : entity work.ul_adaptor_data_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => register7_q_net,
    clk => a_clk_net,
    ce => a_ce_net,
    q => register9_q_net
  );
  reinterpret : entity work.sysgen_reinterpret_86e6fa1485 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => idata_i_net,
    output_port => reinterpret_output_port_net
  );
  reinterpret1 : entity work.sysgen_reinterpret_86e6fa1485 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => qdata_i_net,
    output_port => reinterpret1_output_port_net
  );
  relational6 : entity work.sysgen_relational_7fd127294e 
  port map (
    clr => '0',
    a => constant7_op_net,
    b => buffer_rd_addr_i_net,
    clk => a_clk_net,
    ce => a_ce_net,
    op => relational6_op_net
  );
  slice1 : entity work.ul_adaptor_data_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 0,
    x_width => 14,
    y_width => 1
  )
  port map (
    x => buffer_wr_ctrl_i_net,
    y => slice1_y_net
  );
  slice3 : entity work.ul_adaptor_data_xlslice 
  generic map (
    new_lsb => 1,
    new_msb => 13,
    x_width => 14,
    y_width => 13
  )
  port map (
    x => buffer_wr_ctrl_i_net,
    y => slice3_y_net
  );
  slice53 : entity work.ul_adaptor_data_xlslice 
  generic map (
    new_lsb => 1,
    new_msb => 1,
    x_width => 2,
    y_width => 1
  )
  port map (
    x => buffer_mem_ctrl_en_net,
    y => slice53_y_net
  );
  slice54 : entity work.ul_adaptor_data_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 0,
    x_width => 2,
    y_width => 1
  )
  port map (
    x => buffer_mem_ctrl_en_net,
    y => slice54_y_net
  );
  concat11 : entity work.sysgen_concat_ff17f8264a 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => buffer_mem_addr_i_net,
    in1 => slice54_y_net,
    y => concat11_y_net
  );
  mux5 : entity work.sysgen_mux_35c7f3b1bb 
  port map (
    clr => '0',
    sel => slice54_y_net,
    d0 => slice39_y_net,
    d1 => slice17_y_net,
    clk => a_clk_net,
    ce => a_ce_net,
    y => mux5_y_net
  );
  slice17 : entity work.ul_adaptor_data_xlslice 
  generic map (
    new_lsb => 32,
    new_msb => 63,
    x_width => 64,
    y_width => 32
  )
  port map (
    x => dual_port_ram_douta_net,
    y => slice17_y_net
  );
  slice39 : entity work.ul_adaptor_data_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 31,
    x_width => 64,
    y_width => 32
  )
  port map (
    x => dual_port_ram_douta_net,
    y => slice39_y_net
  );
end structural;
-- Generated from Simulink block 
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity ul_adaptor_data_default_clock_driver is
  port (
    ul_adaptor_data_sysclk : in std_logic;
    ul_adaptor_data_sysce : in std_logic;
    ul_adaptor_data_sysclr : in std_logic;
    ul_adaptor_data_clk1 : out std_logic;
    ul_adaptor_data_ce1 : out std_logic
  );
end ul_adaptor_data_default_clock_driver;
architecture structural of ul_adaptor_data_default_clock_driver is 
begin
  clockdriver : entity work.xlclockdriver 
  generic map (
    period => 1,
    log_2_period => 1
  )
  port map (
    sysclk => ul_adaptor_data_sysclk,
    sysce => ul_adaptor_data_sysce,
    sysclr => ul_adaptor_data_sysclr,
    clk => ul_adaptor_data_clk1,
    ce => ul_adaptor_data_ce1
  );
end structural;
-- Generated from Simulink block 
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity ul_adaptor_data is
  port (
    buffer_mem_addr_i : in std_logic_vector( 12-1 downto 0 );
    buffer_mem_ctrl_en : in std_logic_vector( 2-1 downto 0 );
    buffer_mem_data_i : in std_logic_vector( 32-1 downto 0 );
    buffer_mem_we : in std_logic_vector( 1-1 downto 0 );
    buffer_rd_addr_i : in std_logic_vector( 13-1 downto 0 );
    buffer_rd_en_i : in std_logic_vector( 1-1 downto 0 );
    buffer_wr_ctrl_i : in std_logic_vector( 14-1 downto 0 );
    idata_i : in std_logic_vector( 16-1 downto 0 );
    qdata_i : in std_logic_vector( 16-1 downto 0 );
    clk : in std_logic;
    buffer_mem_data_o : out std_logic_vector( 32-1 downto 0 );
    data_o : out std_logic_vector( 64-1 downto 0 );
    sop_o : out std_logic_vector( 1-1 downto 0 );
    valid_o : out std_logic_vector( 1-1 downto 0 )
  );
end ul_adaptor_data;
architecture structural of ul_adaptor_data is 
  attribute core_generation_info : string;
  attribute core_generation_info of structural : architecture is "ul_adaptor_data,sysgen_core_2018_3,{,compilation=HDL Netlist,block_icon_display=Default,family=zynquplusRFSOC,part=xczu29dr,speed=-2LVI-i,package=ffvf1760,synthesis_language=vhdl,hdl_library=work,synthesis_strategy=Vivado Synthesis Defaults,implementation_strategy=Performance_Explore,testbench=0,interface_doc=0,ce_clr=0,clock_period=2.03451,system_simulink_period=2.03451e-09,waveform_viewer=0,axilite_interface=0,ip_catalog_plugin=0,hwcosim_burst_mode=0,simulation_time=0.0001,concat=3,constant=5,dpram=1,inv=1,logical=1,mux=4,register=9,reinterpret=4,relational=1,slice=8,}";
  signal clk_1_net : std_logic;
  signal ce_1_net : std_logic;
begin
  ul_adaptor_data_default_clock_driver : entity work.ul_adaptor_data_default_clock_driver 
  port map (
    ul_adaptor_data_sysclk => clk,
    ul_adaptor_data_sysce => '1',
    ul_adaptor_data_sysclr => '0',
    ul_adaptor_data_clk1 => clk_1_net,
    ul_adaptor_data_ce1 => ce_1_net
  );
  ul_adaptor_data_struct : entity work.ul_adaptor_data_struct 
  port map (
    buffer_mem_addr_i => buffer_mem_addr_i,
    buffer_mem_ctrl_en => buffer_mem_ctrl_en,
    buffer_mem_data_i => buffer_mem_data_i,
    buffer_mem_we => buffer_mem_we,
    buffer_rd_addr_i => buffer_rd_addr_i,
    buffer_rd_en_i => buffer_rd_en_i,
    buffer_wr_ctrl_i => buffer_wr_ctrl_i,
    idata_i => idata_i,
    qdata_i => qdata_i,
    clk_1 => clk_1_net,
    ce_1 => ce_1_net,
    buffer_mem_data_o => buffer_mem_data_o,
    data_o => data_o,
    sop_o => sop_o,
    valid_o => valid_o
  );
end structural;
