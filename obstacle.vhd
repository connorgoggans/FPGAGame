LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;
use  ieee.math_real.all;


ENTITY obstacle IS
   PORT(pixel_row, pixel_column		: IN std_logic_vector(9 DOWNTO 0);
        Red,Green,Blue 				: OUT std_logic;
        Vert_sync	: IN std_logic
		  );
END obstacle;


architecture behavior of obstacle is

type coordArray is array (3 downto 0) of std_logic_vector(9 downto 0);
type randNums is array (10 downto 0) of integer;

SIGNAL Size : std_logic_vector(9 DOWNTO 0);  
signal y_positions: coordArray;
signal x_positions: coordArray;
signal y_motion : std_logic_vector(9 downto 0) := conv_std_logic_vector(2, 10);
signal rand: integer := 0;
signal isStart: std_logic := '1';
signal ball_on: std_logic;
signal new_cord: std_logic_vector(9 downto 0);


BEGIN           
	
-- Set the size of the ball
Size <= CONV_STD_LOGIC_VECTOR(20,10);

VGA: process (x_positions, y_positions, pixel_column, pixel_row, Size)
begin
	Red <=  NOT Ball_on;
	Green <= NOT Ball_on;
	Blue <=  '1';
	
	ball_on <= '0';
	for i in y_positions' range loop
		-- set RGB for each active ball
		 IF ('0' & x_positions(i) <= pixel_column + Size) AND
				-- compare positive numbers only
		(x_positions(i) + Size >= '0' & pixel_column) AND
		('0' & y_positions(i) <= pixel_row + Size) AND
		(y_positions(i) + Size >= '0' & pixel_row ) THEN
			Ball_on <= '1';
--		ELSE
--			Ball_on <= '0';
		end if;
	end loop;
end process VGA;

Move_Ball: process
BEGIN
			-- Move ball once every vertical sync
	WAIT UNTIL vert_sync'event and vert_sync = '1';
			if(isStart = '1') then
				isStart <= '0';
				for i in y_positions' range loop
					-- do transformations
					y_positions(i) <= Size;
					new_cord <= conv_std_logic_vector(rand, 10);
					x_positions(i) <= new_cord + Size;
				end loop;
--				isStart <= '0';
			else
				for i in y_positions' range loop
					-- do transformations
					if(y_positions(i) & '0') >= 800 - Size then
						-- got to the end, re-gen coordinates
						y_positions(i) <= Size;
						new_cord <= conv_std_logic_vector(rand, 10);
						x_positions(i) <= new_cord + Size;
					else
						y_positions(i) <= y_positions(i) + y_motion;
					end if;
				end loop;
			end if;
			
END process Move_Ball;

Random: process(vert_sync)
--variable seed1, seed2: positive;               -- seed values for random generator
variable rand_num: integer := 20;   -- random real-number value in range 0 to 1.0  
variable range_of_rand : integer := 600;    -- the range of random values created will be 0 to +600.
begin
	 --wait until vert_sync'event and vert_sync = '1';
    --uniform(seed1, seed2, rand_num);   -- generate random number
    --rand <= integer(rand_num*range_of_rand);  -- rescale to 0..1000, convert integer part
	if(rand + rand_num >= 600) then
		rand <= 20 + rand_num;
	else
		rand <= rand + rand_num;
	end if;
end process;

END behavior;
