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
        
library work;
use work.pd_path_def.all;

entity input_up2 is
  port (
    -- clock & enable
    clk    : in std_logic := '0';
    ce     : in std_logic := '0';

    -- signal input
    x       : in std_logic_vector(15 downto 0);

    -- signal output, signal goes as [y0, y1, ...]
    y0      : out std_logic_vector(15 downto 0);
    y1      : out std_logic_vector(15 downto 0)
  );
end input_up2;

architecture bh of input_up2 is

  component xilinx_dsp_compact is
  generic (
    AREG        : integer := 1;     -- 1 or 2
    BREG        : integer := 1;     -- 1 or 2
    
    RND         : std_logic_vector := X"000000000000";  -- 48bit, default zero
    TYPES       : integer := 1      -- used types
  );
  port (
    clk     : in std_logic;
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
  
  signal xtaps  : vector_16b_t(9 downto 0) := (others => (others => '0'));
  signal coef0, coef1, coef2    : std_logic_vector(17 downto 0);
  signal RND    : std_logic_vector(47 downto 0);
  
  signal a0,d0  : std_logic_vector(24 downto 0);
  signal a1,d1  : std_logic_vector(24 downto 0);
  signal a2,d2  : std_logic_vector(24 downto 0);
  
  signal q0_cas : std_logic_vector(47 downto 0);
  signal q1_cas : std_logic_vector(47 downto 0);
  signal q      : std_logic_vector(47 downto 0);
  

begin
  coef0 <= conv_std_logic_vector(IN2X_COEF0, 18);
  coef1 <= conv_std_logic_vector(IN2X_COEF1, 18);
  coef2 <= conv_std_logic_vector(IN2X_COEF2, 18);

  RND <= X"000000008000";
  
  process(clk)
  begin
    if rising_edge(clk) then
      xtaps(0) <= x;
      xtaps(9 downto 1) <= xtaps(9-1 downto 0);
      
      y1 <= q(31 downto 16);
    end if;
  end process;
  
  a0(15 downto 0) <= x;
  a0(24 downto 16) <= (others => x(15));
  
  d0(15 downto 0) <= xtaps(4);
  d0(24 downto 16) <= (others => xtaps(4)(15));

  dsp0 : xilinx_dsp_compact
  generic map(
    AREG        => 1,
    TYPES       => 20
  )
  port map(
    clk     => clk,

    -- basic port
    b       => coef0,
    a       => a0,
    d       => d0,

    c       => RND,

    -- cascaded port, optional
    pcout   => q0_cas
  );

  a1(15 downto 0) <= xtaps(1);
  a1(24 downto 16) <= (others => xtaps(1)(15));
  
  d1(15 downto 0) <= xtaps(4);
  d1(24 downto 16) <= (others => xtaps(4)(15));
  
  dsp1 : xilinx_dsp_compact
  generic map(
    AREG        => 1,
    TYPES       => 21
  )
  port map(
    clk     => clk,

    -- basic port
    b       => coef1,
    a       => a1,
    d       => d1,
    pcin    => q0_cas,

    -- cascaded port, optional
    pcout   => q1_cas
  );

  a2(15 downto 0) <= xtaps(3);
  a2(24 downto 16) <= (others => xtaps(3)(15));
  
  d2(15 downto 0) <= xtaps(4);
  d2(24 downto 16) <= (others => xtaps(4)(15));
  
  dsp2 : xilinx_dsp_compact
  generic map(
    AREG        => 1,
    TYPES       => 21
  )
  port map(
    clk     => clk,

    -- basic port
    b       => coef2,
    a       => a2,
    d       => d2,    
    pcin    => q1_cas,
    
    p       => q
  );

  y0 <= xtaps(9)(15 downto 0);

end bh;