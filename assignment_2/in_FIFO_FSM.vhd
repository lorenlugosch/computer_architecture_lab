-- Loren Lugosch
-- 260404057
-- 
-- Controller for
-- router input port.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.router_parameters.all;

entity in_FIFO_FSM is
	port (
		clock : in std_logic;
		reset : in std_logic;
		write_into_X : in std_logic;
	
		dest_enable : out std_logic;
		pop_enable : out std_logic;
		
		queue_empty : in std_logic;
		waitrequest : in std_logic
	);
end in_FIFO_FSM;

architecture rtl of in_FIFO_FSM is
	-- state information
	type state_type is (RST, IDLE, SERVICING_PACKET);
	signal state : state_type;

begin

	process (clock, reset)
	begin
		-- asynchronous reset
		if (reset = '1') then
			state <= RST;
		
		-- synchronous state machine
		elsif (rising_edge(clock)) then
		
			case state is
				when RST =>
					dest_enable <= '0';
					pop_enable <= '0';
					state <= IDLE;
				
				when IDLE =>
					pop_enable <= '0';
				
					-- if no packets in queue, do nothing
					if (queue_empty = '1') then
						dest_enable <= '0';
						state <= IDLE;
					
					-- if there are packets in the queue,
					-- service them
					else
						dest_enable <= '1'; -- determine destination and set write high
						state <= SERVICING_PACKET;

					end if;
				
				when SERVICING_PACKET =>
					-- once waitrequest deasserts, 
					-- pop packet from queue,
					-- disable dest_enable,
					
					-- TODO: burst mode?
					if (waitrequest = '0') then
						pop_enable <= '1';
						state <= IDLE;
					else 
						state <= SERVICING_PACKET;
					end if;
			
			end case;
		
		end if;
		
	end process;

end rtl;