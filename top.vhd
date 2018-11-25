library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.ALL;


entity top is
	
	port(
		clk: in std_logic;

		-- User Input
		reset: in std_logic;
		jump: in std_logic;

		-- VGA 
		hsync: out std_logic;
		vsync: out std_logic;
		Red: out std_logic_vector(3 downto 0);
		Green: out std_logic_vector(3 downto 0);
		Blue: out std_logic_vector(3 downto 0);

		-- 7 Seg Display
		
		segment0 : out std_logic_vector (7 downto 0);	
		segment1 : out std_logic_vector (7 downto 0);	
		segment2 : out std_logic_vector (7 downto 0);	
		segment3 : out std_logic_vector (7 downto 0);			
        anodes   : out  std_logic_vector (0 to 3)
	);		
end top;



architecture Behavioral of top is
	constant PIX : integer := 16;
	constant ROWS : integer := 30;
	constant COLS : integer := 40;
	constant T_FAC : integer := 100000;
	constant RAN_WIDTH : integer :=  5;

	-- Speed
	constant cloudSpeed : integer := 60;
	constant cactusSpeed : integer := 40;
	constant pteroSpeed : integer := 30;
	constant trexSpeed : integer := 25;

	-- VGA Sigs
	signal hCount: integer := 640;
	signal vCount: integer := 480;
	signal nextHCount: integer := 641;
	signal nextVCount: integer := 480;
	
	-- T-Rex
	signal trexX: integer := 8;
	signal trexY: integer := 24;

	-- Pterodactyl
	signal pteroX: integer := COLS*3;
	signal pteroY: integer := 21;

	-- Clouds
	signal cloudX_1: integer := COLS;
	signal cloudY_1: integer := 8;
	signal cloudX_2: integer := COLS + (COLS/2);
	signal cloudY_2: integer := 18;
	
	-- Cactus
	signal resetGame : std_logic := '0';
	signal cactusX_1: integer := COLS;
	signal cactusX_2: integer := COLS + (COLS/2);
	signal cactusX_3: integer := COLS + COLS;
	signal cactusY: integer := 24;
	
	-- Game Logic
	signal gameOver : std_logic := '0';
	signal isJumping : std_logic := '0';	
	signal gameSpeed: integer := 0;
	signal rand_num : integer := 0;
	
	signal scoreX :natural;
	signal scoreY :natural;
	signal score :bit;
	signal scorePosX :natural;
	signal scorePosY :natural;

	-- COMPONENT SIGNALS
	signal sclock, cleanJump : std_logic;
	signal d0, d10, d100, d1000 : std_logic_vector (3 downto 0);
	signal d :std_logic_vector (15 downto 0);
	type hs is array (0 to 3) of std_logic_vector (3 downto 0);
	type m is array (0 to 1) of integer;
	signal highScoreD : hs;
	signal highScoreI : integer:= 0;
	
	signal mode :  m := (1,0);
	
	signal disp1, disp2, disp3 : std_logic_vector (6 downto 0);

	-- Sprites
	type sprite_block is array(0 to 15, 0 to 15) of integer range 0 to 1;
	constant trex_1: sprite_block:=((0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0), -- 0 
									(0,0,0,0,0,0,0,1,1,0,1,1,1,1,1,1), -- 1 
									(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1), -- 2
									(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1), -- 3
									(0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0), -- 4
									(0,0,0,0,0,0,0,1,1,1,1,1,1,1,0,0), -- 5
									(0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0), -- 6
									(1,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0), -- 7
									(1,1,0,0,1,1,1,1,1,1,1,0,0,1,0,0), -- 8
									(1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0), -- 9
									(0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0), -- 10
									(0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0), -- 11
									(0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0), -- 12
		 							(0,0,0,0,0,1,0,0,1,1,0,0,0,0,0,0), -- 13
									(0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0), -- 14
									(0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0));-- 15

	constant trex_2: sprite_block:=((0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0), -- 0 
									(0,0,0,0,0,0,0,1,1,0,1,1,1,1,1,1), -- 1 
									(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1), -- 2
									(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1), -- 3
									(0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0), -- 4
									(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,0), -- 5
									(0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0), -- 6
									(1,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0), -- 7
									(1,1,0,0,1,1,1,1,1,1,1,0,0,1,0,0), -- 8
									(1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0), -- 9
									(0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0), -- 10
									(0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0), -- 11
									(0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0), -- 12
		 							(0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0), -- 13
									(0,0,0,0,0,1,1,0,1,0,0,0,0,0,0,0), -- 14
									(0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0));-- 15

	constant trex_dead: sprite_block:=( (0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0), -- 0 
										(0,0,0,0,0,0,0,1,0,0,0,1,1,1,1,1), -- 1 
										(0,0,0,0,0,0,0,1,0,1,0,1,1,1,1,1), -- 2
										(0,0,0,0,0,0,0,1,0,0,0,1,1,1,1,1), -- 3
										(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1), -- 4
										(0,0,0,0,0,0,0,1,1,1,1,1,1,1,0,0), -- 5
										(0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0), -- 6
										(1,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0), -- 7
										(1,1,0,0,1,1,1,1,1,1,1,0,0,1,0,0), -- 8
										(1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0), -- 9
										(0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0), -- 10
										(0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0), -- 11
										(0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0), -- 12
										(0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0), -- 13
										(0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0), -- 14
										(0,0,0,0,0,1,1,0,1,1,0,0,0,0,0,0));-- 15

	constant cactus: sprite_block :=((0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0), -- 0 
									 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 1 
									 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 2
									 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 3
									 (0,0,0,0,0,1,0,1,1,1,0,1,0,0,0,0), -- 4
									 (0,0,0,0,1,1,0,1,1,1,0,1,0,0,0,0), -- 5
									 (0,0,0,0,1,1,0,1,1,1,0,1,0,0,0,0), -- 6
									 (0,0,0,0,1,1,0,1,1,1,0,1,0,0,0,0), -- 7
									 (0,0,0,0,1,1,0,1,1,1,0,1,0,0,0,0), -- 8
									 (0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0), -- 9
									 (0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0), -- 10
									 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 11
									 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 12
		 							 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 13
									 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 14
									 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0));-- 15

	constant ptero_1: sprite_block:=((0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0), -- 0 
									 (0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0), -- 1 
									 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 2
									 (0,0,0,1,1,0,0,1,1,1,1,0,0,0,0,0), -- 3
									 (0,0,1,1,1,0,0,1,1,1,1,1,0,0,0,0), -- 4
									 (0,1,1,1,1,0,0,1,1,1,1,1,1,0,0,0), -- 5
									 (1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0), -- 6
									 (0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1), -- 7
									 (0,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0), -- 8
									 (0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,0), -- 9
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 11
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 10
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 12
		 							 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 13
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 14
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));-- 15

	constant ptero_2: sprite_block:=((0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 0 
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 1 
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 2
									 (0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0), -- 3
									 (0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0), -- 4
									 (0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0), -- 5
									 (1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0), -- 6
									 (0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1), -- 7
									 (0,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0), -- 8
									 (0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0), -- 9
									 (0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0), -- 10
									 (0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0), -- 11
									 (0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0), -- 12
		 							 (0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0), -- 13
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 14
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));-- 15

	constant cloud: sprite_block:=(  (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 0 
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 1 
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 2
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 3
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 4
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 5
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 6
									 (0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0), -- 7
									 (0,0,0,0,0,1,1,0,0,0,1,1,1,1,0,0), -- 8
									 (0,1,1,1,1,1,0,0,0,0,0,0,0,1,1,1), -- 9
									 (1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1), -- 10
									 (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1), -- 11
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 12
		 							 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 13
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 14
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));-- 15
									 
	------------------------- digits
	constant one: sprite_block:=((0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0),
											(0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0),
											(0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,0),
											(0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,0),
											(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
											(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
											(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
											(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
											(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
											(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
											(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
											(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
											(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
											(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
											(0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,0),
											(0,0,0,0,0,1,1,1,1,1,1,1,1,0,1,0));

	constant two: sprite_block:=((0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0),
											(0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0),
											(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
											(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
											(0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0),
											(0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0),
											(0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0),
											(0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0),
											(0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0),
											(0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0),
											(0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0),
											(0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0));
											
											
	constant three: sprite_block:=((0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0),
											(0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0),
											(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0),
											(0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0),
											(0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,0,1,1,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,0,1,1,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0),
											(0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0));

	constant four: sprite_block:=((0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
												(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
												(0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0),
												(0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0),
												(0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,0),
												(0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,0),
												(0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0),
												(0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0),
												(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
												(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
												(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
												(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
												(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
												(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
												(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
												(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0));

	constant five: sprite_block:=((0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0),
												(0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0),
												(0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0),
												(0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0),
												(0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0),
												(0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0));
											
	constant six: sprite_block:=((0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0),
												(0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0),
												(0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0),
												(0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0),
												(0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0),
												(0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0),
												(0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0));

	constant seven: sprite_block:=((0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0),
												(0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0),
												(0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
												(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
												(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
												(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
												(0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0),
												(0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0),
												(0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0),
												(0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0),
												(0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0),
												(0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0),
												(0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0),
												(0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0));


												
	constant eight: sprite_block:=((0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0),
													(0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0),
													(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
													(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
													(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
													(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
													(0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0),
													(0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0),
													(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
													(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
													(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
													(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
													(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
													(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
													(0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0),
													(0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0));
													
	constant nine: sprite_block:=((0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0),
												(0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0),
												(0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0),
												(0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0),
												(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
												(0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0),
												(0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0),
												(0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0));
	
	constant zero: sprite_block:=((0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0),
											(0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0),
											(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,1,1,0,0,0,0,1,1,1,1,0,0,0),
											(0,0,0,1,1,0,0,0,0,1,1,1,1,0,0,0),
											(0,0,0,1,1,0,0,1,1,0,0,1,1,0,0,0),
											(0,0,0,1,1,0,0,1,1,0,0,1,1,0,0,0),
											(0,0,0,1,1,1,1,0,0,0,0,1,1,0,0,0),
											(0,0,0,1,1,1,1,0,0,0,0,1,1,0,0,0),
											(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0),
											(0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0),
											(0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0));
	
	type color_arr is array(0 to 1) of std_logic_vector(11 downto 0);
	type digits is array(0 to 9) of sprite_block;
	constant numbers : digits := (zero, one, two, three, four, five, six, seven, eight, nine);
	constant sprite_color : color_arr := ("111011101110", "000000000000");

	-- COMPONENTS
	-- Clock Divider
   component Debo
       port ( clk  : in  std_logic;
       		  key  : in  std_logic;
	    	  pulse : out std_logic
            );
   end component;

	-- Clock Divider
   component CDiv
       port ( Cin  : in  std_logic;
              Cout : out std_logic
            );
   end component;
	
	-- Counter
   component Counter
       port ( clk     : in  std_logic; 
              countup : in  std_logic;
              reset: in std_logic; 
              d0  : out std_logic_vector(3 downto 0);
			  d10  : out std_logic_vector(3 downto 0);
			  d100  : out std_logic_vector(3 downto 0);
			  d1000  : out std_logic_vector(3 downto 0));
   end component;
	
	--Bcd to Seg Decoder
   component BcdSegDecoder
       port(clk : in std_logic;
			bcd : in  std_logic_vector (3 downto 0);
			segment7 : out  std_logic_vector (6 downto 0));
   end component;
   
   --Segment Driver
   component SegmentDriver
       port(disp1 : in  std_logic_vector (6 downto 0);
            disp2 : in  std_logic_vector (6 downto 0);
            disp3 : in  std_logic_vector (6 downto 0);
            disp4 : in  std_logic_vector (6 downto 0);
            clk : in  std_logic;
        	display_seg : out  std_logic_vector (6 downto 0);
        	display_ena : out  std_logic_vector (3 downto 0));
   end component;

-- Behaviour Block
begin	

	-- COMPONENTS
	JumpDebo: Debo port map (clk => sclock,
							 key => jump,
							 pulse => cleanJump);

	SegClock: CDiv port map (Cin => clk,
							Cout => sclock);
									
	ScoreCounter: Counter
		port map(	clk => clk,
					countup => not gameOver,
					reset => resetGame, 
					d0 => d0,
					d10 => d10,
					d100 => d100,
					d1000 => d1000
					);
						
	Digit1: BcdSegDecoder 
		port map (	clk => clk,
					bcd => highScoreD(0),
					segment7 => segment0(7 downto 1));
												
	Digit2: BcdSegDecoder
		port map (	clk => clk,
					bcd => highScoreD(1),
              		segment7 => segment1(7 downto 1));
												
   Digit3: BcdSegDecoder 
		port map (	clk => clk,
					bcd => highScoreD(2),
              		segment7 => segment2(7 downto 1));
						
	Digit4: BcdSegDecoder 
		port map (	clk => clk,
					bcd => highScoreD(3),
              		segment7 => segment3(7 downto 1));
												
   --Driver: SegmentDriver
	--	port map (	disp1 => disp1,
	--				disp2 => disp2,
	--				disp3 => disp3,
	--				disp4 => disp4,
	--				clk => sclock,
	--				display_seg => segments(7 downto 1),
	--				display_ena => anodes);				
	

	-- PROCESSES
	vgaSignal: process(clk)
		variable sprite_x : integer := 0;
		variable sprite_y : integer := 0;
		variable prescalerCount: integer := 0;
		variable prescaler: integer := 5000000;
		variable divide_by_2 : std_logic := '0';
		variable rgbDrawColor : std_logic_vector(11 downto 0) := (others => '0');
		variable t0: integer;
		variable t10: integer;
		variable t100: integer;
		variable t1000: integer;
	begin
		
		if clk'event and clk = '1' then
			if reset = '1' then
				hsync <= '1';
				vsync <= '1';
				
				hCount <= 640;
				vCount <= 480;
				nextHCount <= 641;
				nextVCount <= 480;
				
				rgbDrawColor := (others => '0');
				
				divide_by_2 := '0';
			else
				
				-- Running at 25 Mhz (50 Mhz / 2)
				if divide_by_2 = '1' then
					if(hCount = 799) then
						hCount <= 0;
						
						if(vCount = 524) then
							vCount <= 0;
						else
							vCount <= vCount + 1;
						end if;
					else
						hCount <= hCount + 1;
					end if;
					
					
					-- horizontal rollover
					if (nextHCount = 799) then	
						nextHCount <= 0;
						
						-- vertical rollover
						if (nextVCount = 524) then	
							nextVCount <= 0;
						else
							nextVCount <= vCount + 1;
						end if;
					else
						nextHCount <= hCount + 1;
					end if;
					

					-- trigger vsync and hsync pulses
					if (vCount >= 490 and vCount < 492) then
						vsync <= '0';
					else
						vsync <= '1';
					end if;
					
					if (hCount >= 656 and hCount < 752) then
						hsync <= '0';
					else
						hsync <= '1';
					end if;
					
					
					-- in display range
					if (hCount < 640 and vCount < 480) then

						-- Default is background
						--rgbDrawColor := "1110" & "1110" & "1110";
						rgbDrawColor := sprite_color(mode(0));
			
						sprite_x := hCount mod PIX;
						sprite_y := vCount mod PIX;

						-- Cloud1
						if ((hCount / PIX) = cloudX_1) and ((vCount / PIX) = cloudY_1) then 
							rgbDrawColor := sprite_color(mode(cloud(sprite_y, sprite_x)));
						end if;
						-- Cloud2
						if ((hCount / PIX) = cloudX_2) and ((vCount / PIX) = cloudY_2) then 
							rgbDrawColor := sprite_color(mode(cloud(sprite_y, sprite_x)));
						end if;
						

						-- Cactus1
						if ((hCount / PIX) = cactusX_1) and ((vCount / PIX) = cactusY) then 
							rgbDrawColor := sprite_color(mode(cactus(sprite_y, sprite_x)));
						end if;
						-- Cactus2
						if ((hCount / PIX) = cactusX_2) and ((vCount / PIX) = cactusY) then 
							rgbDrawColor := sprite_color(mode(cactus(sprite_y, sprite_x)));
						end if;
						-- Cactus3
						if ((hCount / PIX) = cactusX_3) and ((vCount / PIX) = cactusY) then 
							rgbDrawColor := sprite_color(mode(cactus(sprite_y, sprite_x)));
						end if;


						-- Pterodactyl
						if ((hCount / PIX) = pteroX) and ((vCount / PIX) = pteroY) then
							if (gameOver = '1') or (prescalerCount <= prescaler) then
								rgbDrawColor := sprite_color(mode(ptero_1(sprite_y, sprite_x)));
							elsif (prescalerCount > prescaler and prescalerCount <= prescaler*2) then
								rgbDrawColor := sprite_color(mode(ptero_2(sprite_y, sprite_x)));
							else
								prescalerCount := 0;
								rgbDrawColor := sprite_color(mode(ptero_2(sprite_y, sprite_x)));
							end if;
						end if;


						-- T-Rex
						if ((hCount / PIX) = trexX) and ((vCount / PIX) = trexY) then
							if (gameOver = '1') then
								rgbDrawColor := sprite_color(mode(trex_dead(sprite_y, sprite_x)));
							elsif (prescalerCount <= prescaler) then
								rgbDrawColor := sprite_color(mode(trex_1(sprite_y, sprite_x)));
							elsif (prescalerCount > prescaler and prescalerCount <= prescaler*2) then
								rgbDrawColor := sprite_color(mode(trex_2(sprite_y, sprite_x)));
							else
								prescalerCount := 0;
								rgbDrawColor := sprite_color(mode(trex_2(sprite_y, sprite_x)));
							end if;
						end if;
						

						-- Ground
						if ((vCount / PIX) = 24) then
							if ((vCount mod PIX) = (PIX - 4)) then
								rgbDrawColor := sprite_color(mode(1));
							end if;
						end if;
						
						
						t0 := to_integer(unsigned(d0));
						t10 := to_integer(unsigned(d10));
						t100 := to_integer(unsigned(d100));
						t1000 := to_integer(unsigned(d1000));
						-- score 
						--this is only a test to show the numbers on screen
						
						--10**3
						if (vCount >= 48 and vCount < 64) and  (hCount >= 48 and hCount < 66)then							
							rgbDrawColor := sprite_color(mode(numbers(t1000)(sprite_y, sprite_x)));							
						end if;
						--10**2
						if (vCount >= 48 and vCount < 64) and  (hCount >= 66 and hCount < 82)then							
							rgbDrawColor := sprite_color(mode(numbers(t100)(sprite_y, sprite_x)));							
						end if;
						-- 10**1
						if (vCount >= 48 and vCount < 64) and  (hCount >= 82 and hCount < 98)then							
							rgbDrawColor := sprite_color(mode(numbers(t10)(sprite_y, sprite_x)));							
						end if;
						-- 10**0
						if (vCount >= 48 and vCount < 64) and  (hCount >= 98 and hCount < 114)then							
							rgbDrawColor := sprite_color(mode(numbers(t0)(sprite_y, sprite_x)));							
						end if;
						
						-- Show dem colors
						Red <= rgbDrawColor(11 downto 8);
						Green <= rgbDrawColor(7 downto 4);
						Blue <= rgbDrawColor(3 downto 0);
					else
						Red <= "0000";
						Green <= "0000";
						Blue <= "0000";
					end if;
				end if;
				divide_by_2 := not divide_by_2;
				prescalerCount := prescalerCount + 1;
			end if;
		end if;
	end process;

	gameLogic: process(clk, cleanJump)
		variable endGame: std_logic := '0';

		variable trexCount: integer := 0;
		variable cactusCount: integer := 0;
		variable pteroCount: integer := 0;
		variable cloudCount: integer := 0;
		variable waitCount: integer := 0;
		variable waitTime: integer := T_FAC*40*25;

		-- Random Number Signals
		variable rand_temp : std_logic_vector(RAN_WIDTH - 1 downto 0):=(RAN_WIDTH - 1 => '1',others => '0');
		variable temp : std_logic := '0';
	begin
		if clk'event and clk = '1' then

			-- Generate Random Number
			temp := rand_temp(RAN_WIDTH - 1) xor rand_temp(RAN_WIDTH - 2);
			rand_temp(RAN_WIDTH - 1 downto 1) := rand_temp(RAN_WIDTH - 2 downto 0);
			rand_temp(0) := temp;
		    rand_num <= to_integer(unsigned(rand_temp));


		    -- Adjust game speed
		    if gameSpeed < 20 and d0 = "0101" then
		    	gameSpeed <= gameSpeed + 5;
		    end if;


			-- Jump Logic
			if cleanJump = '1' and trexY = 24 then
				if (gameOver = '0') then
					isJumping <= '1';
					trexCount := 0;					
				end if;		
			end if;
			
			
			-- Trex Jump animation
			if trexCount >= T_FAC * trexSpeed then
				if isJumping = '1' then
					if (trexY > 20) then
						trexY <= trexY - 1;
					else
						isJumping <= '0';
					end if;
					trexCount := 0;
				else
					if (trexY < 24) then
						trexY <= trexY + 1;
					end if;
					trexCount := 0;
				end if;
			end if;
			trexCount := trexCount + 1;


			-- Detect Hit Cactus
			if (trexY = cactusY) and ((trexX = cactusX_1) or (trexX = cactusX_2) or (trexX = cactusX_3)) then
				endGame := '1';
			end if;

			-- Detect Hit Pterodactyl
			if (trexY = pteroY) and (trexX = pteroX) then
				endGame := '1';
			end if;
			gameOver <= endGame;

			-- Game Over
			if endGame = '1' then
				if waitCount >= waitTime then
					trexX <= 8;
					trexY <= 24;
					endGame := '0';
					waitCount := 0;
					resetGame <= '1';
				end if;
				
				d <= d1000 & d100 & d10 &d0;
				if highScoreI < to_integer(unsigned(d)) then
					highScoreI <= to_integer(unsigned(d));
					highScoreD(0) <= d0;
					highScoreD(1) <= d10;
					highScoreD(2) <= d100;
					highScoreD(3) <= d1000;
				end if;
				waitCount := waitCount + 1;
			end if;

			
			if resetGame = '1' then
				cactusX_1 <= COLS;
				cactusX_2 <= COLS + (COLS/2);
				cactusX_3 <= COLS + COLS;
				cloudX_1 <= COLS;
				cloudX_2 <= COLS + (COLS/2);
				pteroX <= COLS + COLS;
				gameSpeed <= 0;
				resetGame <= '0';
			else
				-- Cactus Movement
				if (endGame = '0') and (cactusCount >= T_FAC * cactusSpeed - gameSpeed) then
					if (cactusX_1 <= 0) then
						cactusX_1 <= COLS + rand_num;
					elsif (cactusX_2 <= 0) then
						cactusX_2 <= COLS + rand_num;
					elsif (cactusX_3 <= 0) then
						cactusX_3 <= COLS + rand_num;
					else
						cactusX_1 <= cactusX_1 - 1;
						cactusX_2 <= cactusX_2 - 1;
						cactusX_3 <= cactusX_3 - 1;
					end if;
					cactusCount := 0;
				end if;
				cactusCount := cactusCount + 1;


				-- Pterodactyl Movement
				if (endGame = '0') and (pteroCount >= T_FAC * pteroSpeed - gameSpeed) and (d10 >= "0001") then
					if pteroX <= 0 then
						pteroX <= COLS + (COLS/2) + rand_num;
					else
						pteroX <= pteroX - 1;
					end if;
					pteroCount := 0;
				end if;
				pteroCount := pteroCount + 1;


				-- Cloud Movement
				if (endGame = '0') and (cloudCount >= T_FAC * cloudSpeed) then
					if cloudX_1 <= 0 then
						cloudX_1 <= COLS + (COLS/2);
					elsif cloudX_2 <= 0 then
						cloudX_2 <= COLS + (COLS/2);
					else
						cloudX_1 <= cloudX_1 - 1;
						cloudX_2 <= cloudX_2 - 1;
					end if;
					cloudCount := 0;

				end if;
				cloudCount := cloudCount + 1;
			end if;

		end if; -- end clock event
	end process;
	
--	process(gameOver) is
--	begin		
--		if gameOver = '1' then			
--			if highScoreI < to_integer(unsigned(d)) then
--				highScoreI <= to_integer(unsigned(d));
--				highScoreD(0) <= d0;
--				highScoreD(1) <= d10;
--				highScoreD(2) <= d100;
--				highScoreD(3) <= d1000;
--			end if;
--		end if;
--	end process;
	process(d100)
	begin
		if d100(0) = '0' then
			mode(0) <= 0;
			mode(1) <= 1;
		else
			mode(0) <= 1;
			mode(1) <= 0;
		end if;
	end process;
end Behavioral;

