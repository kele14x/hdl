library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

LIBRARY UNISIM;
USE UNISIM.VCOMPONENTS.ALL;


entity dim2lut is 
  port (
    -- sysgen clock & enable
    clk    : in std_logic := '0';
    ce     : in std_logic := '0';
    
    -- signal @491
    addr_signal     : in std_logic_vector(8 downto 0);
    ciq0            : out std_logic_vector(31 downto 0);
    ciq1            : out std_logic_vector(31 downto 0);
    
    -- constant
    cnst_lut_id     : in std_logic_vector(3 downto 0);
    cnst_band_id    : in std_logic_vector(0 downto 0);
    cnst_b01        : in std_logic_vector(0 downto 0);
    
    -- per_bus
    per_addr        : in std_logic_vector(19 downto 0);
    per_din         : in std_logic_vector(31 downto 0);
    per_we          : in std_logic;
    
    chnsel          : in std_logic_vector(0 downto 0);
    bandsel         : in std_logic_vector(0 downto 0);
    active          : in std_logic_vector(3 downto 0);
    
    per_clk         : in std_logic
  );
end entity dim2lut;

architecture bh of dim2lut is
 
  -- async clock
  --signal async_regto_umxjdkq, async_reg2        : std_logic;
  
  --attribute ASYNC_REG : string;
  --attribute ASYNC_REG of async_regto_umxjdkq: signal is "TRUE";
  --attribute ASYNC_REG of async_reg2: signal is "TRUE";

  --attribute KEEP : string ;
  --attribute KEEP of async_regto_umxjdkq  : signal is "TRUE"  ;

begin
  
  ciq0 <= (others => '0');
  ciq1 <= (others => '0');
  
end bh;
