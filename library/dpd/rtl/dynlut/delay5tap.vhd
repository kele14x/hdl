library ieee;
use ieee.std_logic_1164.all;

library work;
use work.conv_pkg.all;

entity delay5tap is
  port (
    clk     : in std_logic;
    q       : out std_logic_vector(15 downto 0);
    
    d0      : in std_logic_vector(15 downto 0);
    d1      : in std_logic_vector(15 downto 0);
    d2      : in std_logic_vector(15 downto 0);
    d3      : in std_logic_vector(15 downto 0);
    d4      : in std_logic_vector(15 downto 0);

    c0      : in std_logic_vector(15 downto 0);
    c1      : in std_logic_vector(15 downto 0);
    c2      : in std_logic_vector(15 downto 0);
    c3      : in std_logic_vector(15 downto 0);
    c4      : in std_logic_vector(15 downto 0)
  );
end entity delay5tap;

architecture bh of delay5tap is
  constant COEFBIT  : integer := 14;

  component xilinx_dsp_compact is
  generic (
    AREG        : integer := 1;     -- 1 or 2
    BREG        : integer := 1;     -- 1 or 2

    RND         : std_logic_vector := X"000000000000";  -- 48bit, default zero; on for DSPE2
    TYPES       : integer := 1      -- used types
  );
  port (
    clk     : in std_logic := '0';
    rstp    : in std_logic := '0';
    cep     : in std_logic := '1';

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
  
  signal dsp_b0, dsp_b1, dsp_b2, dsp_b3, dsp_b4     : std_logic_vector(17 downto 0);
  signal dsp_a0, dsp_a1, dsp_a2, dsp_a3, dsp_a4     : std_logic_vector(24 downto 0);
  signal dsp_r0, dsp_r1, dsp_r2, dsp_r3, dsp_r4     : std_logic_vector(47 downto 0);

begin
  dsp_b0 <= sign_extended(d0, 18);
  dsp_b1 <= sign_extended(d1, 18);
  dsp_b2 <= sign_extended(d2, 18);
  dsp_b3 <= sign_extended(d3, 18);
  dsp_b4 <= sign_extended(d4, 18);

  dsp_a0 <= sign_extended(c0, 25);
  dsp_a1 <= sign_extended(c1, 25);
  dsp_a2 <= sign_extended(c2, 25);
  dsp_a3 <= sign_extended(c3, 25);
  dsp_a4 <= sign_extended(c4, 25);

  dsp0 : xilinx_dsp_compact
  generic map(TYPES => 1)
  port map(
    clk     => clk,

    -- basic port
    b       => dsp_b0,
    a       => dsp_a0,
    pcout   => dsp_r0
  );

  dsp1 : xilinx_dsp_compact
  generic map(TYPES => 2)
  port map(
    clk     => clk,

    -- basic port
    pcin    => dsp_r0,

    b       => dsp_b1,
    a       => dsp_a1,
    pcout   => dsp_r1
  );

  dsp2 : xilinx_dsp_compact
  generic map(TYPES => 2)
  port map(
    clk     => clk,

    -- basic port
    pcin    => dsp_r1,

    b       => dsp_b2,
    a       => dsp_a2,
    pcout   => dsp_r2
  );

  dsp3 : xilinx_dsp_compact
  generic map(TYPES => 2)
  port map(
    clk     => clk,

    -- basic port
    pcin    => dsp_r2,

    b       => dsp_b3,
    a       => dsp_a3,
    pcout   => dsp_r3
  );

  dsp4 : xilinx_dsp_compact
  generic map(TYPES => 2)
  port map(
    clk     => clk,

    -- basic port
    pcin    => dsp_r4,

    b       => dsp_b4,
    a       => dsp_a4,
    p       => dsp_r4
  );
  
  process(clk)
  begin
    if rising_edge(clk) then
      q <= dsp_r4(15 + COEFBIT downto COEFBIT);
    end if;
  end process;

end bh;