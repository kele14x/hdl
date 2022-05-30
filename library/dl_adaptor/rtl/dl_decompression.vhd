-- Generated from Simulink block dl_decompression/barrel_shift1
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_decompression_barrel_shift1 is
  port (
    data : in std_logic_vector( 9-1 downto 0 );
    exp : in std_logic_vector( 3-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    mantissa : out std_logic_vector( 16-1 downto 0 )
  );
end dl_decompression_barrel_shift1;
architecture structural of dl_decompression_barrel_shift1 is 
  signal register53_q_net : std_logic_vector( 3-1 downto 0 );
  signal reinterpret9_output_port_net_x0 : std_logic_vector( 16-1 downto 0 );
  signal reinterpret9_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert2_dout_net : std_logic_vector( 16-1 downto 0 );
  signal ce_net : std_logic;
  signal reinterpret3_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal reinterpret4_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal reinterpret5_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert_dout_net : std_logic_vector( 16-1 downto 0 );
  signal convert3_dout_net : std_logic_vector( 16-1 downto 0 );
  signal convert1_dout_net : std_logic_vector( 16-1 downto 0 );
  signal clk_net : std_logic;
  signal convert4_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert5_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret6_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal mux3_y_net : std_logic_vector( 16-1 downto 0 );
  signal convert7_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret7_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal reinterpret8_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert6_dout_net : std_logic_vector( 16-1 downto 0 );
begin
  mantissa <= reinterpret9_output_port_net_x0;
  reinterpret9_output_port_net <= data;
  register53_q_net <= exp;
  clk_net <= clk_1;
  ce_net <= ce_1;
  convert : entity work.dl_decompression_xlconvert 
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
  convert1 : entity work.dl_decompression_xlconvert 
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
  convert2 : entity work.dl_decompression_xlconvert 
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
  convert3 : entity work.dl_decompression_xlconvert 
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
  convert4 : entity work.dl_decompression_xlconvert 
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
  convert5 : entity work.dl_decompression_xlconvert 
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
  convert6 : entity work.dl_decompression_xlconvert 
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
  convert7 : entity work.dl_decompression_xlconvert 
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
  mux3 : entity work.sysgen_mux_5c33ca50b0 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => register53_q_net,
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
  reinterpret1 : entity work.sysgen_reinterpret_5a748a8a0c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret1_output_port_net
  );
  reinterpret2 : entity work.sysgen_reinterpret_5a748a8a0c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret9_output_port_net,
    output_port => reinterpret2_output_port_net
  );
  reinterpret3 : entity work.sysgen_reinterpret_5a748a8a0c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret3_output_port_net
  );
  reinterpret4 : entity work.sysgen_reinterpret_5a748a8a0c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret4_output_port_net
  );
  reinterpret5 : entity work.sysgen_reinterpret_5a748a8a0c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret5_output_port_net
  );
  reinterpret6 : entity work.sysgen_reinterpret_5a748a8a0c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret6_output_port_net
  );
  reinterpret7 : entity work.sysgen_reinterpret_5a748a8a0c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret7_output_port_net
  );
  reinterpret8 : entity work.sysgen_reinterpret_5a748a8a0c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret8_output_port_net
  );
  reinterpret9 : entity work.sysgen_reinterpret_07a6d38459 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => mux3_y_net,
    output_port => reinterpret9_output_port_net_x0
  );
end structural;
-- Generated from Simulink block dl_decompression/barrel_shift2
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_decompression_barrel_shift2 is
  port (
    data : in std_logic_vector( 9-1 downto 0 );
    exp : in std_logic_vector( 3-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    mantissa : out std_logic_vector( 16-1 downto 0 )
  );
end dl_decompression_barrel_shift2;
architecture structural of dl_decompression_barrel_shift2 is 
  signal reinterpret9_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal slice14_y_net : std_logic_vector( 3-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert1_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert2_dout_net : std_logic_vector( 16-1 downto 0 );
  signal clk_net : std_logic;
  signal reinterpret3_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal reinterpret8_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert_dout_net : std_logic_vector( 16-1 downto 0 );
  signal ce_net : std_logic;
  signal reinterpret5_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert3_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret4_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert4_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret6_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert5_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret8_output_port_net_x0 : std_logic_vector( 9-1 downto 0 );
  signal reinterpret7_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal convert7_dout_net : std_logic_vector( 16-1 downto 0 );
  signal convert6_dout_net : std_logic_vector( 16-1 downto 0 );
  signal mux3_y_net : std_logic_vector( 16-1 downto 0 );
begin
  mantissa <= reinterpret9_output_port_net;
  reinterpret8_output_port_net <= data;
  slice14_y_net <= exp;
  clk_net <= clk_1;
  ce_net <= ce_1;
  convert : entity work.dl_decompression_xlconvert 
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
  convert1 : entity work.dl_decompression_xlconvert 
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
  convert2 : entity work.dl_decompression_xlconvert 
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
  convert3 : entity work.dl_decompression_xlconvert 
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
  convert4 : entity work.dl_decompression_xlconvert 
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
  convert5 : entity work.dl_decompression_xlconvert 
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
  convert6 : entity work.dl_decompression_xlconvert 
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
  convert7 : entity work.dl_decompression_xlconvert 
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
  mux3 : entity work.sysgen_mux_5c33ca50b0 
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
  reinterpret1 : entity work.sysgen_reinterpret_5a748a8a0c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret1_output_port_net
  );
  reinterpret2 : entity work.sysgen_reinterpret_5a748a8a0c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret8_output_port_net,
    output_port => reinterpret2_output_port_net
  );
  reinterpret3 : entity work.sysgen_reinterpret_5a748a8a0c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret3_output_port_net
  );
  reinterpret4 : entity work.sysgen_reinterpret_5a748a8a0c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret4_output_port_net
  );
  reinterpret5 : entity work.sysgen_reinterpret_5a748a8a0c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret5_output_port_net
  );
  reinterpret6 : entity work.sysgen_reinterpret_5a748a8a0c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret6_output_port_net
  );
  reinterpret7 : entity work.sysgen_reinterpret_5a748a8a0c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret7_output_port_net
  );
  reinterpret8 : entity work.sysgen_reinterpret_5a748a8a0c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret2_output_port_net,
    output_port => reinterpret8_output_port_net_x0
  );
  reinterpret9 : entity work.sysgen_reinterpret_07a6d38459 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => mux3_y_net,
    output_port => reinterpret9_output_port_net
  );
