library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dim2lut is 
  port (
    -- sysgen clock & enable
    clk    : in std_logic := '0';
    ce     : in std_logic := '0';
    
    -- signal @491
    addr_signal     : in std_logic_vector(8 downto 0);
    ciq0            : out std_logic_vector(31 downto 0);
    ciq1            : out std_logic_vector(31 downto 0);
    
    -- from 491 to local
    chnsel          : in std_logic_vector(0 downto 0);
    bandsel         : in std_logic_vector(0 downto 0);
    active          : in std_logic_vector(3 downto 0);
    
    -- constant
    cnst_lut_id     : in std_logic_vector(3 downto 0);
    cnst_band_id    : in std_logic_vector(0 downto 0);
    cnst_b01        : in std_logic_vector(0 downto 0);
    
    -- per_bus
    per_addr        : in std_logic_vector(19 downto 0);
    per_din         : in std_logic_vector(31 downto 0);
    per_we          : in std_logic;
    
    per_clk         : in std_logic
  );
end entity dim2lut;

architecture bh of dim2lut is

  component blk_mem_gen_0 IS
  port (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
  );
  end component blk_mem_gen_0;


  component async_reg_def is
  port (
    clk     : in std_logic;
    regin   : in std_logic;
    regout  : out std_logic
  );
  end component async_reg_def;

  component async_regs_def is
  generic (WIDTH : integer := 0);       -- WIDTH > 1
  port (
    clk     : in std_logic;
    regin   : in std_logic_vector(WIDTH-1 downto 0);
    regout  : out std_logic_vector(WIDTH-1 downto 0)
  );
  end component async_regs_def;


  signal wr_addr    : std_logic_vector(9 downto 0);
  signal wr_en      : std_logic_vector(0 downto 0);
  signal wr_data    : std_logic_vector(31 downto 0);
  
  signal rd_data    : std_logic_vector(63 downto 0);

  signal sync_chnsel    : std_logic_vector(0 downto 0);
  signal sync_bandsel   : std_logic_vector(0 downto 0);
  signal sync_active    : std_logic_vector(3 downto 0);
  
  signal lut_is_active  : std_logic;


  -- async clock
  --signal async_regto_umxjdkq, async_reg2        : std_logic;
  
  --attribute ASYNC_REG : string;
  --attribute ASYNC_REG of async_regto_umxjdkq: signal is "TRUE";
  --attribute ASYNC_REG of async_reg2: signal is "TRUE";

  --attribute KEEP : string ;
  --attribute KEEP of async_regto_umxjdkq  : signal is "TRUE"  ;

begin

  inst_ram : blk_mem_gen_0
  port map (
    clka    => per_clk,
    wea     => wr_en,
    addra   => wr_addr,
    dina    => wr_data,

    clkb    => clk,
    addrb   => addr_signal,
    doutb   => rd_data
  );
  
  
  inst_sync0 : async_regs_def
  generic map (WIDTH => 1)
  port map(
    clk     => per_clk,
    regin   => chnsel,
    regout  => sync_chnsel
  );

  inst_sync1 : async_regs_def
  generic map (WIDTH => 1)
  port map (
    clk     => per_clk,
    regin   => bandsel,
    regout  => sync_bandsel
  );

  inst_sync2 : async_regs_def
  generic map (WIDTH => 4)
  port map(
    clk     => per_clk,
    regin   => active,
    regout  => sync_active
  );
    
  ciq0 <= rd_data(31 downto 0 );
  ciq1 <= rd_data(63 downto 32);
  
  -- per_logic
  wr_data <= per_din;
  
  wr_addr(9) <= sync_chnsel(0);
  wr_addr(8) <= (not lut_is_active);
  wr_addr(7 downto 0) <= per_addr(7 downto 0);
  
  process(cnst_band_id, sync_chnsel, sync_active)
  begin
    if cnst_band_id = "0" then
      if sync_chnsel = "0" then
        lut_is_active <= sync_active(0);    -- 0A
      else
        lut_is_active <= sync_active(1);    -- 1A
      end if;
    else
      if sync_chnsel = "0" then
        lut_is_active <= sync_active(2);    -- 0B
      else
        lut_is_active <= sync_active(3);    -- 1B
      end if;
    end if;
  end process;
  
  
  process(per_addr, per_we, sync_bandsel, cnst_b01, cnst_lut_id, cnst_band_id)
    variable per_lut_id     : std_logic_vector(8 downto 0);
  begin
    per_lut_id := "00000" & cnst_lut_id;

    if per_addr(8)=cnst_b01(0) and per_addr(19 downto 11)=per_lut_id and sync_bandsel=cnst_band_id and per_we='1' then
      wr_en <= "1";
    else
      wr_en <= "0";
    end if;
  end process;   


end bh;


library ieee;
use ieee.std_logic_1164.all;

entity async_reg_def is
  port (
    clk     : in std_logic;
    regin   : in std_logic;
    regout  : out std_logic
  );
end entity async_reg_def;

architecture bh of async_reg_def is
  signal async_regto_umxjdkq        : std_logic; 
  signal reg2 : std_logic;

  -- behave as set_property ASYNC_REG TRUE
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of async_regto_umxjdkq: signal is "TRUE";
  attribute ASYNC_REG of reg2: signal is "TRUE";

begin
  
  process(clk)
  begin
    if rising_edge(clk) then
	  async_regto_umxjdkq <= regin;
	  reg2 <= async_regto_umxjdkq;
	end if;
  end process;  
  regout <= reg2;
  
end bh;


library ieee;
use ieee.std_logic_1164.all;

entity async_regs_def is
  generic (WIDTH : integer := 0);       -- WIDTH > 1
  port (
    clk     : in std_logic;
    regin   : in std_logic_vector(WIDTH-1 downto 0);
    regout  : out std_logic_vector(WIDTH-1 downto 0)
  );
end entity async_regs_def;

architecture bh of async_regs_def is
  component async_reg_def is
  port (
    clk     : in std_logic;
    regin   : in std_logic;
    regout  : out std_logic
  );
  end component;

begin
  reg_group : for i in 0 to WIDTH - 1 generate
    inst_reg : async_reg_def
    port map(
      clk     => clk ,
      regin   => regin(i) ,
      regout  => regout(i)
    );
  end generate reg_group;
  
end bh;


