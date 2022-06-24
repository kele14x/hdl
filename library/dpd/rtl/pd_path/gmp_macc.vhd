--------------------------------------------------------------------------------
-- GMP blocks MACC
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.pd_path_def.all;

entity gmp_macc_first is
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
end gmp_macc_first;

architecture bh of gmp_macc_first is
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
  
  -- DSP signals
  signal imacc_b0, imacc_b1 : std_logic_vector(17 downto 0);
  signal imacc_a0, imacc_a1 : std_logic_vector(24 downto 0);
  signal imacc_d0, imacc_d1 : std_logic_vector(24 downto 0);
  signal imacc_c            : std_logic_vector(47 downto 0);
  signal imacc_pcas         : std_logic_vector(47 downto 0);
  signal imacc_res          : std_logic_vector(47 downto 0);

  signal qmacc_b0, qmacc_b1 : std_logic_vector(17 downto 0);
  signal qmacc_a0, qmacc_a1 : std_logic_vector(24 downto 0);
  signal qmacc_d0, qmacc_d1 : std_logic_vector(24 downto 0);
  signal qmacc_c            : std_logic_vector(47 downto 0);
  signal qmacc_pcas         : std_logic_vector(47 downto 0);
  signal qmacc_res          : std_logic_vector(47 downto 0);

begin
  -- (xi + j*xq) * (ci + j*cq)
  
  -- xi*ci - xq*cq
  imacc_b0(15 downto  0) <= xi;
  imacc_b0(17 downto 16) <= (others => xi(15));
  
  imacc_b1(15 downto  0) <= xq;
  imacc_b1(17 downto 16) <= (others => xq(15));
  
  imacc_a0(17 downto  0) <= ci;
  imacc_a0(24 downto 18) <= (others => ci(17));
  
  imacc_a1(17 downto  0) <= cq;
  imacc_a1(24 downto 18) <= (others => cq(17));
  
  yi_cas <= imacc_res;
  imacc_c <= X"000000002000";

  inst_dsp0 : xilinx_dsp_compact
  generic map(
    AREG        => 1,
    BREG        => 1,
    TYPES       => 1
  )
  port map(
    clk     => clk,

    -- basic port
    b       => imacc_b0,
    a       => imacc_a0,

    c       => imacc_c,

    -- cascaded port, optional
    pcout   => imacc_pcas
  );

  inst_dsp1 : xilinx_dsp_compact
  generic map(
    AREG        => 2,
    BREG        => 2,
    TYPES       => 3
  )
  port map(
    clk     => clk,

    -- basic port
    b       => imacc_b1,
    a       => imacc_a1,
    pcin    => imacc_pcas,

    -- cascaded port, optional
    pcout   => imacc_res
  );

  -- xi*cq + xq*ci
  qmacc_b0(15 downto  0) <= xi;
  qmacc_b0(17 downto 16) <= (others => xi(15));
  
  qmacc_b1(15 downto  0) <= xq;
  qmacc_b1(17 downto 16) <= (others => xq(15));
  
  qmacc_a0(17 downto  0) <= cq;
  qmacc_a0(24 downto 18) <= (others => cq(17));
  
  qmacc_a1(17 downto  0) <= ci;
  qmacc_a1(24 downto 18) <= (others => ci(17));
  
  yq_cas <= qmacc_res;
  qmacc_c <= X"000000002000";

  inst_dsp2 : xilinx_dsp_compact
  generic map(
    AREG        => 1,
    BREG        => 1,
    TYPES       => 1
  )
  port map(
    clk     => clk,

    -- basic port
    b       => qmacc_b0,
    a       => qmacc_a0,
    c       => qmacc_c,

    -- cascaded port, optional
    pcout   => qmacc_pcas
  );

  inst_dsp3 : xilinx_dsp_compact
  generic map(
    AREG        => 2,
    BREG        => 2,
    TYPES       => 2
  )
  port map(
    clk     => clk,

    -- basic port
    b       => qmacc_b1,
    a       => qmacc_a1,

    pcin    => qmacc_pcas,

    -- cascaded port, optional
    pcout   => qmacc_res
  );

end bh;

--------------------------------------------------------------------------------
-- GMP blocks MACC
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.pd_path_def.all;

entity gmp_macc_mid is
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
end gmp_macc_mid;

architecture bh of gmp_macc_mid is
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
  
  -- DSP signals
  signal imacc_b0, imacc_b1 : std_logic_vector(17 downto 0);
  signal imacc_a0, imacc_a1 : std_logic_vector(24 downto 0);
  signal imacc_d0, imacc_d1 : std_logic_vector(24 downto 0);
  signal imacc_pcas         : std_logic_vector(47 downto 0);

  signal qmacc_b0, qmacc_b1 : std_logic_vector(17 downto 0);
  signal qmacc_a0, qmacc_a1 : std_logic_vector(24 downto 0);
  signal qmacc_d0, qmacc_d1 : std_logic_vector(24 downto 0);
  signal qmacc_pcas         : std_logic_vector(47 downto 0);

