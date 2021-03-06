-- Loren Lugosch
-- 260404057
-- 
-- In_FIFOs buffer packets
-- routed into this core
-- and route them to one of the 
-- out_FIFOs.
--
-- *** Testbench ***

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.router_parameters.all;

entity in_FIFO_tb is
end in_FIFO_tb;

architecture tb of in_FIFO_tb is
  
  -- test inputs and clock period
 	signal clock	: std_logic := '0';
	signal reset	: std_logic := '0';
	constant clk_period : time := 1 ns;
	
	signal writedata_into_X : std_logic_vector(packet_size-1 downto 0);
	signal write_into_X : std_logic := '0';
	
	signal waitrequest_into_X_outof_N : std_logic := '1'; -- "wait" high by default
	signal waitrequest_into_X_outof_S : std_logic := '1';
	signal waitrequest_into_X_outof_W : std_logic := '1';
	signal waitrequest_into_X_outof_E : std_logic := '1';
	signal waitrequest_into_X_outof_LOCAL : std_logic := '1';
	
	-- test outputs
	signal waitrequest_outof_X : std_logic;
	signal writedata_outof_X : std_logic_vector(packet_size-1 downto 0);
  
  signal write_outof_X_into_N : std_logic;
	signal write_outof_X_into_S : std_logic;
	signal write_outof_X_into_W : std_logic;
	signal write_outof_X_into_E : std_logic;
	signal write_outof_X_into_LOCAL : std_logic;
  
begin
  
  -- device under test:
  dut: in_FIFO
    port map(
    		clock => clock,
		  reset => reset,
		
		  --Avalon-ish interface with neighboring core
		  writedata_into_X => writedata_into_X,
		  waitrequest_outof_X => waitrequest_outof_X,
		  write_into_X => write_into_X,
		
  		  --Avalon-ish interface with out_FIFOs
		  writedata_outof_X => writedata_outof_X,
		  waitrequest_into_X_outof_N => waitrequest_into_X_outof_N,
		  waitrequest_into_X_outof_S => waitrequest_into_X_outof_S,
		  waitrequest_into_X_outof_W => waitrequest_into_X_outof_W,
		  waitrequest_into_X_outof_E => waitrequest_into_X_outof_E,
		  waitrequest_into_X_outof_LOCAL => waitrequest_into_X_outof_LOCAL,
		
		  write_outof_X_into_N => write_outof_X_into_N,
		  write_outof_X_into_S => write_outof_X_into_S,
		  write_outof_X_into_W => write_outof_X_into_W,
		  write_outof_X_into_E => write_outof_X_into_E,
		  write_outof_X_into_LOCAL => write_outof_X_into_LOCAL
    );
    
  -- 1GHz clock
  clock_process: process
  begin
    
    clock <= '0';
    wait for clk_period/2;
    clock <= '1';
    wait for clk_period/2;
    
  end process;
  
  -- test FIFO
  test_process : process
  begin
    -- reset system
    reset <= '1';
    wait for clk_period * 2;
    reset <= '0';
    wait for clk_period * 2;
    
    -- put packets into queue
    writedata_into_X <= test_packet_A; --X"1234567887654321"
    write_into_X <= '1';
    wait until clock = '1';
    if (waitrequest_outof_X /= '0') then
      wait until waitrequest_outof_X = '0';
    end if;
    write_into_X <= '0';
    wait for clk_period/2;
    
    writedata_into_X <= test_packet_B;
    write_into_X <= '1';
    wait until clock = '1';
    if (waitrequest_outof_X /= '0') then
      wait until waitrequest_outof_X = '0';
    end if;
    write_into_X <= '0';
    wait for clk_period/2;
    
    writedata_into_X <= test_packet_C;
    write_into_X <= '1';
    wait until clock = '1';
    if (waitrequest_outof_X /= '0') then
      wait until waitrequest_outof_X = '0';
    end if;
    write_into_X <= '0';
    wait for clk_period/2;
    
    writedata_into_X <= test_packet_D;
    write_into_X <= '1';
    wait until clock = '1';
    if (waitrequest_outof_X /= '0') then
      wait until waitrequest_outof_X = '0';
    end if;
    write_into_X <= '0';
    writedata_into_X <= undriven_64;
    
    wait for clk_period * 3;
    
    -- allow a packet to exit
    waitrequest_into_X_outof_W  <= '0';
    wait for clk_period;
    waitrequest_into_X_outof_W  <= '1';
    
    wait for clk_period * 4;
 
     -- allow a packet to exit
    waitrequest_into_X_outof_W  <= '0';
    wait for clk_period;
    waitrequest_into_X_outof_W  <= '1';
    
    wait for clk_period * 10;
    
  end process;
  
end tb;