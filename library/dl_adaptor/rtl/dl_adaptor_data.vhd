-- Generated from Simulink block dl_adaptor_data/barrel_shift1
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_adaptor_data_barrel_shift1 is
  port (
    data : in std_logic_vector( 9-1 downto 0 );
    exp : in std_logic_vector( 3-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    mantissa : out std_logic_vector( 16-1 downto 0 )
  );
end dl_adaptor_data_barrel_shift1;
architecture structural of dl_adaptor_data_barrel_shift1 is 
  signal ce_net : std_logic;
  signal slice14_y_net : std_logic_vector( 3-1 downto 0 );
  signal reinterpret9_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert1_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert2_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret4_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret9_output_port_net_x0 : std_logic_vector( 16-1 downto 0 );
  signal clk_net : std_logic;
  signal convert3_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret3_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert5_dout_net : std_logic_vector( 16-1 downto 0 );
  signal convert4_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret5_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal mux3_y_net : std_logic_vector( 16-1 downto 0 );
  signal convert7_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret6_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal reinterpret7_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal reinterpret8_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert6_dout_net : std_logic_vector( 16-1 downto 0 );
begin
  mantissa <= reinterpret9_output_port_net_x0;
  reinterpret9_output_port_net <= data;
  slice14_y_net <= exp;
  clk_net <= clk_1;
  ce_net <= ce_1;
  convert : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 7,
    din_width => 9,
    dout_arith => 2,
    dout_bin_pt => 7,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret2_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert_dout_net
  );
  convert1 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 6,
    din_width => 9,
    dout_arith => 2,
    dout_bin_pt => 7,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret1_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert1_dout_net
  );
  convert2 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 5,
    din_width => 9,
    dout_arith => 2,
    dout_bin_pt => 7,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret3_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert2_dout_net
  );
  convert3 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 4,
    din_width => 9,
    dout_arith => 2,
    dout_bin_pt => 7,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret4_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert3_dout_net
  );
  convert4 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 3,
    din_width => 9,
    dout_arith => 2,
    dout_bin_pt => 7,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret5_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert4_dout_net
  );
  convert5 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 2,
    din_width => 9,
    dout_arith => 2,
    dout_bin_pt => 7,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret6_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert5_dout_net
  );
  convert6 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 1,
    din_width => 9,
    dout_arith => 2,
    dout_bin_pt => 7,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret7_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert6_dout_net
  );
  convert7 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 0,
    din_width => 9,
    dout_arith => 2,
    dout_bin_pt => 7,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret8_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert7_dout_net
  );
  mux3 : entity work.sysgen_mux_288381b4d5 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => slice14_y_net,
    d0 => convert_dout_net,
    d1 => convert1_dout_net,
    d2 => convert2_dout_net,
    d3 => convert3_dout_net,
    d4 => convert4_dout_net,
    d5 => convert5_dout_net,
    d6 => convert6_dout_net,
    d7 => convert7_dout_net,
    y => mux3_y_net
  );
  reinterpret1 : entity work.sysgen_reinterpret_910df35f9e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret1_output_port_net
  );
  reinterpret2 : entity work.sysgen_reinterpret_910df35f9e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret9_output_port_net,
    output_port => reinterpret2_output_port_net
  );
  reinterpret3 : entity work.sysgen_reinterpret_910df35f9e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret3_output_port_net
  );
  reinterpret4 : entity work.sysgen_reinterpret_910df35f9e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret4_output_port_net
  );
  reinterpret5 : entity work.sysgen_reinterpret_910df35f9e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret5_output_port_net
  );
  reinterpret6 : entity work.sysgen_reinterpret_910df35f9e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret6_output_port_net
  );
  reinterpret7 : entity work.sysgen_reinterpret_910df35f9e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret7_output_port_net
  );
  reinterpret8 : entity work.sysgen_reinterpret_910df35f9e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret8_output_port_net
  );
  reinterpret9 : entity work.sysgen_reinterpret_d686c88fee 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => mux3_y_net,
    output_port => reinterpret9_output_port_net_x0
  );
