LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;


ENTITY multiple IS

   PORT(pixel_row, pixel_column	: in std_logic_vector(9 DOWNTO 0);
        Red, Green,Blue 		: out std_logic;
        Vert_sync				: in std_logic;
		move_left, move_right	: in std_logic;
		score					: out std_logic_vector(19 downto 0);
		lives					: out std_logic_vector(3 downto 0);
		level					: out std_logic_vector(3 downto 0);
		--rand_pos: in std_logic_vector(9 downto 0);
		clock: in std_logic
		);
END multiple;


architecture behavior of multiple is

type coordArray is array (4 downto 0) of std_logic_vector(9 downto 0);
type motions is array (4 downto 0) of std_logic_vector(9 downto 0);


SIGNAL Size : std_logic_vector(9 DOWNTO 0);  
signal y_positions: coordArray;
signal x_positions: coordArray;
signal y_motions : motions;
signal isStart: std_logic := '1';
signal ball_on: std_logic;


-- signals to keep track of player's avatar --
signal avatar_x_pos		: std_logic_vector(9 downto 0) := "0101000000";
signal avatar_y_pos		: std_logic_vector(9 downto 0) := conv_std_logic_vector(440,10);
signal avatar_on		: std_logic;

-- signals to keep track of extra life token --
signal life_Size		: std_logic_vector(9 DOWNTO 0);
signal life_x_pos		: std_logic_vector(9 downto 0) := conv_std_logic_vector(70, 10); 
signal life_y_pos		: std_logic_vector(9 downto 0) := life_size;
signal life_on			: std_logic;
signal life_speed		: std_logic_vector(9 downto 0):= conv_std_logic_vector(4,10);
signal toggle_life		: std_logic := '0';

-- signals to keep track of player status --
signal score_counter	: integer := 0;
signal lives_counter	: integer := 3;
signal level_counter	: integer := 0;
signal score_multiplier	: integer := 10;

-- signal to store random number --
signal rand				: integer := 0;

BEGIN           
	
-- Set the size of the ball and extra life token
Size <= CONV_STD_LOGIC_VECTOR(20,10);
life_Size <= CONV_STD_LOGIC_VECTOR(10,10);

--avatar_Y_pos <= CONV_STD_LOGIC_VECTOR(440,10);

