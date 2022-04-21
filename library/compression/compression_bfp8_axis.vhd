library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity compression_bfp8_axis is
  port (
    aclk    : in std_logic;
    aresetn : in std_logic;
    -- Data input
    comp_mantissa : in std_logic_vector(31 downto 0);
    comp_exp      : in std_logic_vector(3 downto 0);
    comp_valid    : in std_logic;
    comp_last     : in std_logic;
    comp_cnt      : in unsigned(5 downto 0);
    -- Data output
    m_axis_tdata  : out std_logic_vector(63 downto 0);
    m_axis_tkeep  : out std_logic_vector(7 downto 0);
    m_axis_tlast  : out std_logic;
    m_axis_tready : in std_logic;
    m_axis_tvalid : out std_logic
  );
end compression_bfp8_axis;

architecture rtl of compression_bfp8_axis is

  -- Signals

  signal comp_mantissa_r : std_logic_vector(31 downto 0);
  signal comp_exp_r      : std_logic_vector(3 downto 0);
  signal comp_valid_r    : std_logic;
  signal comp_cnt_r      : unsigned(5 downto 0);
  signal comp_last_r     : std_logic;

  signal comp_extra_last   : std_logic;
  signal comp_noextra_last : std_logic;

  signal comp_mantissa_d  : std_logic_vector(31 downto 0);

  signal comp_tdata : std_logic_vector(63 downto 0);


  -- Functions

  -- This function performs byte reverse on the input vector, as required by
  -- AXIS standard
  function byte_reverse (
    vector_in    : in std_logic_vector(63 downto 0)
  ) return std_logic_vector is
    variable ret : std_logic_vector(63 downto 0) := (others => '0');
  begin
    for i in 0 to 7 loop
      ret(63-i*8 downto 56-i*8) := vector_in(7+i*8 downto i*8);
    end loop;
    return ret;
  end function byte_reverse;

  -- This function cacluates number of bits until current state counter
  function total_bits (
    cnt : in unsigned(5 downto 0)
  ) return integer is
    variable ret : integer := 0;
  begin
    ret := to_integer(cnt);
    ret := (ret / 6) * 8 + ret * 32 + 40;
    return ret;
  end function total_bits;

  -- This function cacluates number of words until current state counter
  function total_words (
    cnt : in unsigned(5 downto 0)
  ) return integer is
    variable ret : integer := 0;
  begin
    ret := total_bits(cnt) / 64;
    return ret;
  end function total_words;

  -- This function check if at current state counter, we have a valid word
  -- output
  function valid_word (
    cnt : in unsigned(5 downto 0)
  ) return std_logic is
    variable lut : std_logic_vector(63 downto 0) := (others => '0');
    variable ret : std_logic := '0';
  begin
    for i in 1 to 47 loop
      if (total_words(to_unsigned(i, 6)) > total_words(to_unsigned(i - 1, 6))) then
        lut(i) := '1';
      end if;
    end loop;
    ret := lut(to_integer(cnt));
    return ret;
  end function valid_word;