end structural;
-- Generated from Simulink block dl_adaptor_data/barrel_shift2
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_adaptor_data_barrel_shift2 is
  port (
    data : in std_logic_vector( 9-1 downto 0 );
    exp : in std_logic_vector( 3-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    mantissa : out std_logic_vector( 16-1 downto 0 )
  );
end dl_adaptor_data_barrel_shift2;
architecture structural of dl_adaptor_data_barrel_shift2 is 
  signal convert3_dout_net : std_logic_vector( 16-1 downto 0 );
  signal slice14_y_net : std_logic_vector( 3-1 downto 0 );
  signal reinterpret3_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal reinterpret9_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal convert2_dout_net : std_logic_vector( 16-1 downto 0 );
  signal ce_net : std_logic;
  signal reinterpret2_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal clk_net : std_logic;
  signal convert_dout_net : std_logic_vector( 16-1 downto 0 );
  signal convert1_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal reinterpret8_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal mux3_y_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret8_output_port_net_x0 : std_logic_vector( 9-1 downto 0 );
  signal reinterpret4_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert5_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret6_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert4_dout_net : std_logic_vector( 16-1 downto 0 );
  signal convert7_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret5_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal reinterpret7_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert6_dout_net : std_logic_vector( 16-1 downto 0 );
begin
  mantissa <= reinterpret9_output_port_net;
  reinterpret8_output_port_net <= data;
  slice14_y_net <= exp;
  clk_net <= clk_1;
  ce_net <= ce_1;
  convert : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 7,
    din_width => 9,
    dout_arith => 2,
    dout_bin_pt => 7,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret2_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert_dout_net
  );
  convert1 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 6,
    din_width => 9,
    dout_arith => 2,
    dout_bin_pt => 7,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret1_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert1_dout_net
  );
  convert2 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 5,
    din_width => 9,
    dout_arith => 2,
    dout_bin_pt => 7,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret3_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert2_dout_net
  );
  convert3 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 4,
    din_width => 9,
    dout_arith => 2,
    dout_bin_pt => 7,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret4_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert3_dout_net
  );
  convert4 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 3,
    din_width => 9,
    dout_arith => 2,
    dout_bin_pt => 7,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret5_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert4_dout_net
  );
  convert5 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 2,
    din_width => 9,
    dout_arith => 2,
    dout_bin_pt => 7,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret6_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert5_dout_net
  );
  convert6 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 1,
    din_width => 9,
    dout_arith => 2,
    dout_bin_pt => 7,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret7_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert6_dout_net
  );
  convert7 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 0,
    din_width => 9,
    dout_arith => 2,
    dout_bin_pt => 7,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret8_output_port_net_x0,
    clk => clk_net,
    ce => ce_net,
    dout => convert7_dout_net
  );
  mux3 : entity work.sysgen_mux_288381b4d5 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => slice14_y_net,
    d0 => convert_dout_net,
    d1 => convert1_dout_net,
    d2 => convert2_dout_net,
    d3 => convert3_dout_net,
    d4 => convert4_dout_net,
    d5 => convert5_dout_net,
    d6 => convert6_dout_net,
    d7 => convert7_dout_net,
    y => mux3_y_net
  );
  reinterpret1 : entity work.sysgen_reinterpret_910df35f9e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret1_output_port_net
  );
  reinterpret2 : entity work.sysgen_reinterpret_910df35f9e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret8_output_port_net,
    output_port => reinterpret2_output_port_net
  );
  reinterpret3 : entity work.sysgen_reinterpret_910df35f9e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret3_output_port_net
  );
  reinterpret4 : entity work.sysgen_reinterpret_910df35f9e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret4_output_port_net
  );
  reinterpret5 : entity work.sysgen_reinterpret_910df35f9e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret5_output_port_net
  );
  reinterpret6 : entity work.sysgen_reinterpret_910df35f9e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret6_output_port_net
  );
  reinterpret7 : entity work.sysgen_reinterpret_910df35f9e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret7_output_port_net
  );
  reinterpret8 : entity work.sysgen_reinterpret_910df35f9e 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret8_output_port_net_x0
  );
  reinterpret9 : entity work.sysgen_reinterpret_d686c88fee 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => mux3_y_net,
    output_port => reinterpret9_output_port_net
  );
