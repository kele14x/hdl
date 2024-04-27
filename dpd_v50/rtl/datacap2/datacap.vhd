library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity datacap is
  generic (
    DATAPATH    : integer := 1;
    PWRSEL      : std_logic_vector(0 to 7);  -- select signal into power
    DEPTH       : integer := 4096   -- 4096, 8192, 16384, 32768
  );
  port (
    -- input signal, multi-paths
    clk         : in std_logic;

    dini        : in std_logic_vector(16*DATAPATH - 1 downto 0);
    dinq        : in std_logic_vector(16*DATAPATH - 1 downto 0);

    dinval      : in std_logic;
    ext_trig    : in std_logic;

    -- signal status
    round_status: out std_logic;
    loop_rdy    : out std_logic;
    cap_loops   : out std_logic_vector(15 downto 0);
    val_loops   : out std_logic_vector(15 downto 0);
    
    datapwr     : out std_logic_vector(31 downto 0);    
    
    -- per_bus short, same clock with signal data
    ishort_addr : in std_logic_vector(11 downto 0);
    ishort_din  : in std_logic_vector(31 downto 0);
    ishort_wren : in std_logic;

    -- configuration per_bus
    per_clk     : in std_logic;
    per_rst     : in std_logic;
    
    -- per_bus full
    full_addr   : in std_logic_vector(19 downto 0);
    full_din    : in std_logic_vector(31 downto 0);
    full_wren   : in std_logic;
    full_rden   : in std_logic;
    
    full_rdval  : out std_logic;
    full_dout   : out std_logic_vector(31 downto 0)
  );
end entity datacap;

architecture bh of datacap is

  
  component datacap_fsm is
  generic (
    DATAPATH    : integer := 1;
    PWRSEL      : std_logic_vector(0 to 7);  -- select signal into power
    DEPTH       : integer := 4096   -- 4096, 8192, 16384, 32768
  );
  port (
    -- input signal, multi-paths
    clk         : in std_logic;

    dini        : in std_logic_vector(16*DATAPATH - 1 downto 0);
    dinq        : in std_logic_vector(16*DATAPATH - 1 downto 0);

    dinval      : in std_logic;
    ext_trig    : in std_logic;

    -- per_bus short, same clock with signal data
    ishort_addr : in std_logic_vector(11 downto 0); 
    ishort_din  : in std_logic_vector(31 downto 0);
    ishort_wren : in std_logic;
    
    -- signal status
    
    -- module output
    loop_rdy    : out std_logic;
    o_cap_loops : out std_logic_vector(15 downto 0);
    o_val_loops : out std_logic_vector(15 downto 0);
    
    capram_sel  : out std_logic;
    capram_addr : out std_logic_vector(15 downto 0);
    capram_wren : out std_logic;
    
    o_pwr       : out std_logic_vector(31 downto 0)
  );
  end component datacap_fsm;

  component datacap_store is
  generic (
    DATAPATH    : integer := 1;
    DEPTH       : integer := 4096   -- 4096, 8192, 16384, 32768
  );
  port (
    -- input signal, multi-paths
    clk         : in std_logic;

    dini        : in std_logic_vector(16*DATAPATH - 1 downto 0);
    dinq        : in std_logic_vector(16*DATAPATH - 1 downto 0);
    
    -- ram control
    ramsel      : in std_logic;
    capaddr     : in std_logic_vector(15 downto 0);
    capwren     : in std_logic;

    -- configuration per_bus
    per_clk     : in std_logic;
    per_rst     : in std_logic;

    -- per_bus full
    full_addr   : in std_logic_vector(19 downto 0);
    full_din    : in std_logic_vector(31 downto 0);
    full_wren   : in std_logic;
    full_rden   : in std_logic;
    full_rdval  : out std_logic;
    full_dout   : out std_logic_vector(31 downto 0)
  );
  end component datacap_store;

  signal capram_sel     : std_logic;
  signal capram_addr    : std_logic_vector(15 downto 0);
  signal capram_wren    : std_logic;
    
begin
  fsm : datacap_fsm
  generic map(
    DATAPATH    => DATAPATH,
    PWRSEL      => PWRSEL,
    DEPTH       => DEPTH
  )
  port map(
    -- input signal, multi-paths
    clk         => clk     ,

    dini        => dini    ,
    dinq        => dinq    ,

    dinval      => dinval  ,
    ext_trig    => ext_trig,

    -- per_bus short, same clock with signal data
    ishort_addr => ishort_addr,
    ishort_din  => ishort_din ,
    ishort_wren => ishort_wren,
        
    -- module output
    loop_rdy    => loop_rdy,
    o_cap_loops => cap_loops,
    o_val_loops => val_loops,
    
    capram_sel  => capram_sel,
    capram_addr => capram_addr,
    capram_wren => capram_wren,
    
    o_pwr       => datapwr
  );
  round_status <= capram_wren;

  ramstore : datacap_store
  generic map(
    DATAPATH    => DATAPATH,
    DEPTH       => DEPTH
  )
  port map(
    -- input signal, multi-paths
    clk         => clk ,

    dini        => dini,
    dinq        => dinq,
    
    -- ram control
    ramsel      => capram_sel ,
    capaddr     => capram_addr,
    capwren     => capram_wren,

    -- configuration per_bus
    per_clk     => per_clk  ,
    per_rst     => per_rst  ,

    -- per_bus full
    full_addr   => full_addr,
    full_din    => full_din ,
    full_wren   => full_wren,
    full_rden   => full_rden,
    full_rdval  => full_rdval,
    full_dout   => full_dout
  );

end bh;

