-- Generated from Simulink block dl_adaptor_ctrl/counter_0
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_adaptor_ctrl_counter_0 is
  port (
    sof : in std_logic_vector( 1-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    cnt : out std_logic_vector( 16-1 downto 0 )
  );
end dl_adaptor_ctrl_counter_0;
architecture structural of dl_adaptor_ctrl_counter_0 is 
  signal counter12_op_net : std_logic_vector( 16-1 downto 0 );
  signal mux3_y_net : std_logic_vector( 1-1 downto 0 );
  signal ce_net : std_logic;
  signal logical_y_net : std_logic_vector( 1-1 downto 0 );
  signal relational11_op_net : std_logic_vector( 1-1 downto 0 );
  signal clk_net : std_logic;
  signal constant15_op_net : std_logic_vector( 16-1 downto 0 );
  signal register1_q_net : std_logic_vector( 1-1 downto 0 );
begin
  cnt <= counter12_op_net;
  mux3_y_net <= sof;
  clk_net <= clk_1;
  ce_net <= ce_1;
  constant15 : entity work.sysgen_constant_04155b1977 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant15_op_net
  );
  counter12 : entity work.dl_adaptor_ctrl_xlcounter_free 
  generic map (
    core_name0 => "dl_adaptor_ctrl_c_counter_binary_v12_0_i2",
    op_arith => xlUnsigned,
    op_width => 16
  )
  port map (
    clr => '0',
    rst => mux3_y_net,
    en => logical_y_net,
    clk => clk_net,
    ce => ce_net,
    op => counter12_op_net
  );
  logical : entity work.sysgen_logical_5cd6b1873c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    d0 => register1_q_net,
    d1 => relational11_op_net,
    y => logical_y_net
  );
  register1 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => mux3_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register1_q_net
  );
  relational11 : entity work.sysgen_relational_2cf81b4d2b 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    a => counter12_op_net,
    b => constant15_op_net,
    op => relational11_op_net
  );
end structural;
-- Generated from Simulink block dl_adaptor_ctrl/counter_2
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_adaptor_ctrl_counter_2 is
  port (
    sop : in std_logic_vector( 1-1 downto 0 );
    cnt_mode : in std_logic_vector( 2-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    cnt : out std_logic_vector( 15-1 downto 0 );
    valid : out std_logic_vector( 1-1 downto 0 )
  );
end dl_adaptor_ctrl_counter_2;
architecture structural of dl_adaptor_ctrl_counter_2 is 
  signal logical_y_net : std_logic_vector( 1-1 downto 0 );
  signal constant15_op_net : std_logic_vector( 15-1 downto 0 );
  signal register35_q_net : std_logic_vector( 1-1 downto 0 );
  signal relational11_op_net : std_logic_vector( 1-1 downto 0 );
  signal counter12_op_net : std_logic_vector( 15-1 downto 0 );
  signal clk_net : std_logic;
  signal ce_net : std_logic;
  signal mux36_y_net : std_logic_vector( 2-1 downto 0 );
  signal constant2_op_net : std_logic_vector( 14-1 downto 0 );
  signal logical1_y_net : std_logic_vector( 1-1 downto 0 );
  signal relational2_op_net : std_logic_vector( 1-1 downto 0 );
  signal relational1_op_net : std_logic_vector( 1-1 downto 0 );
  signal slice1_y_net : std_logic_vector( 2-1 downto 0 );
  signal slice3_y_net : std_logic_vector( 13-1 downto 0 );
begin
  cnt <= counter12_op_net;
  valid <= logical_y_net;
  register35_q_net <= sop;
  mux36_y_net <= cnt_mode;
  clk_net <= clk_1;
  ce_net <= ce_1;
  constant15 : entity work.sysgen_constant_bd1d934353 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant15_op_net
  );
  constant2 : entity work.sysgen_constant_35777e3f95 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant2_op_net
  );
  counter12 : entity work.dl_adaptor_ctrl_xlcounter_free 
  generic map (
    core_name0 => "dl_adaptor_ctrl_c_counter_binary_v12_0_i3",
    op_arith => xlUnsigned,
    op_width => 15
  )
  port map (
    clr => '0',
    rst => logical1_y_net,
    en => logical_y_net,
    clk => clk_net,
    ce => ce_net,
    op => counter12_op_net
  );
  logical : entity work.sysgen_logical_5cd6b1873c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    d0 => register35_q_net,
    d1 => relational11_op_net,
    y => logical_y_net
  );
  logical1 : entity work.sysgen_logical_3988e4be9f 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    d0 => relational1_op_net,
    d1 => relational2_op_net,
    y => logical1_y_net
  );
  relational1 : entity work.sysgen_relational_0ffe8ee119 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    a => slice3_y_net,
    b => constant2_op_net,
    op => relational1_op_net
  );
  relational11 : entity work.sysgen_relational_de1a39d15c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    a => counter12_op_net,
    b => constant15_op_net,
    op => relational11_op_net
  );
  relational2 : entity work.sysgen_relational_7a7fffb7c1 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    a => slice1_y_net,
    b => mux36_y_net,
    op => relational2_op_net
  );
  slice1 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 13,
    new_msb => 14,
    x_width => 15,
    y_width => 2
  )
  port map (
    x => counter12_op_net,
    y => slice1_y_net
  );
  slice3 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 12,
    x_width => 15,
    y_width => 13
  )
  port map (
    x => counter12_op_net,
    y => slice3_y_net
  );
end structural;
-- Generated from Simulink block dl_adaptor_ctrl/sb_bit_order_rev/10bit_order_rev
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_adaptor_ctrl_10bit_order_rev is
  port (
    index_i : in std_logic_vector( 10-1 downto 0 );
    index_o : out std_logic_vector( 10-1 downto 0 )
  );
end dl_adaptor_ctrl_10bit_order_rev;
architecture structural of dl_adaptor_ctrl_10bit_order_rev is 
  signal concat_y_net : std_logic_vector( 10-1 downto 0 );
  signal slice6_y_net : std_logic_vector( 10-1 downto 0 );
  signal slice8_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice6_y_net_x0 : std_logic_vector( 1-1 downto 0 );
  signal slice10_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice5_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice2_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice7_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice4_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice9_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice1_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice3_y_net : std_logic_vector( 1-1 downto 0 );
