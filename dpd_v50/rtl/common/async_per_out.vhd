library ieee;
use ieee.std_logic_1164.all;

entity async_per_out is 
  generic (STAGE : integer := 2);   -- >=2
  port (
    -- port 1
    clk1        : in std_logic := '0';
    rst1        : in std_logic := '0';
    din         : in std_logic_vector(31 downto 0);
    dvalid_in   : in std_logic;

    -- port 2
    clk2        : in std_logic := '0';
    rst2        : in std_logic := '0';
    dout        : out std_logic_vector(31 downto 0);
    dvalid_out  : out std_logic
  );
end entity async_per_out;

architecture bh of async_per_out is
  -- in [clk1]
  signal toggle_src     : std_logic := '0';
  signal clk1_din       : std_logic_vector(31 downto 0);
  
  -- in [clk2]  
  signal toggle_dst     : std_logic_vector(STAGE-1 downto 0);
  signal toggle_dst_chk : std_logic;

  -- behave as set_property ASYNC_REG TRUE
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of toggle_dst: signal is "TRUE";

begin
  
  -- signal 
  process(clk1, rst1)
  begin
    if rst1 = '1' then
      toggle_src <= '0';
    elsif rising_edge(clk1) and dvalid_in = '1' then
      toggle_src <= not toggle_src;
      clk1_din <= din;
    end if;
  end process;

  process(clk2, rst2)
  begin
    if rst2 = '1' then
      toggle_dst <= (others => '0');
    elsif rising_edge(clk2) then
      toggle_dst <= toggle_dst(STAGE-2 downto 0) & toggle_src;
      toggle_dst_chk <= toggle_dst(STAGE-1);
      
      if (toggle_dst_chk xor toggle_dst(STAGE-1)) = '1' then
        dvalid_out <= '1';
        dout <= clk1_din;
      else
        dvalid_out <= '0';
        dout <= (others => '0');
      end if;
    end if;
  end process;
  
end bh;