end structural;
-- Generated from Simulink block dl_adaptor_data_struct
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_adaptor_data_struct is
  port (
    buffer_mem_addr_i : in std_logic_vector( 12-1 downto 0 );
    buffer_mem_ctrl_en : in std_logic_vector( 2-1 downto 0 );
    buffer_mem_data_i : in std_logic_vector( 32-1 downto 0 );
    buffer_mem_we : in std_logic_vector( 1-1 downto 0 );
    buffer_rd_ctrl_i : in std_logic_vector( 15-1 downto 0 );
    compression_mode : in std_logic_vector( 2-1 downto 0 );
    data_i : in std_logic_vector( 64-1 downto 0 );
    data_i_even : in std_logic_vector( 16-1 downto 0 );
    data_i_odd : in std_logic_vector( 16-1 downto 0 );
    data_q_even : in std_logic_vector( 16-1 downto 0 );
    data_q_odd : in std_logic_vector( 16-1 downto 0 );
    re_no_i : in std_logic_vector( 12-1 downto 0 );
    sof_i : in std_logic_vector( 1-1 downto 0 );
    sop_i : in std_logic_vector( 1-1 downto 0 );
    valid_i : in std_logic_vector( 1-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    buffer_mem_data_o : out std_logic_vector( 32-1 downto 0 );
    idata_o : out std_logic_vector( 16-1 downto 0 );
    qdata_o : out std_logic_vector( 16-1 downto 0 )
  );
end dl_adaptor_data_struct;
architecture structural of dl_adaptor_data_struct is 
  signal buffer_mem_data_i_net : std_logic_vector( 32-1 downto 0 );
  signal compression_mode_net : std_logic_vector( 2-1 downto 0 );
  signal data_i_odd_net : std_logic_vector( 16-1 downto 0 );
  signal data_q_odd_net : std_logic_vector( 16-1 downto 0 );
  signal sof_i_net : std_logic_vector( 1-1 downto 0 );
  signal data_i_even_net : std_logic_vector( 16-1 downto 0 );
  signal data_q_even_net : std_logic_vector( 16-1 downto 0 );
  signal mux4_y_net : std_logic_vector( 16-1 downto 0 );
  signal data_i_net : std_logic_vector( 64-1 downto 0 );
  signal mux2_y_net : std_logic_vector( 16-1 downto 0 );
  signal buffer_mem_ctrl_en_net : std_logic_vector( 2-1 downto 0 );
  signal re_no_i_net : std_logic_vector( 12-1 downto 0 );
  signal buffer_mem_addr_i_net : std_logic_vector( 12-1 downto 0 );
  signal buffer_rd_ctrl_i_net : std_logic_vector( 15-1 downto 0 );
  signal buffer_mem_we_net : std_logic_vector( 1-1 downto 0 );
  signal sop_i_net : std_logic_vector( 1-1 downto 0 );
  signal mux1_y_net : std_logic_vector( 32-1 downto 0 );
  signal concat3_y_net : std_logic_vector( 12-1 downto 0 );
  signal register16_q_net : std_logic_vector( 32-1 downto 0 );
  signal reinterpret8_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal slice29_y_net : std_logic_vector( 1-1 downto 0 );
  signal register15_q_net : std_logic_vector( 32-1 downto 0 );
  signal constant7_op_net : std_logic_vector( 1-1 downto 0 );
  signal slice14_y_net : std_logic_vector( 3-1 downto 0 );
  signal register5_q_net : std_logic_vector( 11-1 downto 0 );
  signal reinterpret9_output_port_net_x0 : std_logic_vector( 16-1 downto 0 );
  signal slice41_y_net : std_logic_vector( 1-1 downto 0 );
  signal reinterpret9_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal concat2_y_net : std_logic_vector( 64-1 downto 0 );
  signal clk_net : std_logic;
  signal concat8_y_net : std_logic_vector( 12-1 downto 0 );
  signal reinterpret9_output_port_net_x1 : std_logic_vector( 9-1 downto 0 );
  signal slice18_y_net : std_logic_vector( 11-1 downto 0 );
  signal ce_net : std_logic;
  signal concat9_y_net : std_logic_vector( 64-1 downto 0 );
  signal concat10_y_net : std_logic_vector( 64-1 downto 0 );
  signal valid_i_net : std_logic_vector( 1-1 downto 0 );
  signal register11_q_net : std_logic_vector( 1-1 downto 0 );
  signal convert4_dout_net : std_logic_vector( 64-1 downto 0 );
  signal dual_port_ram_doutb_net : std_logic_vector( 64-1 downto 0 );
  signal register34_q_net : std_logic_vector( 1-1 downto 0 );
  signal convert1_dout_net : std_logic_vector( 1-1 downto 0 );
  signal register39_q_net : std_logic_vector( 1-1 downto 0 );
  signal slice36_y_net : std_logic_vector( 1-1 downto 0 );
  signal inverter1_op_net : std_logic_vector( 1-1 downto 0 );
  signal register14_q_net : std_logic_vector( 1-1 downto 0 );
  signal logical7_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice13_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice30_y_net : std_logic_vector( 1-1 downto 0 );
  signal mux14_y_net : std_logic_vector( 12-1 downto 0 );
  signal dual_port_ram_douta_net : std_logic_vector( 64-1 downto 0 );
  signal register7_q_net : std_logic_vector( 64-1 downto 0 );
  signal convert2_dout_net : std_logic_vector( 1-1 downto 0 );
  signal convert3_dout_net : std_logic_vector( 1-1 downto 0 );
  signal mux12_y_net : std_logic_vector( 64-1 downto 0 );
  signal register44_q_net : std_logic_vector( 32-1 downto 0 );
  signal slice39_y_net : std_logic_vector( 32-1 downto 0 );
  signal register10_q_net : std_logic_vector( 16-1 downto 0 );
  signal register18_q_net : std_logic_vector( 16-1 downto 0 );
  signal register8_q_net : std_logic_vector( 16-1 downto 0 );
  signal register46_q_net : std_logic_vector( 1-1 downto 0 );
  signal register17_q_net : std_logic_vector( 16-1 downto 0 );
  signal slice15_y_net : std_logic_vector( 1-1 downto 0 );
  signal mux6_y_net : std_logic_vector( 32-1 downto 0 );
  signal register45_q_net : std_logic_vector( 32-1 downto 0 );
  signal mux17_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice17_y_net : std_logic_vector( 32-1 downto 0 );
  signal slice22_y_net : std_logic_vector( 32-1 downto 0 );
  signal reinterpret6_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal register13_q_net : std_logic_vector( 1-1 downto 0 );
  signal slice2_y_net : std_logic_vector( 1-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal slice21_y_net : std_logic_vector( 32-1 downto 0 );
  signal register2_q_net : std_logic_vector( 32-1 downto 0 );
  signal register48_q_net : std_logic_vector( 1-1 downto 0 );
  signal register47_q_net : std_logic_vector( 1-1 downto 0 );
  signal slice12_y_net : std_logic_vector( 11-1 downto 0 );
  signal register43_q_net : std_logic_vector( 64-1 downto 0 );
  signal slice25_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice11_y_net : std_logic_vector( 9-1 downto 0 );
  signal slice20_y_net : std_logic_vector( 18-1 downto 0 );
  signal reinterpret7_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal slice19_y_net : std_logic_vector( 9-1 downto 0 );
  signal slice10_y_net : std_logic_vector( 16-1 downto 0 );
  signal slice4_y_net : std_logic_vector( 16-1 downto 0 );
  signal slice28_y_net : std_logic_vector( 12-1 downto 0 );
  signal synbol_cnt1_op_net : std_logic_vector( 1-1 downto 0 );
begin
  buffer_mem_addr_i_net <= buffer_mem_addr_i;
  buffer_mem_ctrl_en_net <= buffer_mem_ctrl_en;
  buffer_mem_data_i_net <= buffer_mem_data_i;
  buffer_mem_data_o <= mux1_y_net;
  buffer_mem_we_net <= buffer_mem_we;
  buffer_rd_ctrl_i_net <= buffer_rd_ctrl_i;
  compression_mode_net <= compression_mode;
  data_i_net <= data_i;
  data_i_even_net <= data_i_even;
  data_i_odd_net <= data_i_odd;
  data_q_even_net <= data_q_even;
  data_q_odd_net <= data_q_odd;
  idata_o <= mux4_y_net;
  qdata_o <= mux2_y_net;
  re_no_i_net <= re_no_i;
  sof_i_net <= sof_i;
  sop_i_net <= sop_i;
  valid_i_net <= valid_i;
  clk_net <= clk_1;
  ce_net <= ce_1;
  barrel_shift1 : entity work.dl_adaptor_data_barrel_shift1 
  port map (
    data => reinterpret9_output_port_net_x1,
    exp => slice14_y_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    mantissa => reinterpret9_output_port_net_x0
  );
  barrel_shift2 : entity work.dl_adaptor_data_barrel_shift2 
  port map (
    data => reinterpret8_output_port_net,
    exp => slice14_y_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    mantissa => reinterpret9_output_port_net
  );
  concat10 : entity work.sysgen_concat_e8fa01c855 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => data_q_odd_net,
    in1 => data_i_odd_net,
    in2 => data_q_even_net,
    in3 => data_i_even_net,
    y => concat10_y_net
  );
  concat2 : entity work.sysgen_concat_98da57e59d 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => buffer_mem_data_i_net,
    in1 => buffer_mem_data_i_net,
    y => concat2_y_net
  );
  concat3 : entity work.sysgen_concat_8587dcc071 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => slice41_y_net,
    in1 => register5_q_net,
    y => concat3_y_net
  );
  concat8 : entity work.sysgen_concat_4a48bd946a 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => slice29_y_net,
    in1 => slice18_y_net,
    y => concat8_y_net
  );
  concat9 : entity work.sysgen_concat_98da57e59d 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => register16_q_net,
    in1 => register15_q_net,
    y => concat9_y_net
  );
  constant7 : entity work.sysgen_constant_fc92696315 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => constant7_op_net
  );
  convert1 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 1,
    din_arith => 1,
    din_bin_pt => 0,
    din_width => 1,
    dout_arith => 1,
    dout_bin_pt => 0,
    dout_width => 1,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => slice36_y_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert1_dout_net
  );
  convert2 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 1,
    din_arith => 1,
    din_bin_pt => 0,
    din_width => 1,
    dout_arith => 1,
    dout_bin_pt => 0,
    dout_width => 1,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => slice13_y_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert2_dout_net
  );
  convert3 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 1,
    din_arith => 1,
    din_bin_pt => 0,
    din_width => 1,
    dout_arith => 1,
    dout_bin_pt => 0,
    dout_width => 1,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => register11_q_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert3_dout_net
  );
  convert4 : entity work.dl_adaptor_data_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 1,
    din_bin_pt => 0,
    din_width => 64,
    dout_arith => 1,
    dout_bin_pt => 0,
    dout_width => 64,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => concat9_y_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert4_dout_net
  );
  dual_port_ram : entity work.dl_adaptor_data_xldpram 
  generic map (
    c_address_width_a => 12,
    c_address_width_b => 12,
    c_width_a => 64,
    c_width_b => 64,
    core_name0 => "dl_adaptor_data_blk_mem_gen_i0",
    latency => 0
  )
  port map (
    rsta => "0",
    rstb => "0",
    addra => mux14_y_net,
    dina => register7_q_net,
    wea => register39_q_net,
    addrb => concat8_y_net,
    dinb => convert4_dout_net,
    web => register34_q_net,
    ena => constant7_op_net,
    enb => constant7_op_net,
    a_clk => clk_net,
    a_ce => ce_net,
    b_clk => clk_net,
    b_ce => ce_net,
    douta => dual_port_ram_douta_net,
    doutb => dual_port_ram_doutb_net
  );
  inverter1 : entity work.sysgen_inverter_38e6051e94 
  port map (
    clr => '0',
    ip => register14_q_net,
    clk => clk_net,
    ce => ce_net,
    op => inverter1_op_net
  );
  logical7 : entity work.sysgen_logical_41cf778f30 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    d0 => slice30_y_net,
    d1 => convert1_dout_net,
    y => logical7_y_net
  );
  mux1 : entity work.sysgen_mux_a1fa2a1f98 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => convert2_dout_net,
    d0 => slice39_y_net,
    d1 => slice17_y_net,
    y => mux1_y_net
  );
  mux12 : entity work.sysgen_mux_3c72f0c869 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => slice36_y_net,
    d0 => concat10_y_net,
    d1 => concat2_y_net,
    y => mux12_y_net
  );
  mux14 : entity work.sysgen_mux_044f62bcb9 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => slice36_y_net,
    d0 => concat3_y_net,
    d1 => buffer_mem_addr_i_net,
    y => mux14_y_net
  );
  mux17 : entity work.sysgen_mux_5b770c3875 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => slice36_y_net,
    d0 => valid_i_net,
    d1 => buffer_mem_we_net,
    y => mux17_y_net
  );
  mux2 : entity work.sysgen_mux_81f369649b 
  port map (
    clr => '0',
    sel => slice15_y_net,
    d0 => register17_q_net,
    d1 => register10_q_net,
    clk => clk_net,
    ce => ce_net,
    y => mux2_y_net
  );
  mux4 : entity work.sysgen_mux_81f369649b 
  port map (
    clr => '0',
    sel => slice15_y_net,
    d0 => register18_q_net,
    d1 => register8_q_net,
    clk => clk_net,
    ce => ce_net,
    y => mux4_y_net
  );
  mux6 : entity work.sysgen_mux_ff6eacdf66 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => register46_q_net,
    d0 => register44_q_net,
    d1 => register45_q_net,
    y => mux6_y_net
  );
  register10 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 16,
    init_value => b"0000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => reinterpret6_output_port_net,
    clk => clk_net,
    ce => ce_net,
    q => register10_q_net
  );
  register11 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => slice2_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register11_q_net
  );
  register13 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => register11_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register13_q_net
  );
  register14 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => convert3_dout_net,
    clk => clk_net,
    ce => ce_net,
    q => register14_q_net
  );
  register15 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 32,
    init_value => b"00000000000000000000000000000000"
  )
  port map (
    en => "1",
    d => slice22_y_net,
    rst => inverter1_op_net,
    clk => clk_net,
    ce => ce_net,
    q => register15_q_net
  );
  register16 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 32,
    init_value => b"00000000000000000000000000000000"
  )
  port map (
    en => "1",
    d => slice21_y_net,
    rst => register14_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register16_q_net
  );
  register17 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 16,
    init_value => b"0000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => reinterpret1_output_port_net,
    clk => clk_net,
    ce => ce_net,
    q => register17_q_net
  );
  register18 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 16,
    init_value => b"0000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => reinterpret2_output_port_net,
    clk => clk_net,
    ce => ce_net,
    q => register18_q_net
  );
  register2 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 32,
    init_value => b"00000000000000000000000000000000"
  )
  port map (
    d => mux6_y_net,
    rst => register48_q_net,
    en => register47_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register2_q_net
  );
  register34 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    d => slice25_y_net,
    rst => logical7_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register34_q_net
  );
  register39 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => mux17_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register39_q_net
  );
  register43 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 64,
    init_value => b"0000000000000000000000000000000000000000000000000000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => dual_port_ram_douta_net,
    clk => clk_net,
    ce => ce_net,
    q => register43_q_net
  );
  register44 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 32,
    init_value => b"00000000000000000000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => slice22_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register44_q_net
  );
  register45 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 32,
    init_value => b"00000000000000000000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => slice21_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register45_q_net
  );
  register46 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => register13_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register46_q_net
  );
  register47 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => slice25_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register47_q_net
  );
  register48 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => slice30_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register48_q_net
  );
  register5 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 11,
    init_value => b"00000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => slice12_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register5_q_net
  );
  register7 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 64,
    init_value => b"0000000000000000000000000000000000000000000000000000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => mux12_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register7_q_net
  );
  register8 : entity work.dl_adaptor_data_xlregister 
  generic map (
    d_width => 16,
    init_value => b"0000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => reinterpret7_output_port_net,
    clk => clk_net,
    ce => ce_net,
    q => register8_q_net
  );
  reinterpret1 : entity work.sysgen_reinterpret_7d2e9b0e70 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => slice4_y_net,
    output_port => reinterpret1_output_port_net
  );
  reinterpret2 : entity work.sysgen_reinterpret_7d2e9b0e70 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => slice10_y_net,
    output_port => reinterpret2_output_port_net
  );
  reinterpret6 : entity work.sysgen_reinterpret_d686c88fee 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret9_output_port_net,
    output_port => reinterpret6_output_port_net
  );
  reinterpret7 : entity work.sysgen_reinterpret_d686c88fee 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret9_output_port_net_x0,
    output_port => reinterpret7_output_port_net
  );
  reinterpret8 : entity work.sysgen_reinterpret_82e12a3d16 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => slice11_y_net,
    output_port => reinterpret8_output_port_net
  );
  reinterpret9 : entity work.sysgen_reinterpret_82e12a3d16 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => slice19_y_net,
    output_port => reinterpret9_output_port_net_x1
  );
  slice10 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 15,
    x_width => 32,
    y_width => 16
  )
  port map (
    x => register2_q_net,
    y => slice10_y_net
  );
  slice11 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 9,
    new_msb => 17,
    x_width => 18,
    y_width => 9
  )
  port map (
    x => slice20_y_net,
    y => slice11_y_net
  );
  slice12 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 1,
    new_msb => 11,
    x_width => 12,
    y_width => 11
  )
  port map (
    x => re_no_i_net,
    y => slice12_y_net
  );
  slice13 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 0,
    x_width => 2,
    y_width => 1
  )
  port map (
    x => buffer_mem_ctrl_en_net,
    y => slice13_y_net
  );
  slice14 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 18,
    new_msb => 20,
    x_width => 32,
    y_width => 3
  )
  port map (
    x => register2_q_net,
    y => slice14_y_net
  );
  slice15 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 0,
    x_width => 2,
    y_width => 1
  )
  port map (
    x => compression_mode_net,
    y => slice15_y_net
  );
  slice17 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 32,
    new_msb => 63,
    x_width => 64,
    y_width => 32
  )
  port map (
    x => register43_q_net,
    y => slice17_y_net
  );
  slice18 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 1,
    new_msb => 11,
    x_width => 12,
    y_width => 11
  )
  port map (
    x => slice28_y_net,
    y => slice18_y_net
  );
  slice19 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 8,
    x_width => 18,
    y_width => 9
  )
  port map (
    x => slice20_y_net,
    y => slice19_y_net
  );
  slice2 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 0,
    x_width => 12,
    y_width => 1
  )
  port map (
    x => slice28_y_net,
    y => slice2_y_net
  );
  slice20 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 17,
    x_width => 32,
    y_width => 18
  )
  port map (
    x => register2_q_net,
    y => slice20_y_net
  );
  slice21 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 32,
    new_msb => 63,
    x_width => 64,
    y_width => 32
  )
  port map (
    x => dual_port_ram_doutb_net,
    y => slice21_y_net
  );
  slice22 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 31,
    x_width => 64,
    y_width => 32
  )
  port map (
    x => dual_port_ram_doutb_net,
    y => slice22_y_net
  );
  slice25 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 1,
    new_msb => 1,
    x_width => 15,
    y_width => 1
  )
  port map (
    x => buffer_rd_ctrl_i_net,
    y => slice25_y_net
  );
  slice28 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 3,
    new_msb => 14,
    x_width => 15,
    y_width => 12
  )
  port map (
    x => buffer_rd_ctrl_i_net,
    y => slice28_y_net
  );
  slice29 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 2,
    new_msb => 2,
    x_width => 15,
    y_width => 1
  )
  port map (
    x => buffer_rd_ctrl_i_net,
    y => slice29_y_net
  );
  slice30 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 0,
    x_width => 15,
    y_width => 1
  )
  port map (
    x => buffer_rd_ctrl_i_net,
    y => slice30_y_net
  );
  slice36 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 1,
    new_msb => 1,
    x_width => 2,
    y_width => 1
  )
  port map (
    x => buffer_mem_ctrl_en_net,
    y => slice36_y_net
  );
  slice39 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 31,
    x_width => 64,
    y_width => 32
  )
  port map (
    x => register43_q_net,
    y => slice39_y_net
  );
  slice4 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 16,
    new_msb => 31,
    x_width => 32,
    y_width => 16
  )
  port map (
    x => register2_q_net,
    y => slice4_y_net
  );
  slice41 : entity work.dl_adaptor_data_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 0,
    x_width => 1,
    y_width => 1
  )
  port map (
    x => synbol_cnt1_op_net,
    y => slice41_y_net
  );
  synbol_cnt1 : entity work.sysgen_counter_f86f34e4b9 
  port map (
    clr => '0',
    rst => sof_i_net,
    en => sop_i_net,
    clk => clk_net,
    ce => ce_net,
    op => synbol_cnt1_op_net
  );
