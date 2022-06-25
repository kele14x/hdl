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
use work.conv_pkg.all;

entity addr_map is
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
end addr_map;

architecture bh of addr_map is

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

  signal sigpwr     : std_logic_vector(15 downto 0);    -- power/2^15

  -- power scaling
  signal dsp2_b     : std_logic_vector(17 downto 0);
  signal dsp2_a     : std_logic_vector(24 downto 0);
  signal dsp2_p     : std_logic_vector(47 downto 0);
  
  signal pwr_sat    : std_logic_vector(12 downto 0) := (others => '0');
  signal pwr_satd   : std_logic_vector(12 downto 0) := (others => '0');
  
  -- compare
  signal compflag   : std_logic_vector(4 downto 0)  := (others => '0');
  
  signal selres0    : std_logic_vector(8 downto 0)  := (others => '0');
  signal selres1    : std_logic_vector(8 downto 0)  := (others => '0');
  signal selres2    : std_logic_vector(8 downto 0)  := (others => '0');
  signal selres3    : std_logic_vector(8 downto 0)  := (others => '0');
  signal selres4    : std_logic_vector(8 downto 0)  := (others => '0');
  signal selres5    : std_logic_vector(8 downto 0)  := (others => '0');

  signal selflag0   : std_logic_vector(1 downto 0) := "00";
  signal selflag1   : std_logic;
  signal selflag2   : std_logic_vector(1 downto 0) := "00";

  signal addr0, addr1, addr2    : std_logic_vector(8 downto 0) := (others => '0');
  signal addr_pre   : std_logic_vector(15 downto 0) := (others => '0');
  
  constant TAR_LIMIT: std_logic_vector(8 downto 0)  := conv_std_logic_vector(252, 9);

begin

  -- input power
  dsp0_b <= sign_extended(xi, 18);
  dsp0_a <= sign_extended(xi, 25);

  dsp1_b <= sign_extended(xq, 18);
  dsp1_a <= sign_extended(xq, 25);

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
  dsp2_b <= sign_extended(gscale, 18);
  dsp2_a <= sign_extended(sigpwr, 25);

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
    c       => X"000000000200",     -- 2^9

    -- output
    p       => dsp2_p
  );

  -- saturation
  process(clk)
  begin
    if rising_edge(clk) then
      sigpwr <= dsp1_p(30 downto 15);       -- power / 2^15
      pwr_sat <= dsp2_p(24 downto 12);      -- 15 => 13bits

      if pwr_sat(12 downto 6) = conv_std_logic_vector(0, 7) then
        compflag(0) <= '1';
      else
        compflag(0) <= '0';
      end if;

      if pwr_sat(12 downto 7) = conv_std_logic_vector(0, 6) then
        compflag(1) <= '1';
      else
        compflag(1) <= '0';
      end if;

      if pwr_sat(12 downto 8) = conv_std_logic_vector(0, 5) then
        compflag(2) <= '1';
      else
        compflag(2) <= '0';
      end if;

      if pwr_sat(12 downto 9) = conv_std_logic_vector(0, 4) then
        compflag(3) <= '1';
      else
        compflag(3) <= '0';
      end if;
      
      if pwr_sat(12 downto 12) = "0" then
        compflag(4) <= '1';
      else
        compflag(4) <= '0';
      end if;
      
      pwr_satd <= pwr_sat;
      
      selres0(5 downto 0) <= pwr_satd(5 downto 0);
      selres1(6 downto 0) <= pwr_satd(7 downto 1) + conv_std_logic_vector(32, 7);
      selres2(6 downto 0) <= pwr_satd(8 downto 2) + conv_std_logic_vector(64, 7);
      selres3(7 downto 0) <= pwr_satd(10 downto 3) + conv_std_logic_vector(96, 8);
      selres4(8 downto 0) <= pwr_satd(12 downto 4) + conv_std_logic_vector(128, 9);
      selres5(8 downto 0) <= pwr_satd(12 downto 5) + conv_std_logic_vector(256, 9);
      
      -- mux select
      selflag0(1) <= ((not compflag(1)) and compflag(2)) or ((not compflag(2)) and compflag(3));
      selflag0(0) <= ((not compflag(0)) and compflag(1)) or ((not compflag(2)) and compflag(3));
            
      selflag1 <= not compflag(4);
      
      selflag2(0) <= ((not compflag(3)) and compflag(4)) or (not compflag(4));
      selflag2(1) <= selflag2(0);
      
      case selflag0 is
        when "00" => addr0 <= selres0;
        when "01" => addr0 <= selres1;
        when "10" => addr0 <= selres2;
        when others => addr0 <= selres3;
      end case;
      
      if selflag1 = '0' then
        addr1 <= selres4;
      else
        addr1 <= selres5;
      end if;
      
      if selflag2(1) = '0' then
        addr2 <= addr0;
      else
        addr2 <= addr1;
      end if;

      if addr2 <= TAR_LIMIT then
        --addr_pre(8 downto 0) <= addr2;
      else
        --addr_pre(8 downto 0) <= TAR_LIMIT;
      end if;

      addr_pre(8 downto 0) <= addr2;
      addr_pre(15 downto 9) <= (others => '0');
      
      addr <= addr_pre;

    end if;
  end process;
  
  

end bh;