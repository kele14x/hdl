library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity random_captrig is
  generic (CLK_FREQUENCY : integer := 150000000);
  port (
    clk         : in std_logic;
    rst         : in std_logic;

    captrig_i   : in std_logic;
    fixdelay    : in std_logic_vector(23 downto 0);
    
    -- rising_edge indicate an effective trigger
    captrig_o   : out std_logic
  );
end entity random_captrig;

architecture bh of random_captrig is

  constant RNDCNT_ROUND : integer := CLK_FREQUENCY / 1000 * 73 / 100;

  component async_reg_def is
  port (
    clk     : in std_logic;
    regin   : in std_logic;
    regout  : out std_logic
  );
  end component async_reg_def;
  
  -- synchronization
  signal sync_trig      : std_logic;
  signal dl_trig        : std_logic;

  signal edge_trig      : std_logic;
  
  -- delay time
  signal usedelay       : std_logic_vector(23 downto 0);
  
  -- random counter
  signal randcnt        : std_logic_vector(23 downto 0) := (others => '0');
  signal trigcnt        : std_logic_vector(23 downto 0);
  
  -- output trigger edge
  signal delayed_trig   : std_logic;
  signal trigcycles     : std_logic_vector(7 downto 0);
  
  -- status registers
  signal trig_in_count  : std_logic;
  
begin
  inst_sync : async_reg_def
  port map (
    clk     => clk ,
    regin   => captrig_i ,
    regout  => sync_trig
  );
  
  process(clk)
  begin
    if rising_edge(clk) then
      dl_trig <= sync_trig;
      
      if dl_trig /= sync_trig then
        edge_trig <= '1';
      else
        edge_trig <= '0';
      end if;
      
      if edge_trig = '1' and trig_in_count = '0' then
        if fixdelay = X"000000" then
          usedelay <= randcnt + X"000010";
        else
          usedelay <= fixdelay;
        end if;
      end if;
      
      -- output
      trigcycles <= trigcycles(6 downto 0) & delayed_trig;
      captrig_o <= trigcycles(7) or trigcycles(6) or trigcycles(5) or trigcycles(4) or trigcycles(3) or trigcycles(2) or trigcycles(1) or trigcycles(0);
       
      -- trigcnt
      -- count from trigger
      if rst = '1' then
        trig_in_count <= '0';
      elsif edge_trig = '1' then
        trig_in_count <= '1';
      elsif trigcnt = usedelay then
        trig_in_count <= '0';
      end if;
      
      if trig_in_count = '1' and trigcnt = usedelay then
        delayed_trig <= '1';
      else
        delayed_trig <= '0';
      end if;

      if edge_trig = '1' then
        trigcnt <= (others => '0');
      elsif trig_in_count = '1' then
        trigcnt <= trigcnt + X"000001";
      end if;
      
      -- rand counter
      if randcnt = conv_std_logic_vector(RNDCNT_ROUND, 24) then
        randcnt <= (others => '0');
      else
        randcnt <= randcnt + X"000001";
      end if;
      
    end if;
  end process;
  


end bh;
