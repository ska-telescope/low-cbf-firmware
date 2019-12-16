---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Fine (CTF) - Main Package
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert.abel@autac.nz)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- Provides basic functions and data records for the Fine Corner Turner
--
---------------------------------------------------------------------------------------------------
-- NOTE:
-- The data records support a metadata part that is only used in simulation to ease debugging.
-- It is explicitly excluded from synthesis using pragmas.
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

package ctf_pkg is
    
    constant pc_CTF_DATA_WIDTH    : natural := 16; --re+im
    constant pc_CTF_INPUT_NUMBER  : natural := 4;  --how many input ports are there?
    constant pc_CTF_OUTPUT_NUMBER : natural := 4;  --how many output ports are there?
    constant pc_CTF_OUTPUT_FACTOR : natural := 4;  --how many re+im values are there in parallel per output port?
    constant pc_CTF_META_WIDTH    : natural := 9+4+9+1+32+13;
    constant pc_CTF_HEADER_WIDTH  : natural := 128;
    
    type t_ctf_payload is record     
        re       : std_logic_vector(7 downto 0);
        im       : std_logic_vector(7 downto 0);
    end record;

    function payload_to_slv(i: t_ctf_payload) return std_logic_vector;
    function slv_to_payload(i: std_logic_vector) return t_ctf_payload;

    type t_ctf_meta is record    
        coarse   : std_logic_vector(8 downto 0);
        st_group : std_logic_vector(3 downto 0);
        station  : std_logic_vector(8 downto 0);
        pol      : std_logic_vector(0 downto 0);
        ts       : std_logic_vector(31 downto 0);
        fine     : std_logic_vector(12 downto 0);
    end record;
    type t_ctf_meta_a is array (integer range <>) of t_ctf_meta;

    function slv_to_meta(i: std_logic_vector) return t_ctf_meta;
    function slv_to_meta(i: std_logic_vector) return t_ctf_meta_a;
    function meta_to_slv(i: t_ctf_meta) return std_logic_vector;
    function meta_to_slv(i: t_ctf_meta_a) return std_logic_vector;

    type t_ctf_data is record
        data     : t_ctf_payload;
        meta     : t_ctf_meta;
    end record;
      
    type t_ctf_input_data_a is array (integer range <>) of t_ctf_data;
    
    type t_ctf_output_data   is array (pc_CTF_OUTPUT_FACTOR-1 downto 0) of t_ctf_data;
    type t_ctf_output_data_a is array (integer range <>) of t_ctf_output_data;

    
    type t_ctf_hbm_data is record
        data : std_logic_vector(255 downto 0);
        meta : t_ctf_meta_a(15 downto 0);
    end record;    

    type t_ctf_input_header is record
        timestamp         : std_logic_vector(43 downto 0);
        virtual_channel   : std_logic_vector(8 downto 0);
        station_id_1      : std_logic_vector(8 downto 0);
        station_id_2      : std_logic_vector(8 downto 0);
        reserved          : std_logic_vector(127 downto 71);
    end record;
    constant pc_CTC_INPUT_HEADER_ZERO : t_ctf_input_header := (others=>(others=>'0'));
    type t_ctf_input_header_a is array (integer range <>) of t_ctf_input_header;

    type t_ctf_output_header is record
        timestamp         : std_logic_vector(43 downto 0);
        virtual_channel   : std_logic_vector(8 downto 0);
        station_id_1      : std_logic_vector(8 downto 0);
        station_id_2      : std_logic_vector(8 downto 0);
        fine              : std_logic_vector(11 downto 0);
    end record;
    constant pc_CTC_OUTPUT_HEADER_ZERO : t_ctf_output_header := (others=>(others=>'0'));
    type t_ctf_output_header_a is array (integer range <>) of t_ctf_output_header;


    function slv_to_header(i: std_logic_vector(pc_CTF_HEADER_WIDTH-1 downto 0)) return t_ctf_input_header;
    function header_to_slv(i: t_ctf_input_header) return std_logic_vector;


    function log2_ceil(i: integer) return integer;
    function maxi (a: integer; b: integer) return integer;
    function sel (s: boolean; a: integer; b: integer) return integer;
    function THIS_IS_SIMULATION return boolean;