begin
  index_o <= concat_y_net;
  slice6_y_net <= index_i;
  concat : entity work.sysgen_concat_ac219fcee2 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => slice2_y_net,
    in1 => slice1_y_net,
    in2 => slice3_y_net,
    in3 => slice4_y_net,
    in4 => slice5_y_net,
    in5 => slice6_y_net_x0,
    in6 => slice7_y_net,
    in7 => slice8_y_net,
    in8 => slice9_y_net,
    in9 => slice10_y_net,
    y => concat_y_net
  );
  slice1 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 1,
    new_msb => 1,
    x_width => 10,
    y_width => 1
  )
  port map (
    x => slice6_y_net,
    y => slice1_y_net
  );
  slice10 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 9,
    new_msb => 9,
    x_width => 10,
    y_width => 1
  )
  port map (
    x => slice6_y_net,
    y => slice10_y_net
  );
  slice2 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 0,
    x_width => 10,
    y_width => 1
  )
  port map (
    x => slice6_y_net,
    y => slice2_y_net
  );
  slice3 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 2,
    new_msb => 2,
    x_width => 10,
    y_width => 1
  )
  port map (
    x => slice6_y_net,
    y => slice3_y_net
  );
  slice4 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 3,
    new_msb => 3,
    x_width => 10,
    y_width => 1
  )
  port map (
    x => slice6_y_net,
    y => slice4_y_net
  );
  slice5 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 4,
    new_msb => 4,
    x_width => 10,
    y_width => 1
  )
  port map (
    x => slice6_y_net,
    y => slice5_y_net
  );
  slice6 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 5,
    new_msb => 5,
    x_width => 10,
    y_width => 1
  )
  port map (
    x => slice6_y_net,
    y => slice6_y_net_x0
  );
  slice7 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 6,
    new_msb => 6,
    x_width => 10,
    y_width => 1
  )
  port map (
    x => slice6_y_net,
    y => slice7_y_net
  );
  slice8 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 7,
    new_msb => 7,
    x_width => 10,
    y_width => 1
  )
  port map (
    x => slice6_y_net,
    y => slice8_y_net
  );
  slice9 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 8,
    new_msb => 8,
    x_width => 10,
    y_width => 1
  )
  port map (
    x => slice6_y_net,
    y => slice9_y_net
  );
end structural;
-- Generated from Simulink block dl_adaptor_ctrl/sb_bit_order_rev/11bit_order_rev
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_adaptor_ctrl_11bit_order_rev is
  port (
    index_i : in std_logic_vector( 11-1 downto 0 );
    index_o : out std_logic_vector( 11-1 downto 0 )
  );
end dl_adaptor_ctrl_11bit_order_rev;
architecture structural of dl_adaptor_ctrl_11bit_order_rev is 
  signal slice2_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice1_y_net : std_logic_vector( 1-1 downto 0 );
  signal concat_y_net : std_logic_vector( 11-1 downto 0 );
  signal slice33_y_net : std_logic_vector( 11-1 downto 0 );
  signal slice3_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice8_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice5_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice9_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice7_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice11_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice10_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice4_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice6_y_net : std_logic_vector( 1-1 downto 0 );
begin
  index_o <= concat_y_net;
  slice33_y_net <= index_i;
  concat : entity work.sysgen_concat_b5f2524a6a 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => slice2_y_net,
    in1 => slice1_y_net,
    in2 => slice3_y_net,
    in3 => slice4_y_net,
    in4 => slice5_y_net,
    in5 => slice6_y_net,
    in6 => slice7_y_net,
    in7 => slice8_y_net,
    in8 => slice9_y_net,
    in9 => slice10_y_net,
    in10 => slice11_y_net,
    y => concat_y_net
  );
  slice1 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 1,
    new_msb => 1,
    x_width => 11,
    y_width => 1
  )
  port map (
    x => slice33_y_net,
    y => slice1_y_net
  );
  slice10 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 9,
    new_msb => 9,
    x_width => 11,
    y_width => 1
  )
  port map (
    x => slice33_y_net,
    y => slice10_y_net
  );
  slice11 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 10,
    new_msb => 10,
    x_width => 11,
    y_width => 1
  )
  port map (
    x => slice33_y_net,
    y => slice11_y_net
  );
  slice2 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 0,
    x_width => 11,
    y_width => 1
  )
  port map (
    x => slice33_y_net,
    y => slice2_y_net
  );
  slice3 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 2,
    new_msb => 2,
    x_width => 11,
    y_width => 1
  )
  port map (
    x => slice33_y_net,
    y => slice3_y_net
  );
  slice4 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 3,
    new_msb => 3,
    x_width => 11,
    y_width => 1
  )
  port map (
    x => slice33_y_net,
    y => slice4_y_net
  );
  slice5 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 4,
    new_msb => 4,
    x_width => 11,
    y_width => 1
  )
  port map (
    x => slice33_y_net,
    y => slice5_y_net
  );
  slice6 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 5,
    new_msb => 5,
    x_width => 11,
    y_width => 1
  )
  port map (
    x => slice33_y_net,
    y => slice6_y_net
  );
  slice7 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 6,
    new_msb => 6,
    x_width => 11,
    y_width => 1
  )
  port map (
    x => slice33_y_net,
    y => slice7_y_net
  );
  slice8 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 7,
    new_msb => 7,
    x_width => 11,
    y_width => 1
  )
  port map (
    x => slice33_y_net,
    y => slice8_y_net
  );
  slice9 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 8,
    new_msb => 8,
    x_width => 11,
    y_width => 1
  )
  port map (
    x => slice33_y_net,
    y => slice9_y_net
  );
end structural;
-- Generated from Simulink block dl_adaptor_ctrl/sb_bit_order_rev/9bit_order_rev
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_adaptor_ctrl_9bit_order_rev is
  port (
    index_i : in std_logic_vector( 9-1 downto 0 );
    index_o : out std_logic_vector( 9-1 downto 0 )
  );
end dl_adaptor_ctrl_9bit_order_rev;
architecture structural of dl_adaptor_ctrl_9bit_order_rev is 
  signal slice4_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice1_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice3_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice6_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice31_y_net : std_logic_vector( 9-1 downto 0 );
  signal slice5_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice7_y_net : std_logic_vector( 1-1 downto 0 );
  signal concat_y_net : std_logic_vector( 9-1 downto 0 );
  signal slice2_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice8_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice9_y_net : std_logic_vector( 1-1 downto 0 );
