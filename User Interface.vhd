library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- User interface: purely combinational module that builds the text shown on the 16x2 LCD.
-- Depending on game_status it composes one of four screens (setup, play, win, lose)
-- in a 32-character buffer (16 chars for line 1 + 16 chars for line 2).
-- Note: "(espaço)" in the inline comments means "(space)", i.e. ASCII x"20".
entity user_interface is
    Port (
        -- Entradas de contexto do jogo
        -- Game context inputs
        game_status   : in  std_logic_vector(1 downto 0); -- 00: Setup, 01: Play, 10: Win, 11: Lose
        attempt_count : in  integer range 0 to 6;         -- Number of attempts used so far
        
        -- Entradas do typing_buffer
        -- Inputs from the typing_buffer: the word currently being typed
        char0, char1, char2, char3, char4 : in std_logic_vector(7 downto 0);
        
        -- Entradas do data_subsystem (memória)
        -- Inputs from the data_subsystem (stored data)
        last_c0, last_c1, last_c2, last_c3, last_c4 : in std_logic_vector(7 downto 0); -- Last guess submitted
        ans0, ans1, ans2, ans3, ans4 : in std_logic_vector(7 downto 0);                -- Feedback for the last guess ('V', '?', 'X')
        p0, p1, p2, p3, p4 : in std_logic_vector(7 downto 0);                          -- Secret keyword
        
        -- Text for each LCD line: 16 characters x 8 bits (leftmost character in the MSBs)
        line1_out : out std_logic_vector(127 downto 0);
        line2_out : out std_logic_vector(127 downto 0)
    );
end user_interface;

architecture rtl of user_interface is
    -- Screen buffer: 32 characters (positions 0-15 = line 1, positions 16-31 = line 2)
    type char_array is array (0 to 31) of std_logic_vector(7 downto 0);
    signal screen_buffer : char_array;
    
    -- ASCII digit of the attempt number being played (1 to 6)
    signal play_attempt_ascii : std_logic_vector(7 downto 0);
    -- ASCII digit of the number of attempts used when the player won (1 to 6)
    signal win_attempt_ascii  : std_logic_vector(7 downto 0);
