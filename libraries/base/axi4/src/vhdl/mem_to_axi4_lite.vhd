LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE work.axi4_lite_pkg.ALL;

ENTITY mem_to_axi4_lite IS
   GENERIC (
      g_adr_w     : NATURAL := 8;
      g_dat_w     : NATURAL := 32;
      g_timeout   : NATURAL := 6);        -- 2^clocks for transaction timeout. Needs to be longer than 3* slowest clock on AXI bus

   PORT (
      rst      : IN  STD_LOGIC;   -- reset synchronous with mm_clk
      clk      : IN  STD_LOGIC;   -- memory-mapped bus clock

      -- Memory Mapped Slave in mm_clk domain
      sla_in   : IN  t_axi4_lite_mosi;
      sla_out  : OUT t_axi4_lite_miso;

      wren     : OUT STD_LOGIC;
      rden     : OUT STD_LOGIC;

      wr_adr   : OUT STD_LOGIC_VECTOR(g_adr_w-1 DOWNTO 0);
      wr_dat   : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
      rd_adr   : OUT STD_LOGIC_VECTOR(g_adr_w-1 DOWNTO 0);
      rd_dat   : IN STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
      rd_busy  : IN STD_LOGIC;
      rd_val   : IN STD_LOGIC;
      wr_busy  : IN STD_LOGIC;
      wr_val   : IN STD_LOGIC);
END mem_to_axi4_lite;


ARCHITECTURE str OF mem_to_axi4_lite IS

   SIGNAL i_sla_out                 : t_axi4_lite_miso;

   SIGNAL write_pending             : STD_LOGIC := '0';
   SIGNAL write_counter             : UNSIGNED(g_timeout-1 DOWNTO 0);
   SIGNAL write_trans_valid         : STD_LOGIC;
   SIGNAL i_wren_d                  : STD_LOGIC;
   SIGNAL i_wren                    : STD_LOGIC;

   SIGNAL read_pending              : STD_LOGIC := '0';
   SIGNAL read_counter              : UNSIGNED(g_timeout-1 DOWNTO 0);
   SIGNAL read_trans_valid          : STD_LOGIC;
   SIGNAL i_rden                    : STD_LOGIC;
   SIGNAL i_rden_d                  : STD_LOGIC;

   SIGNAL rresp                     : STD_LOGIC_VECTOR(1 DOWNTO 0);
   SIGNAL rresp_r                   : STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN


   sla_out <= i_sla_out;


---------------------------------------------------------------------------
-- Write Channel --
---------------------------------------------------------------------------


   write_timeout: PROCESS(clk)
   BEGIN
      IF rising_edge(clk) THEN
         i_wren_d <= i_wren;

         IF write_pending = '0' THEN
            IF sla_in.awvalid = '1' AND wr_busy = '0' THEN
               write_counter <= (OTHERS => '1');
               write_pending <= '1';
            END IF;
         ELSE
            -- Once the whole transaction is complete release pending and allow next
            IF i_sla_out.bvalid = '1' AND sla_in.bready = '1' THEN
               write_pending <= '0';
            ELSE
               write_counter <= write_counter - 1;
            END IF;
         END IF;
      END IF;
   END PROCESS;

   write_trans_valid <= '1' WHEN write_pending = '1' AND (write_counter = 0 OR wr_val = '1') ELSE '0';

   -- Assert ready after the transaction has been (or should have been) acknowledged
   i_sla_out.wready  <= write_trans_valid;
   i_sla_out.awready <= write_trans_valid;

   -- Write when data path and address path are valid (make it a single clock for neatness)
   i_wren <= sla_in.wvalid AND sla_in.awvalid AND NOT wr_busy;
   wren <= i_wren AND NOT i_wren_d;

   wr_adr <= sla_in.awaddr(g_adr_w+1 DOWNTO 2);            -- Correct for byte addressing, ARSG uses dword addressing
   wr_dat <= sla_in.wdata(g_dat_w-1 DOWNTO 0);

   -- Need to latch response code in case ready is asserted on response bus
   write_response_latch: PROCESS(CLK)
   BEGIN
      IF RISING_EDGE(CLK) THEN
         IF RST = '1' THEN
            i_sla_out.bvalid <= '0';
         ELSE
            IF i_sla_out.bvalid = '1' THEN
               IF sla_in.bready = '1' THEN
                  i_sla_out.bvalid <= '0';
               END IF;
            ELSE
               IF write_trans_valid = '1' THEN
                  i_sla_out.bvalid <= '1';
                  IF wr_val = '1' THEN
                     i_sla_out.bresp <= c_axi4_lite_resp_okay;
                  ELSE
                     i_sla_out.bresp <= c_axi4_lite_resp_slverr;
                  END IF;
               END IF;
            END IF;
         END IF;
      END IF;
   END PROCESS;

---------------------------------------------------------------------------
-- Read Channel --
---------------------------------------------------------------------------

   read_timeout: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         i_rden_d <= i_rden;

         IF read_pending = '0' THEN
            IF sla_in.arvalid = '1' AND rd_busy = '0' THEN
               read_counter <= (OTHERS => '1');
               read_pending <= '1';
            END IF;
         ELSE
            IF read_trans_valid = '1' THEN
               read_pending <= '0';
            ELSE
               read_counter <= read_counter - 1;
            END IF;
         END IF;
      END IF;
   END PROCESS;

   read_trans_valid <= '1' WHEN read_pending = '1' and (read_counter = 0 or rd_val = '1') ELSE '0';

   -- Acknowledge read when response is ready
   i_sla_out.arready <= read_trans_valid;

   -- Map read address bus
   rd_adr  <= sla_in.araddr(g_adr_w+1 DOWNTO 2);

   -- Read Enable when address is valid
   i_rden <= read_pending;
   rden <= i_rden and not(i_rden_d);

   -- Assert data valid after the transaction has been (or should have been) acknowledged
   i_sla_out.rvalid <= read_trans_valid;
   i_sla_out.rdata(g_dat_w-1 DOWNTO 0) <= rd_dat;

   -- If the address was decoded return OK otherwise error. Need to latch status as AXI clock
   -- crossing IP for AXI4Lite assumes values are static after the valid is deasserted

   rresp <= c_axi4_lite_resp_okay WHEN rd_val = '1' ELSE
            c_axi4_lite_resp_slverr;

   u_pipe_rresp : ENTITY common_lib.common_pipeline
   GENERIC MAP (
      g_pipeline    => 1,
      g_in_dat_w    => 2,
      g_out_dat_w   => 2)
   PORT MAP (
      clk         => clk,
      clken       => read_trans_valid,
      in_dat      => rresp,
      out_dat     => rresp_r);

      i_sla_out.rresp <= rresp WHEN read_trans_valid = '1' ELSE rresp_r;

END str;
