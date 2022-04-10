library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity decompression_bfp8 is
  port (
    aclk    : in std_logic;
    aresetn : in std_logic;
    -- Data input
    s_defm_tdata  : in std_logic_vector(63 downto 0);
    s_defm_tkeep  : in std_logic_vector(7 downto 0);
    s_defm_tlast  : in std_logic;
    s_defm_tready : out std_logic;
    s_defm_tuser  : in std_logic_vector(30 downto 0);
    s_defm_tvalid : in std_logic;
    -- Data output
    m_unpack_tdata  : out std_logic_vector(63 downto 0);
    m_unpack_tkeep  : out std_logic_vector(7 downto 0);
    m_unpack_tlast  : out std_logic;
    m_unpack_tuser  : out std_logic_vector(30 downto 0);
    m_unpack_tvalid : out std_logic
  );
end entity decompression_bfp8;

architecture rtl of decompression_bfp8 is

  constant DEBUG : integer := 1;

  -- State counter
  -- For BFP8, this module eat 25 words (8 RBs/96 REs/1600 bits) from input AXIS
  -- interface, and write 48 words to output AXIS (25 : 8 : 48).
  -- Since there is no need for output AXIS to support backward pressure, this
  -- makes simpler for state machine. We only need a state machine with 48
  -- states (encoded as integer form 0 to 47).
  -- At some specified states, it eat a new word from input. At other states,
  -- it does not need new word.

  signal state      : unsigned(5 downto 0);
  signal state_next : unsigned(5 downto 0);

  -- Current state need new word from input AXIS
  signal state_eat_new_word : std_logic;

  -- Current state contains extra RE pair
  signal state_extra_re_pair : std_logic;

  -- This flag indicates we recevied tlast at previous tick, but we still need
  -- to process one extra RE pair. For example, if we receive 8 RB (25 words)
  -- from input AXIS, at 25th tick there is one extra RE pair to write.
  signal state_extra_tlast   : std_logic;
  signal state_noextra_tlast : std_logic;

  signal not_first_word : std_logic;


  signal temp_data_current : std_logic_vector(63 downto 0);
  signal temp_data_last    : std_logic_vector(63 downto 0);
  signal temp_last         : std_logic;
  signal temp_state        : unsigned(5 downto 0);
  signal temp_user         : std_logic_vector(30 downto 0);
  signal temp_valid        : std_logic;

  signal temp2_data     : std_logic_vector(63 downto 0);
  signal temp2_data_i0  : std_logic_vector(7 downto 0);
  signal temp2_data_i1  : std_logic_vector(7 downto 0);
  signal temp2_data_q0  : std_logic_vector(7 downto 0);
  signal temp2_data_q1  : std_logic_vector(7 downto 0);
  signal temp2_exponent : std_logic_vector(3 downto 0);
  signal temp2_last     : std_logic;
  signal temp2_user     : std_logic_vector(30 downto 0);
  signal temp2_valid    : std_logic;


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

  -- This function calcuates how many bits required for each state
  function required_bits (
    s : in integer
  ) return integer is
    variable irb : integer := 0;
    variable ire : integer := 0;
    variable ret : integer := 0;
  begin
    irb := s / 6;
    ire := (s * 2 + 1) mod 12;
    ret := irb * (8 + 12 * 8 * 2) + (ire + 1) * 8 * 2 + 8;
    return ret;
  end function required_bits;

  -- This function calculates how many words required for each state
  function required_words (
    s : in integer
  ) return integer is
    variable ret : integer;
  begin
    ret := (required_bits(s) + 63) / 64;
    return ret;
  end function required_words;

  -- This function calcuates whether this state needs a new word from input
  function require_new_word (
    state : in unsigned(5 downto 0)
  ) return std_logic is
    variable ret : std_logic := '0';
    variable lut : std_logic_vector(63 downto 0) := (others => '0');
  begin
    -- Build the Loop up table
    for s in 0 to 63 loop
      if (s = 0) then
        lut(s) := '1';
      elsif (required_words(s) = required_words(s - 1)) then
        lut(s) := '0';
      else
        lut(s) := '1';
      end if;
    end loop;
    --
    ret := lut(to_integer(state));
    return ret;
  end function require_new_word;

  function extra_re_pair (
    state : in unsigned(5 downto 0)
  ) return std_logic is
    variable ret : std_logic := '0';
    variable lut : std_logic_vector(63 downto 0) := (others => '0');
  begin
    for s in 0 to 63 loop
      if (required_words(s) = required_words(s + 1)) then
        lut(s) := '1';
      else
        lut(s) := '0';
      end if ;
    end loop;
    ret := lut(to_integer(state));
    return ret;
  end function extra_re_pair;

  -- This function gets the LSB position of required IQ
  function get_iq_lsb (
    state        : in unsigned(5 downto 0);
    data_current : in std_logic_vector(63 downto 0);
    data_last    : in std_logic_vector(63 downto 0)
  ) return std_logic_vector is
    variable comb : std_logic_vector(127 downto 0) := (others => '0');
    variable idx  : integer := 0;
    variable ret  : std_logic_vector(31 downto 0) := (others => '0');
  begin
    comb := data_last & data_current;
    idx  := (64 - required_bits(to_integer(state))) mod 32;
    ret  := comb(idx+31 downto idx);
    return ret;
  end function get_iq_lsb;

