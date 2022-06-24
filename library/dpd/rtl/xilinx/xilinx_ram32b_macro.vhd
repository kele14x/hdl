library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

library unisim;
use unisim.vcomponents.all;

entity xilinx_ram32b_macro is
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
end entity xilinx_ram32b_macro;

architecture bh of xilinx_ram32b_macro is
  constant INST_NUM     : integer := DEPTH / 1024;
  constant DATA_WIDTH   : integer := 32 / INST_NUM;

  component xilinx_tdpbram_macro is
  generic (
    WIDTH       : integer := 1;     -- data width, 1, 2, 4, 8, 16, 32
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
  end component xilinx_tdpbram_macro;
  
  type array_addr is array(0 to INST_NUM-1) of std_logic_vector(15 downto 0);
  
  signal cached_addr1 : array_addr := (others => (others => '0'));
  signal cached_din1  : std_logic_vector(31 downto 0) := (others => '0');
  signal cached_we1   : std_logic_vector(INST_NUM-1 downto 0) := (others => '0');

  signal cached_addr2 : array_addr := (others => (others => '0'));
  signal cached_din2  : std_logic_vector(31 downto 0) := (others => '0');
  signal cached_we2   : std_logic_vector(INST_NUM-1 downto 0) := (others => '0');

  -- keep cached register
  attribute keep : string ;
  attribute keep of cached_addr1    : signal is "true" ;
  attribute keep of cached_din1     : signal is "true" ;
  attribute keep of cached_we1      : signal is "true" ;

  attribute keep of cached_addr2    : signal is "true" ;
  attribute keep of cached_din2     : signal is "true" ;
  attribute keep of cached_we2      : signal is "true" ;
  
begin

  ------------------------------------------------ (1)
  -- no cached
  no_cache1 : if CACHED1 = 0 generate
    cached_din1 <= din1;
    ff : for i in 0 to INST_NUM-1 generate
      cached_addr1(i) <= addr1;
      cached_we1  (i) <= we1;
    end generate;
  end generate;

  -- cached
  in_cached1 : if CACHED1 > 0 generate
    process(clk1)
    begin
      if rising_edge(clk1) then
        cached_din1 <= din1;
      end if;
    end process;

    ff : for i in 0 to INST_NUM / CACHED1 - 1 generate
      process(clk1)
      begin
        if rising_edge(clk1) then
          cached_addr1(i*CACHED1) <= addr1;
          cached_we1  (i*CACHED1) <= we1;
        end if;
      end process;

      dups : for j in 1 to CACHED1 - 1 generate
        cached_addr1(i*CACHED1+j) <= cached_addr1(i*CACHED1);
        cached_we1  (i*CACHED1+j) <= cached_we1  (i*CACHED1);
      end generate;

    end generate;
  end generate;


  ------------------------------------------------ (1)
  -- no cached
  no_cache2 : if CACHED2 = 0 generate
    cached_din2 <= din2;
    
    ff : for i in 0 to INST_NUM-1 generate
      cached_addr2(i) <= addr2;
      cached_we2  (i) <= we2;
    end generate;
  end generate;

  -- cached
  in_cached2 : if CACHED2 > 0 generate
    process(clk2)
    begin
      if rising_edge(clk2) then
        cached_din2 <= din2;
      end if;
    end process;
    
    ff : for i in 0 to INST_NUM / CACHED2 - 1 generate
      process(clk2)
      begin
        if rising_edge(clk2) then
          cached_addr2(i*CACHED2) <= addr2;
          cached_we2  (i*CACHED2) <= we2;
        end if;
      end process;

      dups : for j in 1 to CACHED2 - 1 generate
        cached_addr2(i*CACHED2+j) <= cached_addr2(i*CACHED2);
        cached_we2  (i*CACHED2+j) <= cached_we2  (i*CACHED2);
      end generate;

    end generate;
  end generate;


  rams : for i in 0 to INST_NUM-1 generate
    inst : xilinx_tdpbram_macro
    generic map(
      WIDTH       => DATA_WIDTH,
      DREG        => DREG
    )
    port map(
      -- port1, read
      clk1    => clk1,
      addr1   => cached_addr1(i),
      din1    => cached_din1 ((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH),
      we1     => cached_we1  (i),
      dout1   => dout1((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH),
    
      -- port2, write
      clk2    => clk2,
      addr2   => cached_addr2(i),
      din2    => cached_din2 ((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH),
      we2     => cached_we2  (i),
      dout2   => dout2((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH)
    );
  end generate;

end bh;

