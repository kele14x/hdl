----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: Mar. 12, 2018
-- Design Name: 
-- Module Name: pd_path_v50.vhd
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--  
-- 
-- function:
-- 10 clocks delay
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.arch.all;
use work.pd_path_def.all;

entity gmp_model is
  port (
    -- clock
    clk         : in std_logic := '0';

    -- per_bus, LUT access
    per_clk     : in std_logic;
    per_addr    : in std_logic_vector(19 downto 0);
    per_wrdata  : in std_logic_vector(31 downto 0);
    per_wren    : in std_logic;

    per_rden    : in std_logic;
    per_rdval   : out std_logic;
    per_rddata  : out std_logic_vector(31 downto 0);

    -- signal input
    xi0     : in std_logic_vector(15 downto 0);
    xq0     : in std_logic_vector(15 downto 0);
    addr0   : in std_logic_vector(9 downto 0);

    xi1     : in std_logic_vector(15 downto 0);
    xq1     : in std_logic_vector(15 downto 0);
    addr1   : in std_logic_vector(9 downto 0);
    
    ramsel  : in std_logic;
    tddsel  : in std_logic_vector(2 downto 0);
    tapsel  : in std_logic_vector(31 downto 0);

    -- signal output
    si      : out std_logic_vector(15 downto 0);
    sq      : out std_logic_vector(15 downto 0);

    di      : out std_logic_vector(17 downto 0);
    dq      : out std_logic_vector(17 downto 0)
  );
end gmp_model;

architecture bh of gmp_model is

  component xilinx_dsp_compact is
  generic (
    AREG        : integer := 1;     -- 1 or 2
    BREG        : integer := 1;     -- 1 or 2
    
    RND         : std_logic_vector := X"000000000000";  -- 48bit, default zero
    TYPES       : integer := 1      -- used types
  );
  port (
    clk     : in std_logic := '0';
    rstp    : in std_logic := '0';

    -- basic port
    b       : in  std_logic_vector(17 downto 0) := (others => '0');
    a       : in  std_logic_vector(24 downto 0) := (others => '0');
    d       : in  std_logic_vector(24 downto 0) := (others => '0');

    c       : in  std_logic_vector(47 downto 0) := (others => '0');
    p       : out std_logic_vector(47 downto 0);

    -- cascaded port, optional
    pcin    : in  std_logic_vector(47 downto 0) := (others => '0');
    pcout   : out std_logic_vector(47 downto 0)
  );
  end component xilinx_dsp_compact;

  component lut_ram is
  generic ( LUT_ID : integer := 0 );
  port (
    -- signal
    clk     : in std_logic := '0';

    addr    : in std_logic_vector(9 downto 0);
    ci      : out std_logic_vector(17 downto 0);
    cq      : out std_logic_vector(17 downto 0);

    ramsel  : in std_logic;     -- 0&1, select active RAM

    -- per_bus
    per_clk     : in std_logic;
    per_addr    : in std_logic_vector(19 downto 0);
    per_din     : in std_logic_vector(31 downto 0);
    per_we      : in std_logic
  );
  end component lut_ram;

  component gmp_macc_first is
  port (
    -- signal
    clk     : in std_logic := '0';
    
    xi      : in std_logic_vector(15 downto 0);
    xq      : in std_logic_vector(15 downto 0);
    
    ci      : in std_logic_vector(17 downto 0);
    cq      : in std_logic_vector(17 downto 0);
    
    yi_cas  : out std_logic_vector(47 downto 0);
    yq_cas  : out std_logic_vector(47 downto 0)
  );
  end component gmp_macc_first;

  component gmp_macc_mid is
  port (
    -- signal
    clk     : in std_logic := '0';
    
    xi      : in std_logic_vector(15 downto 0);
    xq      : in std_logic_vector(15 downto 0);
    
    ci      : in std_logic_vector(17 downto 0);
    cq      : in std_logic_vector(17 downto 0);
    
    icas_in : in std_logic_vector(47 downto 0);
    qcas_in : in std_logic_vector(47 downto 0);
    
    icas_out: out std_logic_vector(47 downto 0);
    qcas_out: out std_logic_vector(47 downto 0)
  );
  end component gmp_macc_mid;

  component gmp_macc_last is
  port (
    -- signal
    clk     : in std_logic := '0';

    xi      : in std_logic_vector(15 downto 0);
    xq      : in std_logic_vector(15 downto 0);

    ci      : in std_logic_vector(17 downto 0);
    cq      : in std_logic_vector(17 downto 0);

    icas_in : in std_logic_vector(47 downto 0);
    qcas_in : in std_logic_vector(47 downto 0);

    iout    : out std_logic_vector(47 downto 0);
    qout    : out std_logic_vector(47 downto 0)
  );
  end component gmp_macc_last;

  -- signal delay taps
  signal xi_pipes   : vector_16b_t(GMP_PIPES-1 downto 0);
  signal xq_pipes   : vector_16b_t(GMP_PIPES-1 downto 0);  
  signal addr_pipes : vector_10b_t(GMP_PIPES-1 downto 0);

  -- GMP crossing
  signal xi_gmp     : vector_16b_t(GMP_UTAPS-1 downto 0);
  signal xq_gmp     : vector_16b_t(GMP_UTAPS-1 downto 0);
  signal addr_cross : vector_10b_t(GMP_UTAPS*GMP_UTAPS - 1 downto 0);

  -- LUT & RAMs
  signal luts_di, luts_dq           : vector_18b_t(GMP_UTAPS*GMP_UTAPS - 1 downto 0) := (others => (others => '0'));

  -- pre-adder chain
  signal ichain, qchain             : vector_18b_t(GMP_UTAPS*GMP_UTAPS - 1 downto 0) := (others => (others => '0'));

  -- MACC cascaded
  signal imacc, qmacc               : vector_48b_t(GMP_UTAPS-1 downto 0);

  -- special LUTs, {TDD_ON}, {GaN Trapping}
  signal splut_di, splut_dq         : std_logic_vector(17 downto 0) := (others => '0');
  
  signal tddlut_di, tddlut_dq       : std_logic_vector(17 downto 0) := (others => '0');
  signal dynlut_di, dynlut_dq       : std_logic_vector(17 downto 0) := (others => '0');

  signal tddluts_di         : vector_18b_t(2 downto 0);
  signal tddluts_dq         : vector_18b_t(2 downto 0);  -- each ram output
  signal tddsel2            : std_logic_vector(2 downto 0);
  signal tddaddr            : std_logic_vector(9 downto 0);
  
