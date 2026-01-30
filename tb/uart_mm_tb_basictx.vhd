library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uart_mm_helper.all;

entity uart_mm_tb_basictx is
end entity;

architecture tb of uart_mm_tb_basictx is

	signal clk : std_logic;
	signal rst_n : std_logic;
	
	signal txd : std_logic;
	signal rxd : std_logic;
	
	signal avs_addr : std_logic_vector(1 downto 0);
	
	signal avs_write : std_logic := '0';
	signal avs_writedata : std_logic_vector(31 downto 0);
	
	signal avs_read : std_logic := '0';
	signal avs_readdata : std_logic_vector(31 downto 0);
	
	signal avs_waitrequest : std_logic;
	
begin

	uart_mm : entity work.uart_mm
		generic map
		(
			PHASE_INC => x"7fffffff"
		)
		port map
		(
			clk => clk,
			rst_n => rst_n,
			
			txd => txd,
			rxd => rxd,
		
			avs_addr => avs_addr,
		
			avs_write => avs_write,
			avs_writedata => avs_writedata,
		
			avs_read => avs_read,
			avs_readdata => avs_readdata,
		
			avs_waitrequest => avs_waitrequest
		);
		
	-- reset
   rst_n <= '0', '1' after 20 ns;
		
	-- clk
	process
	begin
		while true loop
			clk <= '1'; wait for 10 ns;
			clk <= '0'; wait for 10 ns;
		end loop;
	end process;

	-- test
	process
	begin

		report "txd = " & std_logic'image(txd);
		wait for 100 ns;
		wait until rising_edge(clk);
		
		uart_readdata(clk, avs_addr, avs_read, "10");
		assert avs_readdata(1 downto 0) = "01"
			report "avs_readdata should be 01, fifotx: full=0, empty=1" severity error;
		
		-- write 8x byte until full
		uart_writedata(clk, avs_addr, avs_writedata, avs_write, x"aa");
		uart_writedata(clk, avs_addr, avs_writedata, avs_write, x"bb");
		uart_writedata(clk, avs_addr, avs_writedata, avs_write, x"cc");
		uart_writedata(clk, avs_addr, avs_writedata, avs_write, x"dd");
		uart_writedata(clk, avs_addr, avs_writedata, avs_write, x"ee");
		uart_writedata(clk, avs_addr, avs_writedata, avs_write, x"11");
		uart_writedata(clk, avs_addr, avs_writedata, avs_write, x"22");
		uart_writedata(clk, avs_addr, avs_writedata, avs_write, x"33");
		uart_writedata(clk, avs_addr, avs_writedata, avs_write, x"55"); -- full
		
		uart_readdata(clk, avs_addr, avs_read, "10");
		assert avs_readdata(1 downto 0) = "10"
			report "avs_readdata should be 10, fifotx: full=1, empty=0" severity error;
		
		-- wait until not fifo full
		loop
			uart_readdata(clk, avs_addr, avs_read, "10");
			exit when avs_readdata(1) = '0';
		end loop;
		
		uart_writedata(clk, avs_addr, avs_writedata, avs_write, x"a5");
		
		-- wait until fifo empty
		loop
			uart_readdata(clk, avs_addr, avs_read, "10");
			exit when avs_readdata(0) = '1';
		end loop;
		
		wait;
	end process;
		
end architecture;
