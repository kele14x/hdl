library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.arch.all;

entity data_cap_use is 
  port (
    
    -- 245.76MHz clock
    clk245  : in std_logic;
    rst245  : in std_logic;
    
    clk491  : in std_logic;
    rst491  : in std_logic;
    
    en2s    : in std_logic;
    
    ----------------------------------------------------------------------------
    -- 491MHz
    tori    : in std_logic_vector ( 15 downto 0 );
    torq    : in std_logic_vector ( 15 downto 0 );
    
    ----------------------------------------------------------------------------
    -- 245.76MHz
    
    -- source iq of a&b
    ai      : in std_logic_vector ( 15 downto 0 );
    aq      : in std_logic_vector ( 15 downto 0 );
    bi      : in std_logic_vector ( 15 downto 0 );
    bq      : in std_logic_vector ( 15 downto 0 );

    ----------------------------------------------------------------------------
    -- do not care the clocks
    -- capture control signal
    ext_trig    : in std_logic;
    tx_valid    : in std_logic;
    
    ----------------------------------------------------------------------------
    -- per_bus
    per_clk     : in std_logic;
    per_rst     : in std_logic;

    -- short per_bus
    short_per_addr  : in std_logic_vector ( 11 downto 0 );
    short_per_din   : in std_logic_vector ( 31 downto 0 );
    short_per_wren  : in std_logic;
    short_per_rden  : in std_logic;
    
    short_per_rdval : out std_logic;
    short_per_rddata: out std_logic_vector ( 31 downto 0 );
    
    
    -- full per_bus
    full_per_addr   : in std_logic_vector ( 19 downto 0 );
    full_per_din    : in std_logic_vector ( 31 downto 0 );
    full_per_wren   : in std_logic;
    full_per_rden   : in std_logic;

    full_rddata     : out std_logic_vector ( 31 downto 0 );
    full_rdvalid    : out std_logic;
    
    -- design tag
    tag             : out std_logic_vector ( 31 downto 0 )
  );
end entity data_cap_use;

architecture bh of data_cap_use is

  component datacap is
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
  end component datacap;

  component async_reg_def is
  port (
    clk     : in std_logic;
    regin   : in std_logic;
    regout  : out std_logic
  );
  end component async_reg_def;

  component async_per_in is 
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
  end component async_per_in;
  
  component async_per_out is 
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
  end component async_per_out;

  signal dini   : std_logic_vector(16*4 - 1 downto 0);
  signal dinq   : std_logic_vector(16*4 - 1 downto 0);
  
  -- tor IQ
  signal tori0, torq0, tori1, torq1 : std_logic_vector ( 15 downto 0 );
  signal tori_dl, torq_dl           : std_logic_vector ( 15 downto 0 );
  
  signal sync_trig, sync_txval      : std_logic;
  
  -- result registers
  signal cap_loops      : std_logic_vector ( 15 downto 0 );
  signal val_loops      : std_logic_vector ( 15 downto 0 );
  signal loop_ready     : std_logic_vector ( 0 to 0 );
  signal round_status   : std_logic_vector ( 0 to 0 );

  signal pwra, pwrb     : std_logic_vector ( 31 downto 0 );
  
  -- per_bus inter-connect
  
  -- for registers
  signal reg_addr       : std_logic_vector ( 11 downto 0 );
  signal reg_data       : std_logic_vector ( 31 downto 0 );
  signal reg_wren       : std_logic;
  signal reg_rden       : std_logic;
  
  signal reg_rdval      : std_logic;
  signal reg_rddata     : std_logic_vector ( 31 downto 0 );
  
  -- for memory
  signal mem_addr       : std_logic_vector ( 19 downto 0 );
  signal mem_data       : std_logic_vector ( 31 downto 0 );
  signal mem_wren       : std_logic;
  signal mem_rden       : std_logic;
  
  signal mem_rdval      : std_logic;
  signal mem_rddata     : std_logic_vector ( 31 downto 0 );

