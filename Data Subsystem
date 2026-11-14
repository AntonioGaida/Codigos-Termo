library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Data subsystem (datapath) of the word-guessing game (Termo/Wordle style).
-- It stores the secret keyword, compares each 5-letter guess against it,
-- produces per-letter feedback and counts the attempts.
-- Feedback codes (ASCII): 'V' (x"56") = right letter, right position
--                         '?' (x"3F") = right letter, wrong position
--                         'X' (x"58") = letter not in the word
--                         ' ' (x"20") = blank / empty
entity data_subsystem is
    Port (
        clk             : in  std_logic;  -- System clock
        rst             : in  std_logic;  -- Synchronous reset (active high)
        en_keyword      : in  std_logic;  -- From control: store char0..char4 as the secret keyword
        en_guess        : in  std_logic;  -- From control: evaluate char0..char4 as a guess
        inc_attempt     : in  std_logic;  -- From control: increment the attempt counter
        attempt_count   : out integer range 0 to 6;  -- Number of attempts used so far
        flag_victory    : out std_logic;  -- '1' when all five letters are correct
        flag_max_att    : out std_logic;  -- '1' when the attempt limit (6) was reached
        char0, char1, char2, char3, char4 : in std_logic_vector(7 downto 0);        -- Input word (ASCII, one byte per letter)
        last_c0, last_c1, last_c2, last_c3, last_c4 : out std_logic_vector(7 downto 0);  -- Last guess submitted (for display)
        ans0, ans1, ans2, ans3, ans4 : out std_logic_vector(7 downto 0);            -- Feedback for each letter of the last guess
        p0, p1, p2, p3, p4 : out std_logic_vector(7 downto 0)                       -- Secret keyword (exposed as output)
    );
end data_subsystem;

architecture rtl of data_subsystem is
    -- Registers holding the secret keyword (one byte per letter)
    signal kw0, kw1, kw2, kw3, kw4 : std_logic_vector(7 downto 0); -- KeyWord
    -- Attempt counter, saturates at 6
    signal try_count : integer range 0 to 6 := 0; -- Internal Try/ Attempt Counter
    -- Internal copies of the feedback outputs (outputs cannot be read back in the logic below)
    signal ans0_s, ans1_s, ans2_s, ans3_s, ans4_s : std_logic_vector(7 downto 0) := (others => x"20");