end structural;
-- Generated from Simulink block dl_decompression/barrel_shift3
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_decompression_barrel_shift3 is
  port (
    data : in std_logic_vector( 11-1 downto 0 );
    exp : in std_logic_vector( 3-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    mantissa : out std_logic_vector( 16-1 downto 0 )
  );
end dl_decompression_barrel_shift3;
architecture structural of dl_decompression_barrel_shift3 is 
  signal convert4_dout_net : std_logic_vector( 15-1 downto 0 );
  signal convert5_dout_net : std_logic_vector( 15-1 downto 0 );
  signal reinterpret6_output_port_net : std_logic_vector( 11-1 downto 0 );
  signal reinterpret5_output_port_net : std_logic_vector( 11-1 downto 0 );
  signal mux3_y_net : std_logic_vector( 15-1 downto 0 );
  signal reinterpret7_output_port_net : std_logic_vector( 11-1 downto 0 );
  signal convert7_dout_net : std_logic_vector( 15-1 downto 0 );
  signal reinterpret9_output_port_net : std_logic_vector( 15-1 downto 0 );
  signal reinterpret8_output_port_net : std_logic_vector( 11-1 downto 0 );
  signal convert6_dout_net : std_logic_vector( 15-1 downto 0 );
  signal ce_net : std_logic;
  signal convert3_dout_net : std_logic_vector( 15-1 downto 0 );
  signal convert1_dout_net : std_logic_vector( 15-1 downto 0 );
  signal convert8_dout_net : std_logic_vector( 16-1 downto 0 );
  signal clk_net : std_logic;
  signal reinterpret1_output_port_net : std_logic_vector( 11-1 downto 0 );
  signal convert_dout_net : std_logic_vector( 15-1 downto 0 );
  signal slice37_y_net : std_logic_vector( 3-1 downto 0 );
  signal reinterpret4_output_port_net : std_logic_vector( 11-1 downto 0 );
  signal slice35_y_net : std_logic_vector( 11-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 11-1 downto 0 );
  signal convert2_dout_net : std_logic_vector( 15-1 downto 0 );
  signal reinterpret3_output_port_net : std_logic_vector( 11-1 downto 0 );
begin
  mantissa <= convert8_dout_net;
  slice35_y_net <= data;
  slice37_y_net <= exp;
  clk_net <= clk_1;
  ce_net <= ce_1;
  convert : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 1,
    din_bin_pt => 0,
    din_width => 11,
    dout_arith => 1,
    dout_bin_pt => 4,
    dout_width => 15,
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
  convert1 : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 1,
    din_bin_pt => 1,
    din_width => 11,
    dout_arith => 1,
    dout_bin_pt => 4,
    dout_width => 15,
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
  convert2 : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 1,
    din_bin_pt => 2,
    din_width => 11,
    dout_arith => 1,
    dout_bin_pt => 4,
    dout_width => 15,
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
  convert3 : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 1,
    din_bin_pt => 3,
    din_width => 11,
    dout_arith => 1,
    dout_bin_pt => 4,
    dout_width => 15,
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
  convert4 : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 1,
    din_bin_pt => 4,
    din_width => 11,
    dout_arith => 1,
    dout_bin_pt => 4,
    dout_width => 15,
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
  convert5 : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 1,
    din_bin_pt => 5,
    din_width => 11,
    dout_arith => 1,
    dout_bin_pt => 4,
    dout_width => 15,
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
  convert6 : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 1,
    din_bin_pt => 6,
    din_width => 11,
    dout_arith => 1,
    dout_bin_pt => 4,
    dout_width => 15,
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
  convert7 : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 1,
    din_bin_pt => 7,
    din_width => 11,
    dout_arith => 1,
    dout_bin_pt => 4,
    dout_width => 15,
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
  convert8 : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 1,
    din_bin_pt => 15,
    din_width => 15,
    dout_arith => 2,
    dout_bin_pt => 15,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret9_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert8_dout_net
  );
  mux3 : entity work.sysgen_mux_a0edad98b6 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => slice37_y_net,
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
  reinterpret1 : entity work.sysgen_reinterpret_212fdf1cbb 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => slice35_y_net,
    output_port => reinterpret1_output_port_net
  );
  reinterpret2 : entity work.sysgen_reinterpret_212fdf1cbb 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => slice35_y_net,
    output_port => reinterpret2_output_port_net
  );
  reinterpret3 : entity work.sysgen_reinterpret_212fdf1cbb 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => slice35_y_net,
    output_port => reinterpret3_output_port_net
  );
  reinterpret4 : entity work.sysgen_reinterpret_212fdf1cbb 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => slice35_y_net,
    output_port => reinterpret4_output_port_net
  );
  reinterpret5 : entity work.sysgen_reinterpret_212fdf1cbb 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => slice35_y_net,
    output_port => reinterpret5_output_port_net
  );
  reinterpret6 : entity work.sysgen_reinterpret_212fdf1cbb 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => slice35_y_net,
    output_port => reinterpret6_output_port_net
  );
  reinterpret7 : entity work.sysgen_reinterpret_212fdf1cbb 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => slice35_y_net,
    output_port => reinterpret7_output_port_net
  );
  reinterpret8 : entity work.sysgen_reinterpret_212fdf1cbb 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => slice35_y_net,
    output_port => reinterpret8_output_port_net
  );
  reinterpret9 : entity work.sysgen_reinterpret_665c9da6c7 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => mux3_y_net,
    output_port => reinterpret9_output_port_net
  );
