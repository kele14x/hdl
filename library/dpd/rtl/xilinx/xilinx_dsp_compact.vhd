library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.arch.all;

library unisim;
use unisim.vcomponents.all;

entity xilinx_dsp_compact is
  generic (
    AREG        : integer := 1;     -- 1 or 2
    BREG        : integer := 1;     -- 1 or 2

    RND         : std_logic_vector := X"000000000000";  -- 48bit, default zero; on for DSPE2
    TYPES       : integer := 1      -- used types
    -- 1:
    -- p = a*b + c, basic purpose
    
    -- 2:
    -- p = a*b + pcin
    
    -- 3:
    -- p = pcin - a*b
    
    -- 10:
    -- p = a*b + p
    
    -- 20:
    -- p = (a+d)*b + c, restered adder {a+d}

    -- 21
    -- p = (a+d)*b + pcin

    -- 22
    -- p = (acin+d)*b + pcin
    
    -- 23
    -- p = pcin - (d+a)*b
    
    -- 30
    -- p = (d-a)*b + c

    -- 31
    -- p = (d-a)*b + pcin
    
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
end entity xilinx_dsp_compact;

architecture bh of xilinx_dsp_compact is


  component xilinx_dsp_E1 is
  generic (
    AREG        : integer := 1;     -- 1 or 2
    BREG        : integer := 1;     -- 1 or 2

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
  end component xilinx_dsp_E1;

  component xilinx_dsp_E2 is
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
  end component xilinx_dsp_E2;

begin
  
  e1 : if (DSP_TYPE = "DSPE1") generate
  dsp: xilinx_dsp_E1
  generic map(
    AREG        => AREG ,
    BREG        => BREG ,

    TYPES       => TYPES
  )
  port map(
    clk     => clk,
    rstp    => rstp,
    cep     => cep,

    -- basic port
    b       => b,
    a       => a,
    d       => d,

    c       => c,
    p       => p,

    -- cascaded port, optional
    pcin    => pcin,
    pcout   => pcout
  );
  end generate;
  
  e2 : if (DSP_TYPE = "DSPE2") generate
  dsp: xilinx_dsp_E2
  generic map(
    AREG        => AREG ,
    BREG        => BREG ,
    RND         => RND  ,
    TYPES       => TYPES
  )
  port map(
    clk     => clk,
    rstp    => rstp,
    cep     => cep,

    -- basic port
    b       => b,
    a       => a,
    d       => d,

    c       => c,
    p       => p,

    -- cascaded port, optional
    pcin    => pcin,
    pcout   => pcout
  );
  end generate;


end bh;
