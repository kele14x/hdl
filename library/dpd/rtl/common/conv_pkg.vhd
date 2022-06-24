library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package conv_pkg is
  -- functions
  function sign_extended(d : std_logic_vector; width : integer) return std_logic_vector;


end conv_pkg;

package body conv_pkg is
  -- signed extended
  function sign_extended(d : std_logic_vector; width : integer) return std_logic_vector is
    constant old_width  : integer := d'length;     --'
    variable j          : integer;
    variable result     : std_logic_vector(width-1 downto 0) := (others => '0');
    variable d2         : std_logic_vector(old_width-1 downto 0);
  begin
    d2 := d;
    for i in 0 to width-1 loop
      if ( i > old_width-1) then
        result(i) := d2(old_width-1);
      else
        result(i) := d2(i);
      end if;
    end loop;
    return result;
  end;
    
end conv_pkg;