end structural;
-- Generated from Simulink block dl_decompression_struct
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_decompression_struct is
  port (
    compression_scale : in std_logic_vector( 16-1 downto 0 );
    data0_i : in std_logic_vector( 32-1 downto 0 );
    data1_i : in std_logic_vector( 32-1 downto 0 );
    data2_i : in std_logic_vector( 32-1 downto 0 );
    data3_i : in std_logic_vector( 32-1 downto 0 );
    decomp_ctrl_i : in std_logic_vector( 3-1 downto 0 );
    eq_gain_i : in std_logic_vector( 10-1 downto 0 );
    compression_mode1 : in std_logic_vector( 2-1 downto 0 );
    compression_mode0 : in std_logic_vector( 2-1 downto 0 );
    compression_mode2 : in std_logic_vector( 2-1 downto 0 );
    compression_mode3 : in std_logic_vector( 2-1 downto 0 );
    clk_1 : in std_logic;
    ce_1 : in std_logic;
    idata0_o : out std_logic_vector( 16-1 downto 0 );
    idata1_o : out std_logic_vector( 16-1 downto 0 );
    idata2_o : out std_logic_vector( 16-1 downto 0 );
    idata3_o : out std_logic_vector( 16-1 downto 0 );
    qdata0_o : out std_logic_vector( 16-1 downto 0 );
    qdata1_o : out std_logic_vector( 16-1 downto 0 );
    qdata2_o : out std_logic_vector( 16-1 downto 0 );
    qdata3_o : out std_logic_vector( 16-1 downto 0 )
  );
end dl_decompression_struct;
architecture structural of dl_decompression_struct is 
  signal reinterpret16_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal slice23_y_net : std_logic_vector( 3-1 downto 0 );
  signal slice4_y_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret7_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal slice11_y_net : std_logic_vector( 9-1 downto 0 );
  signal slice10_y_net : std_logic_vector( 16-1 downto 0 );
  signal register38_q_net : std_logic_vector( 2-1 downto 0 );
  signal slice20_y_net : std_logic_vector( 18-1 downto 0 );
  signal slice19_y_net : std_logic_vector( 9-1 downto 0 );
  signal data2_i_net : std_logic_vector( 32-1 downto 0 );
  signal data3_i_net : std_logic_vector( 32-1 downto 0 );
  signal decomp_ctrl_i_net : std_logic_vector( 3-1 downto 0 );
  signal eq_gain_i_net : std_logic_vector( 10-1 downto 0 );
  signal register92_q_net : std_logic_vector( 16-1 downto 0 );
  signal register24_q_net : std_logic_vector( 16-1 downto 0 );
  signal compression_scale_net : std_logic_vector( 16-1 downto 0 );
  signal data0_i_net : std_logic_vector( 32-1 downto 0 );
  signal data1_i_net : std_logic_vector( 32-1 downto 0 );
  signal register21_q_net : std_logic_vector( 16-1 downto 0 );
  signal register28_q_net : std_logic_vector( 16-1 downto 0 );
  signal register31_q_net : std_logic_vector( 16-1 downto 0 );
  signal register32_q_net : std_logic_vector( 16-1 downto 0 );
  signal ce_net : std_logic;
  signal compression_mode0_net : std_logic_vector( 2-1 downto 0 );
  signal clk_net : std_logic;
  signal reinterpret9_output_port_net_x0 : std_logic_vector( 16-1 downto 0 );
  signal register53_q_net : std_logic_vector( 3-1 downto 0 );
  signal compression_mode1_net : std_logic_vector( 2-1 downto 0 );
  signal compression_mode2_net : std_logic_vector( 2-1 downto 0 );
  signal compression_mode3_net : std_logic_vector( 2-1 downto 0 );
  signal reinterpret9_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret8_output_port_net : std_logic_vector( 9-1 downto 0 );
  signal slice14_y_net : std_logic_vector( 3-1 downto 0 );
  signal convert8_dout_net_x0 : std_logic_vector( 16-1 downto 0 );
  signal slice37_y_net : std_logic_vector( 3-1 downto 0 );
  signal register89_q_net : std_logic_vector( 16-1 downto 0 );
  signal slice35_y_net : std_logic_vector( 11-1 downto 0 );
  signal reinterpret9_output_port_net_x1 : std_logic_vector( 9-1 downto 0 );
  signal slice34_y_net : std_logic_vector( 1-1 downto 0 );
  signal slice32_y_net : std_logic_vector( 4-1 downto 0 );
  signal concat10_y_net : std_logic_vector( 5-1 downto 0 );
  signal register29_q_net : std_logic_vector( 16-1 downto 0 );
  signal convert10_dout_net : std_logic_vector( 30-1 downto 0 );
  signal slice15_y_net : std_logic_vector( 4-1 downto 0 );
  signal convert12_dout_net : std_logic_vector( 18-1 downto 0 );
  signal concat5_y_net : std_logic_vector( 5-1 downto 0 );
  signal reinterpret14_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal slice24_y_net : std_logic_vector( 1-1 downto 0 );
  signal convert8_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret12_output_port_net : std_logic_vector( 5-1 downto 0 );
  signal reinterpret11_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal convert17_dout_net : std_logic_vector( 16-1 downto 0 );
  signal convert6_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret5_output_port_net : std_logic_vector( 48-1 downto 0 );
  signal convert18_dout_net : std_logic_vector( 30-1 downto 0 );
  signal reinterpret3_output_port_net : std_logic_vector( 48-1 downto 0 );
  signal opmode2_op_net : std_logic_vector( 22-1 downto 0 );
  signal dsp48e2_1_p_net : std_logic_vector( 48-1 downto 0 );
  signal opmode1_op_net : std_logic_vector( 22-1 downto 0 );
  signal dsp48e2_2_p_net : std_logic_vector( 48-1 downto 0 );
  signal register19_q_net : std_logic_vector( 18-1 downto 0 );
  signal mux2_y_net : std_logic_vector( 16-1 downto 0 );
  signal mux10_y_net : std_logic_vector( 2-1 downto 0 );
  signal dsp48e2_3_p_net : std_logic_vector( 48-1 downto 0 );
  signal register49_q_net : std_logic_vector( 16-1 downto 0 );
  signal register50_q_net : std_logic_vector( 16-1 downto 0 );
  signal register8_q_net : std_logic_vector( 16-1 downto 0 );
  signal mux4_y_net : std_logic_vector( 16-1 downto 0 );
  signal register17_q_net : std_logic_vector( 16-1 downto 0 );
  signal register10_q_net : std_logic_vector( 16-1 downto 0 );
  signal register9_q_net : std_logic_vector( 16-1 downto 0 );
  signal mux7_y_net : std_logic_vector( 32-1 downto 0 );
  signal slice38_y_net : std_logic_vector( 2-1 downto 0 );
  signal mux8_y_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret17_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal register18_q_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret6_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal register20_q_net : std_logic_vector( 16-1 downto 0 );
  signal register25_q_net : std_logic_vector( 1-1 downto 0 );
  signal register26_q_net : std_logic_vector( 16-1 downto 0 );
  signal register30_q_net : std_logic_vector( 1-1 downto 0 );
  signal slice40_y_net : std_logic_vector( 1-1 downto 0 );
  signal register3_q_net : std_logic_vector( 3-1 downto 0 );
  signal register33_q_net : std_logic_vector( 1-1 downto 0 );
  signal register52_q_net : std_logic_vector( 32-1 downto 0 );
  signal register312_q_net : std_logic_vector( 10-1 downto 0 );
  signal reinterpret2_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret1_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret4_output_port_net : std_logic_vector( 48-1 downto 0 );
  signal convert13_dout_net : std_logic_vector( 18-1 downto 0 );
  signal reinterpret15_output_port_net : std_logic_vector( 5-1 downto 0 );
  signal convert14_dout_net : std_logic_vector( 16-1 downto 0 );
  signal reinterpret10_output_port_net : std_logic_vector( 10-1 downto 0 );
  signal reinterpret13_output_port_net : std_logic_vector( 16-1 downto 0 );
  signal convert15_dout_net : std_logic_vector( 30-1 downto 0 );
