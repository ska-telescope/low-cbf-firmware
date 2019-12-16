----------------------------------------------------------------------------------
-- Company: CSIRO - CASS 
-- Engineer: David Humphrey
-- 
-- Create Date: 15.11.2018 09:30:43
-- Module Name: fb_mem - Behavioral
-- Description: 
--  Memories for the Correlator Filterbank.
-- Notes:
--  * The number of taps is semi-configurable; some modification is required if "TAPS" is not set to 12.
--  * Read data is staggered by one clock for each of the 12 samples, so that the FIR filter can use the adders in the DSPs.
--
----------------------------------------------------------------------------------
library IEEE, common_lib;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use common_lib.common_pkg.all;
Library xpm;
use xpm.vcomponents.all;

entity PSSFBMem is
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
        wrEn_i       : in std_logic; -- should be a burst of 4096 clocks.
        -- Read data, comes out 2 clocks after the first write.
        rd_data_o    : out t_slv_96_arr(TAPS-1 downto 0); -- 96 (=6*16) bits wide, 12 taps simultaneously; First sample is wr_data_i delayed by 1 clock. 
        coef_o       : out t_slv_18_arr(TAPS-1 downto 0);  -- 18 bits per filter tap.
        -- Writing FIR Taps
        FIRTapData_i   : in std_logic_vector(17 downto 0);  -- For register writes of the filtertaps.
        FIRTapData_o   : out std_logic_vector(17 downto 0); -- For register reads of the filtertaps. 3 cycle latency from FIRTapAddr_i
        FIRTapAddr_i   : in std_logic_vector(9 downto 0);   -- 64 * 12 filter taps = 768 total.
        FIRTapWE_i     : in std_logic;
        FIRTapClk      : in std_logic;
        FIRTapSelect_i : in std_logic  -- FIR Taps are double buffered; this selects the buffer to access for registers. Choose which buffer to use with FIRTapUse_i
    );
end PSSFBMem;

