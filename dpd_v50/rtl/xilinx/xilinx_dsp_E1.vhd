library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity xilinx_dsp_E1 is
  generic (
    AREG        : integer := 1;     -- 1 or 2
    BREG        : integer := 1;     -- 1 or 2

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

    -- 22, not supported
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
end entity xilinx_dsp_E1;

architecture bh of xilinx_dsp_E1 is
  type array40 is array(0 to 39) of boolean;
  constant USE_DPORT_SEL : array40 := (
    false, false, false, false, false, false, false, false, false, false, 
    false, false, false, false, false, false, false, false, false, false, 
    true , true , true , true , false, false, false, false, false, false, 
    true , true , false, false, false, false, false, false, false, false
  );
  constant USE_DPORT : boolean := USE_DPORT_SEL(TYPES);
  
  signal a_wire     : std_logic_vector(29 downto 0) := (others => '0');
  signal alumode    : std_logic_vector(3 downto 0)  := (others => '0');
  signal opmode     : std_logic_vector(6 downto 0)  := (others => '0');

  -- B4: 0 - B2; 1 - B1
  -- B3: 0 - {+A}; 1 - {-A}
  -- B2: 1 - {D} enabled; 0 - disabled
  -- B1: 0 - {A} enabled; 1 - disabled
  -- B0: 0 - A2; 1 - A1
  -- value: "0x100";
  signal inmode     : std_logic_vector(4 downto 0)  := (others => '0');
  

begin
  a_wire(24 downto 0) <= a;
  a_wire(29 downto 25) <= (others => a(24));

  -- 1: p = a*b + c
  type01 : if TYPES = 1 generate
    alumode <= "0000";
    opmode <= "0110101";
    inmode <= "00100";

  end generate;
  
  -- 2: p = a*b + pcin
  type02 : if TYPES = 2 generate
    alumode <= "0000";
    opmode <= "0010101";
    inmode <= "00100";

  end generate;

  -- 3: p = pcin - a*b
  type03 : if TYPES = 3 generate
    alumode <= "0011";
    opmode <= "0010101";
    inmode <= "00100";

  end generate;

  --10: p = a*b + p
  type10 : if TYPES = 10 generate   -- "010": select P
    alumode <= "0000";
    opmode <= "0100101";
    inmode <= "00100";

  end generate;
  
  --20: p = (a+d)*b + c
  type20 : if TYPES = 20 generate
    alumode <= "0000";
    opmode <= "0110101";
    inmode <= "00100";

  end generate;
  
  --21: p = (a+d)*b + pcin
  type21 : if TYPES = 21 generate
    alumode <= "0000";
    opmode <= "0010101";
    inmode <= "00100";

  end generate;
  
  --22: p = (acin+d)*b + pcin, not used any more
  
  --23: p = pcin - (d+a)*b
  type23 : if TYPES = 23 generate
    alumode <= "0011";
    opmode <= "0010101";
    inmode <= "00100";

  end generate;
  
  --30: p = (d-a)*b + c
  type30 : if TYPES = 30 generate
    alumode <= "0000";
    opmode <= "0110101";
    inmode <= "01100";

  end generate;

  --31: p = (d-a)*b + pcin
  type31 : if TYPES = 31 generate
    alumode <= "0000";
    opmode <= "0010101";
    inmode <= "01100";

  end generate;



  dsp : DSP48E1
  generic map (
      ACASCREG      => AREG,                    -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
      ADREG         => 1,                       -- Number of pipeline stages for pre-adder (0 or 1)
      ALUMODEREG    => 1,                       -- Number of pipeline stages for ALUMODE (0 or 1)
      AREG          => AREG,                    -- Number of pipeline stages for A (0, 1 or 2)
      AUTORESET_PATDET => "NO_RESET",           -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
      A_INPUT       => "DIRECT",                -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
      BCASCREG      => BREG,                    -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
      BREG          => BREG,                    -- Number of pipeline stages for B (0, 1 or 2)
      B_INPUT       => "DIRECT",                -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
      CARRYINREG    => 1,                       -- Number of pipeline stages for CARRYIN (0 or 1)
      CARRYINSELREG => 1,                       -- Number of pipeline stages for CARRYINSEL (0 or 1)
      CREG          => 1,                       -- Number of pipeline stages for C (0 or 1)
      DREG          => 1,                       -- Number of pipeline stages for D (0 or 1)
      INMODEREG     => 1,                       -- Number of pipeline stages for INMODE (0 or 1)
      MASK          => X"3fffffffffff",         -- 48-bit mask value for pattern detect (1=ignore)
      MREG          => 1,                       -- Number of multiplier pipeline stages (0 or 1)
      OPMODEREG     => 1,                       -- Number of pipeline stages for OPMODE (0 or 1)
      PATTERN       => X"000000000000",         -- 48-bit pattern match for pattern detect
      PREG          => 1,                       -- Number of pipeline stages for P (0 or 1)
      SEL_MASK      => "MASK",                  -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
      SEL_PATTERN   => "PATTERN",               -- Select pattern value ("PATTERN" or "C")
      USE_DPORT     => USE_DPORT,               -- Select D port usage (TRUE or FALSE)
      USE_MULT      => "MULTIPLY",              -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
      USE_PATTERN_DETECT => "NO_PATDET",        -- Enable pattern detect ("PATDET" or "NO_PATDET")
      USE_SIMD => "ONE48"                       -- SIMD selection ("ONE48", "TWO24", "FOUR12")
  )
  port map (
      -- Cascade: 30-bit (each) output: Cascade Ports
      ACOUT                 => open,            -- 30-bit output: A port cascade output
      BCOUT                 => open,            -- 18-bit output: B port cascade output
      CARRYCASCOUT          => open,            -- 1-bit output: Cascade carry output
      CARRYOUT              => open,            -- 4-bit output: Carry output
      MULTSIGNOUT           => open,            -- 1-bit output: Multiplier sign cascade output
      OVERFLOW              => open,            -- 1-bit output: Overflow in add/acc output
      P                     => p,               -- 48-bit output: Primary data output
      PATTERNBDETECT        => open,            -- 1-bit output: Pattern bar detect output
      PATTERNDETECT         => open,            -- 1-bit output: Pattern detect output
      PCOUT                 => pcout,           -- 48-bit output: Cascade output
      UNDERFLOW             => open,            -- 1-bit output: Underflow in add/acc output

      A                     => a_wire,          -- 30-bit input: A data input
      ACIN                  => (others => '0'), -- 30-bit input: A cascade data input
      ALUMODE               => alumode,         -- 4-bit input: ALU control input
      B                     => b,               -- 18-bit input: B data input
      BCIN                  => (others => '0'), -- 18-bit input: B cascade input
      C                     => c,               -- 48-bit input: C data input
      CARRYCASCIN           => '0',             -- 1-bit input: Cascade carry input
      CARRYIN               => '0',             -- 1-bit input: Carry input signal
      CARRYINSEL            => "000",           -- 3-bit input: Carry select input

      CEA1                  => '1',             -- 1-bit input: Clock enable input for 1st stage AREG
      CEA2                  => '1',             -- 1-bit input: Clock enable input for 2nd stage AREG
      CEAD                  => '1',             -- 1-bit input: Clock enable input for ADREG
      CEALUMODE             => '1',             -- 1-bit input: Clock enable input for ALUMODE
      CEB1                  => '1',             -- 1-bit input: Clock enable input for 1st stage BREG
      CEB2                  => '1',             -- 1-bit input: Clock enable input for 2nd stage BREG
      CEC                   => '1',             -- 1-bit input: Clock enable input for CREG
      CECARRYIN             => '1',             -- 1-bit input: Clock enable input for CARRYINREG
      CECTRL                => '1',             -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
      CED                   => '1',             -- 1-bit input: Clock enable input for DREG
      CEINMODE              => '1',             -- 1-bit input: Clock enable input for INMODEREG
      CEM                   => '1',             -- 1-bit input: Clock enable input for MREG
      CEP                   => cep,             -- 1-bit input: Clock enable input for PREG

      CLK                   => clk,             -- 1-bit input: Clock input
      D                     => d,               -- 25-bit input: D data input
      INMODE                => inmode,          -- 5-bit input: INMODE control input
      MULTSIGNIN            => '0',             -- 1-bit input: Multiplier sign input
      OPMODE                => opmode,          -- 7-bit input: Operation mode input
      PCIN                  => pcin,            -- 48-bit input: P cascade input

      RSTA                  => '0',             -- 1-bit input: Reset input for AREG
      RSTALLCARRYIN         => '0',             -- 1-bit input: Reset input for CARRYINREG
      RSTALUMODE            => '0',             -- 1-bit input: Reset input for ALUMODEREG
      RSTB                  => '0',             -- 1-bit input: Reset input for BREG
      RSTC                  => '0',             -- 1-bit input: Reset input for CREG
      RSTCTRL               => '0',             -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
      RSTD                  => '0',             -- 1-bit input: Reset input for DREG and ADREG
      RSTINMODE             => '0',             -- 1-bit input: Reset input for INMODEREG
      RSTM                  => '0',             -- 1-bit input: Reset input for MREG
      RSTP                  => rstp             -- 1-bit input: Reset input for PREG
  );

end bh;
