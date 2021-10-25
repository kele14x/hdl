-- Generated from Simulink block ul_adaptor_ctrl/counter_2
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity ul_adaptor_ctrl_counter_2 is
  port (
    sop : in std_logic_vector( 1-1 downto 0 );
    cnt_mode : in std_logic_vector( 2-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    cnt : out std_logic_vector( 15-1 downto 0 );
    valid : out std_logic_vector( 1-1 downto 0 )
  );
end ul_adaptor_ctrl_counter_2;
architecture structural of ul_adaptor_ctrl_counter_2 is 
  signal counter12_op_net : std_logic_vector( 15-1 downto 0 );
  signal logical_y_net : std_logic_vector( 1-1 downto 0 );
  signal ce_net : std_logic;
  signal logical1_y_net : std_logic_vector( 1-1 downto 0 );
  signal constant2_op_net : std_logic_vector( 14-1 downto 0 );
  signal mux36_y_net : std_logic_vector( 2-1 downto 0 );
  signal ul_sop_ahead_3_i_net : std_logic_vector( 1-1 downto 0 );
  signal constant15_op_net : std_logic_vector( 15-1 downto 0 );
  signal relational11_op_net : std_logic_vector( 1-1 downto 0 );
  signal clk_net : std_logic;
  signal relational1_op_net : std_logic_vector( 1-1 downto 0 );
  signal relational2_op_net : std_logic_vector( 1-1 downto 0 );
  signal slice3_y_net : std_logic_vector( 13-1 downto 0 );
  signal slice1_y_net : std_logic_vector( 2-1 downto 0 );
begin
  cnt <= counter12_op_net;
  valid <= logical_y_net;
  ul_sop_ahead_3_i_net <= sop;
  mux36_y_net <= cnt_mode;
  clk_net <= clk_1;
  ce_net <= ce_1;
  constant15 : entity work.sysgen_constant_8d74f7e0b2 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant15_op_net
  );
  constant2 : entity work.sysgen_constant_107515d32e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant2_op_net
  );
  counter12 : entity work.ul_adaptor_ctrl_xlcounter_free 
  generic map (
    core_name0 => "ul_adaptor_ctrl_c_counter_binary_v12_0_i1",
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
  logical : entity work.sysgen_logical_5e8763524f 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    d0 => ul_sop_ahead_3_i_net,
    d1 => relational11_op_net,
    y => logical_y_net
  );
  logical1 : entity work.sysgen_logical_cba6e93afa 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    d0 => relational1_op_net,
    d1 => relational2_op_net,
    y => logical1_y_net
  );
  relational1 : entity work.sysgen_relational_e8f49e4c05 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    a => slice3_y_net,
    b => constant2_op_net,
    op => relational1_op_net
  );
  relational11 : entity work.sysgen_relational_7f301d0231 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    a => counter12_op_net,
    b => constant15_op_net,
    op => relational11_op_net
  );
  relational2 : entity work.sysgen_relational_7dc3043371 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    a => slice1_y_net,
    b => mux36_y_net,
    op => relational2_op_net
  );
  slice1 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice3 : entity work.ul_adaptor_ctrl_xlslice 
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
-- Generated from Simulink block ul_adaptor_ctrl/counter_4
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity ul_adaptor_ctrl_counter_4 is
  port (
    sof : in std_logic_vector( 1-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    cnt : out std_logic_vector( 16-1 downto 0 )
  );
end ul_adaptor_ctrl_counter_4;
architecture structural of ul_adaptor_ctrl_counter_4 is 
  signal counter12_op_net : std_logic_vector( 16-1 downto 0 );
  signal ul_sof_ahead_3_i_net : std_logic_vector( 1-1 downto 0 );
  signal logical_y_net : std_logic_vector( 1-1 downto 0 );
  signal clk_net : std_logic;
  signal constant15_op_net : std_logic_vector( 16-1 downto 0 );
  signal ce_net : std_logic;
  signal register1_q_net : std_logic_vector( 1-1 downto 0 );
  signal relational11_op_net : std_logic_vector( 1-1 downto 0 );
begin
  cnt <= counter12_op_net;
  ul_sof_ahead_3_i_net <= sof;
  clk_net <= clk_1;
  ce_net <= ce_1;
  constant15 : entity work.sysgen_constant_20276dd56f 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant15_op_net
  );
  counter12 : entity work.ul_adaptor_ctrl_xlcounter_free 
  generic map (
    core_name0 => "ul_adaptor_ctrl_c_counter_binary_v12_0_i2",
    op_arith => xlUnsigned,
    op_width => 16
  )
  port map (
    clr => '0',
    rst => ul_sof_ahead_3_i_net,
    en => logical_y_net,
    clk => clk_net,
    ce => ce_net,
    op => counter12_op_net
  );
  logical : entity work.sysgen_logical_5e8763524f 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    d0 => register1_q_net,
    d1 => relational11_op_net,
    y => logical_y_net
  );
  register1 : entity work.ul_adaptor_ctrl_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => ul_sof_ahead_3_i_net,
    clk => clk_net,
    ce => ce_net,
    q => register1_q_net
  );
  relational11 : entity work.sysgen_relational_34f04b2278 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    a => counter12_op_net,
    b => constant15_op_net,
    op => relational11_op_net
  );
