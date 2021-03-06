-- Loren Lugosch
-- 260404057
-- 
-- This module looks at the router address in the packet 
-- header and determines which output queue the packet is 
-- destined for.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Package of router parameters
use work.router_parameters.all;

entity destination_decoder is
	generic (
		-- The coordinates in the network of this processor.
		-- Another possible implementation uses a small ROM
		-- instead of generics.
		
		my_x : integer := 1;
		my_y : integer := 1
	);
	
	port (
	  clock : in std_logic;
		dest_enable : in std_logic;
	
		x_coordinate : in integer;
		y_coordinate : in integer;
		
		destination	: out std_logic_vector(2 downto 0);
		
		write_outof_X_into_N : out std_logic;
		write_outof_X_into_S : out std_logic;
		write_outof_X_into_W : out std_logic;
		write_outof_X_into_E : out std_logic;
		write_outof_X_into_LOCAL : out std_logic
	);
end destination_decoder;

architecture rtl of destination_decoder is

	signal destination_internal : std_logic_vector(2 downto 0); -- N, S, W, E, LOCAL

begin

-- Since the top left corner of the processor
-- grid is (0,0), and moving right or 
-- down from that core increases the coordinates'
-- values, we can determine the 
-- correct queue by comparing the packet's x
-- coordinate with this core's x coordinate 
-- (and same with y) and move right/down (if greater than)
-- or left (if less than).

-- A packet destined for a core to the NW
-- (or any non-cardinal direction)
-- can either move N -> W
--              or W -> N.
-- We have arbitrarily decided to
-- move W -> N. Since zigzagging
-- will take the same number
-- of moves as moving all the way W
-- and then all the way N, our  
-- simplification imposes no extra 
-- travel time.

-- The following table describes the
-- decoding of a router address to a
-- direction to move.

--x __ my x | y __ my y || destination
--====================================
--   =      |    =      ||        LOCAL
--   =      |    <      ||         N
--   =      |    >      ||         S

--   >      |    =      ||         E
--   >      |    <      ||         E (really, NE)
--   >      |    >      ||         E (really, SE)

--   <      |    =      ||         W
--   <      |    <      ||         W (really, NW)
--   <      |    >      ||         W (really, SW)

	decoding : process(x_coordinate, y_coordinate, dest_enable, clock)
	begin
	
		-- determine destination
		if (dest_enable /= '1') then
		  destination_internal <= NO_DEST;
		elsif    (x_coordinate = my_x) and (y_coordinate = my_y) then
			destination_internal <= LOCAL;
		elsif (x_coordinate = my_x) and (y_coordinate < my_y) then
			destination_internal <= N;
		elsif (x_coordinate = my_x) and (y_coordinate > my_y) then
			destination_internal <= S;
		elsif (x_coordinate > my_x) and (y_coordinate = my_y) then
			destination_internal <= E;
		elsif (x_coordinate > my_x) and (y_coordinate < my_y) then
			destination_internal <= E;
		elsif (x_coordinate > my_x) and (y_coordinate > my_y) then
			destination_internal <= E;
		elsif (x_coordinate < my_x) and (y_coordinate = my_y) then
			destination_internal <= W;
		elsif (x_coordinate < my_x) and (y_coordinate < my_y) then
			destination_internal <= W;
		elsif (x_coordinate < my_x) and (y_coordinate > my_y) then
			destination_internal <= W;
		else 
		  destination_internal <= NO_DEST;
		end if;
		
		-- decode destination
		if (dest_enable /= '1') then
			write_outof_X_into_N <= '0';
			write_outof_X_into_S <= '0';
			write_outof_X_into_W <= '0';
			write_outof_X_into_E <= '0';
			write_outof_X_into_LOCAL <= '0';
			
		elsif (destination_internal = N) then
			write_outof_X_into_N <= '1';
			write_outof_X_into_S <= '0';
			write_outof_X_into_W <= '0';
			write_outof_X_into_E <= '0';
			write_outof_X_into_LOCAL <= '0';
			
		elsif (destination_internal = S) then
			write_outof_X_into_N <= '0';
			write_outof_X_into_S <= '1';
			write_outof_X_into_W <= '0';
			write_outof_X_into_E <= '0';
			write_outof_X_into_LOCAL <= '0';
			
		elsif (destination_internal = W) then
			write_outof_X_into_N <= '0';
			write_outof_X_into_S <= '0';
			write_outof_X_into_W <= '1';
			write_outof_X_into_E <= '0';
			write_outof_X_into_LOCAL <= '0';
			
		elsif (destination_internal = E) then
			write_outof_X_into_N <= '0';
			write_outof_X_into_S <= '0';
			write_outof_X_into_W <= '0';
			write_outof_X_into_E <= '1';
			write_outof_X_into_LOCAL <= '0';
			
		elsif (destination_internal = LOCAL) then
			write_outof_X_into_N <= '0';
			write_outof_X_into_S <= '0';
			write_outof_X_into_W <= '0';
			write_outof_X_into_E <= '0';
			write_outof_X_into_LOCAL <= '1';
			
		else
			write_outof_X_into_N <= '0';
			write_outof_X_into_S <= '0';
			write_outof_X_into_W <= '0';
			write_outof_X_into_E <= '0';
			write_outof_X_into_LOCAL <= '0';
			
		end if;
		
	end process;

	destination <= destination_internal;

end rtl;