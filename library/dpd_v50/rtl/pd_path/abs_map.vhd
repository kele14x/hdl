----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: Mar. 12, 2018
-- Design Name: 
-- Module Name: pd_path_v50.vhd
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--  
-- 
-- function:
-- 10 clocks delay
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
        
library work;
use work.pd_path_def.all;

entity abs_map is
  port (
    -- clock & enable
    clk    : in std_logic := '0';
    ce     : in std_logic := '0';

    -- signal input
    xi      : in std_logic_vector(15 downto 0);
    xq      : in std_logic_vector(15 downto 0);

    -- scaling, default 1024
    gscale  : in std_logic_vector(15 downto 0);

    -- mapped addres
    addr    : out std_logic_vector(15 downto 0)
  );
end abs_map;

architecture bh of abs_map is

  component xilinx_dsp_compact is
  generic (
    AREG        : integer := 1;     -- 1 or 2
    BREG        : integer := 1;     -- 1 or 2
    RND         : std_logic_vector := X"000000000000";  -- 48bit, default zero
    TYPES       : integer := 1      -- used types
  );
  port (
    clk     : in std_logic := '0';
    rstp    : in std_logic := '0';

    -- basic port
    b       : in  std_logic_vector(17 downto 0) := (others => '0');
    a       : in  std_logic_vector(24 downto 0) := (others => '0');
    d       : in  std_logic_vector(24 downto 0) := (others => '0');

    c       : in  std_logic_vector(47 downto 0) := (others => '0');
    p       : out std_logic_vector(47 downto 0);

    -- cascaded port, optional
    pcin    : in  std_logic_vector(47 downto 0) := (others => '0');
    pcout   : out std_logic_vector(47 downto 0)
  );
  end component xilinx_dsp_compact;
  
  -- input power
  signal dsp0_b     : std_logic_vector(17 downto 0);
  signal dsp0_a     : std_logic_vector(24 downto 0);
  signal dsp0_pcout : std_logic_vector(47 downto 0);

  signal dsp1_b     : std_logic_vector(17 downto 0);
  signal dsp1_a     : std_logic_vector(24 downto 0);
  signal dsp1_p     : std_logic_vector(47 downto 0);
  
  signal sigpwr     : std_logic_vector(21 downto 0);    -- 22bit power
  
  -- power scaling
  signal dsp2_b     : std_logic_vector(17 downto 0);
  signal dsp2_a     : std_logic_vector(24 downto 0);
  signal dsp2_p     : std_logic_vector(47 downto 0);
  
  signal pwr_scale  : std_logic_vector(21 downto 0);    -- 22bit scaled power
  signal pwr_sat    : std_logic_vector(17 downto 0) := (others => '0');
  
  constant PWR_PEAK : std_logic_vector(21 downto 0) := "0000111000010000000000";    -- 230400
  
  -- sqrt mapping
  signal u  : std_logic_vector(3 downto 0);
  signal v  : std_logic_vector(13 downto 0);

  signal w  : std_logic_vector(3 downto 0);
  signal z  : std_logic_vector(9 downto 0);
  
  signal ac : std_logic_vector(17 downto 0);
  signal bd : std_logic_vector(15 downto 0);
  
  signal vz     : std_logic_vector(15 downto 0);    -- {v} or {z}

  signal dsp3_b     : std_logic_vector(17 downto 0);
  signal dsp3_a     : std_logic_vector(24 downto 0);
  signal dsp3_p     : std_logic_vector(47 downto 0);
  signal dsp3_c     : std_logic_vector(47 downto 0);
  
