library ieee; 
use ieee.std_logic_1164.all;

entity lfsr_9_bit is 
port (
  i_clk           : in  std_logic;
  i_rstb          : in  std_logic;
  i_sync_reset    : in  std_logic;
  i_seed          : in  std_logic_vector (9 downto 0);
  i_en            : in  std_logic;
  o_lsfr          : out std_logic_vector (9 downto 0));
end lfsr_9_bit;

architecture rtl of lfsr_9_bit is	

signal r_lfsr           : std_logic_vector (10 downto 1);

begin	
o_lsfr  <= r_lfsr(11 downto 1);

p_lfsr : process (i_clk,i_rstb) begin 
  if (i_rstb = '0') then 
    r_lfsr   <= (others=>'1');
  elsif rising_edge(i_clk) then 
    if(i_sync_reset='1') then
      r_lfsr   <= i_seed;
    elsif (i_en = '1') then 
		r_lfsr(10) <= r_lfsr(1);
	   r_lfsr(9) <= r_lfsr(10) xor r_lfsr(1);
		r_lfsr(8) <= r_lfsr(9);
      r_lfsr(7) <= r_lfsr(8);
      r_lfsr(6) <= r_lfsr(7); 
      r_lfsr(5) <= r_lfsr(6);
      r_lfsr(4) <= r_lfsr(5);
      r_lfsr(3) <= r_lfsr(4);
      r_lfsr(2) <= r_lfsr(3);
      r_lfsr(1) <= r_lfsr(2);
    end if; 
  end if; 
end process p_lfsr; 

end architecture rtl;