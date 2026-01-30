library ieee;
use ieee.std_logic_1164.all;

entity uart_tx is
	
	generic
	(
		CLK_FREQ_HZ : natural := 50_000_000;
		BAUD_BPS : natural := 115_200
	);
	
	port
	(
		clk : in std_logic;
		rst_n : in std_logic;
		baud_tick : in std_logic;

		tx_data : in std_logic_vector(7 downto 0);
		tx_data_valid : in std_logic;
		tx_ready : out std_logic;

		tx_out : out std_logic
	);
	
end entity;

architecture rtl of uart_tx is
	
	type uart_tx_state_t is (IDLE, START_BIT, DATA, STOP_BIT);
	
	signal c_state : uart_tx_state_t := IDLE;
	signal n_state : uart_tx_state_t := IDLE;
	
	signal tx_data_copy : std_logic_vector(7 downto 0) := (others => '0');
	signal bit_cnt : natural range 0 to 7 := 0;
	
	signal cnt : natural := 0;

begin
	
	-- fsm register state process 
	process(clk, rst_n)
	begin
		if rst_n ='0' then
			c_state <= IDLE;
		elsif rising_edge(clk) then
			--if baud_tick = '1' then
				c_state <= n_state;
			--end if;
		end if;
	end process;
	
	-- fsm combination process
	process(c_state, bit_cnt, baud_tick, cnt, tx_data_valid)
	begin

		n_state <= c_state;
		
		case c_state is
			
			when IDLE =>
				if tx_data_valid = '1' then
					n_state <= START_BIT;
				end if;
				
			when START_BIT =>
				if baud_tick = '1' then
					if cnt = 15 then
						n_state <= DATA;
					end if;
				end if;
				
			when DATA =>
				if baud_tick = '1' then
					if bit_cnt = 7 and cnt = 15 then
						n_state <= STOP_BIT;
					end if;
				end if;
				
			when STOP_BIT =>
				if baud_tick = '1' then
					if cnt = 15 then
						n_state <= IDLE;
					end if;
				end if;

			when others =>
				n_state <= IDLE;
				
		end case;
	end process;
	
	-- fsm data path process
	process(clk, rst_n)
	begin
		if rst_n = '0' then
		
			tx_data_copy <= (others => '0');
			bit_cnt <= 0;

		elsif rising_edge(clk) then

			case c_state is
				
				when IDLE =>
					if tx_data_valid = '1' then				
						tx_data_copy <= tx_data;
						bit_cnt <= 0;
					end if;
					
				when START_BIT =>
					if baud_tick = '1' then
						if cnt = 15 then
							cnt <= 0;
						else
							cnt <= cnt + 1; 
						end if;
					end if;
					
				when DATA =>
					if baud_tick = '1' then					
						if cnt = 15 then
							cnt <= 0;
							
							if bit_cnt /= 7 then
								bit_cnt <= bit_cnt + 1;
							end if;							
						else
							cnt <= cnt + 1; 
						end if;
					end if;

				when STOP_BIT =>
					if baud_tick = '1' then
						if cnt = 15 then
							cnt <= 0;
						else
							cnt <= cnt + 1; 
						end if;
					end if;
					
				when others =>
								
			end case;		
		end if;
	end process;
	
	-- outputs
	tx_out <= '1' when c_state = IDLE else
				 '0' when c_state = START_BIT else
				 tx_data_copy(bit_cnt) when c_state = DATA else
				 '1' when c_state = STOP_BIT else '1';
 
	tx_ready <= '1' when c_state = IDLE else '0';

end architecture;