end package ctf_pkg;



package body ctf_pkg is

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

    function sel (s: boolean; a: integer; b: integer) return integer is
    begin
        if s then return a; else return b; end if;
    end function;


    function slv_to_meta(i: std_logic_vector) return t_ctf_meta is
        variable o:  t_ctf_meta;
        variable tmp: std_logic_vector(i'length-1 downto 0); --i can have a range that does not start at 0
    begin
        tmp := i;
        o.coarse   := tmp(08 downto 00);
        o.st_group := tmp(12 downto 09);
        o.station  := tmp(21 downto 13);
        o.pol      := tmp(22 downto 22);
        o.ts       := tmp(54 downto 23);
        o.fine     := tmp(67 downto 55);
        return o;
    end function;

    function slv_to_meta(i: std_logic_vector) return t_ctf_meta_a is
        constant segments : integer := i'length / pc_CTF_META_WIDTH;
        variable tmp      : std_logic_vector(i'length-1 downto 0); --i can have a range that does not start at 0
        variable o        : t_ctf_meta_a(segments-1 downto 0);
    begin
        tmp := i;
        for p in 0 to segments-1 loop
            o(p) := slv_to_meta(tmp((p+1)*pc_CTF_META_WIDTH-1 downto p*pc_CTF_META_WIDTH));
        end loop;
        return o;
    end function;

    function meta_to_slv(i: t_ctf_meta) return std_logic_vector is
        variable o: std_logic_vector(pc_CTF_META_WIDTH-1 downto 0);
    begin
        o(08 downto 00) := i.coarse;
        o(12 downto 09) := i.st_group;
        o(21 downto 13) := i.station;
        o(22 downto 22) := i.pol;
        o(54 downto 23) := i.ts;
        o(67 downto 55) := i.fine;
        return o;
    end function;

    function meta_to_slv(i: t_ctf_meta_a) return std_logic_vector is
        variable o: std_logic_vector((i'length)*pc_CTF_META_WIDTH-1 downto 0);
    begin
        for p in 0 to i'length-1 loop
            o((p+1)*pc_CTF_META_WIDTH-1 downto p*pc_CTF_META_WIDTH) := meta_to_slv(i(p));
        end loop;
        return o;
    end function;

    function slv_to_header(i: std_logic_vector(pc_CTF_HEADER_WIDTH-1 downto 0)) return t_ctf_input_header is
        variable o: t_ctf_input_header;
    begin
        o.timestamp         := i(43 downto 00);
        o.virtual_channel   := i(52 downto 44);
        o.station_id_1      := i(61 downto 53);
        o.station_id_2      := i(70 downto 62);
        o.reserved          := i(127 downto 71);
        return o;
    end function;

    function header_to_slv(i: t_ctf_input_header) return std_logic_vector is
        variable o: std_logic_vector(pc_CTF_HEADER_WIDTH-1 downto 0);
    begin
        o(43 downto 00)  := i.timestamp;
        o(52 downto 44)  := i.virtual_channel;
        o(61 downto 53)  := i.station_id_1;
        o(70 downto 62)  := i.station_id_2;
        o(127 downto 71) := i.reserved;
        return o;
    end function;

    function payload_to_slv(i: t_ctf_payload) return std_logic_vector is
        variable o: std_logic_vector(15 downto 0);
    begin
        o(07 downto 00) := i.re;
        o(15 downto 08) := i.im;
        return o;    
    end function;

    function slv_to_payload(i: std_logic_vector) return t_ctf_payload is
        variable o   : t_ctf_payload;
        variable tmp : std_logic_vector(15 downto 0); 
    begin
        tmp  := i;
        o.re := tmp(07 downto 00);
        o.im := tmp(15 downto 08);
        return o;    
    end function;


    function THIS_IS_SIMULATION return boolean is
    begin
        -- synthesis translate_off
        return true;
        -- synthesis translate_on
        return false;
    end function;

end ctf_pkg;