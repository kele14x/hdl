library ieee;
use ieee.std_logic_1164.all;

entity async_per_in is 
  generic (STAGE : integer := 2);   -- >=2
  port (
    -- port 1
    clk1    : in std_logic := '0';
    rst1    : in std_logic := '0';
    addr1   : in std_logic_vector;
    wrdata1 : in std_logic_vector(31 downto 0);
    wren1   : in std_logic;
    rden1   : in std_logic;

    -- port 2
    clk2  : in std_logic := '0';
    rst2  : in std_logic := '0';
    addr2   : out std_logic_vector;
    wrdata2 : out std_logic_vector(31 downto 0);
    wren2   : out std_logic;
    rden2   : out std_logic
  );
end entity async_per_in;

architecture bh of async_per_in is
  constant ADDR_WIDTH   : integer := addr1'length;  --'
  
  -- clk1
  signal wrdata_regin   : std_logic_vector(31 downto 0);
  signal addr_regin     : std_logic_vector(ADDR_WIDTH-1 downto 0);
  
  signal togsrc_wren    : std_logic;
  signal togsrc_rden    : std_logic;
  
  -- clk2
  signal togdst_wren    : std_logic_vector(STAGE-1 downto 0);
  signal togdst_wrenchk : std_logic;
  signal togdst_rden    : std_logic_vector(STAGE-1 downto 0);
  signal togdst_rdenchk : std_logic;
      
  -- behave as set_property ASYNC_REG TRUE
  attribute ASYNC_REG : string;
  
  attribute ASYNC_REG of togdst_wren: signal is "TRUE";
  attribute ASYNC_REG of togdst_rden: signal is "TRUE";
begin

  -- lock input data
  process(clk1, rst1)
  begin
    if rst1 = '1' then
      togsrc_wren <= '0';
      togsrc_rden <= '0';
    elsif rising_edge(clk1) then
      if wren1 = '1' or rden1 = '1' then
        addr_regin <= addr1;
      end if;
      if wren1 = '1' then
        wrdata_regin <= wrdata1;
      end if;
      
      if wren1 = '1' then
        togsrc_wren <= not togsrc_wren;
      end if;
      
      if rden1 = '1' then
        togsrc_rden <= not togsrc_rden;
      end if;
    end if;
  end process;
  
  -- [clk2]
  process(clk2)
    variable wren2t       : std_logic;
    variable rden2t       : std_logic;
  begin
    if rising_edge(clk2) then
      togdst_wren <= togdst_wren(STAGE-2 downto 0) & togsrc_wren;
      togdst_wrenchk <= togdst_wren(STAGE-1);

      togdst_rden <= togdst_rden(STAGE-2 downto 0) & togsrc_rden;
      togdst_rdenchk <= togdst_rden(STAGE-1);

      wren2t := togdst_wrenchk xor togdst_wren(STAGE-1);
      rden2t := togdst_rdenchk xor togdst_rden(STAGE-1);

      if wren2t = '1' or rden2t = '1' then
        addr2 <= addr_regin;
      end if;

      if wren2t = '1' then
        wrdata2 <= wrdata_regin;
      end if;

      wren2 <= wren2t;
      rden2 <= rden2t;      
    end if;
  end process;

end bh;