begin
  index_o <= concat_y_net;
  slice31_y_net <= index_i;
  concat : entity work.sysgen_concat_ef8139ab5e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => slice2_y_net,
    in1 => slice1_y_net,
    in2 => slice3_y_net,
    in3 => slice4_y_net,
    in4 => slice5_y_net,
    in5 => slice6_y_net,
    in6 => slice7_y_net,
    in7 => slice8_y_net,
    in8 => slice9_y_net,
    y => concat_y_net
  );
  slice1 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 1,
    new_msb => 1,
    x_width => 9,
    y_width => 1
  )
  port map (
    x => slice31_y_net,
    y => slice1_y_net
  );
  slice2 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 0,
    x_width => 9,
    y_width => 1
  )
  port map (
    x => slice31_y_net,
    y => slice2_y_net
  );
  slice3 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 2,
    new_msb => 2,
    x_width => 9,
    y_width => 1
  )
  port map (
    x => slice31_y_net,
    y => slice3_y_net
  );
  slice4 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 3,
    new_msb => 3,
    x_width => 9,
    y_width => 1
  )
  port map (
    x => slice31_y_net,
    y => slice4_y_net
  );
  slice5 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 4,
    new_msb => 4,
    x_width => 9,
    y_width => 1
  )
  port map (
    x => slice31_y_net,
    y => slice5_y_net
  );
  slice6 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 5,
    new_msb => 5,
    x_width => 9,
    y_width => 1
  )
  port map (
    x => slice31_y_net,
    y => slice6_y_net
  );
  slice7 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 6,
    new_msb => 6,
    x_width => 9,
    y_width => 1
  )
  port map (
    x => slice31_y_net,
    y => slice7_y_net
  );
  slice8 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 7,
    new_msb => 7,
    x_width => 9,
    y_width => 1
  )
  port map (
    x => slice31_y_net,
    y => slice8_y_net
  );
  slice9 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 8,
    new_msb => 8,
    x_width => 9,
    y_width => 1
  )
  port map (
    x => slice31_y_net,
    y => slice9_y_net
  );
end structural;
-- Generated from Simulink block dl_adaptor_ctrl/sb_bit_order_rev
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_adaptor_ctrl_sb_bit_order_rev is
  port (
    cnt_in : in std_logic_vector( 15-1 downto 0 );
    rat_mode : in std_logic_vector( 2-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    cnt_out : out std_logic_vector( 12-1 downto 0 )
  );
end dl_adaptor_ctrl_sb_bit_order_rev;
architecture structural of dl_adaptor_ctrl_sb_bit_order_rev is 
  signal convert_dout_net : std_logic_vector( 12-1 downto 0 );
  signal concat_y_net_x0 : std_logic_vector( 11-1 downto 0 );
  signal clk_net : std_logic;
  signal counter12_op_net : std_logic_vector( 15-1 downto 0 );
  signal mux_y_net : std_logic_vector( 12-1 downto 0 );
  signal slice31_y_net : std_logic_vector( 9-1 downto 0 );
  signal convert2_dout_net : std_logic_vector( 12-1 downto 0 );
  signal convert3_dout_net : std_logic_vector( 12-1 downto 0 );
  signal slice6_y_net : std_logic_vector( 10-1 downto 0 );
  signal ce_net : std_logic;
  signal convert9_dout_net : std_logic_vector( 2-1 downto 0 );
  signal convert1_dout_net : std_logic_vector( 12-1 downto 0 );
  signal concat_y_net : std_logic_vector( 10-1 downto 0 );
  signal slice33_y_net : std_logic_vector( 11-1 downto 0 );
  signal concat_y_net_x1 : std_logic_vector( 9-1 downto 0 );
  signal reinterpret_output_port_net : std_logic_vector( 12-1 downto 0 );
begin
  cnt_out <= mux_y_net;
  counter12_op_net <= cnt_in;
  convert9_dout_net <= rat_mode;
  clk_net <= clk_1;
  ce_net <= ce_1;
  x10bit_order_rev : entity work.dl_adaptor_ctrl_10bit_order_rev 
  port map (
    index_i => slice6_y_net,
    index_o => concat_y_net
  );
  x11bit_order_rev : entity work.dl_adaptor_ctrl_11bit_order_rev 
  port map (
    index_i => slice33_y_net,
    index_o => concat_y_net_x0
  );
  x9bit_order_rev : entity work.dl_adaptor_ctrl_9bit_order_rev 
  port map (
    index_i => slice31_y_net,
    index_o => concat_y_net_x1
  );
  convert : entity work.dl_adaptor_ctrl_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 1,
    din_bin_pt => 0,
    din_width => 10,
    dout_arith => 1,
    dout_bin_pt => 0,
    dout_width => 12,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => concat_y_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert_dout_net
  );
  convert1 : entity work.dl_adaptor_ctrl_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 1,
    din_bin_pt => 0,
    din_width => 9,
    dout_arith => 1,
    dout_bin_pt => 0,
    dout_width => 12,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => concat_y_net_x1,
    clk => clk_net,
    ce => ce_net,
    dout => convert1_dout_net
  );
  convert2 : entity work.dl_adaptor_ctrl_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 1,
    din_bin_pt => 0,
    din_width => 11,
    dout_arith => 1,
    dout_bin_pt => 0,
    dout_width => 12,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => concat_y_net_x0,
    clk => clk_net,
    ce => ce_net,
    dout => convert2_dout_net
  );
  convert3 : entity work.dl_adaptor_ctrl_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 1,
    din_bin_pt => 0,
    din_width => 11,
    dout_arith => 1,
    dout_bin_pt => 1,
    dout_width => 12,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => concat_y_net_x0,
    clk => clk_net,
    ce => ce_net,
    dout => convert3_dout_net
  );
  mux : entity work.sysgen_mux_0383943c40 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => convert9_dout_net,
    d0 => convert_dout_net,
    d1 => convert1_dout_net,
    d2 => reinterpret_output_port_net,
    d3 => convert2_dout_net,
    y => mux_y_net
  );
  reinterpret : entity work.sysgen_reinterpret_de72a662de 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => convert3_dout_net,
    output_port => reinterpret_output_port_net
  );
  slice31 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 4,
    new_msb => 12,
    x_width => 15,
    y_width => 9
  )
  port map (
    x => counter12_op_net,
    y => slice31_y_net
  );
  slice33 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 4,
    new_msb => 14,
    x_width => 15,
    y_width => 11
  )
  port map (
    x => counter12_op_net,
    y => slice33_y_net
  );
  slice6 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 4,
    new_msb => 13,
    x_width => 15,
    y_width => 10
  )
  port map (
    x => counter12_op_net,
    y => slice6_y_net
  );
