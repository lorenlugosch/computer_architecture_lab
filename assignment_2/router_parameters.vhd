library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package router_parameters is

	-- direction codes
	constant N : std_logic_vector(2 downto 0) := "000";
	constant S : std_logic_vector(2 downto 0) := "001";
	constant W : std_logic_vector(2 downto 0) := "010";
	constant E : std_logic_vector(2 downto 0) := "011";
	constant LOCAL : std_logic_vector(2 downto 0) := "100";
	constant NO_DEST : std_logic_vector(2 downto 0) := "111";
	constant NO_SRC : std_logic_vector(2 downto 0) := "111";

	-- useful definitions
	constant undriven_32 : std_logic_vector := "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
	constant undriven_64 : std_logic_vector := undriven_32 & undriven_32;
	constant packet_size : integer := 64;
	constant data_width : integer := 32;
	constant header_width : integer := 16;
	constant address_size : integer := 16;
	-- <header = 16 bits> <address = 16bits> | <data> --
	--  bits 63-62 = x, bits 61-60 = y
	
	-- test packets for testbenches
	constant test_packet_A : std_logic_vector := X"1234567887654321";
	constant test_packet_B : std_logic_vector := X"ABCDEFABCDEFABCD";
	constant test_packet_C : std_logic_vector := X"0000111122223333";
	constant test_packet_D : std_logic_vector := X"4444555566667777";
	constant test_packet_E : std_logic_vector := X"6444555566667777";
	
	-- components
	component destination_decoder is
		generic (
			my_x : integer := 1;
			my_y : integer := 1
		);
		port (
		  clock : in std_logic;
			dest_enable : in std_logic;
		
			x_coordinate : in integer;
			y_coordinate : in integer;
			
			destination : out std_logic_vector(2 downto 0);
			
			write_outof_X_into_N : out std_logic;
			write_outof_X_into_S : out std_logic;
			write_outof_X_into_W : out std_logic;
			write_outof_X_into_E : out std_logic;
			write_outof_X_into_LOCAL : out std_logic
		);
	end component;
	
	component reg is 
		generic(
			data_width : integer := packet_size
		);
		port (
			D : in std_logic_vector(data_width-1 downto 0);
			Q : out std_logic_vector(data_width-1 downto 0);
		
			clock : in std_logic;
			reset : in std_logic
		);
	end component;

	component STD_FIFO is
		generic (
			constant DATA_WIDTH  : positive := 64;
			constant FIFO_DEPTH	: positive := 256
		);
		port ( 
			CLK		: in  STD_LOGIC;
			RST		: in  STD_LOGIC;
			WriteEn	: in  STD_LOGIC;
			DataIn	: in  STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
			ReadEn	: in  STD_LOGIC;
			DataOut	: out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
			Empty	: out STD_LOGIC;
			Full	: out STD_LOGIC
		);
	end component;
	
	component in_FIFO_FSM is
		port (
			clock : in std_logic;
			reset : in std_logic;
			write_into_X : in std_logic;
		
			dest_enable : out std_logic;
			pop_enable : out std_logic;
			push_enable : out std_logic;
			
			queue_full : in std_logic;
			queue_empty : in std_logic;
			waitrequest : in std_logic;
		  waitrequest_outof_X : out std_logic
		);
	end component;
	
	component in_FIFO is
		generic (
			direction : std_logic_vector := NO_DEST
		);
		
		port (
			clock : in std_logic;
			reset : in std_logic;
			
			--Avalon-ish interface with neighboring core
			writedata_into_X : in std_logic_vector(packet_size-1 downto 0);
			waitrequest_outof_X : out std_logic;
			write_into_X : in std_logic;
			
			--Avalon-ish interface with out_FIFOs
			writedata_outof_X : out std_logic_vector(packet_size-1 downto 0);
			waitrequest_into_X_outof_N : in std_logic;
			waitrequest_into_X_outof_S : in std_logic;
			waitrequest_into_X_outof_W : in std_logic;
			waitrequest_into_X_outof_E : in std_logic;
			waitrequest_into_X_outof_LOCAL : in std_logic;
			
			write_outof_X_into_N : out std_logic;
			write_outof_X_into_S : out std_logic;
			write_outof_X_into_W : out std_logic;
			write_outof_X_into_E : out std_logic;
			write_outof_X_into_LOCAL : out std_logic
		);
	end component;
	
	component source_mux is
		port (
			currently_servicing : in std_logic_vector(2 downto 0);
			
			--Data from N, S, W, E, LOCAL
			writedata_outof_N : in std_logic_vector(packet_size-1 downto 0);
			writedata_outof_S : in std_logic_vector(packet_size-1 downto 0);
			writedata_outof_W : in std_logic_vector(packet_size-1 downto 0);
			writedata_outof_E : in std_logic_vector(packet_size-1 downto 0);
			writedata_outof_LOCAL : in std_logic_vector(packet_size-1 downto 0);
			
			--Data to be written to queue
			writedata : out std_logic_vector(packet_size-1 downto 0)
		);
	end component;

	component out_FIFO is
		generic (
			direction : std_logic_vector := NO_DEST
		);
		port (
			clock : in std_logic;
			reset : in std_logic;
			
			--Avalon-ish interface with neighboring core
			writedata_outof_X : out std_logic_vector(packet_size-1 downto 0);
			waitrequest_into_X : in std_logic;
			write_outof_X : out std_logic;
			
			--Avalon-ish interface with in_FIFOs
			writedata_outof_N : in std_logic_vector(packet_size-1 downto 0);
			writedata_outof_S : in std_logic_vector(packet_size-1 downto 0);
			writedata_outof_W : in std_logic_vector(packet_size-1 downto 0);
			writedata_outof_E : in std_logic_vector(packet_size-1 downto 0);
			writedata_outof_LOCAL : in std_logic_vector(packet_size-1 downto 0);
			
			write_outof_N_into_X : in std_logic;
			write_outof_S_into_X : in std_logic;
			write_outof_W_into_X : in std_logic;
			write_outof_E_into_X : in std_logic;
			write_outof_LOCAL_into_X : in std_logic;
			
			waitrequest_into_N_outof_X : out std_logic;
			waitrequest_into_S_outof_X : out std_logic;
			waitrequest_into_W_outof_X : out std_logic;
			waitrequest_into_E_outof_X : out std_logic;
			waitrequest_into_LOCAL_outof_X : out std_logic
		);
	end component;
	
	component out_FIFO_FSM is
		port (
			clock : in std_logic;
			reset : in std_logic;
			
			waitrequest_into_X : in std_logic;
			write_outof_X : out std_logic;
			
			write_outof_N_into_X : in std_logic;
			write_outof_S_into_X : in std_logic;
			write_outof_W_into_X : in std_logic;
			write_outof_E_into_X : in std_logic;
			write_outof_LOCAL_into_X : in std_logic;
			
			waitrequest_into_N_outof_X : out std_logic;
			waitrequest_into_S_outof_X : out std_logic;
			waitrequest_into_W_outof_X : out std_logic;
			waitrequest_into_E_outof_X : out std_logic;
			waitrequest_into_LOCAL_outof_X : out std_logic;
			
			currently_servicing : out std_logic_vector(2 downto 0);
			queue_empty : in std_logic;
			queue_full : in std_logic;
			push_enable : out std_logic;
			pop_enable : out std_logic
		);
	end component;
	
	component router_on_chip is
	generic (
		my_x : integer := 1;
		my_y : integer := 1
	);
	
	port (
		clock : in std_logic;
		reset : in std_logic;
	
		-- data from neighbors to here
		N_in : in std_logic_vector(packet_size-1 downto 0);
		S_in : in std_logic_vector(packet_size-1 downto 0);
		W_in : in std_logic_vector(packet_size-1 downto 0);
		E_in : in std_logic_vector(packet_size-1 downto 0);
		LOCAL_in : in std_logic_vector(packet_size-1 downto 0);
		
		-- data from here to neighbors
		N_out : out std_logic_vector(packet_size-1 downto 0);
		S_out : out std_logic_vector(packet_size-1 downto 0);
		W_out : out std_logic_vector(packet_size-1 downto 0);
		E_out : out std_logic_vector(packet_size-1 downto 0);
		LOCAL_out : out std_logic_vector(packet_size-1 downto 0);
		
		-- wait signals from neighbors to here
		waitrequest_into_N : in std_logic;
		waitrequest_into_S : in std_logic;
		waitrequest_into_W : in std_logic;
		waitrequest_into_E : in std_logic;
		waitrequest_into_LOCAL : in std_logic;
		
		-- wait signals from here to neighbors
		waitrequest_outof_N : out std_logic;
		waitrequest_outof_S : out std_logic;
		waitrequest_outof_W : out std_logic;
		waitrequest_outof_E : out std_logic;
		waitrequest_outof_LOCAL : out std_logic;
		
		-- write signals from neighbors to here
		write_into_N : in std_logic;
		write_into_S : in std_logic;
		write_into_W : in std_logic;
		write_into_E : in std_logic;
		write_into_LOCAL : in std_logic;
		
		-- write signals from here to neighbors
		write_outof_N : out std_logic;
		write_outof_S : out std_logic;
		write_outof_W : out std_logic;
		write_outof_E : out std_logic;
		write_outof_LOCAL : out std_logic
	);
end component;
	
end router_parameters;