begin
    -- Connect internal signals to the output ports
    ans0 <= ans0_s; ans1 <= ans1_s; ans2 <= ans2_s; ans3 <= ans3_s; ans4 <= ans4_s;
    attempt_count <= try_count;
    -- Victory: every feedback letter is 'V' (x"56")
    flag_victory  <= '1' when (ans0_s = x"56" and ans1_s = x"56" and ans2_s = x"56" and ans3_s = x"56" and ans4_s = x"56") else '0';
    -- Max attempts: counter reached 6
    flag_max_att  <= '1' when (try_count = 6) else '0';
    -- Expose the stored keyword
    p0 <= kw0; p1 <= kw1; p2 <= kw2; p3 <= kw3; p4 <= kw4;
    process(clk)
        -- Temporary results for each letter of the current guess (computed within one clock cycle)
        variable r0_v, r1_v, r2_v, r3_v, r4_v : std_logic_vector(7 downto 0);
        -- Marks which keyword positions were already matched, so a keyword letter is not counted twice
        variable used : std_logic_vector(4 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- Reset: clear keyword, last guess, feedback (all blanks) and the attempt counter
                kw0       <= x"20"; kw1     <= x"20"; kw2     <= x"20"; kw3     <= x"20"; kw4     <= x"20";
                last_c0   <= x"20"; last_c1 <= x"20"; last_c2 <= x"20"; last_c3 <= x"20"; last_c4 <= x"20";
                ans0_s    <= x"20"; ans1_s  <= x"20"; ans2_s  <= x"20"; ans3_s  <= x"20"; ans4_s  <= x"20";
                try_count <= 0;
            else
                if en_keyword = '1' then
                    -- Store the new secret keyword and start a fresh game
                    -- (clear last guess, feedback and attempt counter)
                    kw0       <= char0; kw1 <= char1; kw2 <= char2; kw3 <= char3; kw4 <= char4;
                    last_c0   <= x"20"; last_c1 <= x"20"; last_c2 <= x"20"; last_c3 <= x"20"; last_c4 <= x"20";
                    ans0_s    <= x"20"; ans1_s  <= x"20"; ans2_s  <= x"20"; ans3_s  <= x"20"; ans4_s  <= x"20";
                    try_count <= 0;
                end if;
                
                if en_guess = '1' then
                    -- Save the guess so it can be displayed
                    last_c0 <= char0; last_c1 <= char1; last_c2 <= char2; last_c3 <= char3; last_c4 <= char4;
                    -- Start assuming every letter is wrong ('X') and no keyword position is used
                    r0_v := x"58"; r1_v := x"58"; r2_v := x"58"; r3_v := x"58"; r4_v := x"58";
                    used := "00000";


                    -- Check 1: Acerto Exato (V)
                    -- Pass 1 (exact matches): same letter in the same position -> 'V' (x"56"),
                    -- and that keyword position is marked as used
                    if char0 = kw0 then
                        r0_v := x"56";
                        used(0) := '1';
                    end if;
                    if char1 = kw1 then
                        r1_v := x"56";
                        used(1) := '1';
                    end if;
                    if char2 = kw2 then
                        r2_v := x"56";
                        used(2) := '1';
                    end if;
                    if char3 = kw3 then
                        r3_v := x"56";
                        used(3) := '1';
                    end if;
                    if char4 = kw4 then
                        r4_v := x"56";
                        used(4) := '1';
                    end if;


                    -- Check 2: Acerto de Letra, Erro de Posição (?) 
                    -- Pass 2 (misplaced letters): for each letter still marked 'X', look for the same
                    -- letter in another keyword position that is not used yet. If found, mark it '?'
                    -- (x"3F") and mark that keyword position as used (handles repeated letters correctly).
                    -- Letter 0: compare with keyword positions 1..4
                    if r0_v = x"58" then
                        if    (char0 = kw1 and used(1) = '0') then
                            r0_v := x"3F";
                            used(1) := '1';
                        elsif (char0 = kw2 and used(2) = '0') then
                            r0_v := x"3F";
                            used(2) := '1';
                        elsif (char0 = kw3 and used(3) = '0') then
                            r0_v := x"3F";
                            used(3) := '1';
                        elsif (char0 = kw4 and used(4) = '0') then
                            r0_v := x"3F";
                            used(4) := '1';
                        end if;
                    end if;

                    -- Letter 1: compare with keyword positions 0, 2, 3, 4
                    if r1_v = x"58" then
                        if (char1 = kw0 and used(0) = '0') then
                            r1_v := x"3F";
                            used(0) := '1';
                        elsif (char1 = kw2 and used(2) = '0') then
                            r1_v := x"3F";
                            used(2) := '1';
                        elsif (char1 = kw3 and used(3) = '0') then
                            r1_v := x"3F";
                            used(3) := '1';
                        elsif (char1 = kw4 and used(4) = '0') then
                            r1_v := x"3F";
                            used(4) := '1';
                        end if;
                    end if;

                    -- Letter 2: compare with keyword positions 0, 1, 3, 4
                    if r2_v = x"58" then
                        if (char2 = kw0 and used(0) = '0') then
                            r2_v := x"3F";
                            used(0) := '1';
                        elsif (char2 = kw1 and used(1) = '0') then
                            r2_v := x"3F";
                            used(1) := '1';
                        elsif (char2 = kw3 and used(3) = '0') then
                            r2_v := x"3F";
                            used(3) := '1';
                        elsif (char2 = kw4 and used(4) = '0') then
                            r2_v := x"3F";
                            used(4) := '1';
                        end if;
                    end if;

                    -- Letter 3: compare with keyword positions 0, 1, 2, 4
                    if r3_v = x"58" then
                        if (char3 = kw0 and used(0) = '0') then
                            r3_v := x"3F";
                            used(0) := '1';
                        elsif (char3 = kw1 and used(1) = '0') then
                            r3_v := x"3F";
                            used(1) := '1';
                        elsif (char3 = kw2 and used(2) = '0') then
                            r3_v := x"3F";
                            used(2) := '1';
                        elsif (char3 = kw4 and used(4) = '0') then
                            r3_v := x"3F";
                            used(4) := '1';
                        end if;
                    end if;

                    -- Letter 4: compare with keyword positions 0, 1, 2, 3
                    if r4_v = x"58" then
                        if (char4 = kw0 and used(0) = '0') then
                            r4_v := x"3F";
                            used(0) := '1';
                        elsif (char4 = kw1 and used(1) = '0') then
                            r4_v := x"3F";
                            used(1) := '1';
                        elsif (char4 = kw2 and used(2) = '0') then
                            r4_v := x"3F";
                            used(2) := '1';
                        elsif (char4 = kw3 and used(3) = '0') then
                            r4_v := x"3F";
                            used(3) := '1';
                        end if;
                    end if;
                    -- Register the final feedback (valid from the next clock edge on)
                    ans0_s <= r0_v; ans1_s <= r1_v; ans2_s <= r2_v; ans3_s <= r3_v; ans4_s <= r4_v;
                end if;

                -- Count one more attempt (saturates at 6)
                if inc_attempt = '1' and try_count < 6 then
                    try_count <= try_count + 1;
                end if;
            end if;
        end if;
    end process;
end rtl;
