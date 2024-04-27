library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.arch.all;

entity capram is
  generic (
    DEPTH       : integer := 4096   -- 2048, 4096, 8192, 16384, 32768
  );
  port (
    -- port1, fast
    clk1        : in std_logic;
    addr1       : in std_logic_vector(15 downto 0);
    din1        : in std_logic_vector(31 downto 0);
    wren1       : in std_logic;
    dout1       : out std_logic_vector(31 downto 0);

    -- port2, slow
    clk2        : in std_logic;
    addr2       : in std_logic_vector(15 downto 0);
    din2        : in std_logic_vector(31 downto 0);
    wren2       : in std_logic;
    dout2       : out std_logic_vector(31 downto 0)
  );
end entity capram;

architecture bh of capram is
  function ram_para1 (depth : integer) return integer is
  begin
    if depth <= 1024 then
      return 1024;
    else
      return depth;
    end if;
  end ram_para1;

  function ram_para2 (depth : integer) return integer is
  begin
    if depth <= 4096 then
      return 0;
    else
      return 4;
    end if;
  end ram_para2;

  constant RAM_DEPTH_PARA   : integer := ram_para1(DEPTH);
  constant CACHED1_PARA     : integer := ram_para2(DEPTH);

  component xilinx_ram32b_macro is
  generic (
    DEPTH       : integer := 1024;  -- 1024, 2048, 4096, 8192, 16384, 32768

    CACHED1     : integer := 0;
    CACHED2     : integer := 0;     -- add input cached registers, 1 clock latency
                                    -- 1, 2, 4, 8, ...
                                    -- add register on every {CACHED} RAM32K

    DREG        : integer := 1      -- 0 or 1
  );
  port (
    -- port1, read
    clk1    : in std_logic := '0';
    addr1   : in std_logic_vector(15 downto 0);
    din1    : in std_logic_vector(31 downto 0);
    we1     : in std_logic;
    dout1   : out std_logic_vector(31 downto 0);

    -- port2, write
    clk2    : in std_logic := '0';
    addr2   : in std_logic_vector(15 downto 0);
    din2    : in std_logic_vector(31 downto 0);
    we2     : in std_logic;
    dout2   : out std_logic_vector(31 downto 0)
  );
  end component xilinx_ram32b_macro;

begin
  
  type0 : if FPGA_DEVICE = "7SERIES" generate
  ram : xilinx_ram32b_macro
    generic map(
    DEPTH       => RAM_DEPTH_PARA,
    CACHED1     => CACHED1_PARA,
    CACHED2     => 0,
    DREG        => 1
  )
  port map(
    -- port1, read
    clk1    => clk1,
    addr1   => addr1,
    din1    => din1,
    we1     => wren1,
    dout1   => dout1,

    -- port2, write
    clk2    => clk2,
    addr2   => addr2,
    din2    => din2,
    we2     => wren2,
    dout2   => dout2
  );  
  end generate;


end bh;