begin

  -- input power
  dsp0_b(15 downto 0) <= xi;
  dsp0_b(17 downto 16) <= (others => xi(15));
  dsp0_a(15 downto 0) <= xi;
  dsp0_a(24 downto 16) <= (others => xi(15));

  dsp1_b(15 downto 0) <= xq;
  dsp1_b(17 downto 16) <= (others => xq(15));
  dsp1_a(15 downto 0) <= xq;
  dsp1_a(24 downto 16) <= (others => xq(15));

  pwr_dsp0 : xilinx_dsp_compact
  generic map(
    AREG        => 1,     -- 1 or 2
    BREG        => 1,     -- 1 or 2
    TYPES       => 1      -- used types
  )
  port map(
    clk     => clk,

    -- basic port
    b       => dsp0_b,
    a       => dsp0_a,

    -- cascaded port, optional
    pcout   => dsp0_pcout
  );

  pwr_dsp1 : xilinx_dsp_compact
  generic map(
    AREG        => 2,     -- 1 or 2
    BREG        => 2,     -- 1 or 2
    TYPES       => 2      -- used types
  )
  port map(
    clk     => clk,

    -- basic port
    b       => dsp1_b,
    a       => dsp1_a,
    p       => dsp1_p,

    -- cascaded port, optional
    pcin   => dsp0_pcout
  );

  -- power scaling
  dsp2_b(15 downto 0) <= gscale;
  dsp2_b(17 downto 16) <= (others => '0');
  
  dsp2_a(21 downto 0) <= sigpwr;
  dsp2_a(24 downto 22) <= (others =>'0');

  pwr_dsp2 : xilinx_dsp_compact
  generic map(
    AREG        => 1,     -- 1 or 2
    BREG        => 1,     -- 1 or 2
    TYPES       => 1      -- used types
  )
  port map(
    clk     => clk,

    -- basic port
    b       => dsp2_b,
    a       => dsp2_a,

    -- output
    p       => dsp2_p
  );

  -- saturation
  process(clk)
    variable PEAK_SUB1  : std_logic_vector(21 downto 0);
  begin
    if rising_edge(clk) then
      sigpwr <= dsp1_p(31 downto 10);
      pwr_scale <= dsp2_p(31 downto 10);

      if pwr_scale(21 downto 10) >= PWR_PEAK(21 downto 10) then
        PEAK_SUB1 := PWR_PEAK - (X"00000" & "01");

        pwr_sat <= PEAK_SUB1(17 downto 0);
      else
        pwr_sat <= pwr_scale(17 downto 0);
      end if;
    end if;
  end process;
  
  -- {sqrt} function mapping
  u <= pwr_sat(17 downto 14);
  v <= pwr_sat(13 downto 0);
  
  w <= pwr_sat(13 downto 10);
  z <= pwr_sat(9 downto 0);

  process(clk)
  begin
    if rising_edge(clk) then
      if u /= "0000" then
        vz(13 downto 0) <= v;
        vz(15 downto 14) <= (others => '0');
        
        case u is
          when X"0" =>
            ac <= conv_std_logic_vector(16384, 18);
            bd <= conv_std_logic_vector(    0, 16);
          when X"1" =>
            ac <= conv_std_logic_vector( 6788, 18);
            bd <= conv_std_logic_vector( 4096, 16);          
          when X"2" =>
            ac <= conv_std_logic_vector( 5204, 18);
            bd <= conv_std_logic_vector( 5793, 16);
          when X"3" =>
            ac <= conv_std_logic_vector( 4392, 18);
            bd <= conv_std_logic_vector( 7094, 16);
          when X"4" =>
            ac <= conv_std_logic_vector( 3868, 18);
            bd <= conv_std_logic_vector( 8192, 16);
          when X"5" =>
            ac <= conv_std_logic_vector( 3496, 18);
            bd <= conv_std_logic_vector( 9159, 16);
          when X"6" =>
            ac <= conv_std_logic_vector( 3216, 18);
            bd <= conv_std_logic_vector(10033, 16);
          when X"7" =>
            ac <= conv_std_logic_vector( 2992, 18);
            bd <= conv_std_logic_vector(10837, 16);
          when X"8" =>
            ac <= conv_std_logic_vector( 2812, 18);
            bd <= conv_std_logic_vector(11585, 16);
          when X"9" =>
            ac <= conv_std_logic_vector( 2660, 18);
            bd <= conv_std_logic_vector(12288, 16);
          when X"A" =>
            ac <= conv_std_logic_vector( 2528, 18);
            bd <= conv_std_logic_vector(12953, 16);
          when X"B" =>
            ac <= conv_std_logic_vector( 2416, 18);
            bd <= conv_std_logic_vector(13585, 16);
          when X"C" =>
            ac <= conv_std_logic_vector( 2316, 18);
            bd <= conv_std_logic_vector(14189, 16);
          when X"D" =>
            ac <= conv_std_logic_vector( 2232, 18);
            bd <= conv_std_logic_vector(14768, 16);
          when X"E" =>
            ac <= conv_std_logic_vector( 2152, 18);
            bd <= conv_std_logic_vector(15326, 16);
          when others =>
            ac <= conv_std_logic_vector( 2080, 18);
            bd <= conv_std_logic_vector(15864, 16);
        end case;
      else
        vz(9 downto 0) <= z;
        vz(15 downto 10) <= (others => '0');

        case w is
          when X"0" =>
            ac <= conv_std_logic_vector(65536, 18);
            bd <= conv_std_logic_vector(    0, 16);
          when X"1" =>
            ac <= conv_std_logic_vector(27136, 18);
            bd <= conv_std_logic_vector( 1024, 16);          
          when X"2" =>
            ac <= conv_std_logic_vector(20864, 18);
            bd <= conv_std_logic_vector( 1448, 16);
          when X"3" =>
            ac <= conv_std_logic_vector(17536, 18);
            bd <= conv_std_logic_vector( 1774, 16);
          when X"4" =>
            ac <= conv_std_logic_vector(15488, 18);
            bd <= conv_std_logic_vector( 2048, 16);
          when X"5" =>
            ac <= conv_std_logic_vector(13952, 18);
            bd <= conv_std_logic_vector( 2290, 16);
          when X"6" =>
            ac <= conv_std_logic_vector(12864, 18);
            bd <= conv_std_logic_vector( 2508, 16);
          when X"7" =>
            ac <= conv_std_logic_vector(11968, 18);
            bd <= conv_std_logic_vector( 2709, 16);
          when X"8" =>
            ac <= conv_std_logic_vector(11264, 18);
            bd <= conv_std_logic_vector( 2896, 16);
          when X"9" =>
            ac <= conv_std_logic_vector(10624, 18);
            bd <= conv_std_logic_vector( 3072, 16);
          when X"A" =>
            ac <= conv_std_logic_vector(10112, 18);
            bd <= conv_std_logic_vector( 3238, 16);
          when X"B" =>
            ac <= conv_std_logic_vector( 9664, 18);
            bd <= conv_std_logic_vector( 3396, 16);
          when X"C" =>
            ac <= conv_std_logic_vector( 9280, 18);
            bd <= conv_std_logic_vector( 3547, 16);
          when X"D" =>
            ac <= conv_std_logic_vector( 8896, 18);
            bd <= conv_std_logic_vector( 3692, 16);
          when X"E" =>
            ac <= conv_std_logic_vector( 8640, 18);
            bd <= conv_std_logic_vector( 3831, 16);
          when others =>
            ac <= conv_std_logic_vector( 8320, 18);
            bd <= conv_std_logic_vector( 3966, 16);
        end case;
      end if;
    end if;
  end process;
  
  -- vz * ac / 65536 + bd
  dsp3_b(15 downto 0) <= vz;
  dsp3_b(17 downto 16) <= (others => '0');
  
  dsp3_a(17 downto 0) <= ac;
  dsp3_a(24 downto 18) <= (others => '0');
  
  process(clk)
  begin
    if rising_edge(clk) then
      dsp3_c(31 downto 16) <= bd;
      dsp3_c(15 downto 0 ) <= (others => '0');
      dsp3_c(47 downto 32) <= (others => '0');
      
      addr <= dsp3_p(31 downto 16);
    end if;
  end process;

  pwr_dsp3 : xilinx_dsp_compact
  generic map(
    AREG        => 1,     -- 1 or 2
    BREG        => 1,     -- 1 or 2
    TYPES       => 1      -- used types
  )
  port map(
    clk     => clk,

    -- basic port
    b       => dsp3_b,
    a       => dsp3_a,
    c       => dsp3_c,

    p       => dsp3_p
  );

end bh;