architecture Behavioral of PSSFBMem is
    
    -- Store the filter taps.
    -- Dual port so it can be read/written over MACE.
    -- ok, it's not a ROM, but it's used that way most of the time.
    component PSSFB_ROM1
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(6 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(6 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;    
    
    component PSSFB_ROM2
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(6 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(6 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;  
    
    component PSSFB_ROM3
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(6 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(6 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;
    
    component PSSFB_ROM4
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(6 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(6 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;
    
    component PSSFB_ROM5
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(6 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(6 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;
    
    component PSSFB_ROM6
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(6 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(6 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;

    component PSSFB_ROM7
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(6 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(6 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;

    component PSSFB_ROM8
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(6 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(6 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;

    component PSSFB_ROM9
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(6 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(6 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;

    component PSSFB_ROM10
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(6 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(6 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;

    component PSSFB_ROM11
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(6 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(6 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;

    component PSSFB_ROM12
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(6 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(6 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;
    
    -- Tcl to create the FIR coefficient memories.
    --
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSSROM1 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSSROM1} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSSFIRTaps1.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSROM1]
    --
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSSROM2 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSSROM2} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSSFIRTaps2.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSROM2]
    --
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSSROM3 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSSROM3} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSSFIRTaps3.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSROM3]
    --
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSSROM4 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSSROM4} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSSFIRTaps4.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSROM4]
    --
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSSROM5 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSSROM5} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSSFIRTaps5.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSROM5]
    --
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSSROM6 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSSROM6} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSSFIRTaps6.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSROM6]
    --
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSSROM7 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSSROM7} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSSFIRTaps7.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSROM7]
    --
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSSROM8 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSSROM8} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSSFIRTaps8.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSROM8]
    --
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSSROM9 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSSROM9} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSSFIRTaps9.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSROM9]
    --
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSSROM10 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSSROM10} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSSFIRTaps10.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSROM10]
    --
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSSROM11 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSSROM11} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSSFIRTaps11.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSROM11]
    --
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSSROM12 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {PSSROM12} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/PSSFIRTaps12.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSROM12]
    
    -- distributed memory; 64 deep by 96 wide, 1 clock read latency.
    -- Tcl:
    --  create_ip -name dist_mem_gen -vendor xilinx.com -library ip -version 8.0 -module_name PSSFBdr64 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --  set_property -dict [list CONFIG.data_width {96} CONFIG.Component_Name {PSSFBdr64} CONFIG.memory_type {simple_dual_port_ram} CONFIG.output_options {registered} CONFIG.common_output_clk {true}] [get_ips PSSFBdr64]
    component PSSFBdr64
    port (
        a    : in std_logic_vector(5 downto 0);
        d    : in std_logic_vector(95 downto 0);
        dpra : in std_logic_vector(5 downto 0);
        clk  : in std_logic;
        we   : in std_logic;
        qdpo : out std_logic_vector(95 downto 0));
    end component;
    
    signal FIRTapsWE : t_slv_1_arr((TAPS-1) downto 0);
    signal FIRTapRegAddr : std_logic_vector(6 downto 0);  -- double buffered; 2x64 buffers = 7 bit address
    signal FIRTapRegWrData : std_logic_vector(17 downto 0);
    signal FIRTapRegRdData : t_slv_18_arr((TAPS-1) downto 0);
    signal dummy0SLV : std_logic_vector(0 downto 0);
    signal FIRTapAddrDel1, FIRTapAddrDel2, FIRTapAddrDel3 : std_logic_vector(3 downto 0) := "0000";
    signal dummy0_18 : std_logic_vector(17 downto 0);
    
    signal rdAddr : std_logic_vector(5 downto 0);
    signal rdAddrDel : t_slv_6_arr((TAPS) downto 0) := (others => (others => '0'));
    signal wrDataDel1 : std_logic_vector((DATAWIDTH-1) downto 0);
    signal wrEnDel1 : std_logic := '0';
    
    signal wr_en_slv : std_logic_vector(0 downto 0);
    
    signal romAddrDel : t_slv_7_arr((TAPS-1) downto 0):= (others => (others => '0'));
    signal wrEnDel : std_logic_vector((TAPS) downto 0) := (others => '0');
    
    -- Change the data type to match the Generic if the generic is not 96. 
    signal rdDataDel : t_slv_96_arr((TAPS-1) downto 0);
    signal rdDataDel2 : t_slv_96_arr((TAPS-1) downto 0);
    
begin
    
    process(clk)
    begin
        if rising_edge(clk) then
        
            wrDataDel1 <= wrData_i;       -- Extra Delay on the the input data so that the read data from the first coefficient ROM matches the first data output.
            rdDataDel2(0) <= wrDataDel1;  -- Two cycle latency for the first data; Each memory has a 2 cycle latency so second data has 3 cycle latency.
        
            wrEnDel1 <= wrEn_i;
            wrEnDel(1) <= wrEnDel1;
            if wrEn_i = '0' then
                rdAddr <= (others => '0');
            else
                rdAddr <= std_logic_vector(unsigned(rdAddr) + 1);
            end if;
            
            rdAddrDel(TAPS downto 1) <= rdAddrDel(TAPS-1 downto 0);
            romAddrDel((TAPS-1) downto 1) <= romAddrDel((TAPS-2) downto 0);
            wrEnDel(TAPS downto 2) <= wrEnDel(TAPS-1 downto 1);
        end if;
    end process;
    
    rdAddrDel(0) <= rdAddr;
    romAddrDel(0) <= FIRTapUse_i & rdAddr;
    
    dataMem : for i in 1 to (TAPS-1) generate
        
        -- Distributed memory, one clock read latency.
        distrams: PSSFBdr64
        port map (
            a    => rdAddrDel(i+1),  -- in(5:0); write address
            d    => rdDataDel2(i-1), -- in(95:0); write data
            dpra => rdAddrDel(i),    -- in(5:0); read address
            clk  => clk,
            we   => wrEnDel(i),
            qdpo => rdDataDel(i)     -- out(95:0); registered data output; one clock read latency.
        );
        
        -- Extra pipeline stage at the output of the memory; avoids read/write collisions and makes the 
        -- sequencing the same as for the other filterbanks (which use BRAM with 2 clock read latency). 
        process(clk)
        begin
            if rising_edge(clk) then
                rdDataDel2(i) <= rdDataDel(i);  
            end if;
        end process;
        
        rd_data_o(i) <= rdDataDel2(i);
        
    end generate;
    
    rd_data_o(0) <= rdDataDel2(0);
    
    --------------------------------------------------------------------------------------
    -- Filter Coefficients
    -- 12 memories, each 18 bits wide, 128 deep, dual port.
    -- Port A used to write new coefficients
    -- Port B used to read.

    -- Note register ports are 
    --  FIRTapData_i : in std_logic_vector(17 downto 0);
    --  FIRTapData_o : out std_logic_vector(17 downto 0);
    --  FIRTapAddr_i : in std_logic_vector(9 downto 0);  -- 64 * 12 filter taps = 768 total.
    --  FIRTapWE_i   : in std_logic;
    --  FIRTapClk    : in std_logic
    
    process(FIRTapClk)
    begin
        if rising_edge(FIRTapClk) then
            for ft in 0 to (TAPS-1) loop
                if (FIRTapWE_i = '1' and FIRTapAddr_i(9 downto 6) = std_logic_vector(to_unsigned(ft,4))) then
                    FIRTapsWE(ft)(0) <= '1';
                else
                    FIRTapsWE(ft)(0) <= '0';
                end if; 
            end loop;
            FIRTapRegAddr <= FIRTapSelect_i & FIRTapAddr_i(5 downto 0);
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
    FIRTaps1 : PSSFB_ROM12
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

    FIRTaps2 : PSSFB_ROM11
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

    FIRTaps3 : PSSFB_ROM10
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

    FIRTaps4 : PSSFB_ROM9
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

    FIRTaps5 : PSSFB_ROM8
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

    FIRTaps6 : PSSFB_ROM7
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

    FIRTaps7 : PSSFB_ROM6
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

    FIRTaps8 : PSSFB_ROM5
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

    FIRTaps9 : PSSFB_ROM4
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

    FIRTaps10 : PSSFB_ROM3
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

    FIRTaps11 : PSSFB_ROM2
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

    FIRTaps12 : PSSFB_ROM1
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