end structural;
-- Generated from Simulink block ul_adaptor_ctrl/sb_bit_order_rev/10bit_order_rev
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity ul_adaptor_ctrl_10bit_order_rev is
  port (
    index_i : in std_logic_vector( 10-1 downto 0 );
    index_o : out std_logic_vector( 10-1 downto 0 )
  );
end ul_adaptor_ctrl_10bit_order_rev;
architecture structural of ul_adaptor_ctrl_10bit_order_rev is 
  signal slice6_y_net : std_logic_vector( 10-1 downto 0 );
  signal concat_y_net : std_logic_vector( 10-1 downto 0 );
  signal slice2_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice6_y_net_x0 : std_logic_vector( 1-1 downto 0 );
  signal slice9_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice7_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice3_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice4_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice5_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice1_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice8_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice10_y_net : std_logic_vector( 1-1 downto 0 );
begin
  index_o <= concat_y_net;
  slice6_y_net <= index_i;
  concat : entity work.sysgen_concat_d232360a89 
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
  slice1 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice10 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice2 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice3 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice4 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice5 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice6 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice7 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice8 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice9 : entity work.ul_adaptor_ctrl_xlslice 
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
-- Generated from Simulink block ul_adaptor_ctrl/sb_bit_order_rev/11bit_order_rev
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity ul_adaptor_ctrl_11bit_order_rev is
  port (
    index_i : in std_logic_vector( 11-1 downto 0 );
    index_o : out std_logic_vector( 11-1 downto 0 )
  );
end ul_adaptor_ctrl_11bit_order_rev;
architecture structural of ul_adaptor_ctrl_11bit_order_rev is 
  signal concat_y_net : std_logic_vector( 11-1 downto 0 );
  signal slice2_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice3_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice4_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice33_y_net : std_logic_vector( 11-1 downto 0 );
  signal slice1_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice7_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice5_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice8_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice9_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice10_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice6_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice11_y_net : std_logic_vector( 1-1 downto 0 );
begin
  index_o <= concat_y_net;
  slice33_y_net <= index_i;
  concat : entity work.sysgen_concat_ecc46364cf 
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
  slice1 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice10 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice11 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice2 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice3 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice4 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice5 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice6 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice7 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice8 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice9 : entity work.ul_adaptor_ctrl_xlslice 
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
-- Generated from Simulink block ul_adaptor_ctrl/sb_bit_order_rev/9bit_order_rev
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity ul_adaptor_ctrl_9bit_order_rev is
  port (
    index_i : in std_logic_vector( 9-1 downto 0 );
    index_o : out std_logic_vector( 9-1 downto 0 )
  );
