library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uart_mm_helper.all;

entity uart_mm_tb_basicrx is
end entity;

architecture sim of uart_mm_tb_basicrx is

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
	
	-- uart loop
	rxd <= txd;
		
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
		report "rxd = " & std_logic'image(rxd);
		wait for 100 ns;
		wait until rising_edge(clk);

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
		
		-- wait until rx fifo is full
		loop
			uart_readdata(clk, avs_addr, avs_read, "01");
			exit when avs_readdata(1) = '1';
		end loop;

		uart_readdata(clk, avs_addr, avs_read, "00");
		assert avs_readdata(7 downto 0) = x"aa"
			report "avs_readdata should be 0xAA" severity error;

		uart_readdata(clk, avs_addr, avs_read, "00");
		assert avs_readdata(7 downto 0) = x"bb"
			report "avs_readdata should be 0xBB" severity error;

		uart_readdata(clk, avs_addr, avs_read, "00");
		assert avs_readdata(7 downto 0) = x"cc"
			report "avs_readdata should be 0xCC" severity error;

		uart_readdata(clk, avs_addr, avs_read, "00");
		assert avs_readdata(7 downto 0) = x"dd"
			report "avs_readdata should be 0xDD" severity error;

		uart_readdata(clk, avs_addr, avs_read, "00");
		assert avs_readdata(7 downto 0) = x"ee"
			report "avs_readdata should be 0xEE" severity error;

		uart_readdata(clk, avs_addr, avs_read, "00");
		assert avs_readdata(7 downto 0) = x"11"
			report "avs_readdata should be 0x11" severity error;

		uart_readdata(clk, avs_addr, avs_read, "00");
		assert avs_readdata(7 downto 0) = x"22"
			report "avs_readdata should be 0x22" severity error;

		uart_readdata(clk, avs_addr, avs_read, "00");
		assert avs_readdata(7 downto 0) = x"33"
			report "avs_readdata should be 0x33" severity error;
			
		-- wait until rx fifo is empty
		loop
			uart_readdata(clk, avs_addr, avs_read, "01");
			exit when avs_readdata(0) = '0';
		end loop;
		
		uart_readdata(clk, avs_addr, avs_read, "00");
		assert avs_readdata(7 downto 0) = x"55"
			report "avs_readdata should be 0x55" severity error;
		
		wait;
	end process;
		
end architecture;
