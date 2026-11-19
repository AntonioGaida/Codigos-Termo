library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Control subsystem: a finite state machine (FSM) that controls the game flow
-- (setup -> wait for guess -> check -> result -> win/lose).
entity control_subsystem is
    Port (
        clk             : in  std_logic;  -- System clock
        rst             : in  std_logic;  -- Synchronous reset (active high)
        guess_ready     : in  std_logic;  -- Input: a word/guess was entered and is ready
        guess_checked   : out std_logic;  -- Output: acknowledges that the guess was consumed/checked
        flag_victory    : in  std_logic;  -- Input: the guess matches the keyword
        flag_max_att    : in  std_logic;  -- Input: the maximum number of attempts was reached
        en_keyword      : out std_logic;  -- Output: enable to store the secret keyword
        en_guess        : out std_logic;  -- Output: enable to store the player's guess
        inc_attempt     : out std_logic;  -- Output: increments the attempt counter
        game_status     : out std_logic_vector(1 downto 0) -- 00: Setup, 01: Play, 10: Win, 11: Lose
    );
end control_subsystem;

architecture rtl of control_subsystem is
    -- FSM states:
    -- SETUP  : waiting for the secret keyword to be entered
    -- HOLD   : waiting for the player's guess
    -- CHECK  : one cycle to let the guess be compared with the keyword
    -- RESULT : evaluates the comparison flags (win, lose or keep playing)
    -- WIN    : final state, player won
    -- LOSE   : final state, player lost
    type state is (SETUP, HOLD, CHECK, RESULT, WIN, LOSE);
    signal current_state, next_state : state;  -- Present state and next state
begin
    -- Sequential process: state register
    -- Updates the current state on each rising clock edge
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_state <= SETUP;         -- Reset returns the FSM to the initial state
            else
                current_state <= next_state;    -- Otherwise, advance to the computed next state
            end if;
        end if;
    end process;

    -- Combinational process: next-state logic and output logic
    -- Runs whenever the state or any input changes
    process(current_state, guess_ready, flag_victory, flag_max_att)
    begin
        -- Default values (avoid latches): outputs inactive and stay in the same state
        en_keyword <= '0';
        en_guess <= '0';
        inc_attempt <= '0';
        guess_checked <= '0';
        game_status <= "01";
        next_state <= current_state;
        case current_state is
            when SETUP =>
                game_status <= "00";            -- Status: Setup
                if guess_ready = '1' then       -- Keyword was entered
                    en_keyword <= '1';          -- Store the keyword
                    guess_checked <= '1';       -- Acknowledge the input
                    next_state <= HOLD;         -- Start waiting for guesses
                end if;
            when HOLD =>
                game_status <= "01";            -- Status: Play
                if guess_ready = '1' then       -- A guess was entered
                    en_guess <= '1';            -- Store the guess
                    inc_attempt <= '1';         -- Count this attempt
                    next_state <= CHECK;        -- Go compare the guess
                end if;
            when CHECK =>
                game_status <= "01";            -- Status: Play
                guess_checked <= '1';           -- Acknowledge that the guess is being checked
                next_state <= RESULT;           -- Move on to evaluate the result
            when RESULT =>
                game_status <= "01";            -- Status: Play
                if flag_victory = '1' then      -- Guess matched the keyword
                    next_state <= WIN;
                elsif flag_max_att = '1' then   -- No more attempts left
                    next_state <= LOSE;
                else                            -- Wrong guess but attempts remain
                    next_state <= HOLD;         -- Wait for a new guess
                end if;
            when WIN =>
                game_status <= "10";            -- Status: Win (stays here until reset)
            when LOSE =>
                game_status <= "11";            -- Status: Lose (stays here until reset)
        end case;
    end process;
end rtl;
