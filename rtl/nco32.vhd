library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nco32 is
	generic
	(
		PHASE_INC : unsigned(31 downto 0) := (others => '0')
	);

	port
	(
		clk : in std_logic;
		rst_n : in std_logic;
		
		tick : out std_logic
	);
end entity;

architecture rtl of nco32 is
	signal cnt : unsigned(31 downto 0) := (others => '0');
	signal tick_prev : std_logic := '0'; 	
begin

	process(clk, rst_n)
	begin
		if rst_n = '0' then
			cnt <= (others => '0');
			tick_prev <= '0';
		elsif rising_edge(clk) then
			cnt <= cnt + PHASE_INC;
			tick_prev <= cnt(31);
		end if;
	end process;
	
	tick <= cnt(31) and not tick_prev;

end architecture;