begin

  inst_async0 : async_reg_def
  port map (
    clk     => clk245,
    regin   => ext_trig,
    regout  => sync_trig
  );

  inst_async1 : async_reg_def
  port map (
    clk     => clk245,
    regin   => tx_valid,
    regout  => sync_txval
  );

  inst_in0 : async_per_in
  generic map (STAGE => 2)
  port map(
    -- port 1
    clk1    => per_clk,
    rst1    => per_rst,
    addr1   => short_per_addr,
    wrdata1 => short_per_din,
    wren1   => short_per_wren,
    rden1   => short_per_rden,

    -- port 2
    clk2    => clk245,
    rst2    => rst245,
    addr2   => reg_addr,
    wrdata2 => reg_data,
    wren2   => reg_wren,
    rden2   => reg_rden
  );

  inst_in1 : async_per_in
  generic map (STAGE => 2)
  port map(
    -- port 1
    clk1    => per_clk,
    rst1    => per_rst,
    addr1   => full_per_addr,
    wrdata1 => full_per_din,
    wren1   => full_per_wren,
    rden1   => full_per_rden,

    -- port 2
    clk2    => clk245,
    rst2    => rst245,
    addr2   => mem_addr,
    wrdata2 => mem_data,
    wren2   => mem_wren,
    rden2   => mem_rden
  );

  
  inst_out0 : async_per_out
  generic map (STAGE => 2)
  port map(
    -- port 1
    clk1        => clk245,
    rst1        => rst245,
    din         => reg_rddata,
    dvalid_in   => reg_rdval,

    -- port 2
    clk2        => per_clk,
    rst2        => per_rst,
    dout        => short_per_rddata,
    dvalid_out  => short_per_rdval
  );

  inst_out1 : async_per_out
  generic map (STAGE => 2)
  port map(
    -- port 1
    clk1        => clk245,
    rst1        => rst245,
    din         => mem_rddata,
    dvalid_in   => mem_rdval,

    -- port 2
    clk2        => per_clk,
    rst2        => per_rst,
    dout        => full_rddata,
    dvalid_out  => full_rdvalid
  );

  -- tor from 491 => 245x2
  process(clk491)
  begin
    if rising_edge(clk491) then
      tori_dl <= tori;
      torq_dl <= torq;
      
      if en2s = '1' then
        tori0 <= tori_dl;
        torq0 <= torq_dl;
        tori1 <= tori;
        torq1 <= torq;
      end if;
    end if;
  end process;
  
  dini <= tori1 & tori0 & bi & ai;
  dinq <= torq1 & torq0 & bq & aq;

  
  inst_cap : datacap
  generic map(
    DATAPATH    => 4,
    PWRSEL      => DATA_PWRSEL,     -- select signal into power
    DEPTH       => DATA_DEPTH       -- 4096, 8192, 16384, 32768
  )
  port map(
    -- input signal, multi-paths
    clk         => clk245,

    dini        => dini,
    dinq        => dinq,

    dinval      => sync_txval,
    ext_trig    => sync_trig,

    -- signal status
    round_status=> round_status(0),
    loop_rdy    => loop_ready(0),
    cap_loops   => cap_loops,
    val_loops   => val_loops,
    
    datapwr     => pwra,
    
    -- per_bus short, same clock with signal data
    ishort_addr => reg_addr,
    ishort_din  => reg_data,
    ishort_wren => reg_wren,

    -- configuration per_bus
    per_clk     => clk245,
    per_rst     => '0',

    -- per_bus full
    full_addr   => mem_addr,
    full_din    => mem_data,
    full_wren   => mem_wren,
    full_rden   => mem_rden,
    
    full_rdval  => mem_rdval,
    full_dout   => mem_rddata
  );
  tag <= (others => '0');

  
  -- registers read
  process(clk245)
  begin
    if rising_edge(clk245) then
      
      if reg_rden = '1' then
        case reg_addr is

          when X"153" =>
            reg_rdval <= '1';
            reg_rddata <= (others => '0');

            reg_rddata(0) <= loop_ready(0);
            reg_rddata(1) <= round_status(0);
            reg_rddata(15 downto 2) <= cap_loops(13 downto 0);
            reg_rddata(31 downto 18) <= val_loops(13 downto 0);

          when X"154" =>
            reg_rdval <= '1';
            reg_rddata <= pwra;
          
          when X"155" =>
            reg_rdval <= '1';
            reg_rddata <= pwrb;

          when others => 
            reg_rdval <= '0';
            reg_rddata <= (others => '0');
        end case;
      else
        reg_rdval <= '0';
        reg_rddata <= (others => '0');
      end if;
    end if;
  end process;


end bh;