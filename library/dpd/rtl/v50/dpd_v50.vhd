--------------------------------------------------------------------------------
-- DPD 1.0 for dual-band, FPGA wrapper
-- designed by Yong Feng, 
-- first revision: 2017-09-25
-- description:
-- 
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use ieee.math_real.all;

library work;
use work.arch.all;
use work.dpd_v50_def.all; 
use work.pd_path_def.all;
use work.per_regs_def.all;

entity dpd_v50 is
  generic (PROC_CLKF : integer := 150000000; PATH_NUM_DEF  : integer := 8; PHASE : integer := 1);
  port (
    ----------------------------------------------------------------------------
    -- global reset and clock
    rst245      : in std_logic;   -- async reset, active high
    rst491      : in std_logic;

    clk245      : in std_logic;   -- 245.76MHz clock
    clk491      : in std_logic;   -- 491.52MHz clock
    en2s        : in std_logic;   -- 245 <=> 491, cross enable, aligned with clk245

    ----------------------------------------------------------------------------
    -- radio software config
    aum_clk     : in std_logic;
    aum_rst     : in std_logic;
    aum_addr    : in std_logic_vector(11 downto 0);
    aum_din     : in std_logic_vector(31 downto 0);
    aum_we      : in std_logic;

    -- processor interface
    per_clk     : in std_logic;   -- clock for peripheral
    per_rst     : in std_logic;

    per_addr_i  : in std_logic_vector(19 downto 0);
    per_wrdata_i: in std_logic_vector(31 downto 0);
    per_wren_i  : in std_logic;
    per_rden_i  : in std_logic;

    per_rddata_o: out std_logic_vector(31 downto 0);
    per_rdval_o : out std_logic;
    
    -- bram interface
    bram_rst    : in std_logic;
    bram_clk    : in std_logic;

    bram_addr_i : in std_logic_vector(15 downto 0);
    bram_data_i : in std_logic_vector(31 downto 0);
    bram_wren_i : in std_logic;
    bram_data_o : out std_logic_vector(31 downto 0);
    
    interface_ram_rd    : in std_logic_vector(31 downto 0);     -- read from interface ram, combined to BRAM interface
    
    -- interrupt
    sw_int_o        : out std_logic_vector(3 downto 0);     -- Bit 0: elog storage request
                                                            -- BIT 1: not used
                                                            -- BIT 2: VCA gain changed
                                                            -- BIT 3: VCA fault

    ----------------------------------------------------------------------------
    -- signal path, input and output
    frm_start   : in std_logic;     -- frame start
    pa_on       : in std_logic;     -- '1'=on; '0'=off; up_edge: rx to tx; down_edge: tx to rx
    tx_valid    : in std_logic;     -- TX and TOR signal are valid for DPD
    cap_trig    : in std_logic;     -- User defined capture trigger, default '0'

    -- input signal
    xi      : in std_logic_vector( 16*PATH_NUM_DEF-1 downto 0 );
    xq      : in std_logic_vector( 16*PATH_NUM_DEF-1 downto 0 );

    -- output IQ signal
    yi0     : out std_logic_vector(PATH_NUM_DEF*16 - 1 downto 0);
    yq0     : out std_logic_vector(PATH_NUM_DEF*16 - 1 downto 0);

    yi1     : out std_logic_vector(PATH_NUM_DEF*16 - 1 downto 0);
    yq1     : out std_logic_vector(PATH_NUM_DEF*16 - 1 downto 0);
    
    rxi         : in std_logic_vector(15 downto 0);     -- 491.52Msps
    rxq         : in std_logic_vector(15 downto 0);     --

    -- Log(N)*bit selector for Tor
    rx_path     : out std_logic_vector(7 downto 0);
    looped      : out std_logic;

    -- DPD status monitor output
    bk_gain     : out std_logic_vector(16*PATH_NUM_DEF-1 downto 0);
    status      : out std_logic_vector(31 downto 0)
  );
end dpd_v50;

