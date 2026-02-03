library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_mm is
	generic
	(
		PHASE_INC : unsigned(31 downto 0) := to_unsigned(158_287_826, 32)
	);

	port
	(
		clk : in std_logic;
		rst_n : in std_logic;

		txd : out std_logic;
		rxd : in std_logic;

		avs_addr : in std_logic_vector(1 downto 0);

		avs_write : in std_logic;
		avs_writedata : in std_logic_vector(31 downto 0);

		avs_read : in std_logic;
		avs_readdata : out std_logic_vector(31 downto 0);

		avs_chipselect : in std_logic;

		avs_waitrequest : out std_logic

	);
end entity;

architecture rtl of uart_mm is

	signal uart_tick : std_logic;

	signal fifotx_uarttx_data : std_logic_vector(7 downto 0);
	signal fifotx_uarttx_valid : std_logic;
	signal uarttx_fifotx_ready : std_logic;

	signal uartrx_fiforx_data : std_logic_vector(7 downto 0);
	signal uartrx_fiforx_valid : std_logic;
	signal fiforx_uartrx_ready : std_logic;

	signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
	signal tx_valid : std_logic := '0';
	signal tx_ready : std_logic;

	signal tx_empty : std_logic;
	signal tx_full : std_logic;

	signal rx_data : std_logic_vector(7 downto 0) := (others => '0');
	signal rx_valid : std_logic;
	signal rx_ready : std_logic := '0';

	signal rx_empty : std_logic;
	signal rx_full : std_logic;
	
begin

	nco : entity work.nco32
		generic map
		(
			--PHASE_INC => 158_287_826
			PHASE_INC => PHASE_INC
		)
		port map
		(
			clk => clk,
			rst_n => rst_n,
			tick => uart_tick
		);

	uarttx : entity work.uart_tx
		port map
		(
			clk => clk,
			rst_n => rst_n,
			baud_tick => uart_tick,

			tx_out => txd,

			tx_data => fifotx_uarttx_data,
			tx_data_valid => fifotx_uarttx_valid,
			tx_ready => uarttx_fifotx_ready
		);

	fifotx : entity work.fifo
		port map
		(
			clk => clk,
			rst_n => rst_n,

			wr_data => tx_data,
			wr_valid => tx_valid,
			wr_ready => tx_ready,

			rd_data => fifotx_uarttx_data,
			rd_valid => fifotx_uarttx_valid,
			rd_ready => uarttx_fifotx_ready,

			empty => tx_empty,
			full => tx_full
		);

	uartrx : entity work.uart_rx
		port map
		(
			clk => clk,
			rst_n => rst_n,
			oversampl_tick => uart_tick,

			rx_in => rxd,

			rx_data => uartrx_fiforx_data,
			rx_data_valid => uartrx_fiforx_valid,
			rx_ready => fiforx_uartrx_ready
		);
		
	fiforx : entity work.fifo
		port map
		(
			clk => clk,
			rst_n => rst_n,

			wr_data => uartrx_fiforx_data,
			wr_valid => uartrx_fiforx_valid,
			wr_ready => fiforx_uartrx_ready,

			rd_data => rx_data,
			rd_valid => rx_valid,
			rd_ready => rx_ready,

			empty => rx_empty,
			full => rx_full
		);

		process(clk, rst_n)
		begin
			if rst_n = '0' then
				
				tx_valid <= '0';
				rx_ready <= '0';

			elsif rising_edge(clk) then

				tx_valid <= '0';
				rx_ready <= '0';

				if avs_chipselect = '1' then
					-- write priority policy
					if avs_write = '1' and avs_addr = "00" then
						if tx_ready = '1' then
							tx_data <= avs_writedata(7 downto 0);
							tx_valid <= '1';
						end if;
					elsif avs_read = '1'  and avs_addr = "00" then
						if rx_valid = '1' then
							rx_ready <= '1';
						end if;
					end if;
				end if;

			end if;
		end process;

		process
		(
			avs_read,
			avs_chipselect,
			avs_addr,
			rx_data,
			rx_full,
			rx_empty,
			tx_full,
			tx_empty
		)
		begin
			avs_readdata <= (others => '1');
			if avs_chipselect = '1' then
				case avs_addr is
					when "00" => avs_readdata <= (31 downto 8 => '0') & rx_data;
					when "01" => avs_readdata <= (31 downto 2 => '0') & rx_full & rx_empty;
					when "10" => avs_readdata <= (31 downto 2 => '0') & tx_full & tx_empty;
					when others => avs_readdata <= (others => '1');
				end case;
			end if;
		end process;

		avs_waitrequest <= '0';

end architecture;