end structural;
-- Generated from Simulink block dl_adaptor_ctrl_struct
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_adaptor_ctrl_struct is
  port (
    bw_sel_i : in std_logic_vector( 4-1 downto 0 );
    rat_mode_i : in std_logic_vector( 2-1 downto 0 );
    s0_read_trig : in std_logic_vector( 1-1 downto 0 );
    s0_read_trig_en : in std_logic_vector( 1-1 downto 0 );
    sof0_i : in std_logic_vector( 1-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    buffer_rd_ctrl0 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl1 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl10 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl11 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl12 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl13 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl14 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl15 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl2 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl3 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl4 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl5 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl6 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl7 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl8 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl9 : out std_logic_vector( 15-1 downto 0 );
    sof_ahead_7_o : out std_logic_vector( 1-1 downto 0 );
    sof_o : out std_logic_vector( 1-1 downto 0 );
    sop_ahead_7_o : out std_logic_vector( 1-1 downto 0 );
    sop_o : out std_logic_vector( 1-1 downto 0 );
    subframe_no_o : out std_logic_vector( 9-1 downto 0 );
    symbol_no_o : out std_logic_vector( 9-1 downto 0 );
    valid_o : out std_logic_vector( 1-1 downto 0 )
  );
end dl_adaptor_ctrl_struct;
architecture structural of dl_adaptor_ctrl_struct is 
  signal slice8_y_net : std_logic_vector( 1-1 downto 0 );
  signal register22_q_net : std_logic_vector( 1-1 downto 0 );
  signal mux5_y_net : std_logic_vector( 16-1 downto 0 );
  signal logical6_y_net : std_logic_vector( 1-1 downto 0 );
  signal relational3_op_net : std_logic_vector( 1-1 downto 0 );
  signal slice44_y_net : std_logic_vector( 12-1 downto 0 );
  signal slice45_y_net : std_logic_vector( 12-1 downto 0 );
  signal relational4_op_net : std_logic_vector( 1-1 downto 0 );
  signal rom2_data_net : std_logic_vector( 36-1 downto 0 );
  signal rom_data_net : std_logic_vector( 17-1 downto 0 );
  signal slice5_y_net : std_logic_vector( 17-1 downto 0 );
  signal register1_q_net : std_logic_vector( 17-1 downto 0 );
  signal register12_q_net : std_logic_vector( 1-1 downto 0 );
  signal s0_read_trig_net : std_logic_vector( 1-1 downto 0 );
  signal s0_read_trig_en_net : std_logic_vector( 1-1 downto 0 );
  signal sof0_i_net : std_logic_vector( 1-1 downto 0 );
  signal clk_net : std_logic;
  signal mux3_y_net : std_logic_vector( 1-1 downto 0 );
  signal register23_q_net : std_logic_vector( 1-1 downto 0 );
  signal mux36_y_net : std_logic_vector( 2-1 downto 0 );
  signal delay5_q_net : std_logic_vector( 1-1 downto 0 );
  signal logical_y_net : std_logic_vector( 1-1 downto 0 );
  signal delay2_q_net : std_logic_vector( 1-1 downto 0 );
  signal register35_q_net : std_logic_vector( 1-1 downto 0 );
  signal ce_net : std_logic;
  signal delay1_q_net : std_logic_vector( 1-1 downto 0 );
  signal subframe_cnt_op_net : std_logic_vector( 9-1 downto 0 );
  signal symbol_cnt1_op_net : std_logic_vector( 9-1 downto 0 );
  signal counter12_op_net_x0 : std_logic_vector( 16-1 downto 0 );
  signal counter12_op_net : std_logic_vector( 15-1 downto 0 );
  signal mux_y_net : std_logic_vector( 12-1 downto 0 );
  signal rom1_data_net : std_logic_vector( 12-1 downto 0 );
  signal addsub1_s_net : std_logic_vector( 12-1 downto 0 );
  signal addsub2_s_net : std_logic_vector( 12-1 downto 0 );
  signal convert9_dout_net : std_logic_vector( 2-1 downto 0 );
  signal register36_q_net : std_logic_vector( 12-1 downto 0 );
  signal logical3_y_net : std_logic_vector( 1-1 downto 0 );
  signal register37_q_net : std_logic_vector( 1-1 downto 0 );
  signal logical5_y_net : std_logic_vector( 1-1 downto 0 );
  signal mux9_y_net : std_logic_vector( 12-1 downto 0 );
  signal register27_q_net : std_logic_vector( 1-1 downto 0 );
  signal register6_q_net : std_logic_vector( 2-1 downto 0 );
  signal constant1_op_net : std_logic_vector( 2-1 downto 0 );
  signal constant29_op_net : std_logic_vector( 2-1 downto 0 );
  signal concat4_y_net : std_logic_vector( 8-1 downto 0 );
  signal concat6_y_net : std_logic_vector( 8-1 downto 0 );
  signal slice3_y_net : std_logic_vector( 6-1 downto 0 );
  signal concat7_y_net : std_logic_vector( 6-1 downto 0 );
  signal constant10_op_net : std_logic_vector( 16-1 downto 0 );
  signal constant26_op_net : std_logic_vector( 2-1 downto 0 );
  signal constant30_op_net : std_logic_vector( 2-1 downto 0 );
  signal constant9_op_net : std_logic_vector( 16-1 downto 0 );
  signal constant5_op_net : std_logic_vector( 19-1 downto 0 );
  signal constant3_op_net : std_logic_vector( 16-1 downto 0 );
  signal logical_y_net_x0 : std_logic_vector( 1-1 downto 0 );
  signal relational_op_net : std_logic_vector( 1-1 downto 0 );
  signal logical2_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice26_y_net : std_logic_vector( 1-1 downto 0 );
  signal relational5_op_net : std_logic_vector( 1-1 downto 0 );
  signal relational2_op_net : std_logic_vector( 1-1 downto 0 );
  signal logical4_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice6_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice27_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice31_y_net : std_logic_vector( 1-1 downto 0 );
  signal logical1_y_net : std_logic_vector( 1-1 downto 0 );
  signal register40_q_net : std_logic_vector( 1-1 downto 0 );
  signal register77_q_net : std_logic_vector( 1-1 downto 0 );
  signal rat_mode_i_net : std_logic_vector( 2-1 downto 0 );
  signal register38_q_net : std_logic_vector( 15-1 downto 0 );
  signal concat1_y_net : std_logic_vector( 15-1 downto 0 );
  signal register19_q_net : std_logic_vector( 15-1 downto 0 );
  signal register3_q_net : std_logic_vector( 15-1 downto 0 );
  signal register24_q_net : std_logic_vector( 15-1 downto 0 );
  signal register30_q_net : std_logic_vector( 15-1 downto 0 );
  signal register29_q_net : std_logic_vector( 15-1 downto 0 );
  signal register31_q_net : std_logic_vector( 15-1 downto 0 );
  signal register20_q_net : std_logic_vector( 15-1 downto 0 );
  signal register32_q_net : std_logic_vector( 15-1 downto 0 );
  signal register25_q_net : std_logic_vector( 15-1 downto 0 );
  signal register26_q_net : std_logic_vector( 15-1 downto 0 );
  signal register28_q_net : std_logic_vector( 15-1 downto 0 );
  signal register9_q_net : std_logic_vector( 15-1 downto 0 );
  signal register33_q_net : std_logic_vector( 15-1 downto 0 );
  signal register21_q_net : std_logic_vector( 15-1 downto 0 );
  signal bw_sel_i_net : std_logic_vector( 4-1 downto 0 );
  signal register4_q_net : std_logic_vector( 1-1 downto 0 );
  signal slice7_y_net : std_logic_vector( 2-1 downto 0 );
  signal relational1_op_net : std_logic_vector( 1-1 downto 0 );
  signal timer_cnt_op_net : std_logic_vector( 19-1 downto 0 );
  signal slice33_y_net : std_logic_vector( 12-1 downto 0 );
  signal slice9_y_net : std_logic_vector( 2-1 downto 0 );
  signal slice16_y_net : std_logic_vector( 2-1 downto 0 );
begin
  buffer_rd_ctrl0 <= concat1_y_net;
  buffer_rd_ctrl1 <= register3_q_net;
  buffer_rd_ctrl10 <= register29_q_net;
  buffer_rd_ctrl11 <= register30_q_net;
  buffer_rd_ctrl12 <= register31_q_net;
  buffer_rd_ctrl13 <= register32_q_net;
  buffer_rd_ctrl14 <= register33_q_net;
  buffer_rd_ctrl15 <= register38_q_net;
  buffer_rd_ctrl2 <= register9_q_net;
  buffer_rd_ctrl3 <= register19_q_net;
  buffer_rd_ctrl4 <= register20_q_net;
  buffer_rd_ctrl5 <= register21_q_net;
  buffer_rd_ctrl6 <= register24_q_net;
  buffer_rd_ctrl7 <= register25_q_net;
  buffer_rd_ctrl8 <= register26_q_net;
  buffer_rd_ctrl9 <= register28_q_net;
  bw_sel_i_net <= bw_sel_i;
  rat_mode_i_net <= rat_mode_i;
  s0_read_trig_net <= s0_read_trig;
  s0_read_trig_en_net <= s0_read_trig_en;
  sof0_i_net <= sof0_i;
  sof_ahead_7_o <= register23_q_net;
  sof_o <= delay2_q_net;
  sop_ahead_7_o <= register35_q_net;
  sop_o <= delay1_q_net;
  subframe_no_o <= subframe_cnt_op_net;
  symbol_no_o <= symbol_cnt1_op_net;
  valid_o <= delay5_q_net;
  clk_net <= clk_1;
  ce_net <= ce_1;
  counter_0 : entity work.dl_adaptor_ctrl_counter_0 
  port map (
    sof => mux3_y_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    cnt => counter12_op_net_x0
  );
  counter_2 : entity work.dl_adaptor_ctrl_counter_2 
  port map (
    sop => register35_q_net,
    cnt_mode => mux36_y_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    cnt => counter12_op_net,
    valid => logical_y_net
  );
  sb_bit_order_rev : entity work.dl_adaptor_ctrl_sb_bit_order_rev 
  port map (
    cnt_in => counter12_op_net,
    rat_mode => convert9_dout_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    cnt_out => mux_y_net
  );
  addsub1 : entity work.dl_adaptor_ctrl_xladdsub 
  generic map (
    a_arith => xlUnsigned,
    a_bin_pt => 0,
    a_width => 12,
    b_arith => xlUnsigned,
    b_bin_pt => 0,
    b_width => 12,
    c_has_c_out => 0,
    c_latency => 1,
    c_output_width => 13,
    core_name0 => "dl_adaptor_ctrl_c_addsub_v12_0_i0",
    extra_registers => 0,
    full_s_arith => 1,
    full_s_width => 13,
    latency => 1,
    overflow => 1,
    quantization => 1,
    s_arith => xlUnsigned,
    s_bin_pt => 0,
    s_width => 12
  )
  port map (
    clr => '0',
    en => "1",
    a => addsub2_s_net,
    b => rom1_data_net,
    clk => clk_net,
    ce => ce_net,
    s => addsub1_s_net
  );
  addsub2 : entity work.dl_adaptor_ctrl_xladdsubmode 
  generic map (
    a_arith => xlUnsigned,
    a_bin_pt => 0,
    a_width => 12,
    b_arith => xlUnsigned,
    b_bin_pt => 0,
    b_width => 12,
    c_has_c_out => 0,
    c_latency => 1,
    c_output_width => 14,
    core_name0 => "dl_adaptor_ctrl_c_addsub_v12_0_i1",
    extra_registers => 0,
    full_s_arith => 2,
    full_s_width => 14,
    latency => 1,
    mode_arith => xlUnsigned,
    mode_bin_pt => 0,
    mode_width => 1,
    overflow => 1,
    quantization => 1,
    s_arith => xlUnsigned,
    s_bin_pt => 0,
    s_width => 12
  )
  port map (
    clr => '0',
    en => "1",
    a => register36_q_net,
    b => mux9_y_net,
    mode => register37_q_net,
    clk => clk_net,
    ce => ce_net,
    s => addsub2_s_net
  );
  concat1 : entity work.sysgen_concat_74c7cdbbd8 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => addsub1_s_net,
    in1 => register27_q_net,
    in2 => logical3_y_net,
    in3 => logical5_y_net,
    y => concat1_y_net
  );
  concat4 : entity work.sysgen_concat_715e01483f 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => concat7_y_net,
    in1 => register6_q_net,
    y => concat4_y_net
  );
  concat6 : entity work.sysgen_concat_d22ca6ba12 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => convert9_dout_net,
    in1 => slice3_y_net,
    y => concat6_y_net
  );
  concat7 : entity work.sysgen_concat_2025d9ba34 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => convert9_dout_net,
    in1 => bw_sel_i_net,
    y => concat7_y_net
  );
  constant1 : entity work.sysgen_constant_a7e943df29 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant1_op_net
  );
  constant10 : entity work.sysgen_constant_1a0ad524f7 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant10_op_net
  );
  constant26 : entity work.sysgen_constant_a7e943df29 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant26_op_net
  );
  constant29 : entity work.sysgen_constant_15e0441361 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant29_op_net
  );
  constant3 : entity work.sysgen_constant_91575c308b 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant3_op_net
  );
  constant30 : entity work.sysgen_constant_55d43e1094 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant30_op_net
  );
  constant5 : entity work.sysgen_constant_0ab0b0a9f4 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant5_op_net
  );
  constant9 : entity work.sysgen_constant_f969f34209 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant9_op_net
  );
  convert9 : entity work.dl_adaptor_ctrl_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 1,
    din_bin_pt => 0,
    din_width => 2,
    dout_arith => 1,
    dout_bin_pt => 0,
    dout_width => 2,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => rat_mode_i_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert9_dout_net
  );
  delay1 : entity work.dl_adaptor_ctrl_xldelay 
  generic map (
    latency => 7,
    reg_retiming => 0,
    reset => 0,
    width => 1
  )
  port map (
    en => '1',
    rst => '1',
    d => register35_q_net,
    clk => clk_net,
    ce => ce_net,
    q => delay1_q_net
  );
  delay2 : entity work.dl_adaptor_ctrl_xldelay 
  generic map (
    latency => 7,
    reg_retiming => 0,
    reset => 0,
    width => 1
  )
  port map (
    en => '1',
    rst => '1',
    d => register23_q_net,
    clk => clk_net,
    ce => ce_net,
    q => delay2_q_net
  );
  delay5 : entity work.dl_adaptor_ctrl_xldelay 
  generic map (
    latency => 5,
    reg_retiming => 0,
    reset => 0,
    width => 1
  )
  port map (
    en => '1',
    rst => '1',
    d => register40_q_net,
    clk => clk_net,
    ce => ce_net,
    q => delay5_q_net
  );
  logical : entity work.sysgen_logical_bbac2cef12 
  port map (
    clr => '0',
    d0 => register37_q_net,
    d1 => relational5_op_net,
    clk => clk_net,
    ce => ce_net,
    y => logical_y_net_x0
  );
  logical1 : entity work.sysgen_logical_05548660b4 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    d0 => register77_q_net,
    d1 => relational2_op_net,
    d2 => relational_op_net,
    y => logical1_y_net
  );
  logical2 : entity work.sysgen_logical_3a74bb4906 
  port map (
    clr => '0',
    d0 => register40_q_net,
    d1 => logical_y_net_x0,
    clk => clk_net,
    ce => ce_net,
    y => logical2_y_net
  );
  logical3 : entity work.sysgen_logical_ae04bdf9b4 
  port map (
    clr => '0',
    d0 => slice27_y_net,
    d1 => slice26_y_net,
    clk => clk_net,
    ce => ce_net,
    y => logical3_y_net
  );
  logical4 : entity work.sysgen_logical_42a857f0f6 
  port map (
    clr => '0',
    d0 => slice6_y_net,
    d1 => slice31_y_net,
    clk => clk_net,
    ce => ce_net,
    y => logical4_y_net
  );
  logical5 : entity work.sysgen_logical_ede55c8e05 
  port map (
    clr => '0',
    d0 => logical2_y_net,
    d1 => logical4_y_net,
    clk => clk_net,
    ce => ce_net,
    y => logical5_y_net
  );
  logical6 : entity work.sysgen_logical_5cd6b1873c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    d0 => relational3_op_net,
    d1 => register77_q_net,
    y => logical6_y_net
  );
  mux3 : entity work.sysgen_mux_54c7d996f5 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => s0_read_trig_en_net,
    d0 => sof0_i_net,
    d1 => s0_read_trig_net,
    y => mux3_y_net
  );
  mux36 : entity work.sysgen_mux_8782c8a191 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => convert9_dout_net,
    d0 => constant29_op_net,
    d1 => constant26_op_net,
    d2 => constant30_op_net,
    d3 => constant30_op_net,
    y => mux36_y_net
  );
  mux5 : entity work.sysgen_mux_0c8db7f0d6 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => mux36_y_net,
    d0 => constant3_op_net,
    d1 => constant9_op_net,
    d2 => constant10_op_net,
    d3 => constant10_op_net,
    y => mux5_y_net
  );
  mux9 : entity work.sysgen_mux_c9820323b8 
  port map (
    clr => '0',
    sel => relational4_op_net,
    d0 => slice45_y_net,
    d1 => slice44_y_net,
    clk => clk_net,
    ce => ce_net,
    y => mux9_y_net
  );
  rom : entity work.dl_adaptor_ctrl_xlsprom_dist 
  generic map (
    addr_width => 8,
    c_address_width => 8,
    c_width => 17,
    core_name0 => "dl_adaptor_ctrl_dist_mem_gen_i0",
    latency => 1
  )
  port map (
    en => "1",
    addr => concat6_y_net,
    clk => clk_net,
    ce => ce_net,
    data => rom_data_net
  );
  rom1 : entity work.dl_adaptor_ctrl_xlsprom_dist 
  generic map (
    addr_width => 8,
    c_address_width => 8,
    c_width => 12,
    core_name0 => "dl_adaptor_ctrl_dist_mem_gen_i1",
    latency => 1
  )
  port map (
    en => "1",
    addr => concat4_y_net,
    clk => clk_net,
    ce => ce_net,
    data => rom1_data_net
  );
  rom2 : entity work.dl_adaptor_ctrl_xlsprom_dist 
  generic map (
    addr_width => 6,
    c_address_width => 6,
    c_width => 36,
    core_name0 => "dl_adaptor_ctrl_dist_mem_gen_i2",
    latency => 1
  )
  port map (
    en => "1",
    addr => concat7_y_net,
    clk => clk_net,
    ce => ce_net,
    data => rom2_data_net
  );
  register1 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 17,
    init_value => b"00000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => slice5_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register1_q_net
  );
  register12 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => relational3_op_net,
    clk => clk_net,
    ce => ce_net,
    q => register12_q_net
  );
  register19 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 15,
    init_value => b"000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => register9_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register19_q_net
  );
  register20 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 15,
    init_value => b"000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => register19_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register20_q_net
  );
  register21 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 15,
    init_value => b"000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => register20_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register21_q_net
  );
  register22 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => register12_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register22_q_net
  );
  register23 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => register22_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register23_q_net
  );
  register24 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 15,
    init_value => b"000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => register21_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register24_q_net
  );
  register25 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 15,
    init_value => b"000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => register24_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register25_q_net
  );
  register26 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 15,
    init_value => b"000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => register25_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register26_q_net
  );
  register27 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => slice8_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register27_q_net
  );
  register28 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 15,
    init_value => b"000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => register26_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register28_q_net
  );
  register29 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 15,
    init_value => b"000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => register28_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register29_q_net
  );
  register3 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 15,
    init_value => b"000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => concat1_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register3_q_net
  );
  register30 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 15,
    init_value => b"000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => register29_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register30_q_net
  );
  register31 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 15,
    init_value => b"000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => register30_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register31_q_net
  );
  register32 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 15,
    init_value => b"000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => register31_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register32_q_net
  );
  register33 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 15,
    init_value => b"000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => register32_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register33_q_net
  );
  register35 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => logical1_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register35_q_net
  );
  register36 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 12,
    init_value => b"000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => mux_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register36_q_net
  );
  register37 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => relational4_op_net,
    clk => clk_net,
    ce => ce_net,
    q => register37_q_net
  );
  register38 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 15,
    init_value => b"000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => register33_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register38_q_net
  );
  register4 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => logical_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register4_q_net
  );
  register40 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => register4_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register40_q_net
  );
  register6 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 2,
    init_value => b"00"
  )
  port map (
    en => "1",
    rst => "0",
    d => slice7_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register6_q_net
  );
  register77 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => logical6_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register77_q_net
  );
  register9 : entity work.dl_adaptor_ctrl_xlregister 
  generic map (
    d_width => 15,
    init_value => b"000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => register3_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register9_q_net
  );
  relational : entity work.sysgen_relational_8f67196696 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    a => register1_q_net,
    b => rom_data_net,
    op => relational_op_net
  );
  relational1 : entity work.sysgen_relational_7183bca9d3 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    a => constant5_op_net,
    b => timer_cnt_op_net,
    op => relational1_op_net
  );
  relational2 : entity work.sysgen_relational_be68654ef0 
  port map (
    clr => '0',
    a => slice9_y_net,
    b => constant1_op_net,
    clk => clk_net,
    ce => ce_net,
    op => relational2_op_net
  );
  relational3 : entity work.sysgen_relational_ff045c43e8 
  port map (
    clr => '0',
    a => counter12_op_net_x0,
    b => mux5_y_net,
    clk => clk_net,
    ce => ce_net,
    op => relational3_op_net
  );
  relational4 : entity work.sysgen_relational_9676c04bf1 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    a => mux_y_net,
    b => slice44_y_net,
    op => relational4_op_net
  );
  relational5 : entity work.sysgen_relational_46f175c059 
  port map (
    clr => '0',
    a => mux_y_net,
    b => slice33_y_net,
    clk => clk_net,
    ce => ce_net,
    op => relational5_op_net
  );
  slice16 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 1,
    x_width => 19,
    y_width => 2
  )
  port map (
    x => timer_cnt_op_net,
    y => slice16_y_net
  );
  slice26 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 1,
    new_msb => 1,
    x_width => 2,
    y_width => 1
  )
  port map (
    x => slice16_y_net,
    y => slice26_y_net
  );
  slice27 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 0,
    x_width => 2,
    y_width => 1
  )
  port map (
    x => slice16_y_net,
    y => slice27_y_net
  );
  slice3 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 13,
    new_msb => 18,
    x_width => 19,
    y_width => 6
  )
  port map (
    x => timer_cnt_op_net,
    y => slice3_y_net
  );
  slice31 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 1,
    new_msb => 1,
    x_width => 2,
    y_width => 1
  )
  port map (
    x => convert9_dout_net,
    y => slice31_y_net
  );
  slice33 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 11,
    x_width => 36,
    y_width => 12
  )
  port map (
    x => rom2_data_net,
    y => slice33_y_net
  );
  slice44 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 12,
    new_msb => 23,
    x_width => 36,
    y_width => 12
  )
  port map (
    x => rom2_data_net,
    y => slice44_y_net
  );
  slice45 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 24,
    new_msb => 35,
    x_width => 36,
    y_width => 12
  )
  port map (
    x => rom2_data_net,
    y => slice45_y_net
  );
  slice5 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 2,
    new_msb => 18,
    x_width => 19,
    y_width => 17
  )
  port map (
    x => timer_cnt_op_net,
    y => slice5_y_net
  );
  slice6 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 3,
    new_msb => 3,
    x_width => 15,
    y_width => 1
  )
  port map (
    x => counter12_op_net,
    y => slice6_y_net
  );
  slice7 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 2,
    new_msb => 3,
    x_width => 15,
    y_width => 2
  )
  port map (
    x => counter12_op_net,
    y => slice7_y_net
  );
  slice8 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 0,
    x_width => 9,
    y_width => 1
  )
  port map (
    x => symbol_cnt1_op_net,
    y => slice8_y_net
  );
  slice9 : entity work.dl_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 1,
    x_width => 19,
    y_width => 2
  )
  port map (
    x => timer_cnt_op_net,
    y => slice9_y_net
  );
  subframe_cnt : entity work.dl_adaptor_ctrl_xlcounter_free 
  generic map (
    core_name0 => "dl_adaptor_ctrl_c_counter_binary_v12_0_i0",
    op_arith => xlUnsigned,
    op_width => 9
  )
  port map (
    clr => '0',
    rst => relational3_op_net,
    en => relational1_op_net,
    clk => clk_net,
    ce => ce_net,
    op => subframe_cnt_op_net
  );
  symbol_cnt1 : entity work.dl_adaptor_ctrl_xlcounter_free 
  generic map (
    core_name0 => "dl_adaptor_ctrl_c_counter_binary_v12_0_i0",
    op_arith => xlUnsigned,
    op_width => 9
  )
  port map (
    clr => '0',
    rst => register23_q_net,
    en => register35_q_net,
    clk => clk_net,
    ce => ce_net,
    op => symbol_cnt1_op_net
  );
  timer_cnt : entity work.dl_adaptor_ctrl_xlcounter_limit 
  generic map (
    cnt_15_0 => 32767,
    cnt_31_16 => 7,
    cnt_47_32 => 0,
    cnt_63_48 => 0,
    core_name0 => "dl_adaptor_ctrl_c_counter_binary_v12_0_i1",
    count_limited => 1,
    op_arith => xlUnsigned,
    op_width => 19
  )
  port map (
    en => "1",
    clr => '0',
    rst => relational3_op_net,
    clk => clk_net,
    ce => ce_net,
    op => timer_cnt_op_net
  );
