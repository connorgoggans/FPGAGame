library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity multiple is
	port (
		pixel_row, pixel_column : in std_logic_vector(9 downto 0);
		Red, Green, Blue        : out std_logic;
		Vert_sync               : in std_logic;
		move_left, move_right   : in std_logic;
		score                   : out std_logic_vector(19 downto 0);
		lives                   : out std_logic_vector(3 downto 0);
		level                   : out std_logic_vector(3 downto 0);
		clock                   : in std_logic;
		reset                   : in std_logic
	);
end multiple;
architecture behavior of multiple is

	-- type definitions for obstacle coordinates and motion --
	type coordArray is array (5 downto 0) of std_logic_vector(9 downto 0);
	type motions is array (5 downto 0) of std_logic_vector(9 downto 0);

	-- signals to keep track of obstacles --
	signal Size        : std_logic_vector(9 downto 0); 
	signal y_positions : coordArray;
	signal x_positions : coordArray;
	signal y_motions   : motions;
	signal isStart     : std_logic := '1';
	signal ball_on     : std_logic;

	-- signals to keep track of player's avatar --
	signal avatar_x_pos : std_logic_vector(9 downto 0) := "0101000000";
	signal avatar_y_pos : std_logic_vector(9 downto 0) := conv_std_logic_vector(440, 10);
	signal avatar_on    : std_logic;

	-- signals to keep track of extra life token --
	signal life_Size   : std_logic_vector(9 downto 0);
	signal life_x_pos  : std_logic_vector(9 downto 0);
	signal life_y_pos  : std_logic_vector(9 downto 0);
	signal life_on     : std_logic;
	signal life_speed  : std_logic_vector(9 downto 0);
	signal toggle_life : std_logic;

	-- signals to keep track of player status --
	signal score_counter    : integer := 0;
	signal lives_counter    : integer := 3;
	signal level_counter    : integer := 0;
	signal score_multiplier : integer := 10;

	-- lfsr signals --
	signal ce, lfsr_done, d0 : std_logic;
	signal lfsr_equal        : std_logic := '0';
	signal lfsr              : std_logic_vector (9 downto 0);

