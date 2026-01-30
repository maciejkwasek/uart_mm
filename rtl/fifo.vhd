library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
	generic
	(
		WIDE : natural := 8;
		DEPTH : natural := 8
	);
	
	port
	(
		clk : in std_logic;
		rst_n : in std_logic;
		
		wr_data : in std_logic_vector(WIDE-1 downto 0);
		wr_valid : in std_logic;
		wr_ready : out std_logic;
		
		rd_data : out std_logic_vector(WIDE-1 downto 0);
		rd_valid : out std_logic;
		rd_ready : in std_logic;
		
		empty : out std_logic;
		full : out std_logic
	);

end entity;

architecture rtl of fifo is

	type fifo_mem_t is array(0 to DEPTH-1) of std_logic_vector(WIDE-1 downto 0);
	
	signal fifo_mem : fifo_mem_t := ( others => (others => '0'));
	signal wr_idx : natural := 0;
	signal rd_idx : natural := 0;
	
	signal data_cnt : natural range 0 to DEPTH := 0;

	signal wr_ready_r : std_logic := '1';
	signal rd_valid_r : std_logic := '0';
	
	signal wr_fire : std_logic := '0';
	signal rd_fire : std_logic := '0';
begin

	wr_ready_r <= '0' when data_cnt = DEPTH else '1';
	rd_valid_r <= '0' when data_cnt = 0 else '1';
	
	wr_ready <= wr_ready_r;
	rd_valid <= rd_valid_r;
	
	full <= '1' when data_cnt = DEPTH else '0';
	empty <= '1' when data_cnt = 0 else '0';
	
	wr_fire <= wr_valid and wr_ready_r;
	rd_fire <= rd_ready and rd_valid_r;
	
	-- uncomment for show-ahead fifo
	rd_data <= fifo_mem(rd_idx);

	process(clk, rst_n)
		variable wr_idx_temp : natural :=0;
	begin
		if rst_n = '0' then
			wr_idx <= 0;
			rd_idx <= 0;
			data_cnt <= 0;
			
		elsif rising_edge(clk) then
		
			case std_logic_vector'(wr_fire & rd_fire) is
				when "00" =>
					-- nothing to do
					
				when "10" =>
					-- only wr
					fifo_mem(wr_idx) <= wr_data;	
					wr_idx <= (wr_idx + 1) mod DEPTH;
					
					if data_cnt < DEPTH then
						data_cnt <=  data_cnt + 1;
					end if;
					
				when "01" =>
					-- only rd
					-- comment for show-ahead fifo
					-- rd_data <= fifo_mem(rd_idx);
					rd_idx <= (rd_idx + 1) mod DEPTH;

					if data_cnt > 0 then
						data_cnt <= data_cnt - 1;
					end if;
					
				when "11" =>
					-- both
					-- comment for show-ahead fifo
					-- rd_data <= fifo_mem(rd_idx);
					fifo_mem(wr_idx) <= wr_data;
					wr_idx <= (wr_idx + 1) mod DEPTH;
					rd_idx <= (rd_idx + 1) mod DEPTH;
									
				when others =>
			end case;
		end if;
	end process;

end architecture;