begin

  -- At some state, delay TLAST

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (comp_valid = '1' and comp_last = '1' and comp_cnt < 47) then
        comp_extra_last  <= '1';
      else
        comp_extra_last  <= '0';
      end if;
    end if;
  end process;

  comp_noextra_last <= '1' when (comp_valid = '1' and comp_last = '1' and comp_cnt = 47) else '0';


  -- Input register

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (comp_valid = '1' or comp_extra_last = '1') then
        comp_mantissa_r  <= comp_mantissa;
        comp_mantissa_d  <= comp_mantissa_r;
      end if;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (comp_valid = '1') then
        comp_exp_r <= comp_exp;
      end if;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      comp_valid_r <= comp_valid or comp_extra_last;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (comp_valid = '1') then
        comp_cnt_r <= comp_cnt;
      elsif (comp_extra_last = '1') then
        comp_cnt_r <= comp_cnt_r + 1;
      end if;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      comp_last_r <= comp_noextra_last or comp_extra_last;
    end if;
  end process;


  -- Output AXIS

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (comp_cnt_r = 0) then
        comp_tdata(63 downto 24) <= x"0" & comp_exp_r & comp_mantissa_r;
      elsif (comp_cnt_r = 1 or comp_cnt_r = 3 or comp_cnt_r = 5) then
        comp_tdata(23 downto  0) <= comp_mantissa_r(31 downto 8);
      elsif (comp_cnt_r = 2 or comp_cnt_r = 4) then
        comp_tdata(63 downto 24) <= comp_mantissa_d(7 downto 0) & comp_mantissa_r(31 downto 0);
      elsif (comp_cnt_r = 6) then
        comp_tdata(63 downto 16) <= comp_mantissa_d(7 downto 0) & x"0" & comp_exp_r & comp_mantissa_r;
      elsif (comp_cnt_r = 7 or comp_cnt_r = 9 or comp_cnt_r = 11) then
        comp_tdata(15 downto 0) <= comp_mantissa_r(31 downto 16);
      elsif (comp_cnt_r = 8 or comp_cnt_r = 10) then
        comp_tdata(63 downto 16) <= comp_mantissa_d(15 downto 0) & comp_mantissa_r;
      elsif (comp_cnt_r = 12) then
        comp_tdata(63 downto 8) <= comp_mantissa_d(15 downto 0) & x"0" & comp_exp_r & comp_mantissa_r;
      elsif (comp_cnt_r = 13 or comp_cnt_r = 15 or comp_cnt_r = 17) then
        comp_tdata(7 downto 0) <= comp_mantissa_r(31 downto 24);
      elsif (comp_cnt_r = 14 or comp_cnt_r = 16) then
        comp_tdata(63 downto 8) <= comp_mantissa_d(23 downto 0) & comp_mantissa_r;
      elsif (comp_cnt_r = 18) then
        comp_tdata(63 downto 0) <= comp_mantissa_d(23 downto 0) & x"0" & comp_exp_r & comp_mantissa_r;
      elsif (comp_cnt_r = 19 or comp_cnt_r = 21 or comp_cnt_r = 23) then
        comp_tdata(63 downto 32) <= comp_mantissa_r;
      elsif (comp_cnt_r = 20 or comp_cnt_r = 22) then
        comp_tdata(31 downto 0) <= comp_mantissa_r;
      elsif (comp_cnt_r = 24) then
        comp_tdata(31 downto 0) <= x"0" & comp_exp_r & comp_mantissa_r(31 downto 8);
      elsif (comp_cnt_r = 25 or comp_cnt_r = 27 or comp_cnt_r = 29) then
        comp_tdata(63 downto 24) <= comp_mantissa_d(7 downto 0) & comp_mantissa_r;
      elsif (comp_cnt_r = 26 or comp_cnt_r = 28) then
        comp_tdata(23 downto 0) <= comp_mantissa_r(31 downto 8);
      elsif (comp_cnt_r = 30) then
        comp_tdata(23 downto 0) <= x"0" & comp_exp_r & comp_mantissa_r(31 downto 16);
      elsif (comp_cnt_r = 31 or comp_cnt_r = 33 or comp_cnt_r = 35) then
        comp_tdata(63 downto 16) <= comp_mantissa_d(15 downto 0) & comp_mantissa_r;
      elsif (comp_cnt_r = 32 or comp_cnt_r = 34) then
        comp_tdata(15 downto 0) <= comp_mantissa_r(31 downto 16);
      elsif (comp_cnt_r = 36) then
        comp_tdata(15 downto 0) <= x"0" & comp_exp_r & comp_mantissa_r(31 downto 24);
      elsif (comp_cnt_r = 37 or comp_cnt_r = 39 or comp_cnt_r = 41) then
        comp_tdata(63 downto 8) <= comp_mantissa_d(23 downto 0) & comp_mantissa_r;
      elsif (comp_cnt_r = 38 or comp_cnt_r = 40) then
        comp_tdata(7 downto 0) <= comp_mantissa_r(31 downto 24);
      elsif (comp_cnt_r = 42) then
        comp_tdata(7 downto 0) <= x"0" & comp_exp_r;
      elsif (comp_cnt_r = 43) then
        comp_tdata(63 downto 0) <= comp_mantissa_d & comp_mantissa_r;
      elsif (comp_cnt_r = 44 or comp_cnt_r = 46) then
        comp_tdata(63 downto 32) <= comp_mantissa_r;
      elsif (comp_cnt_r = 45 or comp_cnt_r = 47) then
        comp_tdata(31 downto 0) <= comp_mantissa_r;
      end if;
    end if;
  end process;

  m_axis_tdata <= byte_reverse(comp_tdata);

  process (aclk) is

    function calc_keep (
      cnt : in unsigned(5 downto 0)
    ) return std_logic_vector is
      variable bytes : integer := 0;
      variable ret : std_logic_vector(7 downto 0) := (others => '0');
    begin
      bytes := to_integer(unsigned(cnt));
      bytes := ((bytes / 6) + bytes * 4 + 5) rem 8;
      for i in 0 to 7 loop
        if (i < bytes) then
          ret(i) := '1';
        else
          ret(i) := '0';
        end if;
      end loop;
      return ret;
    end function calc_keep;

  begin
    if (rising_edge(aclk)) then
      if (comp_last_r = '1') then
        m_axis_tkeep <= calc_keep(comp_cnt_r-1);
      else
        m_axis_tkeep <= (others => '1');
      end if;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      m_axis_tlast <= comp_last_r;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      m_axis_tvalid <= (valid_word(comp_cnt_r) and comp_valid_r) or comp_last_r;
    end if;
  end process;

end architecture;