begin
	-- Set the size of the ball and extra life token
	Size      <= CONV_STD_LOGIC_VECTOR(20, 10);
	life_Size <= CONV_STD_LOGIC_VECTOR(10, 10);

	-- LFSR D0 set
	d0 <= lfsr(9) xnor lfsr(6);
	ce <= '1';
	VGA : process (x_positions, y_positions, pixel_column, pixel_row, Size)
	begin
		Red     <= not Ball_on and not life_on;
		Green   <= not Ball_on and not avatar_on;
		Blue    <= not avatar_on;
 
		ball_on <= '0';
		for i in y_positions' range loop
			-- set RGB for each active ball
			if ('0' & x_positions(i) <= pixel_column + Size) and
			 -- compare positive numbers only
			 (x_positions(i) + Size >= '0' & pixel_column) and
			('0' & y_positions(i) <= pixel_row + Size) and
				 (y_positions(i) + Size >= '0' & pixel_row) then
					Ball_on <= '1';
					-- ELSE
					-- Ball_on <= '0';
			end if;
 
			end loop;

			if ('0' & avatar_X_pos <= pixel_column + Size) and
			 -- compare positive numbers only
			 (avatar_X_pos + Size >= '0' & pixel_column) and
			('0' & avatar_Y_pos <= pixel_row + Size) and
				 (avatar_Y_pos + Size >= '0' & pixel_row) then
					avatar_on <= '1';
			else
				avatar_on <= '0';
			end if;

			-- extra life token --
			if ('0' & life_X_pos <= pixel_column + life_Size) and
				 -- compare positive numbers only
				 (life_X_pos + life_Size >= '0' & pixel_column) and
				('0' & life_Y_pos <= pixel_row + life_Size) and
					 (life_Y_pos + life_Size >= '0' & pixel_row) then
						life_on <= '1';
				else
					life_on <= '0';
				end if;
			end process VGA;

			Move_Ball : process
			begin
				-- Move ball once every vertical sync
				wait until vert_sync'EVENT and vert_sync = '1';
				if (isStart = '1') then

					-- initialize extra life token --
					life_speed <= conv_std_logic_vector(4, 10);
					life_x_pos <= conv_std_logic_vector(800, 10);
					life_y_pos <= life_size;
					toggle_life <= '1';

 
					-- initialize obstacles --
					for i in y_positions' range loop
						if (i = 0) then
							y_positions(i) <= conv_std_logic_vector(20, 10);
							x_positions(i) <= conv_std_logic_vector(20, 10);
							y_motions(i)   <= conv_std_logic_vector(3, 10);
						elsif (i = 1) then
							y_positions(i) <= conv_std_logic_vector(60, 10);
							x_positions(i) <= conv_std_logic_vector(60, 10);
							y_motions(i)   <= conv_std_logic_vector(4, 10);
						elsif (i = 2) then
							y_positions(i) <= conv_std_logic_vector(100, 10);
							x_positions(i) <= conv_std_logic_vector(100, 10);
							y_motions(i)   <= conv_std_logic_vector(2, 10);
						elsif (i = 3) then
							y_positions(i) <= conv_std_logic_vector(140, 10);
							x_positions(i) <= conv_std_logic_vector(140, 10);
							y_motions(i)   <= conv_std_logic_vector(5, 10);
						elsif (i = 4) then
							y_positions(i) <= conv_std_logic_vector(180, 10);
							x_positions(i) <= conv_std_logic_vector(180, 10);
							y_motions(i)   <= conv_std_logic_vector(6, 10);
						else
							y_positions(i) <= conv_std_logic_vector(220, 10);
							x_positions(i) <= conv_std_logic_vector(220, 10);
							y_motions(i)   <= conv_std_logic_vector(7, 10);
						end if;
					end loop;
					isStart <= '0';
				else
					for i in y_positions' range loop
						-- do transformations
						if (y_positions(i) & '0') >= 960 - Size then
							-- got to the end, re-gen coordinates
							y_positions(i) <= Size;
							x_positions(i) <= lfsr;
							score_counter  <= score_counter + score_multiplier;
							score          <= conv_std_logic_vector(score_counter, 20);
							--score <= (conv_std_logic_vector(0, 20)) or lfsr;
						else
							y_positions(i) <= y_positions(i) + y_motions(i);
						end if;
					end loop;
				end if;

				-- movement for extra life token --
				if (life_y_pos & '0') >= 960 - life_Size then
					-- got to the end, re-gen coordinates
					if (toggle_life = '0') then
						--put life on screen--
						life_y_pos <= life_size;
						life_x_pos <= lfsr;
						life_speed <= conv_std_logic_vector(4, 10);
					else
						--put life off screen--
						life_y_pos <= life_size;
						life_x_pos <= conv_std_logic_vector(800, 10);
						life_speed <= conv_std_logic_vector(1, 10);
					end if;
					toggle_life <= not toggle_life;
				else
					life_y_pos <= life_y_pos + life_speed;
				end if;
 
				if ((avatar_x_pos - size < x_positions(0) + size) and (avatar_x_pos + size > x_positions(0) - size)
				 and (avatar_y_pos - size < y_positions(0) + size) and (avatar_y_pos + size > y_positions(0) - size)) then
					if (lives_counter > 0) then
						lives_counter <= lives_counter - 1;
					end if;
					y_positions(0) <= size;
					x_positions(0) <= lfsr;
				elsif ((avatar_x_pos - size < x_positions(1) + size) and (avatar_x_pos + size > x_positions(1) - size)
					and (avatar_y_pos - size < y_positions(1) + size) and (avatar_y_pos + size > y_positions(1) - size)) then
					if (lives_counter > 0) then
						lives_counter <= lives_counter - 1;
					end if;
					y_positions(1) <= size;
					x_positions(1) <= lfsr;
				elsif ((avatar_x_pos - size < x_positions(2) + size) and (avatar_x_pos + size > x_positions(2) - size)
					and (avatar_y_pos - size < y_positions(2) + size) and (avatar_y_pos + size > y_positions(2) - size)) then
					if (lives_counter > 0) then
						lives_counter <= lives_counter - 1;
					end if;
					y_positions(2) <= size;
					x_positions(2) <= lfsr;
				elsif ((avatar_x_pos - size < x_positions(3) + size) and (avatar_x_pos + size > x_positions(3) - size)
					and (avatar_y_pos - size < y_positions(3) + size) and (avatar_y_pos + size > y_positions(3) - size)) then
					if (lives_counter > 0) then
						lives_counter <= lives_counter - 1;
					end if;
					y_positions(3) <= size;
					x_positions(3) <= lfsr;
				elsif ((avatar_x_pos - size < x_positions(4) + size) and (avatar_x_pos + size > x_positions(4) - size)
					and (avatar_y_pos - size < y_positions(4) + size) and (avatar_y_pos + size > y_positions(4) - size)) then
					if (lives_counter > 0) then
						lives_counter <= lives_counter - 1;
					end if;
					y_positions(4) <= size;
					x_positions(4) <= lfsr;
				elsif ((avatar_x_pos - size < x_positions(5) + size) and (avatar_x_pos + size > x_positions(5) - size)
					and (avatar_y_pos - size < y_positions(5) + size) and (avatar_y_pos + size > y_positions(5) - size)) then
					if (lives_counter > 0) then
						lives_counter <= lives_counter - 1;
					end if;
					y_positions(5) <= size;
					x_positions(5) <= lfsr;
				elsif ((avatar_x_pos - size < life_x_pos + size) and (avatar_x_pos + size > life_x_pos - size)
					and (avatar_y_pos - size < life_y_pos + size) and (avatar_y_pos + size > life_y_pos - size)) then
					-- collision with extra life token, add life --
					lives_counter <= lives_counter + 1;
					life_y_pos    <= life_size;
					life_x_pos    <= conv_std_logic_vector(800, 10);
					toggle_life   <= '1';
				end if;
 
				--write to the lives
				lives             <= conv_std_logic_vector(lives_counter, 4);
 
				if (lives_counter <= 0) then
					y_motions(0)      <= conv_std_logic_vector(0, 10);
					y_motions(1)      <= conv_std_logic_vector(0, 10);
					y_motions(2)      <= conv_std_logic_vector(0, 10);
					y_motions(3)      <= conv_std_logic_vector(0, 10);
					y_motions(4)      <= conv_std_logic_vector(0, 10);
					y_motions(5)      <= conv_std_logic_vector(0, 10);
					life_speed        <= conv_std_logic_vector(0, 10);
					if (reset = '0') then
						lives_counter <= 3;
						isStart       <= '1';
						level_counter <= 1;
						score_counter <= 0;
					end if;
				end if;
 
				if (score_counter = 500) then
					y_motions(0)  <= conv_std_logic_vector(4, 10);
					y_motions(1)  <= conv_std_logic_vector(5, 10);
					y_motions(2)  <= conv_std_logic_vector(3, 10);
					y_motions(3)  <= conv_std_logic_vector(6, 10);
					y_motions(4)  <= conv_std_logic_vector(7, 10);
					y_motions(5)  <= conv_std_logic_vector(8, 10);
					level_counter <= 2;
					level         <= conv_std_logic_vector(level_counter, 4);
				elsif (score_counter = 1100) then
					y_motions(0)  <= conv_std_logic_vector(5, 10);
					y_motions(1)  <= conv_std_logic_vector(6, 10);
					y_motions(2)  <= conv_std_logic_vector(4, 10);
					y_motions(3)  <= conv_std_logic_vector(7, 10);
					y_motions(4)  <= conv_std_logic_vector(8, 10);
					y_motions(5)  <= conv_std_logic_vector(9, 10);
					level_counter <= 3;
					level         <= conv_std_logic_vector(level_counter, 4);
				elsif (score_counter = 1800) then
					y_motions(0)  <= conv_std_logic_vector(6, 10);
					y_motions(1)  <= conv_std_logic_vector(7, 10);
					y_motions(2)  <= conv_std_logic_vector(5, 10);
					y_motions(3)  <= conv_std_logic_vector(8, 10);
					y_motions(4)  <= conv_std_logic_vector(9, 10);
					y_motions(5)  <= conv_std_logic_vector(10, 10);
					level_counter <= 4;
					level         <= conv_std_logic_vector(level_counter, 4);
				elsif (score_counter = 2600) then
					y_motions(0)  <= conv_std_logic_vector(7, 10);
					y_motions(1)  <= conv_std_logic_vector(8, 10);
					y_motions(2)  <= conv_std_logic_vector(6, 10);
					y_motions(3)  <= conv_std_logic_vector(9, 10);
					y_motions(4)  <= conv_std_logic_vector(10, 10);
					y_motions(5)  <= conv_std_logic_vector(11, 10);
					level_counter <= 5;
					level         <= conv_std_logic_vector(level_counter, 4);
				end if;
				end process Move_Ball;
				Move_avatar : process
				begin
					wait until vert_sync'EVENT and vert_sync = '1';
					if move_left = '0' then
						if avatar_X_pos > Size then
							avatar_X_pos <= avatar_X_pos - 5;
						end if;
					elsif move_right = '0' then
						if avatar_X_pos < 640 - Size then
							avatar_X_pos <= avatar_X_pos + 5;
						end if;
					end if;
				end process Move_avatar;

				process (lfsr) begin
				if (lfsr = x"18D") then
					lfsr_equal <= '1';
				else
					lfsr_equal <= '0';
				end if;
				end process;

				process (clock, reset) begin
				if (reset = '0') then
					lfsr      <= b"0000000000";
					lfsr_done <= '0';
				elsif (clock'EVENT and clock = '1') then
					lfsr_done <= lfsr_equal;
					if (ce = '1') then
						if (lfsr_equal = '1') then
							lfsr <= b"0000000000";
						else
							lfsr <= lfsr(8 downto 0) & d0;
						end if;
					end if;
				end if;
			end process;
 
end behavior;