begin

  -- DEBUG
  --======

  DEBUG_PRINT : if DEBUG > 0 generate

    process is
      variable state : unsigned(5 downto 0);
      variable buf  : line;
    begin
      for s in 0 to 47 loop
        state := to_unsigned(s, 6);
        write(output, "state: " & integer'image(s));
        write(output, ", required bits: " & integer'image(required_bits(s)));
        write(output, ", required words: " & integer'image(required_words(s)));
        write(output, ", require new word: " & std_logic'image(require_new_word(state)));
        write(output, ", extra re pair: " & to_string(extra_re_pair(state)));
        write(output, "" & LF);
      end loop;
      wait;
    end process;

  end generate DEBUG_PRINT;


  -- FMS
  --====

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (aresetn = '0') then
        state <= (others => '0');
      else
        state <= state_next;
      end if;
    end if;
  end process;

  process (state, state_eat_new_word, state_extra_re_pair, s_defm_tvalid, s_defm_tlast) is
  begin
    if (state < 48) then
      --///
      if ((state_eat_new_word = '1' and s_defm_tvalid = '1' and s_defm_tlast = '1' and state_extra_re_pair = '0') or state_extra_tlast = '1') then
        -- We recevied last word
        state_next <= (others => '0');
      elsif ((state_eat_new_word = '1' and s_defm_tvalid = '1') or state_eat_new_word = '0') then
        -- We got required new word, or we does not need new word
        if (state = 47) then
          state_next <= (others => '0');
        else
          state_next <= state + 1;
        end if;
      else
        state_next <= state;
      end if;
      --///
    else
      -- fault recovery
      state_next <= (others => '0');
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (aresetn = '0') then
        state_extra_tlast <= '0';
      elsif (state_extra_re_pair = '1' and s_defm_tvalid = '1' and s_defm_tlast = '1') then
        state_extra_tlast <= '1';
      else
        state_extra_tlast <= '0';
      end if;
    end if;
  end process;

  state_noextra_tlast <= state_eat_new_word and (not state_extra_re_pair) and s_defm_tlast;

  process (state) is
  begin
    -- Current state need new word from input AXIS
    state_eat_new_word <= require_new_word(state);
  end process;

  process (state) is
  begin
    state_extra_re_pair <= extra_re_pair(state);
  end process;


  -- Input AXIS
  --===========

  proc_state_eat_new_word : process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (aresetn = '0') then
        s_defm_tready <= '0';
      else
        s_defm_tready <= require_new_word(state_next);
      end if;
    end if;
  end process proc_state_eat_new_word;


  -- TEMP1 Register
  --===============

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (state_eat_new_word = '1' and s_defm_tvalid = '1') then
        temp_data_current <= byte_reverse(s_defm_tdata);
        temp_data_last    <= temp_data_current;
      end if;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      temp_last <= state_noextra_tlast or state_extra_tlast;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if ((state_eat_new_word = '1' and s_defm_tvalid = '1') or state_eat_new_word = '0') then
        temp_state <= state;
      end if;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (aresetn = '0') then
        not_first_word <= '0';
      elsif (state_eat_new_word = '1' and s_defm_tvalid = '1' and s_defm_tlast = '1') then
        not_first_word <= '0';
      elsif (state_eat_new_word = '1' and s_defm_tvalid = '1') then
        not_first_word <= '1';
      end if;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if ((state_eat_new_word = '1' and s_defm_tvalid = '1') or not_first_word = '0') then
        temp_user <= s_defm_tuser;
      end if;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      temp_valid <= (state_eat_new_word and s_defm_tvalid) or not state_eat_new_word;
    end if;
  end process;


  -- TEMP2
  --======

  process (temp2_data_i0, temp2_data_i1, temp2_data_q0, temp2_data_q1, temp2_exponent) is

    -- This function decompress BFP8 format
    function decompress (
      mantissa       : in std_logic_vector(7 downto 0);
      exponent       : in std_logic_vector(3 downto 0)
    ) return std_logic_vector is
      variable shift : integer := 0;
      variable ret   : signed(15 downto 0) := (others => '0');
    begin
      shift := 8 - to_integer(unsigned(exponent));
      ret(15 downto 8) := signed(mantissa);
      ret := shift_right(ret, shift);
      return std_logic_vector(ret);
    end function decompress;

  begin
    temp2_data(63 downto 48) <= decompress(temp2_data_i0, temp2_exponent);
    temp2_data(47 downto 32) <= decompress(temp2_data_q0, temp2_exponent);
    temp2_data(31 downto 16) <= decompress(temp2_data_i1, temp2_exponent);
    temp2_data(15 downto  0) <= decompress(temp2_data_q1, temp2_exponent);
  end process;

  process (aclk) is
    variable iq : std_logic_vector(31 downto 0);
  begin
    if (rising_edge(aclk)) then
      iq := get_iq_lsb(temp_state, temp_data_current, temp_data_last);
      temp2_data_i0 <= iq(31 downto 24);
      temp2_data_q0 <= iq(23 downto 16);
      temp2_data_i1 <= iq(15 downto  8);
      temp2_data_q1 <= iq( 7 downto  0);
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (temp_valid = '1') then
        if (temp_state = 0) then
          temp2_exponent <= temp_data_current(59 downto 56);
        elsif (temp_state = 6) then
          temp2_exponent <= temp_data_current(51 downto 48);
        elsif (temp_state = 12) then
          temp2_exponent <= temp_data_current(43 downto 40);
        elsif (temp_state = 18) then
          temp2_exponent <= temp_data_current(35 downto 32);
        elsif (temp_state = 24) then
          temp2_exponent <= temp_data_last(27 downto 24);
        elsif (temp_state = 30) then
          temp2_exponent <= temp_data_last(19 downto 16);
        elsif (temp_state = 36) then
          temp2_exponent <= temp_data_last(11 downto 8);
        elsif (temp_state = 41) then
          temp2_exponent <= temp_data_current(3 downto 0);
        end if;
      end if;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      temp2_last <= temp_last;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      temp2_user <= temp_user;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      temp2_valid <= temp_valid;
    end if;
  end process;


  -- Output AXIS
  --============

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      m_unpack_tdata  <= byte_reverse(temp2_data);
      m_unpack_tlast  <= temp2_last;
      m_unpack_tuser  <= temp2_user;
      m_unpack_tvalid <= temp2_valid;
    end if;
  end process;

  m_unpack_tkeep <= x"FF";

end architecture rtl;
