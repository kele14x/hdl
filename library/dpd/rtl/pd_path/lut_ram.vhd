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
use work.dpd_v50_def.all;
use work.per_regs_def.all;

library unimacro;
use unimacro.vcomponents.all;

entity lut_ram is
  generic ( LUT_ID : integer := 0 );
  port (
    -- signal
    clk     : in std_logic := '0';

    addr    : in std_logic_vector(9 downto 0);
    ci      : out std_logic_vector(17 downto 0);
    cq      : out std_logic_vector(17 downto 0);

    ramsel  : in std_logic;     -- 0&1, select active RAM

    -- per_bus
    per_clk     : in std_logic;
    per_addr    : in std_logic_vector(19 downto 0);
    per_din     : in std_logic_vector(31 downto 0);
    per_we      : in std_logic
  );
end lut_ram;

architecture bh of lut_ram is
  -- RAM read & write
  signal ramselrd   : std_logic;
  signal addr1  : std_logic_vector(8 downto 0);
  
  signal addr2  : std_logic_vector(9 downto 0);
  signal data2  : std_logic_vector(17 downto 0);
  signal wren2  : std_logic;
  signal ramselwr   : std_logic;
  
  -- others
  component async_reg_def is
  port (
    clk     : in std_logic;
    regin   : in std_logic;
    regout  : out std_logic
  );
  end component async_reg_def;
  
  -- real ram instance
  signal ramrddata  : std_logic_vector(35 downto 0);
  signal ramrddata2 : std_logic_vector(35 downto 0) := (others => '0');
  
  -- VHDL constraint
  attribute KEEP : string;
  attribute KEEP of ramselrd   : signal is "TRUE";
  attribute KEEP of ramrddata2 : signal is "TRUE";

begin
  -- port1, read
  process(clk)
  begin
    if rising_edge(clk) then
      ramselrd <= not ramsel;        -- select the other one
      ramrddata2 <= ramrddata;
    end if;
  end process;

  addr1 <= ramselrd & addr(7 downto 0);

  -- port2, write
  inst_reg : async_reg_def
  port map (
    clk     => per_clk,
    regin   => ramsel,
    regout  => ramselwr
  );

  addr2 <= ramselwr & per_addr(8 downto 0);
  data2 <= per_din(17 downto 0);
  
  process(per_addr, per_we)
  begin
    if per_addr(19 downto 12) = conv_std_logic_vector(ADDR_LUTS/4096 + LUT_ID, 8) then
      wren2 <= per_we;
    else
      wren2 <= '0';
    end if;
  end process;

  -- real RAM
   BRAM_SDP_MACRO_inst : BRAM_SDP_MACRO
   generic map (
      BRAM_SIZE => "18Kb", -- Target BRAM, "18Kb" or "36Kb" 
      DEVICE => "7SERIES", -- Target device: "VIRTEX5", "VIRTEX6", "7SERIES", "SPARTAN6" 
      WRITE_WIDTH => 18,    -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
      READ_WIDTH => 36,     -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
      DO_REG => 1, -- Optional output register (0 or 1)
      INIT_FILE => "NONE",
      SIM_COLLISION_CHECK => "NONE", -- Collision check enable "ALL", "WARNING_ONLY", 
                                    -- "GENERATE_X_ONLY" or "NONE"       
      WRITE_MODE => "WRITE_FIRST" -- Specify "READ_FIRST" for same clock or synchronous clocks
   )
   port map (
      DO => ramrddata,         -- Output read data port, width defined by READ_WIDTH parameter
      DI => data2,         -- Input write data port, width defined by WRITE_WIDTH parameter
      RDADDR => addr1, -- Input read address, width defined by read port depth
      RDCLK => clk,   -- 1-bit input read clock
      RDEN => '1',     -- 1-bit input read port enable
      REGCE => '1',   -- 1-bit input read output register enable
      RST => '0',       -- 1-bit input reset 
      WE => "11",         -- Input write enable, width defined by write port depth
      WRADDR => addr2, -- Input write address, width defined by write port depth
      WRCLK => per_clk,   -- 1-bit input write clock
      WREN => wren2      -- 1-bit input write port enable
   );
   ci <= ramrddata2(17 downto 0);
   cq <= ramrddata2(35 downto 18);


end bh;