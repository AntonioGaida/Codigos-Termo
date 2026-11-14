library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- LCD driver for a 16x2 character LCD (HD44780-compatible controller) in 8-bit mode.
-- It initializes the display and then continuously refreshes both lines
-- with the 16 ASCII characters received on line1_in and line2_in.
entity lcd_driver is
    Port (
        clk       : in  STD_LOGIC; -- 50 MHz
        rst       : in  STD_LOGIC; -- Asynchronous reset (active high)
        line1_in  : in  STD_LOGIC_VECTOR(127 downto 0); -- Text for line 1: 16 chars x 8 bits (leftmost char in the MSBs)
        line2_in  : in  STD_LOGIC_VECTOR(127 downto 0); -- Text for line 2: 16 chars x 8 bits (leftmost char in the MSBs)
        lcd_e     : out STD_LOGIC; -- Enable
        lcd_rs    : out STD_LOGIC; -- Register select 
        lcd_rw    : out STD_LOGIC; -- Read/Write
        lcd_db    : out STD_LOGIC_VECTOR(7 downto 0) -- Data Bus
    );
end lcd_driver;

architecture rtl of lcd_driver is
    -- Steps 0-4: Init commands
    -- Step 5: Set Line 1 addr (0x80)
    -- Steps 6-21: Line 1 chars
    -- Step 22: Set Line 2 addr (0xC0)
    -- Steps 23-38: Line 2 chars
    -- Index of the byte (command or character) currently being sent to the LCD
    signal step     : integer range 0 to 38 := 0;
    -- Clock-cycle counter used to time the enable pulse and the wait after each byte
    signal clk_count  : integer range 0 to 1000000 := 0;
    -- Number of clock cycles to wait for the current step (set by the combinational process below)
    signal wait_lim : integer range 0 to 1000000 := 1000000;
begin
    
    lcd_rw <= '0'; -- Always write mode

    -- Select command or character byte for current step
    -- Combinational process: given the step, it drives RS, the data bus and the wait time
    process(step, line1_in, line2_in)
        -- Position (0 = leftmost) of the character being sent within its line
        variable char_index : integer range 0 to 15;
    begin
        -- Default values (avoid latches)
        lcd_rs   <= '0'; -- Commands / Instructions mode
        lcd_db   <= x"00";
        wait_lim <= 5000; -- Default 100 microseconds per cycle (5000 ticks @ 50 MHz)

        case step is
            when 0 =>
                -- Function set (first time), after the power-on delay
                lcd_db <= x"38"; -- 8-bit mode, 2 lines, 5x8 font
                wait_lim <= 1000000; -- 20 ms power-on wait
            when 1 =>
                -- Function set (repeated, as required by the LCD initialization sequence)
                lcd_db <= x"38";
                wait_lim <= 250000; -- 5 ms wait
            when 2 =>
                -- Display control
                lcd_db <= x"0C"; -- Display ON, Cursor OFF
                wait_lim <= 10000; -- 0.2 ms wait
            when 3 =>
                -- Clear display (slow command, needs a longer wait)
                lcd_db <= x"01"; -- Clear Display
                wait_lim <= 150000; -- 3 ms wait for clear
            when 4 =>
                -- Entry mode set
                lcd_db <= x"06"; -- Entry mode: increment cursor
                wait_lim <= 10000; -- 0.2 ms wait
            when 5 =>
                -- Move the cursor to the start of line 1 (uses the default 100 us wait)
                lcd_db <= x"80"; -- DDRAM address - Line 1
            when 6 to 21 =>
                -- Send the 16 characters of line 1, leftmost character first
                lcd_rs <= '1'; -- Character write mode
                -- Step 6 -> index 15 (MSBs of line1_in), step 21 -> index 0 (LSBs)
                char_index := 21 - step;
                -- Select the byte at position char_index from the 128-bit vector
                lcd_db <= line1_in((char_index*8 + 7) downto (char_index*8));
            when 22 =>
                -- Move the cursor to the start of line 2
                lcd_db   <= x"C0"; -- DDRAM address - Line 2
            when 23 to 38 =>
                -- Send the 16 characters of line 2, leftmost character first
                lcd_rs <= '1'; -- Character write mode
                -- Step 23 -> index 15 (MSBs of line2_in), step 38 -> index 0 (LSBs)
                char_index := 38 - step;
                -- Select the byte at position char_index from the 128-bit vector
                lcd_db <= line2_in((char_index*8 + 7) downto (char_index*8));
        end case;
    end process;

    -- Generate enable pulse and advance through sequence
    -- Sequential process: for each step it counts clock cycles, pulses E in the middle
    -- of the interval, waits wait_lim cycles, and then moves to the next step
    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset: restart the initialization sequence from step 0
            step    <= 0;
            clk_count <= 0;
            lcd_e   <= '0';
        elsif rising_edge(clk) then
            if clk_count < wait_lim then
                -- Still waiting for the current step: keep counting
                clk_count <= clk_count + 1;
                -- Assert enable between 50 and 100 clock cycles (0,001 ms pulse)
                -- The LCD latches RS and the data bus on the falling edge of E
                if (clk_count >= 50) and (clk_count < 100) then
                    lcd_e <= '1';
                else
                    lcd_e <= '0';
                end if;
            else
                -- Wait finished: restart the counter and go to the next step
                clk_count <= 0;
                lcd_e   <= '0';
                if step = 38 then
                    step <= 5; -- Loop continuously refreshing Line 1 and Line 2
                else
                    step <= step + 1;
                end if;
            end if;
        end if;
    end process;
end rtl;