end structural;
-- Generated from Simulink block 
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_adaptor_ctrl_default_clock_driver is
  port (
    dl_adaptor_ctrl_sysclk : in std_logic;
    dl_adaptor_ctrl_sysce : in std_logic;
    dl_adaptor_ctrl_sysclr : in std_logic;
    dl_adaptor_ctrl_clk1 : out std_logic;
    dl_adaptor_ctrl_ce1 : out std_logic
  );
end dl_adaptor_ctrl_default_clock_driver;
architecture structural of dl_adaptor_ctrl_default_clock_driver is 
begin
  clockdriver : entity work.xlclockdriver 
  generic map (
    period => 1,
    log_2_period => 1
  )
  port map (
    sysclk => dl_adaptor_ctrl_sysclk,
    sysce => dl_adaptor_ctrl_sysce,
    sysclr => dl_adaptor_ctrl_sysclr,
    clk => dl_adaptor_ctrl_clk1,
    ce => dl_adaptor_ctrl_ce1
  );
end structural;
-- Generated from Simulink block 
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_adaptor_ctrl is
  port (
    bw_sel_i : in std_logic_vector( 4-1 downto 0 );
    rat_mode_i : in std_logic_vector( 2-1 downto 0 );
    s0_read_trig : in std_logic_vector( 1-1 downto 0 );
    s0_read_trig_en : in std_logic_vector( 1-1 downto 0 );
    sof0_i : in std_logic_vector( 1-1 downto 0 );
    clk : in std_logic;
    buffer_rd_ctrl0 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl1 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl10 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl11 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl12 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl13 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl14 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl15 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl2 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl3 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl4 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl5 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl6 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl7 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl8 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl9 : out std_logic_vector( 15-1 downto 0 );
    sof_ahead_7_o : out std_logic_vector( 1-1 downto 0 );
    sof_o : out std_logic_vector( 1-1 downto 0 );
    sop_ahead_7_o : out std_logic_vector( 1-1 downto 0 );
    sop_o : out std_logic_vector( 1-1 downto 0 );
    subframe_no_o : out std_logic_vector( 9-1 downto 0 );
    symbol_no_o : out std_logic_vector( 9-1 downto 0 );
    valid_o : out std_logic_vector( 1-1 downto 0 )
  );
