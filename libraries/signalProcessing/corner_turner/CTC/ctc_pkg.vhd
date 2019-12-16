---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Coarse (CTC) - Main Package
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert_abel@gmx.net)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- Provides basic functions and data records for the Coarse Corner Turner
--
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

package ctc_pkg is
    
    constant pc_CTC_DATA_WIDTH    : natural := 16;         --re+im
    constant pc_CTC_META_WIDTH    : natural := 9+9+1+32+3; --coarse+station+pol+ts+in_port
    constant pc_CTC_HEADER_WIDTH  : natural := 128;
    constant pc_CTC_INPUT_NUMBER  : natural := 1;          --how many input ports are there?
    constant pc_STATIONS_PER_PORT : natural := 6;          --how many stations are there per input port?
    constant pc_STATION_NUMBER    : natural := pc_STATIONS_PER_PORT * pc_CTC_INPUT_NUMBER;
    constant pc_CTC_OUTPUT_NUMBER : natural := 2;          --how many output ports are there (hpol+vpol = 1 output)?
    constant pc_CTC_INPUT_TS_NUM  : natural := 2;          --how many timestamps per cycle on the input port?
    constant pc_CTC_INPUT_WIDTH   : natural := pc_CTC_DATA_WIDTH*2*pc_CTC_INPUT_TS_NUM;  --dual polarisation x pc_CTC_INPUT_TS_NUM timestamps, to get 64 bit wide data input
    constant pc_CTC_MAX_STATIONS  : natural := 6;          --PISA: 512

    --------------------------------------------------
    -- WALL TIME
    --------------------------------------------------
    constant pc_WALL_TIME_LEN    : natural := 32+30;
    type t_wall_time is record
        sec : std_logic_vector(31 downto 0);
        ns  : std_logic_vector(29 downto 0);
    end record; 
    function slv_to_wall_time(i: std_logic_vector) return t_wall_time;
    function wall_time_to_slv(i: t_wall_time) return std_logic_vector;   
    function "<=" (i1, i2: t_wall_time) return boolean;
    function ">=" (i1, i2: t_wall_time) return boolean;
    
    --------------------------------------------------
    -- COMMON 16 bit DATA
    --------------------------------------------------
    type t_ctc_payload is record     
        re       : std_logic_vector(7 downto 0);
        im       : std_logic_vector(7 downto 0);
    end record;
    constant pc_CTC_PAYLOAD_ZERO : t_ctc_payload := (re=>(others=>'0'), im=>(others=>'0'));
    constant pc_CTC_PAYLOAD_RFI  : t_ctc_payload := (re=>B"10000000",   im=>B"10000000");     

    type t_ctc_meta is record    
        coarse   : std_logic_vector(8 downto 0);
        station  : std_logic_vector(8 downto 0);
        pol      : std_logic_vector(0 downto 0);
        ts       : std_logic_vector(31 downto 0);
        in_port  : std_logic_vector(2 downto 0);
    end record;
    constant pc_CTC_META_ZERO : t_ctc_meta := (coarse=>(others=>'0'), station=>(others=>'0'), pol=>(others=>'0'), ts=>(others=>'0'), in_port=>(others=>'0'));

    type t_ctc_meta_a is array (integer range <>) of t_ctc_meta;
    
    function slv_to_meta(i: std_logic_vector) return t_ctc_meta;
    function slv_to_meta(i: std_logic_vector) return t_ctc_meta_a;
    function meta_to_slv(i: t_ctc_meta) return std_logic_vector;
    function meta_to_slv(i: t_ctc_meta_a) return std_logic_vector;

    type t_ctc_data is record
        data     : t_ctc_payload;
        meta     : t_ctc_meta;
    end record;
    constant pc_CTC_DATA_ZERO : t_ctc_data := (data=>pc_CTC_PAYLOAD_ZERO, meta=>pc_CTC_META_ZERO);
    
    type t_ctc_coarse_data_a is array (integer range <>) of std_logic_vector(8 downto 0);
    type t_ctc_station_data_a is array (integer range <>) of std_logic_vector(8 downto 0);

    --------------------------------------------------
    -- INPUT DATA
    --------------------------------------------------
    type t_ctc_input_data    is array (pc_CTC_INPUT_WIDTH/pc_CTC_DATA_WIDTH-1 downto 0) of t_ctc_data;             
    type t_ctc_input_data_a  is array (integer range <>) of t_ctc_input_data;
    function payload_to_slv(i: t_ctc_input_data) return std_logic_vector;
    function slv_to_payload(i: std_logic_vector; seg: integer) return t_ctc_payload;
    type t_ctc_input_data_slv_a is array (integer range<>) of std_logic_vector(pc_CTC_INPUT_WIDTH-1 downto 0);

    type t_ctc_input_header is record
        virtual_channel   : std_logic_vector(8 downto 0);
        channel_frequency : std_logic_vector(8 downto 0);
        station_id        : std_logic_vector(8 downto 0);
        packet_count      : std_logic_vector(31 downto 0);
        reserved          : std_logic_vector(127 downto 59);
    end record;
    constant pc_CTC_INPUT_HEADER_ZERO : t_ctc_input_header := (
        virtual_channel   => (others =>'0'),
        channel_frequency => (others =>'0'),
        station_id        => (others =>'0'),
        packet_count      => (others =>'0'),
        reserved          => (others =>'0')
    );
    type t_ctc_input_header_a is array (integer range <>) of t_ctc_input_header;
    function slv_to_header(i: std_logic_vector(pc_CTC_HEADER_WIDTH-1 downto 0)) return t_ctc_input_header;
    function header_to_slv(i: t_ctc_input_header) return std_logic_vector;
   
    --------------------------------------------------
    -- OUTPUT DATA
    --------------------------------------------------
    type t_ctc_output_payload is record     
        hpol : t_ctc_payload;
        vpol : t_ctc_payload;
    end record;
    type t_ctc_output_data is record
        data     : t_ctc_output_payload;
        meta     : t_ctc_meta_a(1 downto 0); --0=hpol, 1=vpol
    end record;
    constant pc_CTC_OUTPUT_DATA_ZERO : t_ctc_data := (data=>pc_CTC_PAYLOAD_ZERO, meta=>pc_CTC_META_ZERO);
    type t_ctc_output_data_a is array (integer range <>) of t_ctc_output_data;

    type t_ctc_output_header is record
        timestamp         : std_logic_vector(42 downto 0);
        coarse_delay      : std_logic_vector(11 downto 0);
        virtual_channel   : std_logic_vector(8 downto 0);
        station_id        : std_logic_vector(8 downto 0);
        hpol_phase_shift  : std_logic_vector(15 downto 0);  
        vpol_phase_shift  : std_logic_vector(15 downto 0);  
    end record;
    constant pc_CTC_OUTPUT_HEADER_ZERO : t_ctc_output_header := (
        timestamp         => (others=>'0'),
        coarse_delay      => (others=>'0'),
        virtual_channel   => (others=>'0'),
        station_id        => (others=>'0'),
        hpol_phase_shift  => (others=>'0'),
        vpol_phase_shift  => (others=>'0')
    );
    type t_ctc_output_header_a is array (integer range <>) of t_ctc_output_header;
    
    --------------------------------------------------
    -- HBM DATA
    --------------------------------------------------
    type t_ctc_hbm_data is record
        data : std_logic_vector(255 downto 0);
        meta : t_ctc_meta_a(15 downto 0);
    end record;    
    constant pc_CTC_HBM_DATA_RFI  : t_ctc_hbm_data := (data=>X"8080808080808080808080808080808080808080808080808080808080808080", meta=>(others=>pc_CTC_META_ZERO));    
    type t_ctc_hbm_data_a is array (integer range <>) of t_ctc_hbm_data;

    
   
    --------------------------------------------------
    -- COMMON HELPER FUNCTIONS
    --------------------------------------------------
    
    function log2_ceil(i: integer) return integer;
    function maxi (a: integer; b: integer) return integer;
    function THIS_IS_SIMULATION return boolean;
    function sel (s: boolean; a: integer; b: integer) return integer;
    
    function fixed_string(s: string; l:integer) return string;