end ul_adaptor_ctrl_9bit_order_rev;
architecture structural of ul_adaptor_ctrl_9bit_order_rev is 
  signal slice2_y_net : std_logic_vector( 1-1 downto 0 );
  signal concat_y_net : std_logic_vector( 9-1 downto 0 );
  signal slice1_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice3_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice4_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice5_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice6_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice7_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice8_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice31_y_net : std_logic_vector( 9-1 downto 0 );
  signal slice9_y_net : std_logic_vector( 1-1 downto 0 );
begin
  index_o <= concat_y_net;
  slice31_y_net <= index_i;
  concat : entity work.sysgen_concat_b67b10fb84 
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
  slice1 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice2 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice3 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice4 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice5 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice6 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice7 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice8 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice9 : entity work.ul_adaptor_ctrl_xlslice 
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
-- Generated from Simulink block ul_adaptor_ctrl/sb_bit_order_rev
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity ul_adaptor_ctrl_sb_bit_order_rev is
  port (
    cnt_in : in std_logic_vector( 15-1 downto 0 );
    rat_mode : in std_logic_vector( 2-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    cnt_out : out std_logic_vector( 12-1 downto 0 )
  );
end ul_adaptor_ctrl_sb_bit_order_rev;
architecture structural of ul_adaptor_ctrl_sb_bit_order_rev is 
  signal convert2_dout_net : std_logic_vector( 12-1 downto 0 );
  signal convert3_dout_net : std_logic_vector( 12-1 downto 0 );
  signal reinterpret_output_port_net : std_logic_vector( 12-1 downto 0 );
  signal mux_y_net : std_logic_vector( 12-1 downto 0 );
  signal clk_net : std_logic;
  signal counter12_op_net : std_logic_vector( 15-1 downto 0 );
  signal convert9_dout_net : std_logic_vector( 2-1 downto 0 );
  signal ce_net : std_logic;
  signal concat_y_net : std_logic_vector( 10-1 downto 0 );
  signal slice31_y_net : std_logic_vector( 9-1 downto 0 );
  signal concat_y_net_x1 : std_logic_vector( 9-1 downto 0 );
  signal slice6_y_net : std_logic_vector( 10-1 downto 0 );
  signal concat_y_net_x0 : std_logic_vector( 11-1 downto 0 );
  signal slice33_y_net : std_logic_vector( 11-1 downto 0 );
  signal convert_dout_net : std_logic_vector( 12-1 downto 0 );
  signal convert1_dout_net : std_logic_vector( 12-1 downto 0 );
begin
  cnt_out <= mux_y_net;
  counter12_op_net <= cnt_in;
  convert9_dout_net <= rat_mode;
  clk_net <= clk_1;
  ce_net <= ce_1;
  x10bit_order_rev : entity work.ul_adaptor_ctrl_10bit_order_rev 
  port map (
    index_i => slice6_y_net,
    index_o => concat_y_net
  );
  x11bit_order_rev : entity work.ul_adaptor_ctrl_11bit_order_rev 
  port map (
    index_i => slice33_y_net,
    index_o => concat_y_net_x0
  );
  x9bit_order_rev : entity work.ul_adaptor_ctrl_9bit_order_rev 
  port map (
    index_i => slice31_y_net,
    index_o => concat_y_net_x1
  );
  convert : entity work.ul_adaptor_ctrl_xlconvert 
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
  convert1 : entity work.ul_adaptor_ctrl_xlconvert 
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
  convert2 : entity work.ul_adaptor_ctrl_xlconvert 
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
  convert3 : entity work.ul_adaptor_ctrl_xlconvert 
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
  mux : entity work.sysgen_mux_61602457b7 
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
  reinterpret : entity work.sysgen_reinterpret_da3a27d93d 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => convert3_dout_net,
    output_port => reinterpret_output_port_net
  );
  slice31 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice33 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice6 : entity work.ul_adaptor_ctrl_xlslice 
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
-- Generated from Simulink block ul_adaptor_ctrl_struct
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity ul_adaptor_ctrl_struct is
  port (
    bw_sel_i : in std_logic_vector( 4-1 downto 0 );
    rat_mode_i : in std_logic_vector( 2-1 downto 0 );
    ul_sof_ahead_3_i : in std_logic_vector( 1-1 downto 0 );
    ul_sop_ahead_3_i : in std_logic_vector( 1-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    buffer_wr_ctrl : out std_logic_vector( 14-1 downto 0 );
    symbol_no_o : out std_logic_vector( 9-1 downto 0 );
    ul_buf_ready_o : out std_logic_vector( 1-1 downto 0 )
  );
end ul_adaptor_ctrl_struct;
architecture structural of ul_adaptor_ctrl_struct is 
  signal slice16_y_net : std_logic_vector( 2-1 downto 0 );
  signal slice33_y_net : std_logic_vector( 12-1 downto 0 );
  signal constant17_op_net : std_logic_vector( 16-1 downto 0 );
  signal constant16_op_net : std_logic_vector( 16-1 downto 0 );
  signal constant18_op_net : std_logic_vector( 16-1 downto 0 );
  signal inverter4_op_net : std_logic_vector( 1-1 downto 0 );
  signal logical2_y_net : std_logic_vector( 1-1 downto 0 );
  signal inverter3_op_net : std_logic_vector( 1-1 downto 0 );
  signal slice27_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice26_y_net : std_logic_vector( 1-1 downto 0 );
  signal relational5_op_net : std_logic_vector( 1-1 downto 0 );
  signal relational4_op_net : std_logic_vector( 1-1 downto 0 );
  signal slice6_y_net : std_logic_vector( 1-1 downto 0 );
  signal logical4_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice31_y_net : std_logic_vector( 1-1 downto 0 );
  signal rom2_data_net : std_logic_vector( 36-1 downto 0 );
  signal relational3_op_net : std_logic_vector( 1-1 downto 0 );
  signal slice7_y_net : std_logic_vector( 2-1 downto 0 );
  signal slice45_y_net : std_logic_vector( 12-1 downto 0 );
  signal mux6_y_net : std_logic_vector( 16-1 downto 0 );
  signal slice44_y_net : std_logic_vector( 12-1 downto 0 );
  signal ul_sof_ahead_3_i_net : std_logic_vector( 1-1 downto 0 );
  signal clk_net : std_logic;
  signal mux_y_net : std_logic_vector( 12-1 downto 0 );
  signal convert9_dout_net : std_logic_vector( 2-1 downto 0 );
  signal rat_mode_i_net : std_logic_vector( 2-1 downto 0 );
  signal ce_net : std_logic;
  signal logical_y_net : std_logic_vector( 1-1 downto 0 );
  signal concat1_y_net : std_logic_vector( 14-1 downto 0 );
  signal bw_sel_i_net : std_logic_vector( 4-1 downto 0 );
  signal register10_q_net : std_logic_vector( 1-1 downto 0 );
  signal ul_sop_ahead_3_i_net : std_logic_vector( 1-1 downto 0 );
  signal counter12_op_net_x0 : std_logic_vector( 15-1 downto 0 );
  signal mux36_y_net : std_logic_vector( 2-1 downto 0 );
  signal symbol_cnt1_op_net : std_logic_vector( 9-1 downto 0 );
  signal counter12_op_net : std_logic_vector( 16-1 downto 0 );
  signal constant30_op_net : std_logic_vector( 2-1 downto 0 );
  signal constant26_op_net : std_logic_vector( 2-1 downto 0 );
  signal register37_q_net : std_logic_vector( 1-1 downto 0 );
  signal rom1_data_net : std_logic_vector( 12-1 downto 0 );
  signal addsub1_s_net : std_logic_vector( 12-1 downto 0 );
  signal register36_q_net : std_logic_vector( 12-1 downto 0 );
  signal mux9_y_net : std_logic_vector( 12-1 downto 0 );
  signal addsub2_s_net : std_logic_vector( 12-1 downto 0 );
  signal concat7_y_net : std_logic_vector( 6-1 downto 0 );
  signal logical3_y_net : std_logic_vector( 1-1 downto 0 );
  signal concat4_y_net : std_logic_vector( 8-1 downto 0 );
  signal register6_q_net : std_logic_vector( 2-1 downto 0 );
  signal constant29_op_net : std_logic_vector( 2-1 downto 0 );
  signal slice8_y_net : std_logic_vector( 1-1 downto 0 );
begin
  buffer_wr_ctrl <= concat1_y_net;
  bw_sel_i_net <= bw_sel_i;
  rat_mode_i_net <= rat_mode_i;
  symbol_no_o <= symbol_cnt1_op_net;
  ul_buf_ready_o <= register10_q_net;
  ul_sof_ahead_3_i_net <= ul_sof_ahead_3_i;
  ul_sop_ahead_3_i_net <= ul_sop_ahead_3_i;
  clk_net <= clk_1;
  ce_net <= ce_1;
  counter_2 : entity work.ul_adaptor_ctrl_counter_2 
  port map (
    sop => ul_sop_ahead_3_i_net,
    cnt_mode => mux36_y_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    cnt => counter12_op_net_x0,
    valid => logical_y_net
  );
  counter_4 : entity work.ul_adaptor_ctrl_counter_4 
  port map (
    sof => ul_sof_ahead_3_i_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    cnt => counter12_op_net
  );
  sb_bit_order_rev : entity work.ul_adaptor_ctrl_sb_bit_order_rev 
  port map (
    cnt_in => counter12_op_net_x0,
    rat_mode => convert9_dout_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    cnt_out => mux_y_net
  );
  addsub1 : entity work.ul_adaptor_ctrl_xladdsub 
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
    core_name0 => "ul_adaptor_ctrl_c_addsub_v12_0_i0",
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
  addsub2 : entity work.ul_adaptor_ctrl_xladdsubmode 
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
    core_name0 => "ul_adaptor_ctrl_c_addsub_v12_0_i1",
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
  concat1 : entity work.sysgen_concat_7df7b62071 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => slice8_y_net,
    in1 => addsub1_s_net,
    in2 => logical3_y_net,
    y => concat1_y_net
  );
  concat4 : entity work.sysgen_concat_4f5955103b 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => concat7_y_net,
    in1 => register6_q_net,
    y => concat4_y_net
  );
  concat7 : entity work.sysgen_concat_a365dd9af1 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => convert9_dout_net,
    in1 => bw_sel_i_net,
    y => concat7_y_net
  );
  constant26 : entity work.sysgen_constant_bfcedebd66 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant26_op_net
  );
  constant29 : entity work.sysgen_constant_0a05339443 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant29_op_net
  );
  constant30 : entity work.sysgen_constant_80cd7947b0 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant30_op_net
  );
  convert9 : entity work.ul_adaptor_ctrl_xlconvert 
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
  inverter3 : entity work.sysgen_inverter_da04dff5aa 
  port map (
    clr => '0',
    ip => slice27_y_net,
    clk => clk_net,
    ce => ce_net,
    op => inverter3_op_net
  );
  inverter4 : entity work.sysgen_inverter_da04dff5aa 
  port map (
    clr => '0',
    ip => slice26_y_net,
    clk => clk_net,
    ce => ce_net,
    op => inverter4_op_net
  );
  logical2 : entity work.sysgen_logical_5e8763524f 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    d0 => relational4_op_net,
    d1 => relational5_op_net,
    y => logical2_y_net
  );
  logical3 : entity work.sysgen_logical_23093b4eff 
  port map (
    clr => '0',
    d0 => logical2_y_net,
    d1 => logical4_y_net,
    d2 => inverter3_op_net,
    d3 => inverter4_op_net,
    d4 => logical_y_net,
    clk => clk_net,
    ce => ce_net,
    y => logical3_y_net
  );
  logical4 : entity work.sysgen_logical_952e4d3e4a 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    d0 => slice6_y_net,
    d1 => slice31_y_net,
    y => logical4_y_net
  );
  mux36 : entity work.sysgen_mux_b04336f14b 
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
  mux9 : entity work.sysgen_mux_8fdb8580e7 
  port map (
    clr => '0',
    sel => relational4_op_net,
    d0 => slice45_y_net,
    d1 => slice44_y_net,
    clk => clk_net,
    ce => ce_net,
    y => mux9_y_net
  );
  rom1 : entity work.ul_adaptor_ctrl_xlsprom_dist 
  generic map (
    addr_width => 8,
    c_address_width => 8,
    c_width => 12,
    core_name0 => "ul_adaptor_ctrl_dist_mem_gen_i0",
    latency => 1
  )
  port map (
    en => "1",
    addr => concat4_y_net,
    clk => clk_net,
    ce => ce_net,
    data => rom1_data_net
  );
  rom2 : entity work.ul_adaptor_ctrl_xlsprom_dist 
  generic map (
    addr_width => 6,
    c_address_width => 6,
    c_width => 36,
    core_name0 => "ul_adaptor_ctrl_dist_mem_gen_i1",
    latency => 1
  )
  port map (
    en => "1",
    addr => concat7_y_net,
    clk => clk_net,
    ce => ce_net,
    data => rom2_data_net
  );
  register10 : entity work.ul_adaptor_ctrl_xlregister 
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
    q => register10_q_net
  );
  register36 : entity work.ul_adaptor_ctrl_xlregister 
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
  register37 : entity work.ul_adaptor_ctrl_xlregister 
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
  register6 : entity work.ul_adaptor_ctrl_xlregister 
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
  relational3 : entity work.sysgen_relational_9c9f115dea 
  port map (
    clr => '0',
    a => counter12_op_net,
    b => mux6_y_net,
    clk => clk_net,
    ce => ce_net,
    op => relational3_op_net
  );
  relational4 : entity work.sysgen_relational_f3e22668f7 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    a => mux_y_net,
    b => slice44_y_net,
    op => relational4_op_net
  );
  relational5 : entity work.sysgen_relational_a0456157c8 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    a => mux_y_net,
    b => slice33_y_net,
    op => relational5_op_net
  );
  slice16 : entity work.ul_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 1,
    x_width => 15,
    y_width => 2
  )
  port map (
    x => counter12_op_net_x0,
    y => slice16_y_net
  );
  slice26 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice27 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice31 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice33 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice44 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice45 : entity work.ul_adaptor_ctrl_xlslice 
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
  slice6 : entity work.ul_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 3,
    new_msb => 3,
    x_width => 15,
    y_width => 1
  )
  port map (
    x => counter12_op_net_x0,
    y => slice6_y_net
  );
  slice7 : entity work.ul_adaptor_ctrl_xlslice 
  generic map (
    new_lsb => 2,
    new_msb => 3,
    x_width => 15,
    y_width => 2
  )
  port map (
    x => counter12_op_net_x0,
    y => slice7_y_net
  );
  slice8 : entity work.ul_adaptor_ctrl_xlslice 
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
  symbol_cnt1 : entity work.ul_adaptor_ctrl_xlcounter_free 
  generic map (
    core_name0 => "ul_adaptor_ctrl_c_counter_binary_v12_0_i0",
    op_arith => xlUnsigned,
    op_width => 9
  )
  port map (
    clr => '0',
    rst => ul_sof_ahead_3_i_net,
    en => ul_sop_ahead_3_i_net,
    clk => clk_net,
    ce => ce_net,
    op => symbol_cnt1_op_net
  );
  constant16 : entity work.sysgen_constant_682e3d000d 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant16_op_net
  );
  constant17 : entity work.sysgen_constant_e86e69a387 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant17_op_net
  );
  constant18 : entity work.sysgen_constant_996f61694d 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant18_op_net
  );
  mux6 : entity work.sysgen_mux_51d0269415 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => mux36_y_net,
    d0 => constant17_op_net,
    d1 => constant18_op_net,
    d2 => constant16_op_net,
    d3 => constant16_op_net,
    y => mux6_y_net
  );