begin
  compression_scale_net <= compression_scale;
  data0_i_net <= data0_i;
  data1_i_net <= data1_i;
  data2_i_net <= data2_i;
  data3_i_net <= data3_i;
  decomp_ctrl_i_net <= decomp_ctrl_i;
  eq_gain_i_net <= eq_gain_i;
  idata0_o <= register92_q_net;
  idata1_o <= register24_q_net;
  idata2_o <= register29_q_net;
  idata3_o <= register32_q_net;
  qdata0_o <= register89_q_net;
  qdata1_o <= register21_q_net;
  qdata2_o <= register28_q_net;
  qdata3_o <= register31_q_net;
  compression_mode1_net <= compression_mode1;
  compression_mode0_net <= compression_mode0;
  compression_mode2_net <= compression_mode2;
  compression_mode3_net <= compression_mode3;
  clk_net <= clk_1;
  ce_net <= ce_1;
  barrel_shift1 : entity work.dl_decompression_barrel_shift1 
  port map (
    data => reinterpret9_output_port_net_x1,
    exp => register53_q_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    mantissa => reinterpret9_output_port_net_x0
  );
  barrel_shift2 : entity work.dl_decompression_barrel_shift2 
  port map (
    data => reinterpret8_output_port_net,
    exp => slice14_y_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    mantissa => reinterpret9_output_port_net
  );
  barrel_shift3 : entity work.dl_decompression_barrel_shift3 
  port map (
    data => slice35_y_net,
    exp => slice37_y_net,
    clk_1 => clk_net,
    ce_1 => ce_net,
    mantissa => convert8_dout_net_x0
  );
  concat10 : entity work.sysgen_concat_351808024a 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => slice32_y_net,
    in1 => slice34_y_net,
    y => concat10_y_net
  );
  concat5 : entity work.sysgen_concat_351808024a 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    in0 => slice15_y_net,
    in1 => slice24_y_net,
    y => concat5_y_net
  );
  convert10 : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 0,
    din_width => 16,
    dout_arith => 2,
    dout_bin_pt => 0,
    dout_width => 30,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret14_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert10_dout_net
  );
  convert12 : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 0,
    din_width => 10,
    dout_arith => 2,
    dout_bin_pt => 0,
    dout_width => 18,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret10_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert12_dout_net
  );
  convert13 : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 8,
    din_width => 48,
    dout_arith => 2,
    dout_bin_pt => 0,
    dout_width => 18,
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
    dout => convert13_dout_net
  );
  convert14 : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 4,
    din_width => 5,
    dout_arith => 2,
    dout_bin_pt => 15,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret15_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert14_dout_net
  );
  convert15 : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 0,
    din_width => 16,
    dout_arith => 2,
    dout_bin_pt => 0,
    dout_width => 30,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret13_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert15_dout_net
  );
  convert17 : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 15,
    din_width => 48,
    dout_arith => 2,
    dout_bin_pt => 0,
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
    dout => convert17_dout_net
  );
  convert18 : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 0,
    din_width => 16,
    dout_arith => 2,
    dout_bin_pt => 0,
    dout_width => 30,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret11_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert18_dout_net
  );
  convert6 : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 15,
    din_width => 48,
    dout_arith => 2,
    dout_bin_pt => 0,
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
    dout => convert6_dout_net
  );
  convert8 : entity work.dl_decompression_xlconvert 
  generic map (
    bool_conversion => 0,
    din_arith => 2,
    din_bin_pt => 4,
    din_width => 5,
    dout_arith => 2,
    dout_bin_pt => 15,
    dout_width => 16,
    latency => 0,
    overflow => xlWrap,
    quantization => xlTruncate
  )
  port map (
    clr => '0',
    en => "1",
    din => reinterpret12_output_port_net,
    clk => clk_net,
    ce => ce_net,
    dout => convert8_dout_net
  );
  dsp48e2_1 : entity work.dl_decompression_xldsp48e2 
  generic map (
    a_input => "DIRECT",
    acascreg => 1,
    adreg => 0,
    alumodereg => 1,
    amultsel => "A",
    areg => 1,
    autoreset_pattern_detect => "NO_RESET",
    autoreset_priority => "RESET",
    b_input => "DIRECT",
    bcascreg => 2,
    bmultsel => "B",
    breg => 2,
    carryinreg => 1,
    carryinselreg => 1,
    carryout_width => 4,
    creg => 0,
    dreg => 0,
    inmodereg => 1,
    is_alumode_inverted => "0000",
    is_carryin_inverted => '0',
    is_clk_inverted => '0',
    is_inmode_inverted => "00000",
    is_opmode_inverted => "000000000",
    is_rsta_inverted => '0',
    is_rstallcarryin_inverted => '0',
    is_rstalumode_inverted => '0',
    is_rstb_inverted => '0',
    is_rstc_inverted => '0',
    is_rstctrl_inverted => '0',
    is_rstd_inverted => '0',
    is_rstinmode_inverted => '0',
    is_rstm_inverted => '0',
    is_rstp_inverted => '0',
    mreg => 1,
    opmodereg => 1,
    preaddinsel => "A",
    preg => 1,
    rnd => X"000000000080",
    sel_mask => "C",
    sel_pattern => "C",
    use_c_port => 0,
    use_mult => "MULTIPLY",
    use_op => 1,
    use_pattern_detect => "NO_PATDET",
    use_simd => "ONE48",
    use_widexor => "FALSE",
    xorsimd => "XOR12"
  )
  port map (
    carryin => "0",
    en => "1",
    cea1 => "1",
    cea2 => "1",
    ceb1 => "1",
    ceb2 => "1",
    cec => "1",
    cem => "1",
    cealumode => "1",
    cemultcarryin => "1",
    cectrl => "1",
    cecarryin => "1",
    cep => "1",
    ced => "1",
    cead => "1",
    ceinmode => "1",
    alumode => "0000",
    rst => "0",
    rsta => "0",
    rstb => "0",
    rstc => "0",
    rstm => "0",
    rstctrl => "0",
    rstcarryin => "0",
    rstalumode => "0",
    rstp => "0",
    rstd => "0",
    rstinmode => "0",
    a => convert18_dout_net,
    b => convert12_dout_net,
    op => opmode2_op_net,
    clk => clk_net,
    ce => ce_net,
    p => dsp48e2_1_p_net
  );
  dsp48e2_2 : entity work.dl_decompression_xldsp48e2 
  generic map (
    a_input => "DIRECT",
    acascreg => 2,
    adreg => 0,
    alumodereg => 1,
    amultsel => "A",
    areg => 2,
    autoreset_pattern_detect => "NO_RESET",
    autoreset_priority => "RESET",
    b_input => "DIRECT",
    bcascreg => 1,
    bmultsel => "B",
    breg => 1,
    carryinreg => 1,
    carryinselreg => 1,
    carryout_width => 4,
    creg => 0,
    dreg => 0,
    inmodereg => 1,
    is_alumode_inverted => "0000",
    is_carryin_inverted => '0',
    is_clk_inverted => '0',
    is_inmode_inverted => "00000",
    is_opmode_inverted => "000000000",
    is_rsta_inverted => '0',
    is_rstallcarryin_inverted => '0',
    is_rstalumode_inverted => '0',
    is_rstb_inverted => '0',
    is_rstc_inverted => '0',
    is_rstctrl_inverted => '0',
    is_rstd_inverted => '0',
    is_rstinmode_inverted => '0',
    is_rstm_inverted => '0',
    is_rstp_inverted => '0',
    mreg => 1,
    opmodereg => 1,
    preaddinsel => "A",
    preg => 1,
    rnd => X"000000004000",
    sel_mask => "C",
    sel_pattern => "C",
    use_c_port => 0,
    use_mult => "MULTIPLY",
    use_op => 1,
    use_pattern_detect => "NO_PATDET",
    use_simd => "ONE48",
    use_widexor => "FALSE",
    xorsimd => "XOR12"
  )
  port map (
    carryin => "0",
    en => "1",
    cea1 => "1",
    cea2 => "1",
    ceb1 => "1",
    ceb2 => "1",
    cec => "1",
    cem => "1",
    cealumode => "1",
    cemultcarryin => "1",
    cectrl => "1",
    cecarryin => "1",
    cep => "1",
    ced => "1",
    cead => "1",
    ceinmode => "1",
    alumode => "0000",
    rst => "0",
    rsta => "0",
    rstb => "0",
    rstc => "0",
    rstm => "0",
    rstctrl => "0",
    rstcarryin => "0",
    rstalumode => "0",
    rstp => "0",
    rstd => "0",
    rstinmode => "0",
    a => convert15_dout_net,
    b => register19_q_net,
    op => opmode1_op_net,
    clk => clk_net,
    ce => ce_net,
    p => dsp48e2_2_p_net
  );
  dsp48e2_3 : entity work.dl_decompression_xldsp48e2 
  generic map (
    a_input => "DIRECT",
    acascreg => 2,
    adreg => 0,
    alumodereg => 1,
    amultsel => "A",
    areg => 2,
    autoreset_pattern_detect => "NO_RESET",
    autoreset_priority => "RESET",
    b_input => "DIRECT",
    bcascreg => 1,
    bmultsel => "B",
    breg => 1,
    carryinreg => 1,
    carryinselreg => 1,
    carryout_width => 4,
    creg => 0,
    dreg => 0,
    inmodereg => 1,
    is_alumode_inverted => "0000",
    is_carryin_inverted => '0',
    is_clk_inverted => '0',
    is_inmode_inverted => "00000",
    is_opmode_inverted => "000000000",
    is_rsta_inverted => '0',
    is_rstallcarryin_inverted => '0',
    is_rstalumode_inverted => '0',
    is_rstb_inverted => '0',
    is_rstc_inverted => '0',
    is_rstctrl_inverted => '0',
    is_rstd_inverted => '0',
    is_rstinmode_inverted => '0',
    is_rstm_inverted => '0',
    is_rstp_inverted => '0',
    mreg => 1,
    opmodereg => 1,
    preaddinsel => "A",
    preg => 1,
    rnd => X"000000004000",
    sel_mask => "C",
    sel_pattern => "C",
    use_c_port => 0,
    use_mult => "MULTIPLY",
    use_op => 1,
    use_pattern_detect => "NO_PATDET",
    use_simd => "ONE48",
    use_widexor => "FALSE",
    xorsimd => "XOR12"
  )
  port map (
    carryin => "0",
    en => "1",
    cea1 => "1",
    cea2 => "1",
    ceb1 => "1",
    ceb2 => "1",
    cec => "1",
    cem => "1",
    cealumode => "1",
    cemultcarryin => "1",
    cectrl => "1",
    cecarryin => "1",
    cep => "1",
    ced => "1",
    cead => "1",
    ceinmode => "1",
    alumode => "0000",
    rst => "0",
    rsta => "0",
    rstb => "0",
    rstc => "0",
    rstm => "0",
    rstctrl => "0",
    rstcarryin => "0",
    rstalumode => "0",
    rstp => "0",
    rstd => "0",
    rstinmode => "0",
    a => convert10_dout_net,
    b => register19_q_net,
    op => opmode1_op_net,
    clk => clk_net,
    ce => ce_net,
    p => dsp48e2_3_p_net
  );
  mux2 : entity work.sysgen_mux_b786075160 
  port map (
    clr => '0',
    sel => mux10_y_net,
    d0 => register49_q_net,
    d1 => register10_q_net,
    d2 => register9_q_net,
    d3 => register10_q_net,
    clk => clk_net,
    ce => ce_net,
    y => mux2_y_net
  );
  mux4 : entity work.sysgen_mux_b786075160 
  port map (
    clr => '0',
    sel => mux10_y_net,
    d0 => register50_q_net,
    d1 => register8_q_net,
    d2 => register17_q_net,
    d3 => register8_q_net,
    clk => clk_net,
    ce => ce_net,
    y => mux4_y_net
  );
  mux7 : entity work.sysgen_mux_41ee3895f6 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    sel => slice38_y_net,
    d0 => data0_i_net,
    d1 => data1_i_net,
    d2 => data2_i_net,
    d3 => data3_i_net,
    y => mux7_y_net
  );
  mux8 : entity work.sysgen_mux_139c380307 
  port map (
    clr => '0',
    sel => mux10_y_net,
    d0 => compression_scale_net,
    d1 => compression_scale_net,
    d2 => register18_q_net,
    d3 => compression_scale_net,
    clk => clk_net,
    ce => ce_net,
    y => mux8_y_net
  );
  opmode1 : entity work.sysgen_opmode_b35a3cdb6a 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => opmode1_op_net
  );
  opmode2 : entity work.sysgen_opmode_4b4aad4976 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    op => opmode2_op_net
  );
  register10 : entity work.dl_decompression_xlregister 
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
  register17 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 16,
    init_value => b"0000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => reinterpret17_output_port_net,
    clk => clk_net,
    ce => ce_net,
    q => register17_q_net
  );
  register18 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 16,
    init_value => b"0000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => convert8_dout_net_x0,
    clk => clk_net,
    ce => ce_net,
    q => register18_q_net
  );
  register19 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 18,
    init_value => b"000000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => convert13_dout_net,
    clk => clk_net,
    ce => ce_net,
    q => register19_q_net
  );
  register20 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 16,
    init_value => b"0000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => convert6_dout_net,
    clk => clk_net,
    ce => ce_net,
    q => register20_q_net
  );
  register21 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 16,
    init_value => b"0000000000000000"
  )
  port map (
    rst => "0",
    d => register20_q_net,
    en => register25_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register21_q_net
  );
  register24 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 16,
    init_value => b"0000000000000000"
  )
  port map (
    rst => "0",
    d => register26_q_net,
    en => register25_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register24_q_net
  );
  register25 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => slice40_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register25_q_net
  );
  register26 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 16,
    init_value => b"0000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => convert17_dout_net,
    clk => clk_net,
    ce => ce_net,
    q => register26_q_net
  );
  register28 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 16,
    init_value => b"0000000000000000"
  )
  port map (
    rst => "0",
    d => register20_q_net,
    en => register30_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register28_q_net
  );
  register29 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 16,
    init_value => b"0000000000000000"
  )
  port map (
    rst => "0",
    d => register26_q_net,
    en => register30_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register29_q_net
  );
  register3 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 3,
    init_value => b"000"
  )
  port map (
    en => "1",
    rst => "0",
    d => decomp_ctrl_i_net,
    clk => clk_net,
    ce => ce_net,
    q => register3_q_net
  );
  register30 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => register25_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register30_q_net
  );
  register31 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 16,
    init_value => b"0000000000000000"
  )
  port map (
    rst => "0",
    d => register20_q_net,
    en => register33_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register31_q_net
  );
  register312 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 10,
    init_value => b"0000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => eq_gain_i_net,
    clk => clk_net,
    ce => ce_net,
    q => register312_q_net
  );
  register32 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 16,
    init_value => b"0000000000000000"
  )
  port map (
    rst => "0",
    d => register26_q_net,
    en => register33_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register32_q_net
  );
  register33 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 1,
    init_value => b"0"
  )
  port map (
    en => "1",
    rst => "0",
    d => register30_q_net,
    clk => clk_net,
    ce => ce_net,
    q => register33_q_net
  );
  register49 : entity work.dl_decompression_xlregister 
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
    q => register49_q_net
  );
  register50 : entity work.dl_decompression_xlregister 
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
    q => register50_q_net
  );
  register52 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 32,
    init_value => b"00000000000000000000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => mux7_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register52_q_net
  );
  register53 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 3,
    init_value => b"000"
  )
  port map (
    en => "1",
    rst => "0",
    d => slice23_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register53_q_net
  );
  register8 : entity work.dl_decompression_xlregister 
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
  register89 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 16,
    init_value => b"0000000000000000"
  )
  port map (
    rst => "0",
    d => register20_q_net,
    en => slice40_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register89_q_net
  );
  register9 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 16,
    init_value => b"0000000000000000"
  )
  port map (
    en => "1",
    rst => "0",
    d => reinterpret16_output_port_net,
    clk => clk_net,
    ce => ce_net,
    q => register9_q_net
  );
  register92 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 16,
    init_value => b"0000000000000000"
  )
  port map (
    rst => "0",
    d => register26_q_net,
    en => slice40_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register92_q_net
  );
  reinterpret1 : entity work.sysgen_reinterpret_1b9bf41623 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => slice4_y_net,
    output_port => reinterpret1_output_port_net
  );
  reinterpret10 : entity work.sysgen_reinterpret_86be2ff07c 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => register312_q_net,
    output_port => reinterpret10_output_port_net
  );
  reinterpret11 : entity work.sysgen_reinterpret_07a6d38459 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => mux8_y_net,
    output_port => reinterpret11_output_port_net
  );
  reinterpret12 : entity work.sysgen_reinterpret_ef09555723 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => concat10_y_net,
    output_port => reinterpret12_output_port_net
  );
  reinterpret13 : entity work.sysgen_reinterpret_07a6d38459 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => mux2_y_net,
    output_port => reinterpret13_output_port_net
  );
  reinterpret14 : entity work.sysgen_reinterpret_07a6d38459 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => mux4_y_net,
    output_port => reinterpret14_output_port_net
  );
  reinterpret15 : entity work.sysgen_reinterpret_ef09555723 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => concat5_y_net,
    output_port => reinterpret15_output_port_net
  );
  reinterpret16 : entity work.sysgen_reinterpret_07a6d38459 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => convert8_dout_net,
    output_port => reinterpret16_output_port_net
  );
  reinterpret17 : entity work.sysgen_reinterpret_07a6d38459 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => convert14_dout_net,
    output_port => reinterpret17_output_port_net
  );
  reinterpret2 : entity work.sysgen_reinterpret_1b9bf41623 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => slice10_y_net,
    output_port => reinterpret2_output_port_net
  );
  reinterpret3 : entity work.sysgen_reinterpret_46173a0bdd 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => dsp48e2_3_p_net,
    output_port => reinterpret3_output_port_net
  );
  reinterpret4 : entity work.sysgen_reinterpret_46173a0bdd 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => dsp48e2_1_p_net,
    output_port => reinterpret4_output_port_net
  );
  reinterpret5 : entity work.sysgen_reinterpret_46173a0bdd 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => dsp48e2_2_p_net,
    output_port => reinterpret5_output_port_net
  );
  reinterpret6 : entity work.sysgen_reinterpret_07a6d38459 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret9_output_port_net,
    output_port => reinterpret6_output_port_net
  );
  reinterpret7 : entity work.sysgen_reinterpret_07a6d38459 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => reinterpret9_output_port_net_x0,
    output_port => reinterpret7_output_port_net
  );
  reinterpret8 : entity work.sysgen_reinterpret_af68e3eb29 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => slice11_y_net,
    output_port => reinterpret8_output_port_net
  );
  reinterpret9 : entity work.sysgen_reinterpret_af68e3eb29 
  port map (
    clk => '0',
    ce => '0',
    clr => '0',
    input_port => slice19_y_net,
    output_port => reinterpret9_output_port_net_x1
  );
  slice10 : entity work.dl_decompression_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 15,
    x_width => 32,
    y_width => 16
  )
  port map (
    x => register52_q_net,
    y => slice10_y_net
  );
  slice11 : entity work.dl_decompression_xlslice 
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
  slice14 : entity work.dl_decompression_xlslice 
  generic map (
    new_lsb => 18,
    new_msb => 20,
    x_width => 32,
    y_width => 3
  )
  port map (
    x => register52_q_net,
    y => slice14_y_net
  );
  slice15 : entity work.dl_decompression_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 3,
    x_width => 32,
    y_width => 4
  )
  port map (
    x => register52_q_net,
    y => slice15_y_net
  );
  slice19 : entity work.dl_decompression_xlslice 
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
  slice20 : entity work.dl_decompression_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 17,
    x_width => 32,
    y_width => 18
  )
  port map (
    x => register52_q_net,
    y => slice20_y_net
  );
  slice23 : entity work.dl_decompression_xlslice 
  generic map (
    new_lsb => 18,
    new_msb => 20,
    x_width => 32,
    y_width => 3
  )
  port map (
    x => mux7_y_net,
    y => slice23_y_net
  );
  slice24 : entity work.dl_decompression_xlslice 
  generic map (
    new_lsb => 23,
    new_msb => 23,
    x_width => 32,
    y_width => 1
  )
  port map (
    x => register52_q_net,
    y => slice24_y_net
  );
  slice32 : entity work.dl_decompression_xlslice 
  generic map (
    new_lsb => 4,
    new_msb => 7,
    x_width => 32,
    y_width => 4
  )
  port map (
    x => register52_q_net,
    y => slice32_y_net
  );
  slice34 : entity work.dl_decompression_xlslice 
  generic map (
    new_lsb => 23,
    new_msb => 23,
    x_width => 32,
    y_width => 1
  )
  port map (
    x => register52_q_net,
    y => slice34_y_net
  );
  slice35 : entity work.dl_decompression_xlslice 
  generic map (
    new_lsb => 8,
    new_msb => 18,
    x_width => 32,
    y_width => 11
  )
  port map (
    x => register52_q_net,
    y => slice35_y_net
  );
  slice37 : entity work.dl_decompression_xlslice 
  generic map (
    new_lsb => 19,
    new_msb => 21,
    x_width => 32,
    y_width => 3
  )
  port map (
    x => register52_q_net,
    y => slice37_y_net
  );
  slice38 : entity work.dl_decompression_xlslice 
  generic map (
    new_lsb => 0,
    new_msb => 1,
    x_width => 3,
    y_width => 2
  )
  port map (
    x => register3_q_net,
    y => slice38_y_net
  );
  slice4 : entity work.dl_decompression_xlslice 
  generic map (
    new_lsb => 16,
    new_msb => 31,
    x_width => 32,
    y_width => 16
  )
  port map (
    x => register52_q_net,
    y => slice4_y_net
  );
  slice40 : entity work.dl_decompression_xlslice 
  generic map (
    new_lsb => 2,
    new_msb => 2,
    x_width => 3,
    y_width => 1
  )
  port map (
    x => register3_q_net,
    y => slice40_y_net
  );
  mux10 : entity work.sysgen_mux_4be6277f9e 
  port map (
    clr => '0',
    sel => register38_q_net,
    d0 => compression_mode0_net,
    d1 => compression_mode1_net,
    d2 => compression_mode2_net,
    d3 => compression_mode3_net,
    clk => clk_net,
    ce => ce_net,
    y => mux10_y_net
  );
  register38 : entity work.dl_decompression_xlregister 
  generic map (
    d_width => 2,
    init_value => b"00"
  )
  port map (
    en => "1",
    rst => "0",
    d => slice38_y_net,
    clk => clk_net,
    ce => ce_net,
    q => register38_q_net
  );
