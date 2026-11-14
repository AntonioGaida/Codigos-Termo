library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Typing buffer: collects the characters typed on the keyboard into a 5-letter word.
-- It handles Backspace (erase last letter) and Enter (submit the word when 5 letters were typed).
entity typing_buffer is
    Port (
        clk             : in  std_logic; -- System clock
        rst             : in  std_logic; -- Synchronous reset (active high)
        char_ready      : in  std_logic; -- From PS2 driver: a new character is available on char_ascii
        guess_ready     : out std_logic; -- One-cycle pulse: the 5-letter word was submitted with Enter
        guess_checked   : in  std_logic; -- From control FSM: the word was consumed, so the buffer can be cleared
        char_ascii      : in  std_logic_vector(7 downto 0); -- ASCII code of the received character
        char0, char1, char2, char3, char4 : out std_logic_vector(7 downto 0) -- Current content of the buffer (5 letters)
    );
end typing_buffer;

architecture rtl of typing_buffer is
    -- Array of 5 characters (one byte each) that stores the word being typed
    type char_array is array (0 to 4) of std_logic_vector(7 downto 0);
    -- Buffer content; empty positions show '_' (x"5F")
    signal guess : char_array := (others => x"5F"); -- Inicializado com '_'
    -- Index of the next free position (0 to 5); 5 means the buffer is full
    signal write_ptr : integer range 0 to 5 := 0;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Default: no word submitted in this cycle
            guess_ready <= '0';
            if rst = '1' or guess_checked = '1' then
                -- Reset, or the word was already checked by the control FSM: clear the buffer
                guess <= (others => x"5F");
                write_ptr <= 0;
            elsif char_ready = '1' then
                -- A new key was received
                if char_ascii = x"08" then -- BACKSPACE
                    -- Erase the last typed letter (only if there is one)
                    if write_ptr > 0 then
                        write_ptr <= write_ptr - 1;
                        guess(write_ptr - 1) <= x"5F";
                    end if;
                elsif char_ascii = x"0D" then -- ENTER
                    -- Submit the word only if all 5 letters were typed
                    if write_ptr = 5 then
                        guess_ready <= '1';
                    end if;
                else -- Letras A-Z
                    -- Any other character is stored (as long as the buffer is not full)
                    if write_ptr < 5 then
                        guess(write_ptr) <= char_ascii;
                        write_ptr <= write_ptr + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Connect the internal array to the output ports
    char0 <= guess(0); char1 <= guess(1); char2 <= guess(2); char3 <= guess(3); char4 <= guess(4);
end rtl;
