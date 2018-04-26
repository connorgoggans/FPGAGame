LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.ALL;


ENTITY obstacles IS


	PORT
	(
    -- Clocks
    
    CLOCK_50	: IN STD_LOGIC;  -- 50 MHz
 
    -- Buttons 
    
    KEY 		: IN STD_LOGIC_VECTOR (3 downto 0);         -- Push buttons

    -- Input switches
    
    SW 			: IN STD_LOGIC_VECTOR (17 downto 0);         -- DPDT switches
	 
	 -- LED
	 
	 LEDR			: OUT STD_Logic_vector (17 downto 0);

    -- VGA output
    
    VGA_BLANK_N : out std_logic;            -- BLANK
    VGA_CLK 	 : out std_logic;            -- Clock
    VGA_HS 		 : out std_logic;            -- H_SYNC
    VGA_SYNC_N  : out std_logic;            -- SYNC
    VGA_VS 		 : out std_logic;            -- V_SYNC
    VGA_R 		 : out unsigned(7 downto 0); -- Red[9:0]
    VGA_G 		 : out unsigned(7 downto 0); -- Green[9:0]
    VGA_B 		 : out unsigned(7 downto 0); -- Blue[9:0]

	-- 16 X 2 LCD Module
    LCD_BLON : out std_logic;      							-- Back Light ON/OFF
    LCD_EN   : out std_logic;      							-- Enable
    LCD_ON   : out std_logic;      							-- Power ON/OFF
    LCD_RS   : out std_logic;	   							-- Command/Data Select, 0 = Command, 1 = Data
    LCD_RW   : out std_logic; 	   						-- Read/Write Select, 0 = Write, 1 = Read
    LCD_DATA : inout std_logic_vector(7 downto 0) 	-- Data bus 8 bits

	);
END obstacles;


-- Architecture body 
-- 		Describes the functionality or internal implementation of the entity

ARCHITECTURE structural OF obstacles IS

COMPONENT VGA_SYNC_module

	PORT(	clock_50Mhz, red, green, blue		: IN	STD_LOGIC;
			red_out, green_out, blue_out, horiz_sync_out, 
			vert_sync_out, video_on, pixel_clock	: OUT	STD_LOGIC;
			pixel_row, pixel_column: OUT STD_LOGIC_VECTOR(9 DOWNTO 0));

END COMPONENT;

COMPONENT multiple

   PORT(pixel_row, pixel_column		: IN std_logic_vector(9 DOWNTO 0);
        Red, Green,Blue 				: OUT std_logic;
        Vert_sync	: IN std_logic;
		  move_left, move_right: IN std_logic;
		  score   : out std_logic_vector(19 downto 0);
		  lives	 : out std_logic_vector(3 downto 0);
		  level   : out std_logic_vector(3 downto 0)
		  );
   
END COMPONENT;


COMPONENT LCD_Display

	GENERIC(Num_Hex_Digits: Integer:= 4);
	
	PORT(reset					: IN	STD_LOGIC;
	     clk_50MHz				: IN	STD_LOGIC;
		  Hex_Display_Lives	: IN    std_logic_vector(3 downto 0); --STD_LOGIC_VECTOR((Num_Hex_Digits*4)-1 DOWNTO 0);
		  Hex_Display_Level	: IN 	std_logic_vector(3 downto 0);
		  Hex_Display_Score	: IN std_logic_vector(19 downto 0);
		  LCD_RS					: OUT	STD_LOGIC;
		  LCD_E					: OUT	STD_LOGIC;
		  LCD_RW					: OUT   STD_LOGIC;
		  DATA_BUS				: INOUT	STD_LOGIC_VECTOR(7 DOWNTO 0)
		 );

END COMPONENT;



SIGNAL red_int : STD_LOGIC;
SIGNAL green_int : STD_LOGIC;
SIGNAL blue_int : STD_LOGIC;
SIGNAL video_on_int : STD_LOGIC;
SIGNAL vert_sync_int : STD_LOGIC;
SIGNAL horiz_sync_int : STD_LOGIC; 
SIGNAL pixel_clock_int : STD_LOGIC;
SIGNAL pixel_row_int :STD_LOGIC_VECTOR(9 DOWNTO 0); 
SIGNAL pixel_column_int :STD_LOGIC_VECTOR(9 DOWNTO 0);

signal lives_counter : std_logic_vector(3 downto 0);
signal level_counter : std_logic_vector(3 downto 0);
signal score_counter : std_logic_vector(19 downto 0); 
signal rand : std_logic_vector(9 downto 0);

BEGIN

	VGA_R(6 DOWNTO 0) <= "0000000";
	VGA_G(6 DOWNTO 0) <= "0000000";
	VGA_B(6 DOWNTO 0) <= "0000000";

	VGA_HS <= horiz_sync_int;
	VGA_VS <= vert_sync_int;


	U1: VGA_SYNC_module PORT MAP
		(clock_50Mhz		=>	CLOCK_50,
		 red					=>	red_int,
		 green				=>	green_int,	
		 blue					=>	blue_int,
		 red_out				=>	VGA_R(7),
		 green_out			=>	VGA_G(7),
		 blue_out			=>	VGA_B(7),
		 horiz_sync_out	=>	horiz_sync_int,
		 vert_sync_out		=>	vert_sync_int,
		 video_on			=>	VGA_BLANK_N,
		 pixel_clock		=>	VGA_CLK,
		 pixel_row			=>	pixel_row_int,
		 pixel_column		=>	pixel_column_int
		);
		
		U2: multiple PORT MAP
		(pixel_row		=> pixel_row_int,
		 pixel_column	=> pixel_column_int,
		 Green			=> green_int,
		 Blue		    => blue_int,
		 Vert_sync		=> vert_sync_int,
		 move_left      => KEY(2),
		 move_right     => KEY(1),
		 score			=> score_counter,
		 level			=> level_counter,
		 lives			=> lives_counter
		);

		LCD_ON   <= '1';
		LCD_BLON <= '1';


		U3: LCD_Display PORT MAP
		(reset				=>	NOT SW(17),
		 clk_50MHz			=>	CLOCK_50,
		 Hex_Display_Lives	=>	lives_counter,
		 Hex_Display_Level => level_counter,
		 Hex_Display_Score => score_counter,
		 LCD_RS				=>	LCD_RS,
		 LCD_E				=>	LCD_EN,
		 LCD_RW				=>	LCD_RW,
		 DATA_BUS			=>	LCD_DATA
		);
		
--		U4: lfsr_9_bit port map
--		(i_clk    => CLOCK_50;
--		 i_rstb       => '1';
--		 i_sync_reset  => '0';
--       i_seed          => "010101010";
--       i_en            => '1';
--       o_lsfr          => rand);

END structural;