end structural;
-- Generated from Simulink block 
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_adaptor_data_default_clock_driver is
  port (
    dl_adaptor_data_sysclk : in std_logic;
    dl_adaptor_data_sysce : in std_logic;
    dl_adaptor_data_sysclr : in std_logic;
    dl_adaptor_data_clk1 : out std_logic;
    dl_adaptor_data_ce1 : out std_logic
  );
end dl_adaptor_data_default_clock_driver;
architecture structural of dl_adaptor_data_default_clock_driver is 
begin
  clockdriver : entity work.xlclockdriver 
  generic map (
    period => 1,
    log_2_period => 1
  )
  port map (
    sysclk => dl_adaptor_data_sysclk,
    sysce => dl_adaptor_data_sysce,
    sysclr => dl_adaptor_data_sysclr,
    clk => dl_adaptor_data_clk1,
    ce => dl_adaptor_data_ce1
  );
end structural;
-- Generated from Simulink block 
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_adaptor_data is
  port (
    buffer_mem_addr_i : in std_logic_vector( 12-1 downto 0 );
    buffer_mem_ctrl_en : in std_logic_vector( 2-1 downto 0 );
    buffer_mem_data_i : in std_logic_vector( 32-1 downto 0 );
    buffer_mem_we : in std_logic_vector( 1-1 downto 0 );
    buffer_rd_ctrl_i : in std_logic_vector( 15-1 downto 0 );
    compression_mode : in std_logic_vector( 2-1 downto 0 );
    data_i : in std_logic_vector( 64-1 downto 0 );
    data_i_even : in std_logic_vector( 16-1 downto 0 );
    data_i_odd : in std_logic_vector( 16-1 downto 0 );
    data_q_even : in std_logic_vector( 16-1 downto 0 );
    data_q_odd : in std_logic_vector( 16-1 downto 0 );
    re_no_i : in std_logic_vector( 12-1 downto 0 );
    sof_i : in std_logic_vector( 1-1 downto 0 );
    sop_i : in std_logic_vector( 1-1 downto 0 );
    valid_i : in std_logic_vector( 1-1 downto 0 );
    clk : in std_logic;
    buffer_mem_data_o : out std_logic_vector( 32-1 downto 0 );
    idata_o : out std_logic_vector( 16-1 downto 0 );
    qdata_o : out std_logic_vector( 16-1 downto 0 )
  );
