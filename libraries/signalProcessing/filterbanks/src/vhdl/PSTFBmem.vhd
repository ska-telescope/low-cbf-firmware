----------------------------------------------------------------------------------
-- Company: CSIRO - CASS
-- Engineer: David Humphrey
-- 
-- Create Date: 06.12.2018 10:49:58
-- Module Name: PSTFBmem - Behavioral
-- Description: 
--   
-- 
----------------------------------------------------------------------------------
library IEEE, common_lib, filterbanks_lib;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use common_lib.common_pkg.all;

entity PSTFBMem is
    generic (
        TAPS : integer := 12;      -- Note only partially parameterized; modification needed to support anything other than 12.
        -- Number of bits in the data path; Default is 96 = 6*16 bits. 
        -- Only partially parameterised; 
        --  * Set the data type of rd_data_o to match.
        --  * Width of the distributed memory IP block also needs to be set to match. 
        DATAWIDTH : integer := 96  
    );
    port(
        clk          : in std_logic;
        FIRTapUse_i  : in std_logic;   -- FIR Taps are double buffered, choose which set of TAPs to use.
        -- Write data for the start of the chain
        wrData_i     : in std_logic_vector((DATAWIDTH-1) downto 0);
        wrAddr_i     : in std_logic_vector(8 downto 0);
        wrEn_i       : in std_logic; -- should be a burst of 4096 clocks.
        -- Read data, comes out 2 clocks after the first write.
        rdData_o     : out t_slv_96_arr(TAPS-1 downto 0);  -- 96 (=6*16) bits wide, 12 taps simultaneously; First sample is wr_data_i delayed by 1 clock.
        rdAddr_i     : in std_logic_vector(8 downto 0);
        rdWrEn_i     : in std_logic;
        -- Read FIR filter taps
        romAddr_i    : in std_logic_vector(7 downto 0); 
        coef_o       : out t_slv_18_arr(TAPS-1 downto 0);  -- 18 bits per filter tap.
        -- Writing FIR Taps
        FIRTapData_i   : in std_logic_vector(17 downto 0);   -- For register writes of the filtertaps.
        FIRTapData_o   : out std_logic_vector(17 downto 0);  -- For register reads of the filtertaps. 3 cycle latency from FIRTapAddr_i
        FIRTapAddr_i   : in std_logic_vector(11 downto 0);   -- 256 * 12 filter taps = 3072 total.
        FIRTapWE_i     : in std_logic;
        FIRTapClk      : in std_logic;
        FIRTapSelect_i : in std_logic  -- FIR Taps are double buffered; this selects the buffer to access for registers. Choose which buffer to use with FIRTapUse_i
    );
end PSTFBMem;