end structural;
-- Generated from Simulink block 
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_decompression_default_clock_driver is
  port (
    dl_decompression_sysclk : in std_logic;
    dl_decompression_sysce : in std_logic;
    dl_decompression_sysclr : in std_logic;
    dl_decompression_clk1 : out std_logic;
    dl_decompression_ce1 : out std_logic
  );
end dl_decompression_default_clock_driver;
architecture structural of dl_decompression_default_clock_driver is 
begin
  clockdriver : entity work.xlclockdriver 
  generic map (
    period => 1,
    log_2_period => 1
  )
  port map (
    sysclk => dl_decompression_sysclk,
    sysce => dl_decompression_sysce,
    sysclr => dl_decompression_sysclr,
    clk => dl_decompression_clk1,
    ce => dl_decompression_ce1
  );
end structural;
-- Generated from Simulink block 
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.conv_pkg.all;
entity dl_decompression is
  port (
    compression_scale : in std_logic_vector( 16-1 downto 0 );
    data0_i : in std_logic_vector( 32-1 downto 0 );
    data1_i : in std_logic_vector( 32-1 downto 0 );
    data2_i : in std_logic_vector( 32-1 downto 0 );
    data3_i : in std_logic_vector( 32-1 downto 0 );
    decomp_ctrl_i : in std_logic_vector( 3-1 downto 0 );
    eq_gain_i : in std_logic_vector( 10-1 downto 0 );
    compression_mode1 : in std_logic_vector( 2-1 downto 0 );
    compression_mode0 : in std_logic_vector( 2-1 downto 0 );
    compression_mode2 : in std_logic_vector( 2-1 downto 0 );
    compression_mode3 : in std_logic_vector( 2-1 downto 0 );
    clk : in std_logic;
    idata0_o : out std_logic_vector( 16-1 downto 0 );
    idata1_o : out std_logic_vector( 16-1 downto 0 );
    idata2_o : out std_logic_vector( 16-1 downto 0 );
    idata3_o : out std_logic_vector( 16-1 downto 0 );
    qdata0_o : out std_logic_vector( 16-1 downto 0 );
    qdata1_o : out std_logic_vector( 16-1 downto 0 );
    qdata2_o : out std_logic_vector( 16-1 downto 0 );
    qdata3_o : out std_logic_vector( 16-1 downto 0 )
  );
