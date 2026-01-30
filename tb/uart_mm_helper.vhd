library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package uart_mm_helper is

	procedure uart_writedata(
		signal clk : in std_logic;
		signal addr : out std_logic_vector(1 downto 0);
		signal writedata : out std_logic_vector(31 downto 0);
		signal writeena : out std_logic; 
		byte : in std_logic_vector(7 downto 0));
		
	procedure uart_readdata(
		signal clk : in std_logic;
		signal addr : out std_logic_vector(1 downto 0);
		signal readena : out std_logic;
		readaddr : in std_logic_vector(1 downto 0));

end package;

package body uart_mm_helper is

	--
	-- write to reg
	--
	procedure uart_writedata(
		signal clk : in std_logic;
		signal addr : out std_logic_vector(1 downto 0);
		signal writedata : out std_logic_vector(31 downto 0);
		signal writeena : out std_logic; 
		byte : in std_logic_vector(7 downto 0)) is
	begin
		addr <= "00";
		writedata <= (31 downto 8 => '0') & byte;
		writeena <= '1';
		wait until rising_edge(clk);
		writeena <= '0';
		wait until rising_edge(clk);
	end procedure;

	--
	-- read from reg
	--
	procedure uart_readdata(
		signal clk : in std_logic;
		signal addr : out std_logic_vector(1 downto 0);
		signal readena : out std_logic;
		readaddr : in std_logic_vector(1 downto 0)) is
	begin
		addr <= readaddr;
		readena <= '1';
		wait until rising_edge(clk);
		readena <= '0';
		wait until rising_edge(clk);
	end procedure;
		
end package body;
