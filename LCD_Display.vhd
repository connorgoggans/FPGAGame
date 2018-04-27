library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;

entity LCD_Display is
	-- Enter number of live Hex hardware data values to display
	-- (do not count ASCII character constants)
	-----------------------------------------------------------------------
	-- LCD Displays 16 Characters on 2 lines
	-- LCD_display string is an ASCII character string entered in hex for
	-- the two lines of the LCD Display (See ASCII to hex table below)
	-- Edit LCD_Display_String entries above to modify display
	-- Enter the ASCII character's 2 hex digit equivalent value
	-- (see table below for ASCII hex values)
	-- To display character assign ASCII value to LCD_display_string(x)
	-- To skip a character use X"20" (ASCII space)
	-- To dislay "live" hex values from hardware on LCD use the following:
	-- make array element for that character location X"0" & 4-bit field from Hex_Display_Data
	-- state machine sees X"0" in high 4-bits & grabs the next lower 4-bits from Hex_Display_Data input
	-- and performs 4-bit binary to ASCII conversion needed to print a hex digit
	-- Num_Hex_Digits must be set to the count of hex data characters (ie. "00"s) in the display
	-- Connect hardware bits to display to Hex_Display_Data input
	-- To display less than 32 characters, terminate string with an entry of X"FE"
	-- (fewer characters may slightly increase the LCD's data update rate)
	-------------------------------------------------------------------
	-- ASCII HEX TABLE
	-- Hex Low Hex Digit
	-- Value 0 1 2 3 4 5 6 7 8 9 A B C D E F
	------\----------------------------------------------------------------
	--H 2 | SP ! " # $ % & ' () * + , - . /
	--i 3 | 0 1 2 3 4 5 6 7 8 9 :; < = > ?
	--g 4 | @ A B C D E F G H I J K L M N O
	--h 5 | P Q R S T U V W X Y Z [ \ ] ^ _
	-- 6  | ` a b c d e f g h i j k l m n o
	-- 7  | p q r s t u v w x y z { | } ~ DEL
	-----------------------------------------------------------------------
	-- Example "A" is row 4 column 1, so hex value is X"41"
	-- *see LCD Controller's Datasheet for other graphics characters available
	--
	port (
		reset, clk_50MHz  : in STD_LOGIC;
		Hex_Display_Lives : in std_logic_vector(3 downto 0);
		Hex_Display_Level : in std_logic_vector(3 downto 0);
		Hex_Display_Score : in std_logic_vector(19 downto 0);
		LCD_RS, LCD_E     : out STD_LOGIC;
		LCD_RW            : out STD_LOGIC;
		DATA_BUS          : inout STD_LOGIC_VECTOR(7 downto 0);
		score					: in integer
	);
 
end entity LCD_Display;

architecture a of LCD_Display is

	type character_string is array (0 to 31) of STD_LOGIC_VECTOR(7 downto 0);

	type STATE_TYPE is (HOLD, FUNC_SET, DISPLAY_ON, MODE_SET, Print_String, 
	LINE2, RETURN_HOME, DROP_LCD_E, RESET1, RESET2, 
	RESET3, DISPLAY_OFF, DISPLAY_CLEAR);
	signal state, next_command : STATE_TYPE;
	signal LCD_display_string  : character_string;

	-- Enter new ASCII hex data above for LCD Display
	signal DATA_BUS_VALUE, Next_Char    : STD_LOGIC_VECTOR(7 downto 0);
	signal CLK_COUNT_400HZ              : STD_LOGIC_VECTOR(19 downto 0);
	signal CHAR_COUNT                   : STD_LOGIC_VECTOR(4 downto 0);
	signal CLK_400HZ_Enable, LCD_RW_INT : STD_LOGIC;
	signal Line1_chars, Line2_chars     : STD_LOGIC_VECTOR(127 downto 0);

	signal score_out : std_logic_vector(19 downto 0);
	

begin


--	conv_score:process(score)
--		variable count:integer:=0;
--		variable loopDef: std_logic_vector(4 downto 0);
--		variable score_int: integer := 23451;
--		variable digit: integer;
--	BEGIN
--		for i in loopDef' range loop
--			digit := score_int mod 10;
--			score_int := score_int/10;
--			count := i * 4;
--			
--			if(digit = 1) then
--				score_out(count+3 downto count) <= conv_std_logic_vector(1, 4);
--			elsif(digit = 2) then
--				score_out(count+3 downto count) <= conv_std_logic_vector(2, 4);
--			elsif(digit = 3) then
--				score_out(count+3 downto count) <= conv_std_logic_vector(3, 4);
--			elsif(digit = 4) then
--				score_out(count+3 downto count) <= conv_std_logic_vector(4, 4);
--			elsif(digit = 5) then
--				score_out(count+3 downto count) <= conv_std_logic_vector(5, 4);
--			elsif(digit = 6) then
--				score_out(count+3 downto count) <= conv_std_logic_vector(6, 4);
--			elsif(digit = 7) then
--				score_out(count+3 downto count) <= conv_std_logic_vector(7, 4);
--			elsif(digit = 8) then
--				score_out(count+3 downto count) <= conv_std_logic_vector(8, 4);
--			elsif(digit = 9) then
--				score_out(count+3 downto count) <= conv_std_logic_vector(9, 4);
--			else
--				score_out(count+3 downto count) <= conv_std_logic_vector(2, 4);
--			end if;
--			
--	 	end loop;
--
--END PROCESS conv_score;



	LCD_display_string <= (
		-- ASCII hex values for LCD Display
		-- Enter Live Hex Data Values from hardware here
		-- LCD DISPLAYS THE FOLLOWING:
		------------------------------
		--| LIVES: X LEVEL: X |
		--| SCORE: XXXXX |
		------------------------------
		-- Line 1
		X"4C", X"49", X"56", X"45", X"53", X"3A", X"0" & Hex_Display_Lives(3 downto 0), X"20", 
		X"4C", X"45", X"56", X"45", X"4C", X"3A", X"0" & Hex_Display_Level(3 downto 0), X"20", 
		-- Line 2
		X"53", X"43", X"4F", X"52", X"45", X"3A", X"0" & Hex_Display_Score(19 downto 16), 
		X"0" & Hex_Display_Score(15 downto 12), 
		X"0" & Hex_Display_Score(11 downto 8), 
		X"0" & Hex_Display_Score(7 downto 4), 
		X"0" & Hex_Display_Score(3 downto 0), 
		X"20", X"20", X"20", X"20", X"20");

--		X"53", X"43", X"4F", X"52", X"45", X"3A", X"0" & score_out(19 downto 16), 
--		X"0" & score_out(15 downto 12), 
--		X"0" & score_out(11 downto 8), 
--		X"0" & score_out(7 downto 4), 
--		X"0" & score_out(3 downto 0), 
--		X"20", X"20", X"20", X"20", X"20");
		

		--

		-- BIDIRECTIONAL TRI STATE LCD DATA BUS
		DATA_BUS <= DATA_BUS_VALUE when LCD_RW_INT = '0' else "ZZZZZZZZ";
		-- get next character in display string
		Next_Char <= LCD_display_string(CONV_INTEGER(CHAR_COUNT));
		LCD_RW    <= LCD_RW_INT;

		process
	begin
		wait until clk_50MHz'EVENT and clk_50MHz = '1';
		if RESET = '0' then
			CLK_COUNT_400HZ  <= X"00000";
			CLK_400HZ_Enable <= '0';
		else
			if CLK_COUNT_400HZ < X"0F424" then
				CLK_COUNT_400HZ  <= CLK_COUNT_400HZ + 1;
				CLK_400HZ_Enable <= '0';
			else
				CLK_COUNT_400HZ  <= X"00000";
				CLK_400HZ_Enable <= '1';
			end if;
		end if;
	end process;
	process (clk_50MHz, reset)
		begin
			if reset = '0' then
				state          <= RESET1;
				DATA_BUS_VALUE <= X"38";
				next_command   <= RESET2;
				LCD_E          <= '1';
				LCD_RS         <= '0';
				LCD_RW_INT     <= '1';

 
			elsif clk_50MHz'EVENT and clk_50MHz = '1' then
				-- State Machine to send commands and data to LCD DISPLAY 
				if CLK_400HZ_Enable = '1' then
					case state is
						-- Set Function to 8-bit transfer and 2 line display with 5x8 Font size
						-- see Hitachi HD44780 family data sheet for LCD command and timing details
						when RESET1 => 
							LCD_E          <= '1';
							LCD_RS         <= '0';
							LCD_RW_INT     <= '0';
							DATA_BUS_VALUE <= X"38";
							state          <= DROP_LCD_E;
							next_command   <= RESET2;
							CHAR_COUNT     <= "00000";
						when RESET2 => 
							LCD_E          <= '1';
							LCD_RS         <= '0';
							LCD_RW_INT     <= '0';
							DATA_BUS_VALUE <= X"38";
							state          <= DROP_LCD_E;
							next_command   <= RESET3;
						when RESET3 => 
							LCD_E          <= '1';
							LCD_RS         <= '0';
							LCD_RW_INT     <= '0';
							DATA_BUS_VALUE <= X"38";
							state          <= DROP_LCD_E;
							next_command   <= FUNC_SET;
							-- EXTRA STATES ABOVE ARE NEEDED FOR RELIABLE PUSHBUTTON RESET OF LCD
						when FUNC_SET => 
							LCD_E          <= '1';
							LCD_RS         <= '0';
							LCD_RW_INT     <= '0';
							DATA_BUS_VALUE <= X"38";
							state          <= DROP_LCD_E;
							next_command   <= DISPLAY_OFF;
							-- Turn off Display and Turn off cursor
						when DISPLAY_OFF => 
							LCD_E          <= '1';
							LCD_RS         <= '0';
							LCD_RW_INT     <= '0';
							DATA_BUS_VALUE <= X"08";
							state          <= DROP_LCD_E;
							next_command   <= DISPLAY_CLEAR;
							-- Clear Display and Turn off cursor
						when DISPLAY_CLEAR => 
							LCD_E          <= '1';
							LCD_RS         <= '0';
							LCD_RW_INT     <= '0';
							DATA_BUS_VALUE <= X"01";
							state          <= DROP_LCD_E;
							next_command   <= DISPLAY_ON;
							-- Turn on Display and Turn off cursor
						when DISPLAY_ON => 
							LCD_E          <= '1';
							LCD_RS         <= '0';
							LCD_RW_INT     <= '0';
							DATA_BUS_VALUE <= X"0C";
							state          <= DROP_LCD_E;
							next_command   <= MODE_SET;
							-- Set write mode to auto increment address and move cursor to the right
						when MODE_SET => 
							LCD_E          <= '1';
							LCD_RS         <= '0';
							LCD_RW_INT     <= '0';
							DATA_BUS_VALUE <= X"06";
							state          <= DROP_LCD_E;
							next_command   <= Print_String;
							-- Write ASCII hex character in first LCD character location
						when Print_String => 
							state      <= DROP_LCD_E;
							LCD_E      <= '1';
							LCD_RS     <= '1';
							LCD_RW_INT <= '0';
							-- ASCII character to output
							if Next_Char(7 downto 4) /= X"0" then
								DATA_BUS_VALUE <= Next_Char;
							else
								-- Convert 4-bit value to an ASCII hex digit
								if Next_Char(3 downto 0) > 9 then
									-- ASCII A...F
									DATA_BUS_VALUE <= X"4" & (Next_Char(3 downto 0) - 9);
								else
									-- ASCII 0...9
									DATA_BUS_VALUE <= X"3" & Next_Char(3 downto 0);
								end if;
							end if;
							state <= DROP_LCD_E;
							-- Loop to send out 32 characters to LCD Display (16 by 2 lines)
							if (CHAR_COUNT < 31) and (Next_Char /= X"FE") then
								CHAR_COUNT <= CHAR_COUNT + 1;
							else
								CHAR_COUNT <= "00000";
							end if;
							-- Jump to second line?
							if CHAR_COUNT = 15 then
								next_command <= line2;
								-- Return to first line?
							elsif (CHAR_COUNT = 31) or (Next_Char = X"FE") then
								next_command <= return_home;
							else
								next_command <= Print_String;
							end if;
							-- Set write address to line 2 character 1
						when LINE2 => 
							LCD_E          <= '1';
							LCD_RS         <= '0';
							LCD_RW_INT     <= '0';
							DATA_BUS_VALUE <= X"C0";
							state          <= DROP_LCD_E;
							next_command   <= Print_String;
							-- Return write address to first character postion on line 1
						when RETURN_HOME => 
							LCD_E          <= '1';
							LCD_RS         <= '0';
							LCD_RW_INT     <= '0';
							DATA_BUS_VALUE <= X"80";
							state          <= DROP_LCD_E;
							next_command   <= Print_String;
							-- The next three states occur at the end of each command or data transfer to the LCD
							-- Drop LCD E line - falling edge loads inst/data to LCD controller
						when DROP_LCD_E => 
							LCD_E <= '0';
							state <= HOLD;
							-- Hold LCD inst/data valid after falling edge of E line 
						when HOLD => 
							state <= next_command;
					end case;
				end if;
			end if;
		end process;

end a;