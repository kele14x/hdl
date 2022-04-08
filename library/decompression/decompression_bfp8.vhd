library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decompression_bfp8 is
  port (
    aclk    : in std_logic;
    aresetn : in std_logic;
    -- Data input
    s_defm_tdata  : in std_logic_vector(63 downto 0);
    s_defm_tkeep  : in std_logic_vector(7 downto 0);
    s_defm_tvalid : in std_logic;
    s_defm_tlast  : in std_logic;
    s_defm_tready : out std_logic;
    s_defm_tuser  : in std_logic_vector(30 downto 0);
    -- Data output
    m_unpack_tdata  : out std_logic_vector(63 downto 0);
    m_unpack_tkeep  : out std_logic_vector(7 downto 0);
    m_unpack_tvalid : out std_logic;
    m_unpack_tlast  : out std_logic;
    m_unpack_tuser  : out std_logic_vector(30 downto 0)
  );
end entity decompression_bfp8;

architecture rtl of decompression_bfp8 is

  -- State counter
  -- For BFP8, this module eat 25 words (8 RBs/96 REs/1600 bits) from input AXIS
  -- interface, and write 48 words to output AXIS (25 : 8 : 48).
  -- Since there is no need for output AXIS to support backward pressure, this
  -- makes simpler for state machine. We only need a state machine with 48
  -- states (encoded as integer fomr 0 to 47).
  -- At some specificed states, it eat a new word from input. At other states,
  -- it does not need new word.

  signal state      : unsigned(5 downto 0);
  signal state_next : unsigned(5 downto 0);

  -- This indicate current state need a new word from input
  signal state_eat_new_word : std_logic;

  -- The "which state need new word" lookup table is here
  constant state_eat_new_word_hex : std_logic_vector(63 downto 0) := x"0000555555AAAAAB";

  signal not_first_word : std_logic;

  signal defm_dat_reversed : std_logic_vector(63 downto 0);

  signal temp_data_current : std_logic_vector(63 downto 0);
  signal temp_data_last    : std_logic_vector(63 downto 0);
  signal temp_state        : unsigned(5 downto 0);
  signal temp_valid        : std_logic;
  signal temp_user         : std_logic_vector(30 downto 0);
  signal temp_last         : std_logic;

  signal temp2_data_i0  : std_logic_vector(7 downto 0);
  signal temp2_data_q0  : std_logic_vector(7 downto 0);
  signal temp2_data_i1  : std_logic_vector(7 downto 0);
  signal temp2_data_q1  : std_logic_vector(7 downto 0);
  signal temp2_data     : std_logic_vector(63 downto 0);
  signal temp2_exponent : std_logic_vector(3 downto 0);
  signal temp2_valid    : std_logic;
  signal temp2_user     : std_logic_vector(30 downto 0);
  signal temp2_last     : std_logic;

begin

  -- FMS
  --====

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (aresetn = '0') then
        state <= (others => '1');
      else
        state <= state_next;
      end if;
    end if;
  end process;

  process (state, state_eat_new_word, s_defm_tvalid, s_defm_tlast) is
  begin
    if (state < 48) then
      --///
      if (state_eat_new_word = '1' and s_defm_tvalid = '1' and s_defm_tlast = '1') then
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


  -- Input AXIS
  --===========

  proc_state_eat_new_word : process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (aresetn = '0') then
        state_eat_new_word <= '0';
      else
        state_eat_new_word <= state_eat_new_word_hex(to_integer(state_next));
      end if;
    end if;
  end process proc_state_eat_new_word;

  s_defm_tready <= state_eat_new_word;


  -- TEMP1 Register
  --===============

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

  process (s_defm_tdata) is
  begin
    defm_dat_reversed <= s_defm_tdata(7 downto 0) & s_defm_tdata(15 downto 8) & s_defm_tdata(23 downto 16) &
      s_defm_tdata(31 downto 24) & s_defm_tdata(39 downto 32) & s_defm_tdata(47 downto 40) & s_defm_tdata(55 downto 48) &
      s_defm_tdata(63 downto 56);
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (state_eat_new_word = '1' and s_defm_tvalid = '1') then
        temp_data_current <= defm_dat_reversed;
        temp_data_last    <= temp_data_current;
      end if;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      temp_valid <= (state_eat_new_word and s_defm_tvalid) or not state_eat_new_word;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      temp_last <= state_eat_new_word and s_defm_tvalid and s_defm_tlast;
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
      if ((state_eat_new_word = '1' and s_defm_tvalid = '1') or state_eat_new_word = '0') then
        temp_state <= state;
      end if;
    end if;
  end process;

  -- TEMP2
  --======

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      temp2_valid <= temp_valid;
    end if;
  end process;
  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      temp2_valid <= temp_valid;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (temp_valid = '1') then
        if (unsigned(temp_state) = 0) then
          temp2_exponent <= temp_data_current(59 downto 56);
        elsif (unsigned(temp_state) = 6) then
          temp2_exponent <= temp_data_current(51 downto 48);
        elsif (unsigned(temp_state) = 12) then
          temp2_exponent <= temp_data_current(43 downto 40);
        elsif (unsigned(temp_state) = 18) then
          temp2_exponent <= temp_data_current(35 downto 32);
        elsif (unsigned(temp_state) = 24) then
          temp2_exponent <= temp_data_last(27 downto 24);
        elsif (unsigned(temp_state) = 30) then
          temp2_exponent <= temp_data_last(19 downto 16);
        elsif (unsigned(temp_state) = 36) then
          temp2_exponent <= temp_data_last(11 downto 8);
        elsif (unsigned(temp_state) = 41) then
          temp2_exponent <= temp_data_current(3 downto 0);
        end if;
      end if;
    end if;
  end process;

  -- Output AXIS
  --============

  m_unpack_tkeep <= x"FF";

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      m_unpack_tdata  <= temp2_data(7 downto 0) & temp2_data(15 downto 8) & temp2_data(23 downto 16) &
        temp2_data(31 downto 24) & temp2_data(39 downto 32) & temp2_data(47 downto 40) & temp2_data(55 downto 48) &
        temp2_data(63 downto 56);
      m_unpack_tvalid <= temp2_valid;
      m_unpack_tlast  <= temp2_last;
      m_unpack_tuser  <= temp2_user;
    end if;
  end process;

end architecture rtl;