architecture bh of dpd_v50 is
  constant  HW_TAG        : std_logic_vector(31 downto 0) := RLS_DATE;

  component async_reg_def is
  port (
    clk     : in std_logic;
    regin   : in std_logic;
    regout  : out std_logic
  );
  end component async_reg_def;

  component async_regs_def is
  port (
    clk     : in std_logic;
    regin   : in std_logic_vector;
    regout  : out std_logic_vector
  );
  end component async_regs_def;

  component per_comb is 
  generic (TIMEOUT : integer := 12);
  port (
    clk       : in std_logic;
    rst       : in std_logic;
    
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
  end component;

  component reg_dpd_misc is
  generic (CLK_FREQUENCY : integer := 100000000);
  port (
    clk     : in std_logic;
    rst     : in std_logic;
    
    -- log interrupt
    sw_int_o    : out std_logic_vector(1 downto 0);

    -- tx valid, with mask
    frm_start   : in std_logic;
    txval_i     : in std_logic;
    txval_o     : out std_logic;
    
    -- slot5 related signal
    pa_on       : in std_logic;
    cap_trig    : in std_logic;
    
    cap_trig_o  : out std_logic;

    s5_en       : out std_logic;
    s5_sop      : out std_logic;
    s5_eop      : out std_logic;
    s5_nxt      : out std_logic;

    -- Tags from different parts
    hw_tag      : in std_logic_vector(31 downto 0);
    tag_pd_path : in std_logic_vector(31 downto 0);
    tag_datacap : in std_logic_vector(31 downto 0);
    tag_per     : in std_logic_vector(31 downto 0);

    -- pd_path status
    pd_status   : in std_logic_vector(31 downto 0);
    pd_bkgain   : in std_logic_vector(15 downto 0);
    pa3val      : in std_logic_vector(15 downto 0);

    -- path selection
    tor_sw      : out std_logic_vector(7 downto 0);
    pd_txsel    : out std_logic_vector(7 downto 0);

    -- per bus
    per_addr    : in std_logic_vector(11 downto 0);

    per_wrdata  : in std_logic_vector(31 downto 0);
    per_wren    : in std_logic;

    per_rden    : in std_logic;
    per_rddata  : out std_logic_vector(31 downto 0) := (others=>'0');
    per_rdvalid : out std_logic := '0'
  );
  end component reg_dpd_misc;

  component dpd_signal_path is 
  generic (PATH_NUM : integer := 0; PHASE : integer := 0);
  port (
    -- per_bus, directly to LUT RAM, raw clock
    per_clk     : in std_logic;
    per_rst     : in std_logic;

    per_addr    : in std_logic_vector( 19 downto 0 );
    per_din     : in std_logic_vector( 31 downto 0 );
    per_we      : in std_logic;

    short_per_addr  : in std_logic_vector( 11 downto 0 );
    short_per_din   : in std_logic_vector( 31 downto 0 );
    short_per_we    : in std_logic;

    chnsel          : in std_logic_vector( 7 downto 0 );  -- maximum 256TX
    srcsel          : in std_logic_vector( 7 downto 0 );  -- select which TX for data capture
    
    ----------------------------------------------------------------------------
    -- 491MHz clock
    rst     : in std_logic;
    clk     : in std_logic;
    
    -- input signal
    xi      : in std_logic_vector( 16*PATH_NUM-1 downto 0 );
    xq      : in std_logic_vector( 16*PATH_NUM-1 downto 0 );

    -- output IQ signal
    yi0     : out std_logic_vector(PATH_NUM*16 - 1 downto 0);
    yq0     : out std_logic_vector(PATH_NUM*16 - 1 downto 0);

    yi1     : out std_logic_vector(PATH_NUM*16 - 1 downto 0);
    yq1     : out std_logic_vector(PATH_NUM*16 - 1 downto 0);
    
    -- VCA gain
    vca_gain:  in std_logic_vector(PATH_NUM*16 - 1 downto 0);

    -- special LUT control
    s5_en   : in std_logic;
    s5_sop  : in std_logic;
    s5_eop  : in std_logic;
    s5_nxt  : in std_logic;

    -- signal for dpd_upd
    srci    : out std_logic_vector( 15 downto 0 );
    srcq    : out std_logic_vector( 15 downto 0 );
    
    status  : out std_logic_vector(31 downto 0);
    tag     : out std_logic_vector(31 downto 0)
  );
  end component dpd_signal_path;

  component data_cap_use is 
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
  end component data_cap_use;

  component vca_gain is
  generic (
    STAGE   : integer := 2;
    INIT_VAL: integer := 0;
    ID1     : std_logic_vector(11 downto 0) := (others => '0');
    ID2     : std_logic_vector(11 downto 0) := (others => '0')
  );
  port (
    -- only one burst write clock is allowed
    clk1    : in std_logic;
    rst1    : in std_logic;
    addr1   : in std_logic_vector(11 downto 0);
    din1    : in std_logic_vector(31 downto 0);
    we1     : in std_logic;
    qout1   : out std_logic_vector(15 downto 0);

    clk2    : in std_logic;
    addr2   : in std_logic_vector(11 downto 0);
    din2    : in std_logic_vector(31 downto 0);
    we2     : in std_logic;

    clk     : in std_logic;
    rst     : in std_logic;
    qout    : out std_logic_vector(15 downto 0)
  );
  end component vca_gain;

  component interrupt_reg is
  generic (
    PERIOD  : integer := 6;
    ID      : std_logic_vector(11 downto 0) := (others => '0')
  );
  port (
    -- only one burst write clock is allowed
    clk     : in std_logic;
    rst     : in std_logic;

    addr    : in std_logic_vector(15 downto 0);
    din     : in std_logic_vector(31 downto 0);
    we      : in std_logic;

    oint    : out std_logic
  );
  end component interrupt_reg;

  -- TX valid related
  signal tx_valid_comb      : std_logic;
  signal tx_valid_sync1     : std_logic;
  signal tx_valid_sync2     : std_logic;

  -- capture trigger
  signal cap_trig_s         : std_logic;
  signal cap_trig_sync_s    : std_logic;
  
  -- slot 5 special
  signal s5_en, s5_sop, s5_eop, s5_nxt          : std_logic;
  signal s5pd_en, s5pd_sop, s5pd_eop, s5pd_nxt  : std_logic;

  -- sysgen tags
  signal tag_pd_path_s, tag_per_s, tag_datacap_s: std_logic_vector(31 downto 0);

  -- pd status
  signal mon_pd_status   : std_logic_vector(31 downto 0);
  signal mon_pd_bkgain   : std_logic_vector(15 downto 0);

  signal mon_pd_status_per   : std_logic_vector(31 downto 0);
  signal mon_pd_bkgain_per   : std_logic_vector(15 downto 0);

  -- channel selection
  signal reg_chnsel         : std_logic_vector(7 downto 0);
  signal reg_rx_path        : std_logic_vector(7 downto 0);

  -- peripherals
  signal per_addr_proc    : std_logic_vector(19 downto 0);
  signal per_wrdata_proc  : std_logic_vector(31 downto 0);
  signal per_wren_proc    : std_logic;
  signal per_rden_proc    : std_logic;

  signal per_rddata       : std_logic_vector(31 downto 0);
  signal per_rdvalid      : std_logic;

  signal per_rdvalid_reg : std_logic ;  -- read response from [misc]
  signal per_rddata_reg  : std_logic_vector(31 downto 0) ;

  signal short_addr     : std_logic_vector(11 downto 0);
  signal short_wrdata   : std_logic_vector(31 downto 0);
  signal short_wren     : std_logic;
  signal short_rden     : std_logic;
  
  -- data capture signal
  signal srci, srcq, srci0, srcq0       : std_logic_vector( 15 downto 0 );
  signal asrci, asrcq, bsrci, bsrcq     : std_logic_vector( 15 downto 0 );
  attribute MARK_DEBUG : string;
attribute MARK_DEBUG of asrci: signal is "TRUE";
attribute MARK_DEBUG of asrcq: signal is "TRUE";
attribute MARK_DEBUG of bsrci: signal is "TRUE";
attribute MARK_DEBUG of bsrcq: signal is "TRUE";
				
	
  
  
  signal cap_reg_rdval      : std_logic;
  signal cap_reg_rddata     : std_logic_vector(31 downto 0);
  
  signal cap_mem_rdval      : std_logic;
  signal cap_mem_rddata     : std_logic_vector(31 downto 0);

  -- vca control
  signal vcagain            : std_logic_vector(16*PATH_NUM_DEF - 1 downto 0);
  constant PATH_BITN        : integer := natural(log2(real(PATH_NUM_DEF)));

  type vector_vca  is array (0 to PATH_NUM_DEF-1) of std_logic_vector(15 downto 0);
  signal vcagain_default    : vector_vca;
  signal vcagain_defval     : std_logic_vector(15 downto 0);
  signal pa3_wren           : std_logic_vector(PATH_NUM_DEF-1 downto 0);

  -- GMP terms
  signal rddata_terms_id        : std_logic_vector(31 downto 0);
  signal rddata_terms_sig       : std_logic_vector(31 downto 0);
  signal rddata_terms_adr       : std_logic_vector(31 downto 0);
  signal rddata_terms_sig2      : std_logic_vector(31 downto 0);
  signal rdval_terms_id         : std_logic;
  signal rdval_terms_sig        : std_logic;
  signal rdval_terms_adr        : std_logic;
  signal rdval_terms_sig2        : std_logic;

  signal rddata_terms           : std_logic_vector(31 downto 0);
  signal rdval_terms            : std_logic;
  
  -- interrupt control
  signal sw_int_misc            : std_logic_vector(1 downto 0);
  signal sw_int_misc2aum        : std_logic_vector(1 downto 0);
  signal sw_int_vca_chg         : std_logic;
  signal sw_int_vca_fault       : std_logic;
  
begin
  -- clocks synchronization
 inst_async0 : async_reg_def
  port map (
    clk     => clk491,
    regin   => s5_en,
    regout  => s5pd_en
  );
  
 inst_async1 : async_reg_def
  port map (
    clk     => clk491,
    regin   => s5_sop,
    regout  => s5pd_sop
  );

 inst_async2 : async_reg_def
  port map (
    clk     => clk491,
    regin   => s5_nxt,
    regout  => s5pd_nxt
  );

 inst_async3 : async_reg_def
  port map (
    clk     => clk491,
    regin   => s5_eop,
    regout  => s5pd_eop
  );

  --
  inst_misc : reg_dpd_misc
  generic map (CLK_FREQUENCY => PROC_CLKF)
  port map (
    clk     => per_clk ,
    rst     => per_rst ,
    
    -- log interrupt
    sw_int_o    => sw_int_misc,

    -- tx valid, with mask
    frm_start   => frm_start ,
    txval_i     => tx_valid ,
    txval_o     => tx_valid_comb ,
    
    -- slot5 related signal
    pa_on       => pa_on ,
    cap_trig    => cap_trig ,
    
    cap_trig_o  => cap_trig_s ,

    s5_en       => s5_en ,
    s5_sop      => s5_sop ,
    s5_eop      => s5_eop ,
    s5_nxt      => s5_nxt ,

    -- Tags from different parts
    hw_tag      => HW_TAG ,
    tag_pd_path => tag_pd_path_s ,
    tag_datacap => tag_datacap_s ,
    tag_per     => tag_per_s ,

    -- pd_path status
    pd_status   => mon_pd_status_per ,
    pd_bkgain   => mon_pd_bkgain_per ,
    pa3val      => vcagain_defval ,

    -- path selection
    tor_sw      => reg_rx_path ,
    pd_txsel    => reg_chnsel ,

    -- per bus
    per_addr    => short_addr ,

    per_wrdata  => short_wrdata ,
    per_wren    => short_wren ,

    per_rden    => short_rden ,
    per_rddata  => per_rddata_reg ,
    per_rdvalid => per_rdvalid_reg
  );
  rx_path <= reg_rx_path(7 downto 0);
  bk_gain <= (others => '0');

  -- per bus connection
  process(per_clk)
  begin
    if rising_edge(per_clk) then
      per_addr_proc <= per_addr_i;
      per_wrdata_proc <= per_wrdata_i;
      per_wren_proc <= per_wren_i;
      per_rden_proc <= per_rden_i;
      
      short_addr <= per_addr_i(11 downto 0);
      short_wrdata <= per_wrdata_i;

      if per_addr_i(19 downto 12) = X"00" and per_wren_i = '1' then
        short_wren <= '1';
      else
        short_wren <= '0';
      end if;
      
      if per_addr_i(19 downto 12) = X"00" and per_rden_i = '1' then
        short_rden <= '1';
      else
        short_rden <= '0';
      end if;

    end if;
  end process;
  per_rddata_o <= per_rddata;
  per_rdval_o <= per_rdvalid;

  inst_per_read : per_comb
  generic map(TIMEOUT => 32)
  port map(
    clk       => per_clk,
    rst       => per_rst,
    
    read_en   => per_rden_i,

    valid0    => cap_reg_rdval,
    valid1    => cap_mem_rdval,
    valid2    => per_rdvalid_reg,
    valid3    => rdval_terms,
    valid4    => '0',
    
    data0     => cap_reg_rddata,
    data1     => cap_mem_rddata,
    data2     => per_rddata_reg,
    data3     => rddata_terms,
    data4     => (others => '0'),

    valid     => per_rdvalid,
    data      => per_rddata,
    tocnt     => open
  );
  tag_per_s <= X"00001001";

  -- BRAM address mapping
  
  bram_data_o <= interface_ram_rd;
  
  ------------------------------------------------------------------------------
  -- pd signal path
  inst_pd : dpd_signal_path
  generic map (PATH_NUM => PATH_NUM_DEF, PHASE => PHASE)
  port map(
    -- per_bus, directly to LUT RAM, raw clock
    per_clk     => per_clk,
    per_rst     => per_rst,

    per_addr    => per_addr_i,
    per_din     => per_wrdata_i,
    per_we      => per_wren_i,

    short_per_addr  => short_addr,
    short_per_din   => short_wrdata,
    short_per_we    => short_wren,

    chnsel          => reg_chnsel,
    srcsel          => reg_rx_path,
    ----------------------------------------------------------------------------
    -- 491MHz clock
    rst     => rst491,
    clk     => clk491,
    
    -- input signal
    xi      => xi,
    xq      => xq,

    -- output IQ signal
    yi0     => yi0,
    yq0     => yq0,

    yi1     => yi1,
    yq1     => yq1,
    
    -- VCA gain
    vca_gain=> vcagain,

    -- special LUT control
    s5_en   => s5pd_en,
    s5_sop  => s5pd_sop ,
    s5_eop  => s5pd_eop ,
    s5_nxt  => s5pd_nxt ,

    -- signal for dpd_upd
    srci    => srci,
    srcq    => srcq,
    
    status  => mon_pd_status,
    tag     => open
  );
  
  mon_pd_status_per <= mon_pd_status;

  ------------------------------------------------------------------------------
  -- data capture
  -- tor from 491 => 245x2
  process(clk491)
  begin
    if rising_edge(clk491) then
      srci0 <= srci;
      srcq0 <= srcq;
      
      if en2s = '1' then
        asrci <= srci0;
        asrcq <= srcq0;

        bsrci <= srci;
        bsrcq <= srcq;
      end if;
    end if;
  end process;
  
  inst_cap : data_cap_use
  port map (
    
    -- 245.76MHz clock
    clk245  => clk245,
    rst245  => rst245,
    
    clk491  => clk491,
    rst491  => rst491,
    
    en2s    => en2s,
    
    -- 491MHz
    tori    => rxi,
    torq    => rxq,
    
    -- 245.76MHz
    
    -- source iq of a&b
    ai      => asrci,
    aq      => asrcq,
    bi      => bsrci,
    bq      => bsrcq,

    -- do not care the clocks
    -- capture control signal
    ext_trig    => cap_trig_s,
    tx_valid    => tx_valid_comb,
    
    ----------------------------------------------------------------------------
    -- per_bus
    per_clk     => per_clk,
    per_rst     => per_rst,

    -- short per_bus
    short_per_addr  => short_addr,
    short_per_din   => short_wrdata,
    short_per_wren  => short_wren,
    short_per_rden  => short_rden,
    
    short_per_rdval => cap_reg_rdval,
    short_per_rddata=> cap_reg_rddata,
    
    -- full per_bus
    full_per_addr   => per_addr_i,
    full_per_din    => per_wrdata_i,
    full_per_wren   => per_wren_i,
    full_per_rden   => per_rden_i,

    full_rddata     => cap_mem_rddata,
    full_rdvalid    => cap_mem_rdval,
    
    tag             => tag_datacap_s
  );
  
  -- VCA control gain
  vca : for i in 0 to PATH_NUM_DEF-1 generate
    pa3_wren(i) <= '1' when short_wren = '1' and reg_chnsel = conv_std_logic_vector(i, 8) else '0';

    gain : vca_gain
    generic map(
      STAGE   => 3,
      INIT_VAL=> PA3_VAL,
      ID1     => conv_std_logic_vector( conv_integer(ADDR_VCA) + i , 12 ),
      ID2     => conv_std_logic_vector( conv_integer(ADDR_PA3) + 0 , 12 )
    )
    port map(
      -- only one burst write clock is allowed
      clk1    => aum_clk,
      rst1    => aum_rst,
      addr1   => aum_addr,
      din1    => aum_din,
      we1     => aum_we,
      qout1   => vcagain_default(i),

      clk2    => per_clk,
      addr2   => short_addr,
      din2    => short_wrdata,
      we2     => pa3_wren(i),
    
      clk     => clk491,
      rst     => rst491,
      qout    => vcagain(i*16 + 15 downto i*16+0)
    );
  end generate vca;
  vcagain_defval <= vcagain_default( conv_integer( reg_chnsel(PATH_BITN-1 downto 0) ) );
  
  -- dispersed registers
  -- per bus connection
  process(per_clk)
  begin
    if rising_edge(per_clk) then
      if short_addr = X"157" and short_wren = '1' then
        looped <= short_wrdata(0);
      end if;
      
    end if;
  end process;
  
  -- GMP terms
  process(short_addr, short_rden)
    variable short_addr_base    : std_logic_vector(11 downto 0);
    variable terms_sel          : integer range 0 to 31;
    
  begin
    short_addr_base := short_addr(11 downto 5) & "00000";
    terms_sel := conv_integer( short_addr(4 downto 0) );
    
    if short_rden = '1' and short_addr_base = ADDR_TERMS_ID then
      rddata_terms_id <= conv_std_logic_vector(TERMS_ID(terms_sel), 32);
      rdval_terms_id <= '1';
    else
      rddata_terms_id <= (others => '0');
      rdval_terms_id <= '0';
    end if;
    
    if short_rden = '1' and short_addr_base = ADDR_TERMS_SIG then
      rddata_terms_sig <= conv_std_logic_vector(TERMS_SIG(terms_sel), 32);
      rdval_terms_sig <= '1';
    else
      rddata_terms_sig <= (others => '0');
      rdval_terms_sig <= '0';
    end if;

    if short_rden = '1' and short_addr_base = ADDR_TERMS_ADR then
      rddata_terms_adr <= conv_std_logic_vector(TERMS_ADR(terms_sel), 32);
      rdval_terms_adr <= '1';
    else
      rddata_terms_adr <= (others => '0');
      rdval_terms_adr <= '0';
    end if;
    
    if short_rden = '1' and short_addr_base = ADDR_TERMS_SIG2 then
      rddata_terms_sig2 <= conv_std_logic_vector(TERMS_SIG2(terms_sel), 32);
      rdval_terms_sig2 <= '1';
    else
      rddata_terms_sig2 <= (others => '0');
      rdval_terms_sig2 <= '0';
    end if;
    
        
  end process;

  rddata_terms <= rddata_terms_id or rddata_terms_sig or rddata_terms_adr or rddata_terms_sig2;
  rdval_terms <= rdval_terms_id or rdval_terms_sig or rdval_terms_adr or rdval_terms_sig2;
  
  -- interrupt registers
  int0 : interrupt_reg
  generic map(
    PERIOD  => 10,
    ID      => IFRAM_ANT_CHG_INT
  )
  port map(
    -- only one burst write clock is allowed
    clk     => bram_clk,
    rst     => bram_rst,

    addr    => bram_addr_i,
    din     => bram_data_i,
    we      => bram_wren_i,

    oint    => sw_int_vca_chg
  );

  int1 : interrupt_reg
  generic map(
    PERIOD  => 10,
    ID      => IFRAM_FAULT_INT
  )
  port map(
    -- only one burst write clock is allowed
    clk     => bram_clk,
    rst     => bram_rst,

    addr    => bram_addr_i,
    din     => bram_data_i,
    we      => bram_wren_i,

    oint    => sw_int_vca_fault
  );

  int_sync : async_regs_def
  port map(
    clk     => aum_clk,
    regin   => sw_int_misc,
    regout  => sw_int_misc2aum
  );

  sw_int_o(1 downto 0) <= sw_int_misc2aum;
  sw_int_o(2) <= sw_int_vca_chg;
  sw_int_o(3) <= sw_int_vca_fault;
  
  
end bh;