begin

  -- input delay taps
  process(clk)
  begin
    if rising_edge(clk) then
      xi_pipes(0) <= xi1;
      xi_pipes(1) <= xi0;
      
      xq_pipes(0) <= xq1;
      xq_pipes(1) <= xq0;

      xi_pipes(GMP_PIPES-1 downto 2) <= xi_pipes(GMP_PIPES-3 downto 0);
      xq_pipes(GMP_PIPES-1 downto 2) <= xq_pipes(GMP_PIPES-3 downto 0);

      addr_pipes(0) <= addr1;
      addr_pipes(1) <= addr0;

      addr_pipes(GMP_PIPES-1 downto 2) <= addr_pipes(GMP_PIPES-3 downto 0);
    end if;
  end process;

  -- GMP crosing
  icross : for i in 0 to GMP_UTAPS-1 generate
    ifx : if DELAYS_SIG(i) = DELAYS_SIG2(i) generate
      xi_gmp(i) <= xi_pipes(DELAYS_SIG(i));
      xq_gmp(i) <= xq_pipes(DELAYS_SIG(i));
    end generate;

    ifn : if DELAYS_SIG(i) /= DELAYS_SIG2(i) generate
      process(clk)
      begin
        if rising_edge(clk) then
          if tapsel(i) = '0' then
            xi_gmp(i) <= xi_pipes(DELAYS_SIG(i)-2);
            xq_gmp(i) <= xq_pipes(DELAYS_SIG(i)-2);
          else
            xi_gmp(i) <= xi_pipes(DELAYS_SIG2(i)-2);
            xq_gmp(i) <= xq_pipes(DELAYS_SIG2(i)-2);
          end if;
        end if;
      end process;
    end generate;

    jcross : for j in 0 to GMP_UTAPS-1 generate
      ifx : if DELAYS_ADR(i)(j) = DELAYS_ADR2(i)(j) generate
        addr_cross(i*GMP_UTAPS+j) <= addr_pipes(DELAYS_ADR(i)(j));
      end generate;
      
      ifn : if DELAYS_ADR(i)(j) /= DELAYS_ADR2(i)(j) generate
        process(clk)
        begin
          if rising_edge(clk) then
            if tapsel(j) = '0' then
              addr_cross(i*GMP_UTAPS+j) <= addr_pipes(DELAYS_ADR(i)(j)-2);
            else
              addr_cross(i*GMP_UTAPS+j) <= addr_pipes(DELAYS_ADR2(i)(j)-2);
            end if;
          end if;
        end process;        
      end generate;
      
    end generate;
  end generate;

  -- ALL GMP LUTs
  all_iluts : for i in 0 to GMP_UTAPS-1 generate
    all_jluts : for j in 0 to GMP_UTAPS-1 generate
    
    ifx : if GMP_DEF(i)(j)=1 generate
    inst_ram : lut_ram
    generic map ( LUT_ID => LUTS_ID(i)(j) )    
    port map (
      -- signal
      clk     => clk,

      addr    => addr_cross(i*GMP_UTAPS+j),
      ci      => luts_di(i*GMP_UTAPS+j),
      cq      => luts_dq(i*GMP_UTAPS+j),
      
      ramsel  => ramsel,

      -- per_bus
      per_clk     => per_clk,
      per_addr    => per_addr,
      per_din     => per_wrdata,
      per_we      => per_wren
    );
    end generate;
    
    end generate;
  end generate;

  -- LUT & adder chain generation
  all_taps : for i in 0 to GMP_UTAPS-1 generate
  
    -- if main tap, add the PA_ON special LUT here
    lut_sp : if i = MAIN_TAP generate
      process(clk)
      begin
        if rising_edge(clk) then
          ichain(i*GMP_UTAPS + FIRST_LUT(i)) <= luts_di(i*GMP_UTAPS + FIRST_LUT(i)) + splut_di;
          qchain(i*GMP_UTAPS + FIRST_LUT(i)) <= luts_dq(i*GMP_UTAPS + FIRST_LUT(i)) + splut_dq;
        end if;
      end process;
    end generate;

    -- first LUT, normal
    lut_nm : if i /= MAIN_TAP generate
      process(clk)
      begin
        if rising_edge(clk) then
          ichain(i*GMP_UTAPS + FIRST_LUT(i)) <= luts_di(i*GMP_UTAPS + FIRST_LUT(i));
          qchain(i*GMP_UTAPS + FIRST_LUT(i)) <= luts_dq(i*GMP_UTAPS + FIRST_LUT(i));
        end if;
      end process;
    end generate;

    -- adder
    chains : for j in FIRST_LUT(i)+1 to GMP_UTAPS-1 generate
      tap0 : if GMP_DEF(i)(j)=0 generate
        ichain(i*GMP_UTAPS + j) <= ichain(i*GMP_UTAPS + j-1);
        qchain(i*GMP_UTAPS + j) <= qchain(i*GMP_UTAPS + j-1);
      end generate;

      tap1 : if GMP_DEF(i)(j)=1 generate
        process(clk)
        begin
          if rising_edge(clk) then
            ichain(i*GMP_UTAPS + j) <= ichain(i*GMP_UTAPS + j-1) + luts_di(i*GMP_UTAPS + j);
            qchain(i*GMP_UTAPS + j) <= qchain(i*GMP_UTAPS + j-1) + luts_dq(i*GMP_UTAPS + j);
          end if;
        end process;
      end generate;
    end generate;
    
  end generate;
  
  -- GMP MACC, cascaded DSPs
  macc0 : gmp_macc_first
  port map(
    -- signal
    clk     => clk,
    
    xi      => xi_gmp(FIRST_MACC),
    xq      => xq_gmp(FIRST_MACC),

    ci      => ichain(FIRST_MACC*GMP_UTAPS + GMP_UTAPS-1),
    cq      => qchain(FIRST_MACC*GMP_UTAPS + GMP_UTAPS-1),

    yi_cas  => imacc(FIRST_MACC),
    yq_cas  => qmacc(FIRST_MACC)
  );

  mid_macc : for i in FIRST_MACC+1 to LAST_MACC-1 generate
    macc : if MACC_DEF(i) = 1 generate
    midmaccs : gmp_macc_mid
    port map (
      -- signal
      clk     => clk,
      
      xi      => xi_gmp(i),
      xq      => xq_gmp(i),
      
      ci      => ichain(i*GMP_UTAPS + GMP_UTAPS-1),
      cq      => qchain(i*GMP_UTAPS + GMP_UTAPS-1),
      
      icas_in => imacc(i-1),
      qcas_in => qmacc(i-1),
      
      icas_out=> imacc(i),
      qcas_out=> qmacc(i)
    );
    end generate;
    
    mcas : if MACC_DEF(i) = 0 generate
      imacc(i) <= imacc(i-1);
      qmacc(i) <= qmacc(i-1);
    end generate;
    
  end generate;

  macc2 : gmp_macc_last
  port map(
    -- signal
    clk     => clk,

    xi      => xi_gmp(LAST_MACC),
    xq      => xq_gmp(LAST_MACC),

    ci      => ichain(LAST_MACC*GMP_UTAPS + GMP_UTAPS-1),
    cq      => qchain(LAST_MACC*GMP_UTAPS + GMP_UTAPS-1),

    icas_in => imacc(LAST_MACC-1),
    qcas_in => qmacc(LAST_MACC-1),

    iout    => imacc(LAST_MACC),
    qout    => qmacc(LAST_MACC)
  );

  process(clk)
  begin
    if rising_edge(clk) then
      di <= imacc(LAST_MACC)(FBIT_LUT+17 downto FBIT_LUT);
      dq <= qmacc(LAST_MACC)(FBIT_LUT+17 downto FBIT_LUT);
    end if;
  end process;
  
  si <= xi_pipes(GMP_SIGDELAY);
  sq <= xq_pipes(GMP_SIGDELAY);

  ------------------------------------------------------------------------------
  -- special luts
  tddaddr <= addr_pipes(TDD_ADRDELAY);
  
  process(clk)
  begin
    if rising_edge(clk) then
      tddsel2 <= tddsel;
      case tddsel2 is
        when "000" =>
          tddlut_di <= tddluts_di(0);
          tddlut_dq <= tddluts_dq(0);
        when "001" =>
          tddlut_di <= tddluts_di(1);
          tddlut_dq <= tddluts_dq(1);
        when "010" =>
          tddlut_di <= tddluts_di(2);
          tddlut_dq <= tddluts_dq(2);
        when others =>
          tddlut_di <= (others => '0');
          tddlut_dq <= (others => '0');
      end case;

      splut_di <= tddlut_di + dynlut_di;
      splut_dq <= tddlut_dq + dynlut_dq;
    end if;
  end process;

  -- generate each ram, TDD [off]->[on]
  tdd_rams : for i in 0 to 2 generate
    ifx : if i < SPLUTS_NUM generate
      inst_ram : lut_ram
      generic map ( LUT_ID => SPLUTS_ID(i) )    
      port map (
        -- signal
        clk     => clk,

        addr    => tddaddr,
        ci      => tddluts_di(i),
        cq      => tddluts_dq(i),

        ramsel  => ramsel,
        
        -- per_bus
        per_clk     => per_clk,
        per_addr    => per_addr,
        per_din     => per_wrdata,
        per_we      => per_wren
      );
    end generate;
    
    ifn : if i >= SPLUTS_NUM generate
      tddluts_di(i) <= (others => '0');
      tddluts_dq(i) <= (others => '0');
    end generate;
  end generate;

end bh;