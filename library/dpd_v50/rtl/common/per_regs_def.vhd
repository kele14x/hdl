-------------------------------------------------------------------------------
-- copyright (c) ericsson ab, 2011
-- the copyright to the document(s) herein is the property of
-- ericsson ab, sweden.
--
-- the document(s) may be used and/or copied only with the written
-- permission from ericsson ab, or in accordance with the terms and
-- conditions stipulated in the agreement/contract under which
-- the document(s) have been supplied.
--
-- all rights reserved.
-------------------------------------------------------------------------------
--
-- author:     qeliwik
-- created:    2011-03-16
--
-------------------------------------------------------------------------------
-- description: type declarations for xios_i.
--
-------------------------------------------------------------------------------
-- vhdl version: vhdl '93
--
-------------------------------------------------------------------------------
-- modified:
--
-- renamed package
-------------------------------------------------------------------------------

library ieee;  
use ieee.std_logic_1164.all;

package per_regs_def is


  -- per_bus address
  constant ADDR_LUTS        : integer := 393216;-- 0x6000

  constant ADDR_RAMSEL      : std_logic_vector(11 downto 0) := X"200";
  constant ADDR_GSCALE      : std_logic_vector(11 downto 0) := X"201";
  constant ADDR_GAIN        : std_logic_vector(11 downto 0) := X"202";
  constant ADDR_TAPSEL      : std_logic_vector(11 downto 0) := X"203";

  constant ADDR_CLR         : std_logic_vector(11 downto 0) := X"210";
  constant ADDR_PDON        : std_logic_vector(11 downto 0) := X"211";
  constant ADDR_ALARM_EN    : std_logic_vector(11 downto 0) := X"212";
  
  constant ADDR_SRLIMIT     : std_logic_vector(11 downto 0) := X"213";
  constant ADDR_PKLIMIT     : std_logic_vector(11 downto 0) := X"214";
  constant ADDR_GAINLIMIT   : std_logic_vector(11 downto 0) := X"215";
  
  constant ADDR_VCA         : std_logic_vector(11 downto 0) := X"2B0";
  constant ADDR_PA3         : std_logic_vector(11 downto 0) := X"202";
  
  constant ADDR_TERMS_ID        : std_logic_vector(11 downto 0) := X"300";
  constant ADDR_TERMS_SIG       : std_logic_vector(11 downto 0) := X"320";
  constant ADDR_TERMS_ADR       : std_logic_vector(11 downto 0) := X"340";
  constant ADDR_TERMS_SIG2      : std_logic_vector(11 downto 0) := X"360";

  -- register on data_cap
  constant ADDR_DATACAP_RST         : std_logic_vector(11 downto 0) := X"150";
  constant ADDR_DATACAP_START       : std_logic_vector(11 downto 0) := X"150";
  constant ADDR_DATACAP_TRIGSRC     : std_logic_vector(11 downto 0) := X"150";
  constant ADDR_DATACAP_TIMEOUT     : std_logic_vector(11 downto 0) := X"152";
  constant ADDR_DATACAP_RCNT        : std_logic_vector(11 downto 0) := X"151";
  constant ADDR_DATACAP_MODE        : std_logic_vector(11 downto 0) := X"150";
  constant ADDR_DATACAP_PSEL        : std_logic_vector(11 downto 0) := X"150";
  constant ADDR_DATACAP_STOP        : std_logic_vector(11 downto 0) := X"150";
  
  -- register on dynamic LUT
  constant ADDR_DYNLUT_DELAY        : std_logic_vector(11 downto 0) := X"000";
  constant ADDR_DYNLUT_DLCOEF       : std_logic_vector(11 downto 0) := X"000";
  constant ADDR_DYNLUT_CYCLE        : std_logic_vector(11 downto 0) := X"000";

  -- data_cap storage
  constant ADDR_DATA_STORE          : std_logic_vector(19 downto 0) := X"10000";


  
  constant IFRAM_ANT_CHG_INT        : std_logic_vector(11 downto 0) := X"502";
  constant IFRAM_FAULT_INT          : std_logic_vector(11 downto 0) := X"504";



end;
 