end dl_decompression;
architecture structural of dl_decompression is 
  attribute core_generation_info : string;
  attribute core_generation_info of structural : architecture is "dl_decompression,sysgen_core_2020_2,{,compilation=HDL Netlist,block_icon_display=Default,family=zynquplus,part=xczu19eg,speed=-2-i,package=ffvc1760,synthesis_language=vhdl,hdl_library=work,synthesis_strategy=Vivado Synthesis Defaults,implementation_strategy=Performance_Explore,testbench=0,interface_doc=0,ce_clr=0,clock_period=2.03451,system_simulink_period=2.03451e-09,waveform_viewer=0,axilite_interface=0,ip_catalog_plugin=0,hwcosim_burst_mode=0,simulation_time=0.0001,concat=2,convert=34,dsp48e2=3,mux=8,opmode=2,register=26,reinterpret=44,slice=15,}";
  signal ce_1_net : std_logic;
  signal clk_1_net : std_logic;
begin
  dl_decompression_default_clock_driver : entity work.dl_decompression_default_clock_driver 
  port map (
    dl_decompression_sysclk => clk,
    dl_decompression_sysce => '1',
    dl_decompression_sysclr => '0',
    dl_decompression_clk1 => clk_1_net,
    dl_decompression_ce1 => ce_1_net
  );
  dl_decompression_struct : entity work.dl_decompression_struct 
  port map (
    compression_scale => compression_scale,
    data0_i => data0_i,
    data1_i => data1_i,
    data2_i => data2_i,
    data3_i => data3_i,
    decomp_ctrl_i => decomp_ctrl_i,
    eq_gain_i => eq_gain_i,
    compression_mode1 => compression_mode1,
    compression_mode0 => compression_mode0,
    compression_mode2 => compression_mode2,
    compression_mode3 => compression_mode3,
    clk_1 => clk_1_net,
    ce_1 => ce_1_net,
    idata0_o => idata0_o,
    idata1_o => idata1_o,
    idata2_o => idata2_o,
    idata3_o => idata3_o,
    qdata0_o => qdata0_o,
    qdata1_o => qdata1_o,
    qdata2_o => qdata2_o,
    qdata3_o => qdata3_o
  );
end structural;