VGA: process (x_positions, y_positions, pixel_column, pixel_row, Size)
begin
	Red <=  NOT Ball_on and not life_on;
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

	-- extra life token --
	IF ('0' & life_X_pos <= pixel_column + life_Size) AND
 			-- compare positive numbers only
 	(life_X_pos + life_Size >= '0' & pixel_column) AND
 	('0' & life_Y_pos <= pixel_row + life_Size) AND
 	(life_Y_pos + life_Size >= '0' & pixel_row ) THEN
 		life_on <= '1';
 	ELSE
 		life_on <= '0';
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
					y_motions(i) <= conv_std_logic_vector(3,10);
				elsif(i = 1) then
					y_positions(i) <= conv_std_logic_vector(60, 10);
					x_positions(i) <= conv_std_logic_vector(60, 10);
					y_motions(i) <= conv_std_logic_vector(4,10);
				elsif(i = 2) then
					y_positions(i) <= conv_std_logic_vector(100, 10);
					x_positions(i) <= conv_std_logic_vector(100, 10);
					y_motions(i) <= conv_std_logic_vector(2,10);
				elsif(i = 3) then 
					y_positions(i) <= conv_std_logic_vector(140, 10);
					x_positions(i) <= conv_std_logic_vector(140, 10);
					y_motions(i) <= conv_std_logic_vector(5,10);
				else
					y_positions(i) <= conv_std_logic_vector(180, 10);
					x_positions(i) <= conv_std_logic_vector(180, 10);
					y_motions(i) <= conv_std_logic_vector(6,10);
				end if;
			end loop;
			isStart <= '0';
		else
			for i in y_positions' range loop
				-- do transformations
				if(y_positions(i) & '0') >= 960 - Size then
					-- got to the end, re-gen coordinates
					y_positions(i) <= Size;
					x_positions(i) <= conv_std_logic_vector(rand, 10);--rand_pos;
					score_counter <= score_counter + score_multiplier;
					score <= conv_std_logic_vector(score_counter, 20);
				else
					y_positions(i) <= y_positions(i) + y_motions(i);
				end if;
			end loop;
		end if;

			-- movement for extra life token --
		if(life_y_pos & '0') >= 960 - life_Size then
			-- got to the end, re-gen coordinates
			if(toggle_life = '0') then
				--put life on screen--
				life_y_pos <= life_size;
				life_x_pos <= conv_std_logic_vector(rand, 10);
				life_speed <= conv_std_logic_vector(4,10);
			else
				--put life off screen--
				life_y_pos <= life_size;
				life_x_pos <= conv_std_logic_vector(800, 10);
				life_speed <= conv_std_logic_vector(1,10);
			end if;
			toggle_life <= not toggle_life;
		else
			life_y_pos <= life_y_pos + life_speed;
		end if;
		
		if ((avatar_x_pos - size < x_positions(0) + size) AND (avatar_x_pos + size > x_positions(0) - size) 
		AND (avatar_y_pos - size < y_positions(0) + size) AND (avatar_y_pos + size > y_positions(0) - size)) then
			if(lives_counter > 0) then
				lives_counter <= lives_counter - 1;
			end if;
			y_positions(0) <= size;
			x_positions(0) <= conv_std_logic_vector(rand, 10);
		elsif((avatar_x_pos - size < x_positions(1) + size) AND (avatar_x_pos + size > x_positions(1) - size) 
		AND (avatar_y_pos - size < y_positions(1) + size) AND (avatar_y_pos + size > y_positions(1) - size)) then
			if(lives_counter > 0) then
				lives_counter <= lives_counter - 1;
			end if;
			y_positions(1) <= size;
			x_positions(1) <= conv_std_logic_vector(rand, 10);
		elsif((avatar_x_pos - size < x_positions(2) + size) AND (avatar_x_pos + size > x_positions(2) - size) 
		AND (avatar_y_pos - size < y_positions(2) + size) AND (avatar_y_pos + size > y_positions(2) - size)) then
			if(lives_counter > 0) then
				lives_counter <= lives_counter - 1;
			end if;
			y_positions(2) <= size;
			x_positions(2) <= conv_std_logic_vector(rand, 10);
		elsif((avatar_x_pos - size < x_positions(3) + size) AND (avatar_x_pos + size > x_positions(3) - size) 
		AND (avatar_y_pos - size < y_positions(3) + size) AND (avatar_y_pos + size > y_positions(3) - size)) then
			if(lives_counter > 0) then
				lives_counter <= lives_counter - 1;
			end if;
			y_positions(3) <= size;
			x_positions(3) <= conv_std_logic_vector(rand, 10);
		elsif((avatar_x_pos - size < x_positions(4) + size) AND (avatar_x_pos + size > x_positions(4) - size) 
		AND (avatar_y_pos - size < y_positions(4) + size) AND (avatar_y_pos + size > y_positions(4) - size)) then
			if(lives_counter > 0) then
				lives_counter <= lives_counter - 1;
			end if;
			y_positions(4) <= size;
			x_positions(4) <= conv_std_logic_vector(rand, 10);
		elsif ((avatar_x_pos - size < life_x_pos + size) AND (avatar_x_pos + size > life_x_pos - size) 
		AND (avatar_y_pos - size < life_y_pos + size) AND (avatar_y_pos + size > life_y_pos - size)) then
			-- collision with extra life token, add life --
			lives_counter <= lives_counter + 1;
			life_y_pos <= life_size;
			life_x_pos <= conv_std_logic_vector(800, 10);
			toggle_life <= '1';
		end if;
		
		--write to the lives
		lives <= conv_std_logic_vector(lives_counter, 4);
		
		if(lives_counter <= 0) then
			y_motions(0) <= conv_std_logic_vector(0, 10);
			y_motions(1) <= conv_std_logic_vector(0, 10);
			y_motions(2) <= conv_std_logic_vector(0, 10);
			y_motions(3) <= conv_std_logic_vector(0, 10);
			y_motions(4) <= conv_std_logic_vector(0, 10);
		end if;
		
		if(score_counter = 400) then
			y_motions(0) <= conv_std_logic_vector(4, 10);
			y_motions(1) <= conv_std_logic_vector(5, 10);
			y_motions(2) <= conv_std_logic_vector(3, 10);
			y_motions(3) <= conv_std_logic_vector(6, 10);
			y_motions(4) <= conv_std_logic_vector(7, 10);
			level_counter <= 2;
			level <= conv_std_logic_vector(level_counter, 4);
		elsif(score_counter = 800) then
			y_motions(0) <= conv_std_logic_vector(5, 10);
			y_motions(1) <= conv_std_logic_vector(6, 10);
			y_motions(2) <= conv_std_logic_vector(4, 10);
			y_motions(3) <= conv_std_logic_vector(7, 10);
			y_motions(4) <= conv_std_logic_vector(8, 10);
			level_counter <= 3;
			level <= conv_std_logic_vector(level_counter, 4);
		elsif(score_counter = 1200) then
			y_motions(0) <= conv_std_logic_vector(6, 10);
			y_motions(1) <= conv_std_logic_vector(7, 10);
			y_motions(2) <= conv_std_logic_vector(5, 10);
			y_motions(3) <= conv_std_logic_vector(8, 10);
			y_motions(4) <= conv_std_logic_vector(9, 10);
			level_counter <= 4;
			level <= conv_std_logic_vector(level_counter, 4);
		elsif(score_counter = 1600) then
			y_motions(0) <= conv_std_logic_vector(7, 10);
			y_motions(1) <= conv_std_logic_vector(8, 10);
			y_motions(2) <= conv_std_logic_vector(6, 10);
			y_motions(3) <= conv_std_logic_vector(9, 10);
			y_motions(4) <= conv_std_logic_vector(10, 10);
			level_counter <= 5;
			level <= conv_std_logic_vector(level_counter, 4);
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
begin
	if(rand + rand_num >= 1280) then
		rand <= 20 + rand_num;
	else
		rand <= rand + rand_num;
	end if;