end package ctc_pkg;



package body ctc_pkg is

    --------------------------------------------------
    -- COMMON HELPER FUNCTIONS
    --------------------------------------------------
    function log2_ceil(i: integer) return integer is
    begin
        return integer(ceil(log2(real(i))));
    end function;
    
    function maxi (a: integer; b: integer) return integer is
    begin
        if (a>b) then
            return a;
        else
            return b;
        end if;        
    end function;

    function THIS_IS_SIMULATION return boolean is
    begin
        -- synthesis translate_off
        return true;
        -- synthesis translate_on
        return false;
    end function;
    
    function sel (s: boolean; a: integer; b: integer) return integer is
    begin
        if s then return a; else return b; end if;
    end function;

    function fixed_string(s: string; l:integer) return string is
        variable o: string(1 to l);
    begin
        if s'length>=256 then
            o:=s(1 to l);
        else
            o(1 to s'length):=s;
        end if;    
        return o;
    end function;

    --------------------------------------------------
    -- WALL TIME
    --------------------------------------------------
    function slv_to_wall_time(i: std_logic_vector) return t_wall_time is
        variable o: t_wall_time;
    begin
        o.sec := i(30+31 downto 30);
        o.ns  := i(29 downto 0);
        return o;
    end function;
    
    function wall_time_to_slv(i: t_wall_time) return std_logic_vector is
        variable o: std_logic_vector(30+32-1 downto 0);   
    begin
        o(30+31 downto 30) := i.sec;
        o(29 downto 0)     := i.ns;
        return o;
    end function;
     
    function "<=" (i1, i2: t_wall_time) return boolean is
    begin
        if wall_time_to_slv(i1) <= wall_time_to_slv(i2) then
            return true;
        else
            return false;
        end if;        
    end function;

    function ">=" (i1, i2: t_wall_time) return boolean is
    begin
        if wall_time_to_slv(i1) >= wall_time_to_slv(i2) then
            return true;
        else
            return false;
        end if;        
    end function;

    --------------------------------------------------
    -- COMMON 16 bit DATA
    --------------------------------------------------
    function slv_to_meta(i: std_logic_vector) return t_ctc_meta is
        variable o:  t_ctc_meta;
        variable tmp: std_logic_vector(i'length-1 downto 0); --i can have a range that does not start at 0
    begin
        tmp := i;
        o.coarse  := tmp(08 downto 00);
        o.station := tmp(17 downto 09);
        o.pol     := tmp(18 downto 18);
        o.ts      := tmp(50 downto 19);
        o.in_port := tmp(53 downto 51);
        return o;
    end function;

    function slv_to_meta(i: std_logic_vector) return t_ctc_meta_a is
        constant segments : integer := i'length / pc_CTC_META_WIDTH;
        variable tmp      : std_logic_vector(i'length-1 downto 0); --i can have a range that does not start at 0
        variable o        : t_ctc_meta_a(segments-1 downto 0);
    begin
        tmp := i;
        for p in 0 to segments-1 loop
            o(p) := slv_to_meta(tmp((p+1)*pc_CTC_META_WIDTH-1 downto p*pc_CTC_META_WIDTH));
        end loop;
        return o;
    end function;

    function meta_to_slv(i: t_ctc_meta) return std_logic_vector is
        variable o: std_logic_vector(pc_CTC_META_WIDTH-1 downto 0);
    begin
        o(08 downto 00) := i.coarse;
        o(17 downto 09) := i.station;
        o(18 downto 18) := i.pol;
        o(50 downto 19) := i.ts;
        o(53 downto 51) := i.in_port;
        return o;
    end function;

    function meta_to_slv(i: t_ctc_meta_a) return std_logic_vector is
        variable o: std_logic_vector((i'length)*pc_CTC_META_WIDTH-1 downto 0);
    begin
        for p in 0 to i'length-1 loop
            o((p+1)*pc_CTC_META_WIDTH-1 downto p*pc_CTC_META_WIDTH) := meta_to_slv(i(p));
        end loop;
        return o;
    end function;

    function payload_to_slv(i: t_ctc_input_data) return std_logic_vector is
        variable o: std_logic_vector(pc_CTC_INPUT_WIDTH-1 downto 0);
    begin
        for seg in 0 to pc_CTC_INPUT_WIDTH/pc_CTC_DATA_WIDTH-1 loop
            o(07+16*seg downto 0+16*seg) := i(seg).data.re;
            o(15+16*seg downto 8+16*seg) := i(seg).data.im;
        end loop;
        return o;    
    end function;

    function slv_to_payload(i: std_logic_vector; seg: integer) return t_ctc_payload is
        variable o: t_ctc_payload;
    begin
        o.re := i(07+16*seg downto 0+16*seg);
        o.im := i(15+16*seg downto 8+16*seg);
        return o;    
    end function;

    --------------------------------------------------
    -- HEADER
    --------------------------------------------------
    function slv_to_header(i: std_logic_vector(pc_CTC_HEADER_WIDTH-1 downto 0)) return t_ctc_input_header is
        variable o: t_ctc_input_header;
    begin
        o.virtual_channel   := i(08 downto 00);
        o.channel_frequency := i(17 downto 09);
        o.station_id        := i(26 downto 18);
        o.packet_count      := i(58 downto 27);
        o.reserved          := i(127 downto 59);
        return o;
    end function;

    function header_to_slv(i: t_ctc_input_header) return std_logic_vector is
        variable o: std_logic_vector(pc_CTC_HEADER_WIDTH-1 downto 0);
    begin
        o(08 downto 00)  := i.virtual_channel;
        o(17 downto 09)  := i.channel_frequency;
        o(26 downto 18)  := i.station_id;
        o(58 downto 27)  := i.packet_count;
        o(127 downto 59) := i.reserved;
        return o;
    end function;

end ctc_pkg;