end structural;
-- Generated from Simulink block 
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity ul_adaptor_ctrl_default_clock_driver is
  port (
    ul_adaptor_ctrl_sysclk : in std_logic;
    ul_adaptor_ctrl_sysce : in std_logic;
    ul_adaptor_ctrl_sysclr : in std_logic;
    ul_adaptor_ctrl_clk1 : out std_logic;
    ul_adaptor_ctrl_ce1 : out std_logic
  );
end ul_adaptor_ctrl_default_clock_driver;
architecture structural of ul_adaptor_ctrl_default_clock_driver is 
begin
  clockdriver : entity work.xlclockdriver 
  generic map (
    period => 1,
    log_2_period => 1
  )
  port map (
    sysclk => ul_adaptor_ctrl_sysclk,
    sysce => ul_adaptor_ctrl_sysce,
    sysclr => ul_adaptor_ctrl_sysclr,
    clk => ul_adaptor_ctrl_clk1,
    ce => ul_adaptor_ctrl_ce1
  );
end structural;
-- Generated from Simulink block 
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity ul_adaptor_ctrl is
  port (
    bw_sel_i : in std_logic_vector( 4-1 downto 0 );
    rat_mode_i : in std_logic_vector( 2-1 downto 0 );
    ul_sof_ahead_3_i : in std_logic_vector( 1-1 downto 0 );
    ul_sop_ahead_3_i : in std_logic_vector( 1-1 downto 0 );
    clk : in std_logic;
    buffer_wr_ctrl : out std_logic_vector( 14-1 downto 0 );
    symbol_no_o : out std_logic_vector( 9-1 downto 0 );
    ul_buf_ready_o : out std_logic_vector( 1-1 downto 0 )
  );
