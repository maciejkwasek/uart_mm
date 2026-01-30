library ieee;
use ieee.std_logic_1164.all;

entity uart_rx is
	port
	(
		clk : in std_logic;
		rst_n : in std_logic;
		oversampl_tick : in std_logic;
		
		rx_data : out std_logic_vector(7 downto 0);
		rx_data_valid : out std_logic;
		rx_ready : in std_logic;
		
		rx_in : in std_logic
	);
end entity;

architecture rtl of uart_rx is
	type uart_rx_state is (IDLE,  START_BIT, DATA, STOP_BIT);
	
	signal c_state : uart_rx_state := IDLE;
	signal n_state : uart_rx_state := IDLE;
	
	signal cnt : natural := 0;
	signal bit_cnt : natural := 0;
	signal data_ready : std_logic := '0';
	signal cnt_ready : natural := 0;
	
	signal rx_data_copy : std_logic_vector(7 downto 0) := (others => '0');
	signal rx_data_buf : std_logic_vector(7 downto 0) := (others => '0');
	
begin

	process(clk, rst_n)
	begin
		if rst_n = '0' then
			c_state <= IDLE;
		elsif rising_edge(clk) then
			--if oversampl_tick = '1' then
				c_state <= n_state;
			--end if;
		end if;
	end process;
	
	process(c_state, oversampl_tick, rx_in, cnt, bit_cnt, rx_ready)
	begin
		n_state <= c_state;
	
			case c_state is
				when IDLE =>
					if rx_in = '0' then
						n_state <= START_BIT;
					end if;
					
				when START_BIT =>
					if oversampl_tick = '1' then
						if cnt = 7 then
							if rx_in = '0' then
								n_state <= DATA;
							else
								n_state <= IDLE;
							end if;
						end if;
					end if;
					
				when DATA =>
					if oversampl_tick = '1' then	
						if bit_cnt = 7 and cnt = 15 then
							n_state <= STOP_BIT;
						end if;
					end if;
									
				when STOP_BIT =>
					if oversampl_tick = '1' then
						if cnt =  15 then
							n_state <= IDLE;
						end if;
					end if;
					
				when others =>
					n_state <= IDLE;
			end case;
	end process;
	
	process(clk, rst_n)
	begin
		if rst_n = '0' then
		
			data_ready <= '0';
			cnt <= 0;
			bit_cnt <= 0;
			rx_data_copy <= (others => '0');
			rx_data_buf <= (others => '0');
			
		elsif rising_edge(clk) then
		
				if rx_ready = '1' and data_ready = '1' then
					data_ready <= '0';
				end if;
			
				case c_state is

					when IDLE =>
						if rx_in = '0' then
							cnt <= 0;
						end if;
					
					when START_BIT =>
						if oversampl_tick = '1' then
							if cnt = 7 then
								cnt <= 0;
								if rx_in = '0' then
									bit_cnt <= 0;
									rx_data_copy <= (others => '0');
								end if;
							else
								cnt <= cnt + 1;
							end if;
						end if;
					
					when DATA =>
						if oversampl_tick = '1' then
							if cnt = 15 then
								cnt <= 0;
								rx_data_copy(bit_cnt) <= rx_in;
								
								if bit_cnt = 7 then
									bit_cnt <= 0;
								else
									bit_cnt <= bit_cnt + 1;
								end if;
							else
								cnt <= cnt + 1;
							end if;
						end if;

					when STOP_BIT =>
						if oversampl_tick = '1' then
							if cnt = 15 then
								cnt <= 0;
								if rx_in = '1' then
									rx_data_buf <= rx_data_copy;
									data_ready <= '1';
								end if;
							else
								cnt <= cnt + 1;
							end if;
						end if;
					
					when others =>
					
				end case;
		end if;
	end process;
	
	rx_data <= rx_data_buf;
	rx_data_valid <= data_ready;

end architecture;
