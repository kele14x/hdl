library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

LIBRARY UNISIM;
USE UNISIM.VCOMPONENTS.ALL;

entity xilinx_tdpbram_macro is
  generic (
    WIDTH       : integer := 1;     -- data width, 1, 2, 4, 8, 16, 18, 32, 36
    DREG        : integer := 1      -- 0 or 1
  );
  port (
    -- port1, read
    clk1    : in std_logic := '0';
    addr1   : in std_logic_vector(15 downto 0);
    din1    : in std_logic_vector(WIDTH-1 downto 0);
    we1     : in std_logic;
    dout1   : out std_logic_vector(WIDTH-1 downto 0);

    -- port2, write
    clk2    : in std_logic := '0';
    addr2   : in std_logic_vector(15 downto 0);
    din2    : in std_logic_vector(WIDTH-1 downto 0);
    we2     : in std_logic;
    dout2   : out std_logic_vector(WIDTH-1 downto 0)
  );
end entity xilinx_tdpbram_macro;

architecture bh of xilinx_tdpbram_macro is

  function WR_ADAPTION (num : integer) return integer is
  begin
    if num <= 9 then
      return 1;
    elsif num <= 19 then
      return 2;
    else
      return 4;
    end if;
  end WR_ADAPTION;

  constant WRNUM    : integer := WR_ADAPTION(WIDTH);
  constant ADNUM    : integer := 15 - natural(round(log2(real(WIDTH))));


  signal wren1          : std_logic_vector(WRNUM-1 downto 0);
  signal wren2          : std_logic_vector(WRNUM-1 downto 0);
  signal addr1m         : std_logic_vector(ADNUM-1 downto 0);
  signal addr2m         : std_logic_vector(ADNUM-1 downto 0);

begin
  addr1m <= addr1(ADNUM-1 downto 0);
  addr2m <= addr2(ADNUM-1 downto 0);

  wren1 <= (others => we1);
  wren2 <= (others => we2);
  
  inst_ram : BRAM_TDP_MACRO
   generic map (
      BRAM_SIZE => "36Kb", -- Target BRAM, "18Kb" or "36Kb" 
      DEVICE => "7SERIES", -- Target Device: "VIRTEX5", "VIRTEX6", "7SERIES", "SPARTAN6" 
      DOA_REG => DREG, -- Optional port A output register (0 or 1)
      DOB_REG => DREG, -- Optional port B output register (0 or 1)
      
      INIT_A => X"000000000", -- Initial values on A output port
      INIT_B => X"000000000", -- Initial values on B output port
      INIT_FILE => "NONE",
      READ_WIDTH_A => WIDTH,   -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
      READ_WIDTH_B => WIDTH,   -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
      SIM_COLLISION_CHECK => "NONE", -- Collision check enable "ALL", "WARNING_ONLY", 
                                    -- "GENERATE_X_ONLY" or "NONE" 
      SRVAL_A => X"000000000",   -- Set/Reset value for A port output
      SRVAL_B => X"000000000",   -- Set/Reset value for B port output
      WRITE_MODE_A => "NO_CHANGE", -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE" 
      WRITE_MODE_B => "NO_CHANGE", -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE" 
      WRITE_WIDTH_A => WIDTH, -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
      WRITE_WIDTH_B => WIDTH  -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
   )
   port map (
      DOA => dout1,       -- Output port-A data, width defined by READ_WIDTH_A parameter
      DOB => dout2,       -- Output port-B data, width defined by READ_WIDTH_B parameter
      ADDRA => addr1m,   -- Input port-A address, width defined by Port A depth
      ADDRB => addr2m,   -- Input port-B address, width defined by Port B depth
      CLKA => clk1,     -- 1-bit input port-A clock
      CLKB => clk2,     -- 1-bit input port-B clock
      DIA => din1,       -- Input port-A data, width defined by WRITE_WIDTH_A parameter
      DIB => din2,       -- Input port-B data, width defined by WRITE_WIDTH_B parameter
      ENA => '1',       -- 1-bit input port-A enable
      ENB => '1',       -- 1-bit input port-B enable
      REGCEA => '1', -- 1-bit input port-A output register enable
      REGCEB => '1', -- 1-bit input port-B output register enable
      RSTA => '0',     -- 1-bit input port-A reset
      RSTB => '0',     -- 1-bit input port-B reset
      WEA => wren1,       -- Input port-A write enable, width defined by Port A depth
      WEB => wren2        -- Input port-B write enable, width defined by Port B depth
   );

end bh;
