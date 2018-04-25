LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;


ENTITY multiple IS
   PORT(pixel_row, pixel_column		: IN std_logic_vector(9 DOWNTO 0);
        Red, Green,Blue 				: OUT std_logic;
        Vert_sync	: IN std_logic;
		move_left, move_right : IN STD_LOGIC;
		collide: out std_logic
		);
END multiple;


architecture behavior of multiple is

type coordArray is array (4 downto 0) of std_logic_vector(9 downto 0);
type motions is array (4 downto 0) of std_logic_vector(9 downto 0);

SIGNAL Size : std_logic_vector(9 DOWNTO 0);  
signal y_positions: coordArray;
signal x_positions: coordArray;
signal y_motions : motions;
signal rand: integer := 0;
signal isStart: std_logic := '1';
signal ball_on: std_logic;
signal new_cord: std_logic_vector(9 downto 0);
signal rand_speed: std_logic_vector(9 downto 0);
signal counter: std_logic := '1';

signal avatar_x_pos : std_logic_vector(9 downto 0) := "0101000000";
signal avatar_y_pos : std_logic_vector(9 downto 0) := "0000000000";
signal avatar_on: std_logic;


signal collision_detected: std_logic := '0';


BEGIN           
	
-- Set the size of the ball
Size <= CONV_STD_LOGIC_VECTOR(20,10);

avatar_Y_pos <= CONV_STD_LOGIC_VECTOR(440,10);

VGA: process (x_positions, y_positions, pixel_column, pixel_row, Size)
begin
	Red <=  NOT Ball_on;
	Green <= NOT Ball_on AND NOT avatar_on;
	Blue <=  NOT avatar_on;
	
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
		
		-- collision detection
--		IF (std_logic_vector(abs(signed(avatar_x_pos)-signed(x_positions(i)))) < 2 * size) AND
--		(std_logic_vector(abs(signed(avatar_y_pos)-signed(y_positions(i)))) < 2 * size)THEN
			--collision -> deduct 1 life
			
		IF((avatar_x_pos - size < x_positions(i) + size) AND (avatar_y_pos - size < y_positions(i) + size)) OR
		((avatar_x_pos + size > x_positions(i) - size) AND (avatar_y_pos - size < y_positions(i) + size)) OR
		((avatar_x_pos - size < x_positions(i) + size) AND (avatar_y_pos + size > y_positions(i) - size)) OR
		((avatar_x_pos + size > x_positions(i) - size) AND (avatar_y_pos + size > y_positions(i) - size)) THEN
			-- collision detected -> deduct 1 life
			--collision_detected <= '1';
			collide <= '1';
		else
			collide <= '0';

		end if;
		
	end loop;

	IF ('0' & avatar_X_pos <= pixel_column + Size) AND
 			-- compare positive numbers only
 	(avatar_X_pos + Size >= '0' & pixel_column) AND
 	('0' & avatar_Y_pos <= pixel_row + Size) AND
 	(avatar_Y_pos + Size >= '0' & pixel_row ) THEN
 		avatar_on <= '1';
 	ELSE
 		avatar_on <= '0';
END IF;
end process VGA;

Move_Ball: process
BEGIN
			-- Move ball once every vertical sync
	WAIT UNTIL vert_sync'event and vert_sync = '1';
		if(isStart = '1') then
			for i in y_positions' range loop
				if(i = 0) then
					y_positions(i) <= conv_std_logic_vector(20, 10);
					x_positions(i) <= conv_std_logic_vector(20, 10);
					y_motions(i) <= conv_std_logic_vector(2,10);
				elsif(i = 1) then
					y_positions(i) <= conv_std_logic_vector(60, 10);
					x_positions(i) <= conv_std_logic_vector(60, 10);
					y_motions(i) <= conv_std_logic_vector(3,10);
				elsif(i = 2) then
					y_positions(i) <= conv_std_logic_vector(100, 10);
					x_positions(i) <= conv_std_logic_vector(100, 10);
					y_motions(i) <= conv_std_logic_vector(1,10);
				elsif(i = 3) then 
					y_positions(i) <= conv_std_logic_vector(140, 10);
					x_positions(i) <= conv_std_logic_vector(140, 10);
					y_motions(i) <= conv_std_logic_vector(4,10);
				else
					y_positions(i) <= conv_std_logic_vector(180, 10);
					x_positions(i) <= conv_std_logic_vector(180, 10);
					y_motions(i) <= conv_std_logic_vector(5,10);
				end if;
			end loop;
			isStart <= '0';
		else
			for i in y_positions' range loop
				-- do transformations
				if(y_positions(i) & '0') >= 960 - Size then
					-- got to the end, re-gen coordinates
					y_positions(i) <= Size;
					x_positions(i) <= conv_std_logic_vector(rand, 10);
				else
					y_positions(i) <= y_positions(i) + y_motions(i);
				end if;
		end loop;
		end if;
			
END process Move_Ball;

Move_avatar: process
BEGIN
			-- Move ball once every vert sync
	WAIT UNTIL vert_sync'event and vert_sync = '1';
			IF move_left = '0' THEN
				IF avatar_X_pos > Size THEN
					avatar_X_pos <= avatar_X_pos - 5;
				END IF;
			ELSIF move_right = '0' THEN
				IF avatar_X_pos < 640 - Size THEN
					avatar_X_pos <= avatar_X_pos + 5;
				END IF;
			END IF;
END process Move_avatar;

Random: process(vert_sync)
variable rand_num: integer := 20;   
variable range_of_rand : integer := 600;    
begin
	if(rand + rand_num >= 1280) then
		rand <= 20 + rand_num;
	else
		rand <= rand + rand_num;
	end if;
end process Random;		

end behavior;