begin
    -- Current attempt = attempts used + 1 (x"31" = '1' = 0 + 49). It is capped at '6' (x"36")
    -- so that the display never shows '7' after the 6th attempt.
    play_attempt_ascii <= std_logic_vector(to_unsigned(attempt_count + 49, 8)) when attempt_count < 6 else x"36";
    -- Attempts used converted to ASCII (x"30" = '0' = 0 + 48)
    win_attempt_ascii  <= std_logic_vector(to_unsigned(attempt_count + 48, 8));

    -- Combinational process: rebuilds the whole screen whenever any input changes
    process(game_status, play_attempt_ascii, win_attempt_ascii, char0, char1, char2, char3, char4, last_c0, last_c1, last_c2, last_c3, last_c4, ans0, ans1, ans2, ans3, ans4, p0, p1, p2, p3, p4)
    begin
        if game_status = "10" then
            -- TELA DE VITÓRIA
            -- WIN SCREEN: shows the victory message with the number of attempts and the keyword
            -- Linha 1: "VITORIA EM n!"
            -- Line 1: static text "VITORIA EM " + number of attempts + "!"
            screen_buffer(0)  <= x"56"; -- V
            screen_buffer(1)  <= x"49"; -- I
            screen_buffer(2)  <= x"54"; -- T
            screen_buffer(3)  <= x"4F"; -- O
            screen_buffer(4)  <= x"52"; -- R
            screen_buffer(5)  <= x"49"; -- I
            screen_buffer(6)  <= x"41"; -- A
            screen_buffer(7)  <= x"20"; -- (espaço)
            screen_buffer(8)  <= x"45"; -- E
            screen_buffer(9)  <= x"4D"; -- M
            screen_buffer(10) <= x"20"; -- (espaço)
            screen_buffer(11) <= win_attempt_ascii;
            screen_buffer(12) <= x"21"; -- !
            screen_buffer(13) <= x"20"; -- (espaço)
            screen_buffer(14) <= x"20"; -- (espaço)
            screen_buffer(15) <= x"20"; -- (espaço)

            -- Linha 2: "TERMO: _____"
            -- Line 2: static text "TERMO: " + the secret keyword (p0..p4), padded with spaces
            screen_buffer(16) <= x"54"; -- T
            screen_buffer(17) <= x"45"; -- E
            screen_buffer(18) <= x"52"; -- R
            screen_buffer(19) <= x"4D"; -- M
            screen_buffer(20) <= x"4F"; -- O
            screen_buffer(21) <= x"3A"; -- :
            screen_buffer(22) <= x"20"; -- (espaço)
            screen_buffer(23) <= p0;
            screen_buffer(24) <= p1;
            screen_buffer(25) <= p2;
            screen_buffer(26) <= p3;
            screen_buffer(27) <= p4;
            screen_buffer(28) <= x"20"; -- (espaço)
            screen_buffer(29) <= x"20"; -- (espaço)
            screen_buffer(30) <= x"20"; -- (espaço)
            screen_buffer(31) <= x"20"; -- (espaço)

        elsif game_status = "11" then
            -- TELA DE DERROTA
            -- LOSE SCREEN: shows "game over" and reveals the keyword
            -- Linha 1: "FIM DE JOGO :("
            -- Line 1: static text "FIM DE JOGO :(" padded with spaces
            screen_buffer(0)  <= x"46"; -- F
            screen_buffer(1)  <= x"49"; -- I
            screen_buffer(2)  <= x"4D"; -- M
            screen_buffer(3)  <= x"20"; -- (espaço)
            screen_buffer(4)  <= x"44"; -- D
            screen_buffer(5)  <= x"45"; -- E
            screen_buffer(6)  <= x"20"; -- (espaço)
            screen_buffer(7)  <= x"4A"; -- J
            screen_buffer(8)  <= x"4F"; -- O
            screen_buffer(9)  <= x"47"; -- G
            screen_buffer(10) <= x"4F"; -- O
            screen_buffer(11) <= x"20"; -- (espaço)
            screen_buffer(12) <= x"3A"; -- :
            screen_buffer(13) <= x"28"; -- (
            screen_buffer(14) <= x"20"; -- (espaço)
            screen_buffer(15) <= x"20"; -- (espaço)

            -- Linha 2: "TERMO: _____"
            -- Line 2: static text "TERMO: " + the secret keyword (p0..p4), padded with spaces
            screen_buffer(16) <= x"54"; -- T
            screen_buffer(17) <= x"45"; -- E
            screen_buffer(18) <= x"52"; -- R
            screen_buffer(19) <= x"4D"; -- M
            screen_buffer(20) <= x"4F"; -- O
            screen_buffer(21) <= x"3A"; -- :
            screen_buffer(22) <= x"20"; -- (espaço)
            screen_buffer(23) <= p0;
            screen_buffer(24) <= p1;
            screen_buffer(25) <= p2;
            screen_buffer(26) <= p3;
            screen_buffer(27) <= p4;
            screen_buffer(28) <= x"20"; -- (espaço)
            screen_buffer(29) <= x"20"; -- (espaço)
            screen_buffer(30) <= x"20"; -- (espaço)
            screen_buffer(31) <= x"20"; -- (espaço)

        elsif game_status = "00" then
            -- TELA DE SETUP (ESCOLHA)
            -- SETUP SCREEN: asks for the secret keyword and echoes what is being typed
            -- Linha 1: "PALAVRA-CHAVE:  "
            -- Line 1: static text "PALAVRA-CHAVE:" (keyword prompt) padded with spaces
            screen_buffer(0)  <= x"50"; -- P
            screen_buffer(1)  <= x"41"; -- A
            screen_buffer(2)  <= x"4C"; -- L
            screen_buffer(3)  <= x"41"; -- A
            screen_buffer(4)  <= x"56"; -- V
            screen_buffer(5)  <= x"52"; -- R
            screen_buffer(6)  <= x"41"; -- A
            screen_buffer(7)  <= x"2D"; -- -
            screen_buffer(8)  <= x"43"; -- C
            screen_buffer(9)  <= x"48"; -- H
            screen_buffer(10) <= x"41"; -- A
            screen_buffer(11) <= x"56"; -- V
            screen_buffer(12) <= x"45"; -- E
            screen_buffer(13) <= x"3A"; -- :
            screen_buffer(14) <= x"20"; -- (espaço)
            screen_buffer(15) <= x"20"; -- (espaço)

            -- Linha 2: "> _____"
            -- Line 2: prompt "> " + the letters typed so far (char0..char4), padded with spaces
            screen_buffer(16) <= x"3E"; -- >
            screen_buffer(17) <= x"20"; -- (espaço)
            screen_buffer(18) <= char0;
            screen_buffer(19) <= char1;
            screen_buffer(20) <= char2;
            screen_buffer(21) <= char3;
            screen_buffer(22) <= char4;
            screen_buffer(23) <= x"20"; -- (espaço)
            screen_buffer(24) <= x"20"; -- (espaço)
            screen_buffer(25) <= x"20"; -- (espaço)
            screen_buffer(26) <= x"20"; -- (espaço)
            screen_buffer(27) <= x"20"; -- (espaço)
            screen_buffer(28) <= x"20"; -- (espaço)
            screen_buffer(29) <= x"20"; -- (espaço)
            screen_buffer(30) <= x"20"; -- (espaço)
            screen_buffer(31) <= x"20"; -- (espaço)

        else
            -- TELA DE JOGO
            -- PLAY SCREEN (status "01"): shows the current attempt, the word being typed,
            -- and the previous guess with its feedback
            -- Linha 1: "n/6: _____"
            -- Line 1: current attempt number + "/6:" + the letters typed so far
            screen_buffer(0)  <= play_attempt_ascii;
            screen_buffer(1)  <= x"2F"; -- /
            screen_buffer(2)  <= x"36"; -- 6
            screen_buffer(3)  <= x"3A"; -- :
            screen_buffer(4)  <= char0;
            screen_buffer(5)  <= char1;
            screen_buffer(6)  <= char2;
            screen_buffer(7)  <= char3;
            screen_buffer(8)  <= char4;
            screen_buffer(9)  <= x"20"; -- (espaço)
            screen_buffer(10) <= x"20"; -- (espaço)
            screen_buffer(11) <= x"20"; -- (espaço)
            screen_buffer(12) <= x"20"; -- (espaço)
            screen_buffer(13) <= x"20"; -- (espaço)
            screen_buffer(14) <= x"20"; -- (espaço)
            screen_buffer(15) <= x"20"; -- (espaço)

            -- Linha 2: "ÚLTIMA TENTATIVA + FEEDBACK"
            -- Line 2: last submitted guess, a space, and its feedback (V = right place, ? = wrong place, X = not in word)
            screen_buffer(16) <= last_c0;
            screen_buffer(17) <= last_c1;
            screen_buffer(18) <= last_c2;
            screen_buffer(19) <= last_c3;
            screen_buffer(20) <= last_c4;
            screen_buffer(21) <= x"20"; -- (espaço)
            screen_buffer(22) <= ans0;
            screen_buffer(23) <= ans1;
            screen_buffer(24) <= ans2;
            screen_buffer(25) <= ans3;
            screen_buffer(26) <= ans4;
            screen_buffer(27) <= x"20"; -- (espaço)
            screen_buffer(28) <= x"20"; -- (espaço)
            screen_buffer(29) <= x"20"; -- (espaço)
            screen_buffer(30) <= x"20"; -- (espaço)
            screen_buffer(31) <= x"20"; -- (espaço)
        end if;
    end process;

    -- Concatenate the 16 characters of line 1 into one 128-bit vector for the LCD driver
    -- (character 0 ends up in the most significant byte)
    line1_out <= screen_buffer(0)  & screen_buffer(1)  & screen_buffer(2)  & screen_buffer(3)  &
                 screen_buffer(4)  & screen_buffer(5)  & screen_buffer(6)  & screen_buffer(7)  &
                 screen_buffer(8)  & screen_buffer(9)  & screen_buffer(10) & screen_buffer(11) &
                 screen_buffer(12) & screen_buffer(13) & screen_buffer(14) & screen_buffer(15);

    -- Same for line 2 (buffer positions 16 to 31)
    line2_out <= screen_buffer(16) & screen_buffer(17) & screen_buffer(18) & screen_buffer(19) &
                 screen_buffer(20) & screen_buffer(21) & screen_buffer(22) & screen_buffer(23) &
                 screen_buffer(24) & screen_buffer(25) & screen_buffer(26) & screen_buffer(27) &
                 screen_buffer(28) & screen_buffer(29) & screen_buffer(30) & screen_buffer(31);

end rtl;
