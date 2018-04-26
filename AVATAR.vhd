LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

entity avatar is
	port (move_left, move_right 	: IN STD_LOGIC;
		  pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
		  Red 						: OUT std_logic;
          Horiz_sync				: IN std_logic);
end avatar;

architecture behavior of avatar is
	
SIGNAL Ball_on, Direction	: std_logic;
SIGNAL Size 				: std_logic_vector(9 DOWNTO 0);  
SIGNAL Ball_X_pos			: std_logic_vector(9 DOWNTO 0) := "0101000000";
SIGNAL Ball_Y_pos			: std_logic_vector(9 DOWNTO 0) := "0000000000";
	
BEGIN
  
Size <= CONV_STD_LOGIC_VECTOR(20,10);
Ball_Y_pos <= CONV_STD_LOGIC_VECTOR(440,10);
--Ball_X_pos <= CONV_STD_LOGIC_VECTOR(320,10);
	
	-- Colors for pixel data on video signal
Red <=  '1';


RGB_Display: Process (Ball_X_pos, Ball_Y_pos, pixel_column, pixel_row, Size)
BEGIN
			-- Set Ball_on ='1' to display ball
 IF ('0' & Ball_X_pos <= pixel_column + Size) AND
 			-- compare positive numbers only
 	(Ball_X_pos + Size >= '0' & pixel_column) AND
 	('0' & Ball_Y_pos <= pixel_row + Size) AND
 	(Ball_Y_pos + Size >= '0' & pixel_row ) THEN
 		Ball_on <= '1';
 	ELSE
 		Ball_on <= '0';
END IF;
END process RGB_Display;

Move_Ball: process
BEGIN
			-- Move ball once every horiz sync
	WAIT UNTIL horiz_sync'event and horiz_sync = '1';
			IF move_left = '0' THEN
				IF Ball_X_pos > Size THEN
					Ball_X_pos <= Ball_X_pos - 5;
				END IF;
			ELSIF move_right = '0' THEN
				IF Ball_X_pos < 640 - Size THEN
					Ball_X_pos <= Ball_X_pos + 5;
				END IF;
			END IF;
END process Move_Ball;
	
END behavior;
