library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity uram32k_wrapper is
  port (
    clk    : in std_logic := '0';
    ce     : in std_logic := '0';

    wea        : in    std_logic;
    addra      : in    std_logic_vector(14 downto 0);
    dina       : in    std_logic_vector(63 downto 0);

    addrb      : in    std_logic_vector(14 downto 0);
    doutb      : out   std_logic_vector(63 downto 0)
  );
end entity uram32k_wrapper;

architecture bh of uram32k_wrapper is

  component tap_uram_64bx32768 is
  port ( 
    clk        : in    std_logic;
    ena        : in    std_logic;
    wea        : in    std_logic_vector(0 downto 0);
    addra      : in    std_logic_vector(14 downto 0);
    dina       : in    std_logic_vector(63 downto 0);
    douta      : out   std_logic_vector(63 downto 0);
    enb        : in    std_logic;
    web        : in    std_logic_vector(0 downto 0);
    bweb       : in    std_logic_vector(7 downto 0);
    addrb      : in    std_logic_vector(14 downto 0);
    dinb       : in    std_logic_vector(63 downto 0);
    doutb      : out   std_logic_vector(63 downto 0);
    sleep_en   : in    std_logic
  );
  end component tap_uram_64bx32768;


begin

  inst : tap_uram_64bx32768
  port map ( 
    clk        => clk ,
    ena        => '1' ,
    wea(0)     => wea ,
    addra      => addra ,
    dina       => dina ,
    douta      => open ,

    enb        => '1' ,
    web        => "0" ,
    bweb       => (others => '0') ,
    addrb      => addrb ,
    dinb       => (others => '0') ,
    doutb      => doutb ,
    sleep_en   => '0'
  );


end bh;