begin
  -- (xi + j*xq) * (ci + j*cq)
  
  -- xi*ci - xq*cq
  imacc_b0(15 downto  0) <= xi;
  imacc_b0(17 downto 16) <= (others => xi(15));
  
  imacc_b1(15 downto  0) <= xq;
  imacc_b1(17 downto 16) <= (others => xq(15));
  
  imacc_a0(17 downto  0) <= ci;
  imacc_a0(24 downto 18) <= (others => ci(17));
  
  imacc_a1(17 downto  0) <= cq;
  imacc_a1(24 downto 18) <= (others => cq(17));
  
  inst_dsp0 : xilinx_dsp_compact
  generic map(
    AREG        => 1,
    BREG        => 1,
    TYPES       => 2
  )
  port map(
    clk     => clk,

    -- basic port
    b       => imacc_b0,
    a       => imacc_a0,
    pcin    => icas_in,

    -- cascaded port, optional
    pcout   => imacc_pcas
  );

  inst_dsp1 : xilinx_dsp_compact
  generic map(
    AREG        => 2,
    BREG        => 2,
    TYPES       => 3
  )
  port map(
    clk     => clk,

    -- basic port
    b       => imacc_b1,
    a       => imacc_a1,
    pcin    => imacc_pcas,

    -- cascaded port, optional
    pcout   => icas_out
  );

  -- xi*cq + xq*ci
  qmacc_b0(15 downto  0) <= xi;
  qmacc_b0(17 downto 16) <= (others => xi(15));
  
  qmacc_b1(15 downto  0) <= xq;
  qmacc_b1(17 downto 16) <= (others => xq(15));
  
  qmacc_a0(17 downto  0) <= cq;
  qmacc_a0(24 downto 18) <= (others => cq(17));
  
  qmacc_a1(17 downto  0) <= ci;
  qmacc_a1(24 downto 18) <= (others => ci(17));
  
  inst_dsp2 : xilinx_dsp_compact
  generic map(
    AREG        => 1,
    BREG        => 1,
    TYPES       => 2
  )
  port map(
    clk     => clk,

    -- basic port
    b       => qmacc_b0,
    a       => qmacc_a0,
    pcin    => qcas_in,

    -- cascaded port, optional
    pcout   => qmacc_pcas
  );

  inst_dsp3 : xilinx_dsp_compact
  generic map(
    AREG        => 2,
    BREG        => 2,
    TYPES       => 2
  )
  port map(
    clk     => clk,

    -- basic port
    b       => qmacc_b1,
    a       => qmacc_a1,
    pcin    => qmacc_pcas,

    -- cascaded port, optional
    pcout   => qcas_out
  );

end bh;


--------------------------------------------------------------------------------
-- GMP blocks MACC
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.pd_path_def.all;

entity gmp_macc_last is
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
end gmp_macc_last;

architecture bh of gmp_macc_last is
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
  
  -- DSP signals
  signal imacc_b0, imacc_b1 : std_logic_vector(17 downto 0);
  signal imacc_a0, imacc_a1 : std_logic_vector(24 downto 0);
  signal imacc_pcas         : std_logic_vector(47 downto 0);

  signal qmacc_b0, qmacc_b1 : std_logic_vector(17 downto 0);
  signal qmacc_a0, qmacc_a1 : std_logic_vector(24 downto 0);
  signal qmacc_pcas         : std_logic_vector(47 downto 0);

begin
  -- (xi + j*xq) * (ci + j*cq)
  
  -- xi*ci - xq*cq
  imacc_b0(15 downto  0) <= xi;
  imacc_b0(17 downto 16) <= (others => xi(15));
  
  imacc_b1(15 downto  0) <= xq;
  imacc_b1(17 downto 16) <= (others => xq(15));
  
  imacc_a0(17 downto  0) <= ci;
  imacc_a0(24 downto 18) <= (others => ci(17));
  
  imacc_a1(17 downto  0) <= cq;
  imacc_a1(24 downto 18) <= (others => cq(17));
  
  inst_dsp0 : xilinx_dsp_compact
  generic map(
    AREG        => 1,
    BREG        => 1,
    TYPES       => 2
  )
  port map(
    clk     => clk,

    -- basic port
    b       => imacc_b0,
    a       => imacc_a0,
    pcin    => icas_in,

    -- cascaded port, optional
    pcout   => imacc_pcas
  );

  inst_dsp1 : xilinx_dsp_compact
  generic map(
    AREG        => 2,
    BREG        => 2,
    TYPES       => 3
  )
  port map(
    clk     => clk,

    -- basic port
    b       => imacc_b1,
    a       => imacc_a1,
    pcin    => imacc_pcas,

    -- cascaded port, optional
    p       => iout
  );

  -- xi*cq + xq*ci
  qmacc_b0(15 downto  0) <= xi;
  qmacc_b0(17 downto 16) <= (others => xi(15));
  
  qmacc_b1(15 downto  0) <= xq;
  qmacc_b1(17 downto 16) <= (others => xq(15));
  
  qmacc_a0(17 downto  0) <= cq;
  qmacc_a0(24 downto 18) <= (others => cq(17));
  
  qmacc_a1(17 downto  0) <= ci;
  qmacc_a1(24 downto 18) <= (others => ci(17));

  inst_dsp2 : xilinx_dsp_compact
  generic map(
    AREG        => 1,
    BREG        => 1,
    TYPES       => 2
  )
  port map(
    clk     => clk,

    -- basic port
    b       => qmacc_b0,
    a       => qmacc_a0,
    pcin    => qcas_in,

    -- cascaded port, optional
    pcout   => qmacc_pcas
  );

  inst_dsp3 : xilinx_dsp_compact
  generic map(
    AREG        => 2,
    BREG        => 2,
    TYPES       => 2
  )
  port map(
    clk     => clk,

    -- basic port
    b       => qmacc_b1,
    a       => qmacc_a1,
    pcin    => qmacc_pcas,

    -- cascaded port, optional
    p       => qout
  );

end bh;
