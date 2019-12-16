---------------------------------------------------------------------------------------------------
-- 
-- Signal processing - Main Package
--
---------------------------------------------------------------------------------------------------
--
-- Author  : David Humphrey & Norbert Abel (norbert_abel@gmx.net)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
-- Types used to connect different signal processing modules.
--
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

package DSP_topNoHBM_pkg is
    
    -- Number of FPGAs on the Z connect in the system
    -- = number of FPGAs the corner turner takes data from
    function get_FPGA_Zcount(arrayRelease : integer) return integer;
    -- Number of coarse channels processed by the corner turner
    function get_coarse_channels(arrayRelease : integer) return integer;
    -- Number of blocks in the output (=204 for all except for arrayRelease = -2, where it is smaller to speed up simulation)
    function get_output_time_count(arrayRelease : integer) return integer;
    -- how many packet counts wide are the AUX buffers? (PISA = 24)
    function get_aux_width(arrayRelease : integer) return integer;
    
    function get_output_preload(arrayRelease : integer) return integer; -- PISA : 11
    function get_coarse_delay_offset(arrayRelease : integer) return integer; -- PISA : 2
    -- map negative values of ARRAYRELEASE to 0 for use in the interconnect module, since it doesn't do anything special for the simulation only case.
    function get_IC_array_release(arrayRelease : integer) return integer;
    
    function get_maximum_drift(arrayRelease : integer) return integer;
    
    type t_wall_time is record
        sec : std_logic_vector(31 downto 0);
        ns  : std_logic_vector(29 downto 0);
    end record; 
    
end package DSP_topNoHBM_pkg;

package body DSP_topNoHBM_pkg is

    -- Note : Array Releases are :
    -- -2 = single FPGA, cut down numbers of channels and shorter frames for simulation only.
    -- -1 = single FPGA
    -- 0 = PISA,    FPGA array dimensions (z,x,y) = (3,1,1)
    -- 1 = AA1,     FPGA array dimensions (z,x,y) = (2,1,6)
    -- 2 = AA2,     FPGA array dimensions (z,x,y) = (2,6,3)
    -- 3 = AA3-ITF, FPGA array dimensions (z,x,y) = (4,6,2)
    -- 4 = AA3-CPF, FPGA array dimensions (z,x,y) = (8,6,3)
    -- 5 = AA4,     FPGA array dimensions (z,x,y) = (8,6,6)
    
    -- Number of FPGAs on the Z connect in the system
    -- = number of FPGAs the corner turner takes data from
    function get_FPGA_Zcount(arrayRelease : integer) return integer is
    begin
        if arrayRelease = -3 then
            return 1;
        elsif arrayRelease = -2 then
            return 1;
        elsif arrayRelease = -1 then
            return 1;
        elsif arrayRelease = 0 then -- PISA
            return 3;
        elsif arrayRelease = 1 then
            return 2;
        elsif arrayRelease = 2 then
            return 2;
        elsif arrayRelease = 3 then
            return 4;
        elsif arrayRelease = 4 then
            return 8;
        elsif arrayRelease = 5 then
            return 8;
        else
            return 8; -- report "bad array release value" severity failure;
        end if;
    end;

    function get_coarse_channels(arrayRelease : integer) return integer is
    begin
        if arrayRelease = -3 then
            return 4;
        elsif arrayRelease = -2 then
            return 16;
        elsif arrayRelease = -1 then
            return 128;
        elsif arrayRelease = 0 then -- PISA
            return 128;
        elsif arrayRelease = 1 then  
            return 192;
        elsif arrayRelease = 2 then
            return 192;
        elsif arrayRelease = 3 then
            return 96;
        elsif arrayRelease = 4 then
            return 48;
        elsif arrayRelease = 5 then
            return 48;
        else
            report "bad array release value" severity failure;
        end if;
    end;
    
    function get_output_time_count(arrayRelease : integer) return integer is
    begin
        if arrayRelease = -3 then
            return 8;
        elsif arrayRelease = -2 then
            return 16;
        else
            return 204;
        end if;
    end;

    function get_aux_width(arrayRelease : integer) return integer is
    begin
        if arrayRelease = -3 then
            return 4;
        elsif arrayRelease = -2 then
            return 24;
        else
            return 24;
        end if;
    end;
    
    function get_output_preload(arrayRelease : integer) return integer is
    begin
        if arrayRelease = -3 then
            return 1;
        elsif arrayRelease = -2 then
            return 11;
        else
            return 11;
        end if;
    end; -- PISA : 11
    
    function get_coarse_delay_offset(arrayRelease : integer) return integer is
    begin
        if arrayRelease = -3 then
            return 1;
        elsif arrayRelease = -2 then
            return 1;
        else
            return 2;
        end if;
    end; -- PISA : 2
    
    function get_IC_array_release(arrayRelease : integer) return integer is
    begin
        if (arrayRelease < 0) then
            return 0;
        else
            return arrayRelease;
        end if;
    end;
    
    function get_maximum_drift(arrayRelease : integer) return integer is
    begin
        if (arrayRelease < 0) then
            return 2;
        else
            return 20;
        end if;
    end;

    
end DSP_topNoHBM_pkg;