end ul_adaptor_ctrl;
architecture structural of ul_adaptor_ctrl is 
  attribute core_generation_info : string;
  attribute core_generation_info of structural : architecture is "ul_adaptor_ctrl,sysgen_core_2018_3,{,compilation=HDL Netlist,block_icon_display=Default,family=zynquplusRFSOC,part=xczu29dr,speed=-2LVI-i,package=ffvf1760,synthesis_language=vhdl,hdl_library=work,synthesis_strategy=Vivado Synthesis Defaults,implementation_strategy=Performance_Explore,testbench=0,interface_doc=0,ce_clr=0,clock_period=2.03451,system_simulink_period=2.03451e-09,waveform_viewer=0,axilite_interface=0,ip_catalog_plugin=0,hwcosim_burst_mode=0,simulation_time=0.0001,addsub=2,concat=6,constant=9,convert=5,counter=3,inv=2,logical=6,mux=4,register=5,reinterpret=1,relational=7,slice=45,sprom=2,}";
  signal clk_1_net : std_logic;
  signal ce_1_net : std_logic;
begin
  ul_adaptor_ctrl_default_clock_driver : entity work.ul_adaptor_ctrl_default_clock_driver 
  port map (
    ul_adaptor_ctrl_sysclk => clk,
    ul_adaptor_ctrl_sysce => '1',
    ul_adaptor_ctrl_sysclr => '0',
    ul_adaptor_ctrl_clk1 => clk_1_net,
    ul_adaptor_ctrl_ce1 => ce_1_net
  );
  ul_adaptor_ctrl_struct : entity work.ul_adaptor_ctrl_struct 
  port map (
    bw_sel_i => bw_sel_i,
    rat_mode_i => rat_mode_i,
    ul_sof_ahead_3_i => ul_sof_ahead_3_i,
    ul_sop_ahead_3_i => ul_sop_ahead_3_i,
    clk_1 => clk_1_net,
    ce_1 => ce_1_net,
    buffer_wr_ctrl => buffer_wr_ctrl,
    symbol_no_o => symbol_no_o,
    ul_buf_ready_o => ul_buf_ready_o
  );
end structural;
