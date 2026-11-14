library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Top-level entity of the word-guessing game (Termo/Wordle style) on a Spartan 3A/AN FPGA.
-- It contains no logic of its own: it only instantiates and wires together the sub-modules:
-- PS2 keyboard driver -> typing buffer -> control FSM + data subsystem -> user interface -> LCD driver.
entity main is
    Port ( 
        clk         : in  std_logic; -- System clock (50 MHz)
        rst         : in  std_logic; -- Global reset
        
        -- Interface física PS2
        -- PS2 keyboard physical interface
        ps2_clk     : in  std_logic; -- PS2 clock line (driven by the keyboard)
        ps2_data    : in  std_logic; -- PS2 serial data line
        
        -- Interface física LCD
        -- LCD physical interface
        sf_ce0      : out std_logic; -- StrataFlash chip enable (must be disabled to free the shared LCD bus)
        lcd_e       : out std_logic; -- LCD enable pulse
        lcd_rs      : out std_logic; -- LCD register select (command/data)
        lcd_rw      : out std_logic; -- LCD read/write select
        lcd_db    : out std_logic_vector(7 downto 0) -- LCD 8-bit data bus
    );
end main;

architecture structural of main is

    -- Sinais de interconexão geral
    -- General interconnection signals
    -- char_ready_s : a new key was decoded by the PS2 driver
    -- guess_ready_s: the typing buffer holds a complete 5-letter word
    -- guess_checked_s: the control FSM acknowledges the word, so the buffer can be cleared
    signal char_ready_s, guess_ready_s, guess_checked_s : std_logic;
    -- ASCII code of the last key received from the keyboard
    signal char_ascii_s : std_logic_vector(7 downto 0);
    
    -- g0..g4: the 5 letters currently typed (outputs of the typing buffer)
    signal g0, g1, g2, g3, g4 : std_logic_vector(7 downto 0);
    -- last_g0..last_g4: the last guess that was submitted
    signal last_g0, last_g1, last_g2, last_g3, last_g4 : std_logic_vector(7 downto 0);
    -- r0..r4: per-letter feedback of the last guess ('V', '?' or 'X')
    signal r0, r1, r2, r3, r4 : std_logic_vector(7 downto 0);
    -- t0..t4: the secret keyword
    signal t0, t1, t2, t3, t4 : std_logic_vector(7 downto 0);
    
    -- Number of attempts used (0 to 6)
    signal attempt_count_s : integer range 0 to 6;
    -- Game status: 00: Setup, 01: Play, 10: Win, 11: Lose
    signal game_status_s : std_logic_vector(1 downto 0);
    
    -- Sinais internos do Kernel (entre controle e dados)
    -- Internal "kernel" signals (between the control FSM and the data subsystem)
    -- Enables coming from the control FSM, telling the data subsystem what to do
    signal en_keyword_s, en_guess_s, inc_attempt_s : std_logic;
    -- Flags coming from the data subsystem, telling the control FSM the result
    signal flag_victory_s, flag_max_att_s : std_logic;
    
    -- Sinais para conectar UI e LCD driver
    -- Signals connecting the user interface to the LCD driver
    -- Each line holds 16 ASCII characters (16 x 8 = 128 bits)
    signal line1, line2 : std_logic_vector(127 downto 0);

begin
    
    -- Configurações fixas da FPGA Xilinx Spartan 3A/AN
    -- Fixed configuration of the Xilinx Spartan 3A/AN board
    sf_ce0 <= '1'; -- Obrigatório para liberar o barramento do LCD
                   -- Required to release the LCD bus (the flash memory shares these pins)

    -- 1. Instância do driver do teclado PS2
    -- 1. PS2 keyboard driver: decodes the PS2 serial protocol and outputs an ASCII character
    ps2_instance: entity work.ps2_driver
        port map ( 
            clk => clk,
            rst => rst,
            ps2_clk => ps2_clk,
            ps2_data => ps2_data, 
            char_ascii => char_ascii_s,
            char_ready => char_ready_s 
        );

    -- 2. Instância do buffer de digitação
    -- 2. Typing buffer: stores the typed characters until a full 5-letter word is ready
    buffer_instance: entity work.typing_buffer
        port map ( 
            clk => clk,
            rst => rst,
            char_ascii => char_ascii_s,
            char_ready => char_ready_s,
            guess_ready => guess_ready_s,
            guess_checked => guess_checked_s,
            char0 => g0, char1 => g1, char2 => g2, char3 => g3, char4 => g4
        );

    -- 3. Instância do subsistema de controle
    -- 3. Control subsystem: FSM that sequences the game (setup, play, check, win/lose)
    control_instance: entity work.control_subsystem
        port map ( 
            clk => clk,
            rst => rst, 
            guess_ready => guess_ready_s,
            guess_checked => guess_checked_s, 
            game_status => game_status_s,
            flag_victory => flag_victory_s,
            flag_max_att => flag_max_att_s,
            en_keyword => en_keyword_s,
            en_guess => en_guess_s, 
            inc_attempt => inc_attempt_s
        );

    -- 4. Instância do subsistema de dados
    -- 4. Data subsystem: stores the keyword, compares guesses, generates feedback and counts attempts
    data_instance : entity work.data_subsystem
        port map ( 
            clk => clk,
            rst => rst, 
            en_keyword => en_keyword_s,
            en_guess => en_guess_s, 
            inc_attempt => inc_attempt_s,
            attempt_count => attempt_count_s, 
            flag_victory => flag_victory_s,
            flag_max_att => flag_max_att_s,
            char0 => g0, char1 => g1, char2 => g2, char3 => g3, char4 => g4,
            last_c0 => last_g0, last_c1 => last_g1, last_c2 => last_g2, last_c3 => last_g3, last_c4 => last_g4,
            ans0 => r0, ans1 => r1, ans2 => r2, ans3 => r3, ans4 => r4,
            p0 => t0, p1 => t1, p2 => t2, p3 => t3, p4 => t4 
        );

    -- 5. Instância da interface de usuário
    -- 5. User interface: builds the two 16-character text lines to display, based on the game state
    ui_instance : entity work.user_interface
        port map (
            game_status => game_status_s,
            attempt_count => attempt_count_s,
            char0 => g0, char1 => g1, char2 => g2, char3 => g3, char4 => g4,
            last_c0 => last_g0, last_c1 => last_g1, last_c2 => last_g2, last_c3 => last_g3, last_c4 => last_g4,
            ans0 => r0, ans1 => r1, ans2 => r2, ans3 => r3, ans4 => r4,
            p0 => t0, p1 => t1, p2 => t2, p3 => t3, p4 => t4,
            line1_out => line1,
            line2_out => line2
        );

    -- 6. Instância do driver do LCD
    -- 6. LCD driver: initializes the 16x2 LCD and continuously refreshes it with line1 and line2
    lcd_instance : entity work.lcd_driver
        port map (
            clk => clk,
            rst => rst,
            lcd_rs => lcd_rs,
            lcd_rw => lcd_rw,
            lcd_e => lcd_e,
            lcd_db => lcd_db,
            line1_in => line1,
            line2_in => line2
        );

end structural;