architecture Behavioral of PSTFBmem is

    -- Store the filter taps.
    -- Dual port so it can be read/written over MACE.
    -- ok, it's not a ROM, but it's used that way most of the time.
    
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSTROM1 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSTROM1} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSTFIRTaps1.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTROM1]
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSTROM2 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSTROM2} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSTFIRTaps2.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTROM2]
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSTROM3 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSTROM3} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSTFIRTaps3.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTROM3]
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSTROM4 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSTROM4} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSTFIRTaps4.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTROM4]
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSTROM5 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSTROM5} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSTFIRTaps5.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTROM5]
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSTROM6 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSTROM6} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSTFIRTaps6.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTROM6]
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSTROM7 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSTROM7} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSTFIRTaps7.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTROM7]
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSTROM8 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSTROM8} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSTFIRTaps8.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTROM8]
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSTROM9 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSTROM9} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSTFIRTaps9.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTROM9]
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSTROM10 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSTROM10} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSTFIRTaps10.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTROM10]
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSTROM11 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSTROM11} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSTFIRTaps11.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTROM11]
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSTROM12 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSTROM12} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSTFIRTaps12.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTROM12]
    
    component PSTFB_ROM1
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(8 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(8 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;

    component PSTFB_ROM2
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(8 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(8 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;

    component PSTFB_ROM3
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(8 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(8 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component; 

    component PSTFB_ROM4
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(8 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(8 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component; 
    
    component PSTFB_ROM5
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(8 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(8 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component; 
    
    component PSTFB_ROM6
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(8 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(8 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;

    component PSTFB_ROM7
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(8 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(8 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component; 
    
    component PSTFB_ROM8
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(8 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(8 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component; 
    
    component PSTFB_ROM9
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(8 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(8 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component; 

    component PSTFB_ROM10
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(8 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(8 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;
    
    component PSTFB_ROM11
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(8 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(8 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;

    component PSTFB_ROM12
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(8 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(8 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component; 
    
    -- Memories for the data.
    -- Simple dual port, 512 deep by 96 bits wide.
    -- two cycle read latency.
    component PSTFBsdp512x96
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(8 downto 0);
        dina  : in std_logic_vector(95 downto 0);
        clkb  : in std_logic;
        addrb : in std_logic_vector(8 downto 0);
        doutb : out std_logic_vector(95 downto 0));
    end component;

    
    signal FIRTapsWE : t_slv_1_arr((TAPS-1) downto 0);
    signal FIRTapRegAddr : std_logic_vector(8 downto 0);  -- double buffered; 2x256 buffers = 9 bit address
    signal FIRTapRegWrData : std_logic_vector(17 downto 0);
    signal FIRTapRegRdData : t_slv_18_arr((TAPS-1) downto 0);
    signal dummy0SLV : std_logic_vector(0 downto 0);
    signal FIRTapAddrDel1, FIRTapAddrDel2, FIRTapAddrDel3 : std_logic_vector(3 downto 0) := "0000";
    signal dummy0_18 : std_logic_vector(17 downto 0);
    
    signal romAddrDel : t_slv_9_arr((TAPS-1) downto 0):= (others => (others => '0'));
    signal rdAddrDelFull : t_slv_9_arr(TAPS downto 0);
    signal rdAddrDel70 : t_slv_8_arr((TAPS) downto 0) := (others => (others => '0'));
    signal rdAddrDel8 : std_logic_vector(TAPS downto 0) := (others => '0');
    signal wrEnslv : std_logic_vector(0 downto 0);
    signal rdDataDel : t_slv_96_arr((TAPS-1) downto 0);
    signal rdWrEnDel : t_slv_1_arr((TAPS) downto 0) := (others => (others => '0'));
    
begin
    
    wrEnslv(0) <= wrEn_i;
    
    firstMem : PSTFBsdp512x96
    port map(
        -- write side
        clka => clk,
        wea => wrEnslv,
        addra => wrAddr_i,
        dina => wrData_i,
        -- read side
        clkb => clk,
        addrb => rdAddrDelFull(0),
        doutb => rdDataDel(0)
    );
    
    rdAddrDel70(0) <= rdAddr_i(7 downto 0);
    rdAddrDel8(0) <= rdAddr_i(8);
    rdAddrDelFull(0) <= rdAddrDel8(0) & rdAddrDel70(0);
    romAddrDel(0) <= FIRTapUse_i & romAddr_i;
    rdData_o(0) <= rdDataDel(0);
    rdWrEnDel(0)(0) <= rdWrEn_i;
    
    process(clk)
    begin
        if rising_edge(clk) then
           
            rdAddrDel70(TAPS downto 1) <= rdAddrDel70((TAPS-1) downto 0);
            rdAddrDel8(TAPS downto 1) <= not rdAddrDel8((TAPS-1) downto 0); -- read and write alternate between different halves of the memories.
            
            romAddrDel((TAPS-1) downto 1) <= romAddrDel((TAPS-2) downto 0);
            rdWrEnDel(TAPS downto 1) <= rdWrEnDel(TAPS-1 downto 0);
        end if;
    end process;
    
    
    rdAddrDelFull(TAPS) <= rdAddrDel8(TAPS) & rdAddrDel70(TAPS);
    
    othermem : for i in 1 to (TAPS-1) generate
        
        rdAddrDelFull(i) <= rdAddrDel8(i) & rdAddrDel70(i);
        
        otherMemi : PSTFBsdp512x96
        port map(
            -- write side
            clka => clk,
            wea => rdWrEnDel(i+1),  -- writes occur one clock after the reads, hence +1.
            addra => rdAddrDelFull(i+1),
            dina => rdDataDel(i-1),
            -- read side
            clkb => clk,
            addrb => rdAddrDelFull(i),
            doutb => rdDataDel(i)
        );
        
        rdData_o(i) <= rdDataDel(i);
    end generate;

    --------------------------------------------------------------------------------------
    -- Filter Coefficients
    -- 12 memories, each 18 bits wide, 512 deep, dual port.
    -- Port A used to write new coefficients
    -- Port B used to read.

    -- Note register ports are 
    --  FIRTapData_i : in std_logic_vector(17 downto 0);
    --  FIRTapData_o : out std_logic_vector(17 downto 0);
    --  FIRTapAddr_i : in std_logic_vector(7 downto 0);  -- 256 * 12 filter taps = 3072 total.
    --  FIRTapWE_i   : in std_logic;
    --  FIRTapClk    : in std_logic
    
    process(FIRTapClk)
    begin
        if rising_edge(FIRTapClk) then
            for ft in 0 to (TAPS-1) loop
                if (FIRTapWE_i = '1' and FIRTapAddr_i(11 downto 8) = std_logic_vector(to_unsigned(ft,4))) then
                    FIRTapsWE(ft)(0) <= '1';
                else
                    FIRTapsWE(ft)(0) <= '0';
                end if; 
            end loop;
            FIRTapRegAddr <= FIRTapSelect_i & FIRTapAddr_i(7 downto 0);
            FIRTapRegWrData <= FIRTapData_i;
            
            FIRTapAddrDel1 <= FIRTapAddr_i(9 downto 6);    -- del1 aligns with FIRTapRegAddr 
            FIRTapAddrDel2 <= FIRTapAddrDel1; 
            FIRTapAddrDel3 <= FIRTapAddrDel2;              -- del3 aligns with the read data in FIRTapRegRdData
            
            FIRTapData_o <= FIRTapRegRdData(to_integer(unsigned(FIRTapAddrDel3)));
        end if;
    end process;
    
    dummy0SLV(0) <= '0';
    dummy0_18 <= (others => '0');
    
    -- Every memory has a different name so they can have different default contents.
    -- Beware this assumes the generic "TAPS" is 12.
    FIRTaps1 : PSTFB_ROM12
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(0),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(0),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(0),
        dinb  => dummy0_18,
        doutb => coef_o(0)
    );

    FIRTaps2 : PSTFB_ROM11
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(1),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(1),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(1),
        dinb  => dummy0_18,
        doutb => coef_o(1)
    );

    FIRTaps3 : PSTFB_ROM10
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(2),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(2),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(2),
        dinb  => dummy0_18,
        doutb => coef_o(2)
    );

    FIRTaps4 : PSTFB_ROM9
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(3),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(3),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(3),
        dinb  => dummy0_18,
        doutb => coef_o(3)
    );

    FIRTaps5 : PSTFB_ROM8
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(4),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(4),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(4),
        dinb  => dummy0_18,
        doutb => coef_o(4)
    );

    FIRTaps6 : PSTFB_ROM7
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(5),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(5),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(5),
        dinb  => dummy0_18,
        doutb => coef_o(5)
    );

    FIRTaps7 : PSTFB_ROM6
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(6),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(6),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(6),
        dinb  => dummy0_18,
        doutb => coef_o(6)
    );

    FIRTaps8 : PSTFB_ROM5
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(7),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(7),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(7),
        dinb  => dummy0_18,
        doutb => coef_o(7)
    );

    FIRTaps9 : PSTFB_ROM4
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(8),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(8),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(8),
        dinb  => dummy0_18,
        doutb => coef_o(8)
    );

    FIRTaps10 : PSTFB_ROM3
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(9),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(9),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(9),
        dinb  => dummy0_18,
        doutb => coef_o(9)
    );

    FIRTaps11 : PSTFB_ROM2
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(10),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(10),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(10),
        dinb  => dummy0_18,
        doutb => coef_o(10)
    );

    FIRTaps12 : PSTFB_ROM1
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(11),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(11),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(11),
        dinb  => dummy0_18,
        doutb => coef_o(11)
    );
    
end Behavioral;
