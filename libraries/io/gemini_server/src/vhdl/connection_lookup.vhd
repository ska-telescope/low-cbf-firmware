----------------------------------
-- Copyright (C) 2017
-- CSIRO (Commonwealth Scientific and Industrial Research Organization) <http://www.csiro.au/>
-- GPO Box 1700, Canberra, ACT 2601, Australia
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
--   Author           Date      Version comments
--   John Matthews    Dec 2017  Original
-----------------------------------

-- Purpose: Lookup connection table key
--
-- Description: The user inputs a client address identifier. This may,
--              for example, consist of the client IP address and UDP
--              port concatenated into a tuple like (IP,port).
--
--              This unit outputs the connection key that is associated
--              with the supplied client address identifier. The key
--              may be used by the user as a memory address to access
--              per-client state.
--
--              This module uses a linear search lookup since it is
--              assumed that g_noof_clnts will be about 3.
--
--              This module takes between 2 and g_noof_clnts + 3 clocks
--              to complete a lookup and assert complete_out after
--              the user has initiated a lookup with lookup_in = '1'.
--
--              This module supports the re-cycling of connections that
--              haven't been used for a time period that is greater
--              than g_min_recycle_secs. It does this by maintaining
--              a last_used timestamp for each connection. It is possible
--              for a lookup to fail if no existing connection can be
--              recycled.
--
-- Remarks:
--

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
LIBRARY common_lib;
USE common_lib.common_pkg.ALL;

ENTITY connection_lookup IS
    GENERIC (
        g_clnt_addr_w : NATURAL := 48;  -- Width of client address indentifier
        g_key_w : NATURAL := 2; -- Width of key (must be >= log2(g_noof_clnts-1)+1)
        g_noof_clnts : NATURAL := 3; -- Maximum number of clients (minimum value is 2)
        g_tod_w : NATURAL := 48; -- Width of ToD. Assume IEEE1588 ToD format with seconds precision
        g_min_recycle_secs : NATURAL RANGE 0 to 7*24*60
    );
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        lookup_in : IN STD_LOGIC; -- Start lookup, clnt_addr_in and tod_in are valid
        tod_in : IN STD_LOGIC_VECTOR(g_tod_w-1 DOWNTO 0); -- Time of Day with seconds resolution
        clnt_addr_in : IN STD_LOGIC_VECTOR (g_clnt_addr_w-1 DOWNTO 0);
        connect_in : IN STD_LOGIC; -- '1' if its a connect command
        key_out : OUT STD_LOGIC_VECTOR (g_key_w-1 DOWNTO 0);
        failed_out : OUT STD_LOGIC;
        recycle_out : OUT STD_LOGIC;
        complete_out : OUT STD_LOGIC; -- key_out & failed_out are valid
        -- status signals to send to the register interface
        client0IP : out std_logic_vector(31 downto 0);
        client0Port : out std_logic_vector(15 downto 0);
        client0LastUsed : out std_logic_vector(31 downto 0);
        client1IP : out std_logic_vector(31 downto 0);
        client1Port : out std_logic_vector(15 downto 0);
        client1LastUsed : out std_logic_vector(31 downto 0);
        client2IP : out std_logic_vector(31 downto 0);
        client2Port : out std_logic_vector(15 downto 0);
        client2LastUsed : out std_logic_vector(31 downto 0)
    );
END;

ARCHITECTURE rtl OF connection_lookup IS

    SUBTYPE t_tod IS UNSIGNED(g_tod_w-1 DOWNTO 0); -- Time of Day in seconds
    SUBTYPE t_clnt_addr IS STD_LOGIC_VECTOR(g_clnt_addr_w-1 DOWNTO 0);
    subtype t_timeout is UNSIGNED(ceil_log2(g_min_recycle_secs)-1 downto 0);

    TYPE t_state_enum IS ( s_wait, s_lookup, s_recycle, s_update );
    TYPE t_clnt_addr_col IS ARRAY( INTEGER RANGE <> ) OF t_clnt_addr;
    
    TYPE t_current_timeout is ARRAY ( INTEGER RANGE <> ) of t_timeout;
    -- Client connections are stored in a table with one connection per row
    -- Each row has the following columns: clnt_addr : Client address
    --                                     last_used : ToD that this row was last used
    --                                     in_use : '0' means that this row hasn't been used since last reset
    SIGNAL clnt_addr_col : t_clnt_addr_col (0 TO g_noof_clnts-1);
    SIGNAL in_use_col : STD_LOGIC_VECTOR(g_noof_clnts-1 DOWNTO 0);

    SIGNAL state : t_state_enum;
    SIGNAL row : NATURAL RANGE 0 TO g_noof_clnts-1;
    SIGNAL recyclable_row : NATURAL RANGE 0 TO g_noof_clnts-1;
    SIGNAL clnt_addr : t_clnt_addr;
    --SIGNAL recyclable_avail : STD_LOGIC;
    SIGNAL unused_avail : STD_LOGIC;
    signal checkTimeout : std_logic;
    
    signal seconds_in : std_logic;
    signal seconds_in_del1: std_logic;
    signal seconds_in_del2: std_logic;
    signal pps: std_logic;
    signal expiry_secs: t_current_timeout(0 to g_noof_clnts-1);
    signal reload_expiry: std_logic_vector(g_noof_clnts-1 downto 0);

    