end process Random;		

--Random: process(clock)
--begin
--	if(rising_edge(clock)) then
--		rand <= rand + 1;
--		if(rand >= 1280) then
--			rand <= 0;
--		end if;
--	end if;
--end process Random;
			


--Collisions: process(vert_sync)
--begin
--
--if ((avatar_x_pos - size < x_positions(0) + size) AND (avatar_x_pos + size > x_positions(0) - size) 
--AND (avatar_y_pos - size < y_positions(0) + size) AND (avatar_y_pos + size > y_positions(0) - size)) then
--	collide <='1';
--	lives_counter <= lives_counter - 1;
--	lives <= conv_std_logic_vector(lives_counter, 4);
--	y_positions(0) <= size;
--	x_positions(0) <= conv_std_logic_vector(rand, 10);
--elsif((avatar_x_pos - size < x_positions(1) + size) AND (avatar_x_pos + size > x_positions(1) - size) 
--AND (avatar_y_pos - size < y_positions(1) + size) AND (avatar_y_pos + size > y_positions(1) - size)) then
--	collide <= '1';
--elsif((avatar_x_pos - size < x_positions(2) + size) AND (avatar_x_pos + size > x_positions(2) - size) 
--AND (avatar_y_pos - size < y_positions(2) + size) AND (avatar_y_pos + size > y_positions(2) - size)) then
--	collide <= '1';
--elsif((avatar_x_pos - size < x_positions(3) + size) AND (avatar_x_pos + size > x_positions(3) - size) 
--AND (avatar_y_pos - size < y_positions(3) + size) AND (avatar_y_pos + size > y_positions(3) - size)) then
--	collide <= '1';
--elsif((avatar_x_pos - size < x_positions(4) + size) AND (avatar_x_pos + size > x_positions(4) - size) 
--AND (avatar_y_pos - size < y_positions(4) + size) AND (avatar_y_pos + size > y_positions(4) - size)) then
--	collide <= '1';
--else
--	collide <= '0';
--end if;
--
--end process Collisions;

--Scorekeeping: process(collide)
--begin
----track collisions and lives here
--if(collide'event and collide = '1') then
--	if(lives_counter > 0) then
--		lives_counter <= lives_counter - 1;
--		lives <= conv_std_logic_vector(lives_counter, 4);
--	end if;
--end if;
--end process Scorekeeping;

end behavior;