end dl_adaptor_ctrl;
architecture structural of dl_adaptor_ctrl is 
  attribute core_generation_info : string;
  attribute core_generation_info of structural : architecture is "dl_adaptor_ctrl,sysgen_core_2018_3,{,compilation=HDL Netlist,block_icon_display=Default,family=zynquplus,part=xczu19eg,speed=-2-i,package=ffvc1760,synthesis_language=vhdl,hdl_library=work,synthesis_strategy=Vivado Synthesis Defaults,implementation_strategy=Performance_Explore,testbench=0,interface_doc=0,ce_clr=0,clock_period=2.03451,system_simulink_period=2.03451e-09,waveform_viewer=0,axilite_interface=0,ip_catalog_plugin=0,hwcosim_burst_mode=0,simulation_time=0.0002,addsub=2,concat=7,constant=11,convert=5,counter=5,delay=3,logical=10,mux=5,register=28,reinterpret=1,relational=10,slice=48,sprom=3,}";
  signal clk_1_net : std_logic;
  signal ce_1_net : std_logic;
begin
  dl_adaptor_ctrl_default_clock_driver : entity work.dl_adaptor_ctrl_default_clock_driver 
  port map (
    dl_adaptor_ctrl_sysclk => clk,
    dl_adaptor_ctrl_sysce => '1',
    dl_adaptor_ctrl_sysclr => '0',
    dl_adaptor_ctrl_clk1 => clk_1_net,
    dl_adaptor_ctrl_ce1 => ce_1_net
  );
  dl_adaptor_ctrl_struct : entity work.dl_adaptor_ctrl_struct 
  port map (
    bw_sel_i => bw_sel_i,
    rat_mode_i => rat_mode_i,
    s0_read_trig => s0_read_trig,
    s0_read_trig_en => s0_read_trig_en,
    sof0_i => sof0_i,
    clk_1 => clk_1_net,
    ce_1 => ce_1_net,
    buffer_rd_ctrl0 => buffer_rd_ctrl0,
    buffer_rd_ctrl1 => buffer_rd_ctrl1,
    buffer_rd_ctrl10 => buffer_rd_ctrl10,
    buffer_rd_ctrl11 => buffer_rd_ctrl11,
    buffer_rd_ctrl12 => buffer_rd_ctrl12,
    buffer_rd_ctrl13 => buffer_rd_ctrl13,
    buffer_rd_ctrl14 => buffer_rd_ctrl14,
    buffer_rd_ctrl15 => buffer_rd_ctrl15,
    buffer_rd_ctrl2 => buffer_rd_ctrl2,
    buffer_rd_ctrl3 => buffer_rd_ctrl3,
    buffer_rd_ctrl4 => buffer_rd_ctrl4,
    buffer_rd_ctrl5 => buffer_rd_ctrl5,
    buffer_rd_ctrl6 => buffer_rd_ctrl6,
    buffer_rd_ctrl7 => buffer_rd_ctrl7,
    buffer_rd_ctrl8 => buffer_rd_ctrl8,
    buffer_rd_ctrl9 => buffer_rd_ctrl9,
    sof_ahead_7_o => sof_ahead_7_o,
    sof_o => sof_o,
    sop_ahead_7_o => sop_ahead_7_o,
    sop_o => sop_o,
    subframe_no_o => subframe_no_o,
    symbol_no_o => symbol_no_o,
    valid_o => valid_o
  );
end structural;