BEGIN
    
    -- countdown timers for connection timeouts
    expiry_counters: for i in g_noof_clnts-1 downto 0 GENERATE
        down_cnt: PROCESS(clk)
        BEGIN
            if rising_edge(clk) then
                if rst = '1' then
                    expiry_secs(i) <= (others => '0');
                elsif reload_expiry(i) = '1' then
                    expiry_secs(i) <= TO_UNSIGNED(g_min_recycle_secs, ceil_log2(g_min_recycle_secs));
                elsif pps = '1' then
                    if expiry_secs(i) = TO_UNSIGNED(0, ceil_log2(g_min_recycle_secs)) THEN
                        expiry_secs(i) <= (others => '0');
                    else
                        expiry_secs(i) <= expiry_secs(i) - 1;
                    end if;
                else
                    expiry_secs(i) <= expiry_secs(i);
                end if;
            end if;
        END PROCESS;
    END GENERATE;


    -- The connection lookup state machine
    p_lookup : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF rst = '1'  THEN
                state <= s_wait;
                complete_out <= '0';
                in_use_col <= (others=>'0');
            ELSE
                -- generate a pulse per second from the TimeOfDay input (tod_in) LSB
                seconds_in <= tod_in(0); -- metastable, different clock domains
                seconds_in_del1 <= seconds_in;
                seconds_in_del2 <= seconds_in_del1;
                pps <= seconds_in_del1 xor seconds_in_del2;

                -- Find a recyclable row using the rules:
                --  1) Use an unused row if there's one available
                --  2) Use the row with the oldest last_used time but only if it was used prior to tod - min_recycle_secs
	            IF in_use_col(row) = '0' THEN
		            unused_avail <= '1';
                    recyclable_row <= row;
                END IF;

                if checkTimeout = '1' AND expiry_secs(row) = TO_UNSIGNED(0, ceil_log2(g_min_recycle_secs))  THEN
                    -- this continually checks the age of the connection in the default state and clears
                    -- in_use_col if the connection has timed out.
                    in_use_col(row) <= '0';
                end if;

                -- Connection lookup state machine
                complete_out <= '0';
                CASE state IS
                    WHEN s_lookup =>
                        checkTimeout <= '0';
                        reload_expiry <= (others =>'0');
                        IF (in_use_col(row) = '1') AND (clnt_addr_col(row) = clnt_addr) THEN
                            reload_expiry(row) <= '1';
                            state <= s_wait;
                            complete_out <= '1';
                            failed_out <= '0';
                            recycle_out <= '0';
                        ELSIF (row = g_noof_clnts-1) THEN
                            state <= s_recycle;
                        ELSE
                            row <= row + 1;
                        END IF;
                    WHEN s_recycle =>
                        reload_expiry <= (others =>'0');
                        row <= recyclable_row;
                        state <= s_update;
                        checkTimeout <= '0';
                        IF connect_in = '0' OR ( unused_avail = '0')  THEN
                            failed_out <= '1';
                            recycle_out <= '0';
                            complete_out <= '1';
                            state <= s_wait;
                        END IF;
                    WHEN s_update =>
                        reload_expiry <= (others =>'0');
                        complete_out <= '1';
                        failed_out <= '0';
                        recycle_out <= NOT unused_avail;
                        clnt_addr_col(row) <= clnt_addr;
                        in_use_col(row) <= '1';
                        reload_expiry(row) <= '1';
                        checkTimeout <= '0';
                        state <= s_wait;
                    WHEN OTHERS => -- Includes s_wait
                        reload_expiry <= (others =>'0');
                        clnt_addr <= clnt_addr_in;
                        --recyclable_avail <= '0';
                        unused_avail <= '0';
                        IF lookup_in = '1' THEN
                            state <= s_lookup;
                            row <= 0;
                            checkTimeout <= '0';
                        else
                            if (row = g_noof_clnts-1) then
                                row <= 0;
                            else
                                row <= row + 1;
                            end if;
                            checkTimeout <= '1';
                        END IF;
                END CASE;

                key_out <= STD_LOGIC_VECTOR(TO_UNSIGNED(row,g_key_w));



                client0IP <= clnt_addr_col(0)(31 downto 0); -- : out std_logic_vector(31 downto 0);
                client0Port <= clnt_addr_col(0)(47 downto 32); -- : out std_logic_vector(15 downto 0);
                client0LastUsed(ceil_log2(g_min_recycle_secs) - 1 downto 0) <= std_logic_vector(expiry_secs(0));
                client0LastUsed(30 downto ceil_log2(g_min_recycle_secs)) <= (others => '0');
                client0LastUsed(31) <= in_use_col(0);

                if (g_noof_clnts > 1) then
                    client1IP <= clnt_addr_col(1)(31 downto 0); -- : out std_logic_vector(31 downto 0);
                    client1Port <= clnt_addr_col(1)(47 downto 32);-- : out std_logic_vector(15 downto 0);
                    client1LastUsed(ceil_log2(g_min_recycle_secs) - 1 downto 0) <= std_logic_vector(expiry_secs(1));
                    client1LastUsed(30 downto ceil_log2(g_min_recycle_secs)) <= (others => '0');
                    client1LastUsed(31) <= in_use_col(1);
                else
                    client1IP <= (others => '0');
                    client1Port <= (others => '0');
                    client1LastUsed <= (others => '0');
                end if;

                if (g_noof_clnts > 2) then
                    client2IP <= clnt_addr_col(2)(31 downto 0); -- : out std_logic_vector(31 downto 0);
                    client2Port <= clnt_addr_col(2)(47 downto 32);--: out std_logic_vector(15 downto 0);
                    client2LastUsed(ceil_log2(g_min_recycle_secs) - 1 downto 0) <= std_logic_vector(expiry_secs(2));
                    client2LastUsed(30 downto ceil_log2(g_min_recycle_secs)) <= (others => '0');
                    client2LastUsed(31) <= in_use_col(2);
                else
                    client2IP <= (others => '0');
                    client2Port <= (others => '0');
                    client2LastUsed <= (others => '0');
                end if;

            END IF;
        END IF;
    END PROCESS;

END rtl;
