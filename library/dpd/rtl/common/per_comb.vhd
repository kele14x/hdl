library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity per_comb is
  generic (TIMEOUT : integer := 12);
  port (
    rst       : in std_logic;
    clk       : in std_logic;

    read_en   : in std_logic;
    valid0    : in std_logic;
    valid1    : in std_logic;
    valid2    : in std_logic;
    valid3    : in std_logic;
    valid4    : in std_logic;
    data0     : in std_logic_vector(31 downto 0);
    data1     : in std_logic_vector(31 downto 0);
    data2     : in std_logic_vector(31 downto 0);
    data3     : in std_logic_vector(31 downto 0);
    data4     : in std_logic_vector(31 downto 0);

    valid     : out std_logic;
    data      : out std_logic_vector(31 downto 0);
    tocnt     : out std_logic_vector(15 downto 0)
  );
end entity per_comb;

architecture bh of per_comb is
  signal ival       : std_logic;
  signal tval       : std_logic;
  signal waitstat   : std_logic;
  signal waitcnt    : integer range 0 to TIMEOUT + 2;
  
  signal tocntreg   : std_logic_vector(15 downto 0);
  
  -- output data, wide or
  signal rdata0 : std_logic_vector(31 downto 0);
  signal rdata1 : std_logic_vector(31 downto 0);
  signal rdata2 : std_logic_vector(31 downto 0);
  signal rdata3 : std_logic_vector(31 downto 0);
  signal rdata4 : std_logic_vector(31 downto 0);
  
  signal rddata : std_logic_vector(31 downto 0);
  
begin
  
  -- TAG is fixed on this date, and should be not in future


  -- output data
  rdata0 <= data0 when valid0 = '1' else (others => '0');
  rdata1 <= data1 when valid1 = '1' else (others => '0');
  rdata2 <= data2 when valid2 = '1' else (others => '0');
  rdata3 <= data3 when valid3 = '1' else (others => '0');
  rdata4 <= data4 when valid4 = '1' else (others => '0');
  
  rddata <= rdata0 or rdata1 or rdata2 or rdata3 or rdata4;
  
  -- valid FSM
  ival <= valid0 or valid1 or valid2 or valid3 or valid4;
  tval <= '1' when (ival = '1' or waitcnt = TIMEOUT) else '0';
  
  process(clk, ival, waitcnt)
  begin
    if rising_edge(clk) then
      
      if rst = '1' then
        waitstat <= '0';
      elsif waitstat = '0' and read_en = '1' then
        waitstat <= '1';
      elsif waitstat = '1' and tval = '1' then
        waitstat <= '0';
      end if;

      if rst = '1' or (waitstat = '0' and read_en = '1') then
        waitcnt <= 0;
      elsif waitstat = '1' then
        waitcnt <= waitcnt + 1;
      end if;
      
      if rst = '1' then
        tocntreg <= (others => '0');
      elsif waitstat = '1' and waitcnt = TIMEOUT then
        tocntreg <= tocntreg + X"0001";
      end if;
      
      if waitstat = '1' and tval = '1' then
        valid <= '1';
        data <= rddata;
      else
        valid <= '0';
        data <= (others => '0');
      end if;
    end if;
  end process;
  
  tocnt <= tocntreg;

end bh;