end dl_adaptor_data;
architecture structural of dl_adaptor_data is 
  attribute core_generation_info : string;
  attribute core_generation_info of structural : architecture is "dl_adaptor_data,sysgen_core_2018_3,{,compilation=HDL Netlist,block_icon_display=Default,family=zynquplus,part=xczu19eg,speed=-2-i,package=ffvc1760,synthesis_language=vhdl,hdl_library=work,synthesis_strategy=Vivado Synthesis Defaults,implementation_strategy=Performance_Explore,testbench=0,interface_doc=0,ce_clr=0,clock_period=2.03451,system_simulink_period=2.03451e-09,waveform_viewer=0,axilite_interface=0,ip_catalog_plugin=0,hwcosim_burst_mode=0,simulation_time=0.0002,concat=5,constant=2,convert=21,counter=1,dpram=1,inv=1,logical=1,mux=9,register=20,reinterpret=24,slice=21,}";
  signal ce_1_net : std_logic;
  signal clk_1_net : std_logic;
begin
  dl_adaptor_data_default_clock_driver : entity work.dl_adaptor_data_default_clock_driver 
  port map (
    dl_adaptor_data_sysclk => clk,
    dl_adaptor_data_sysce => '1',
    dl_adaptor_data_sysclr => '0',
    dl_adaptor_data_clk1 => clk_1_net,
    dl_adaptor_data_ce1 => ce_1_net
  );
  dl_adaptor_data_struct : entity work.dl_adaptor_data_struct 
  port map (
    buffer_mem_addr_i => buffer_mem_addr_i,
    buffer_mem_ctrl_en => buffer_mem_ctrl_en,
    buffer_mem_data_i => buffer_mem_data_i,
    buffer_mem_we => buffer_mem_we,
    buffer_rd_ctrl_i => buffer_rd_ctrl_i,
    compression_mode => compression_mode,
    data_i => data_i,
    data_i_even => data_i_even,
    data_i_odd => data_i_odd,
    data_q_even => data_q_even,
    data_q_odd => data_q_odd,
    re_no_i => re_no_i,
    sof_i => sof_i,
    sop_i => sop_i,
    valid_i => valid_i,
    clk_1 => clk_1_net,
    ce_1 => ce_1_net,
    buffer_mem_data_o => buffer_mem_data_o,
    idata_o => idata_o,
    qdata_o => qdata_o
  );
end structural;
