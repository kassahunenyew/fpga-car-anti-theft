library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;

entity projectTest is
    Port(
        CLK : in std_logic; -- System Clock
        RESET : in std_logic; -- System Reset (active low)
        Key_in : in std_logic_vector(3 downto 0); -- Keypad input
        Key_valid : in std_logic; -- Signal indicating valid key press
        ALARM_LED : out std_logic; -- Alarm signal
        STATUS_7segmentDisplay : out std_logic_vector(6 downto 0); -- 7-segment display
        Buzzer : out std_logic; 
        LOCK_LED : out std_logic; 
        UNLOCK_LED : out std_logic 
    );
end projectTest;

architecture Behavioral of projectTest is

    -- FSM States
    type State_Type is (IDLE, DIGIT_ENTRY, VERIFY, ALARM, UNLOCKED, UNLOCK_DELAY);
    signal state, next_state : State_Type;

    -- Internal Signals
    signal correct_pass : std_logic_vector(15 downto 0) := "0001001000110100"; -- PIN: 1234
    signal entered_pin : std_logic_vector(15 downto 0) := (others => '0');
    signal digit_count : integer range 0 to 4 := 0;
    signal attempt_count : integer range 0 to 4 := 0;
    signal lock_timer : integer range 0 to 1000 := 0; -- Timeout counter (adjustable)
    signal unlock_timer : integer range 0 to 500 := 0; -- How long to stay unlocked
    signal timeout_active : std_logic := '0';
    signal key_pressed_prev : std_logic := '0';
    signal key_edge : std_logic := '0';

    -- 7-segment display patterns
    constant SEG_L : std_logic_vector(6 downto 0) := "1000111"; -- "L" for Locked
    constant SEG_E : std_logic_vector(6 downto 0) := "0000110"; -- "E" for Entry
    constant SEG_A : std_logic_vector(6 downto 0) := "0001000"; -- "A" for Alarm
    constant SEG_U : std_logic_vector(6 downto 0) := "1000001"; -- "U" for Unlocked
    constant SEG_DASH : std_logic_vector(6 downto 0) := "0111111"; -- "-" for default

begin

    -- Edge detection for key press
    key_edge <= Key_valid and not key_pressed_prev;

    -- Clocked process for state register and internal variables
    process(CLK, RESET)
    begin
        if RESET = '0' then
            state <= IDLE;
            entered_pin <= (others => '0');
            digit_count <= 0;
            attempt_count <= 0;
            lock_timer <= 0;
            unlock_timer <= 0;
            timeout_active <= '0';
            key_pressed_prev <= '0';
        elsif rising_edge(CLK) then
            state <= next_state;
            key_pressed_prev <= Key_valid;
            
            case state is
                when IDLE =>
                    -- Reset entry variables when in idle
                    entered_pin <= (others => '0');
                    digit_count <= 0;
                    
                    -- Handle timeout countdown
                    if timeout_active = '1' then
                        if lock_timer > 0 then
                            lock_timer <= lock_timer - 1;
                        else
                            timeout_active <= '0';
                            attempt_count <= 0;
                        end if;
                    end if;

                when DIGIT_ENTRY =>
                    -- Capture digit when key is pressed
                    if key_edge = '1' then
                        if digit_count < 4 then
                            -- Shift previous digits and add new digit
                            entered_pin <= entered_pin(11 downto 0) & Key_in;
                            digit_count <= digit_count + 1;
                        end if;
                    end if;

                when VERIFY =>
                    -- Increment attempt counter for wrong PIN
                    if entered_pin /= correct_pass then
                        if attempt_count < 3 then
                            attempt_count <= attempt_count + 1;
                        else
                            -- Start alarm timeout
                            timeout_active <= '1';
                            lock_timer <= 1000; -- 1000 clock cycles timeout (adjust as needed)
                        end if;
                    else
                        -- Correct PIN entered - reset attempt counter
                        attempt_count <= 0;
                        unlock_timer <= 500; -- Stay unlocked for 500 clock cycles
                    end if;

                when ALARM =>
                    -- Countdown in alarm state
                    if lock_timer > 0 then
                        lock_timer <= lock_timer - 1;
                    else
                        timeout_active <= '0';
                        attempt_count <= 0;
                    end if;

                when UNLOCKED =>
                    -- Countdown unlock timer
                    if unlock_timer > 0 then
                        unlock_timer <= unlock_timer - 1;
                    end if;

                when UNLOCK_DELAY =>
                    -- Brief delay state before returning to idle
                    null; -- Just transition handled in combinational logic

                when others =>
                    null;
            end case;
        end if;
    end process;

    -- Combinational process for next state logic
    process(state, key_edge, digit_count, entered_pin, correct_pass, attempt_count, 
            lock_timer, timeout_active, unlock_timer)
    begin
        -- Default: stay in current state
        next_state <= state;

        case state is
            when IDLE =>
                if timeout_active = '0' then
                    -- Only accept input if not in timeout
                    if key_edge = '1' then
                        next_state <= DIGIT_ENTRY;
                    end if;
                else
                    -- In timeout - go to alarm
                    if lock_timer > 0 then
                        next_state <= ALARM;
                    end if;
                end if;

            when DIGIT_ENTRY =>
                -- Check if we have 4 digits
                if digit_count >= 4 then
                    next_state <= VERIFY;
                end if;

            when VERIFY =>
                if entered_pin = correct_pass then
                    next_state <= UNLOCKED;
                else
                    if attempt_count >= 3 then
                        next_state <= ALARM;
                    else
                        next_state <= IDLE;
                    end if;
                end if;

            when ALARM =>
                if lock_timer = 0 then
                    next_state <= IDLE;
                end if;

            when UNLOCKED =>
                if unlock_timer = 0 then
                    next_state <= UNLOCK_DELAY;
                end if;

            when UNLOCK_DELAY =>
                next_state <= IDLE;

            when others =>
                next_state <= IDLE;
        end case;
    end process;

    -- Output assignment process
    process(state, timeout_active, digit_count)
    begin
        -- Default outputs
        ALARM_LED <= '0';
        Buzzer <= '0';
        LOCK_LED <= '0';
        UNLOCK_LED <= '0';
        STATUS_7segmentDisplay <= SEG_DASH;

        case state is
            when IDLE =>
                STATUS_7segmentDisplay <= SEG_L; -- "L" for Locked
                LOCK_LED <= '1';
                if timeout_active = '1' then
                    ALARM_LED <= '1'; -- Show alarm LED during timeout
                end if;

            when DIGIT_ENTRY =>
                STATUS_7segmentDisplay <= SEG_E; -- "E" for Entry
                LOCK_LED <= '1';

            when VERIFY =>
                STATUS_7segmentDisplay <= SEG_DASH; -- Processing
                LOCK_LED <= '1';

            when ALARM =>
                STATUS_7segmentDisplay <= SEG_A; -- "A" for Alarm
                ALARM_LED <= '1';
                Buzzer <= '1';
                LOCK_LED <= '1';

            when UNLOCKED =>
                STATUS_7segmentDisplay <= SEG_U; -- "U" for Unlocked
                UNLOCK_LED <= '1';

            when UNLOCK_DELAY =>
                STATUS_7segmentDisplay <= SEG_L; -- Back to locked display
                LOCK_LED <= '1';

            when others =>
                STATUS_7segmentDisplay <= SEG_DASH;
                LOCK_LED <= '1';
        end case;
    end process;

end Behavioral;