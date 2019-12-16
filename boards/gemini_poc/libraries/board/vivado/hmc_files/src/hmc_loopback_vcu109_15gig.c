/**************************************************************************
*
 * Xilinx, Inc.
 * XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
 * COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
 * ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR 
 * STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION 
 * IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE 
 * FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION
 * XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO 
 * THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO 
 * ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE 
 * FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE.
*
*     (c) Copyright 2014 Xilinx, Inc.
*     All rights reserved.
*
**************************************************************************/
/**************************************************************************
* Filename:     hmc_loopback_vcu109_15gig.c
*
* Description:
* Menu that runs HMC Loopback for VCU109, Default setting for 15G
*
*
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00  lsm  09/08/2014  Initial Release
*
*
******************************************************************************/
#include "hmc_loopback_vcu109_15gig.h"

/************************** Constant Definitions *****************************/
    volatile u8 TransmitComplete; /* Flag to check completion of Transmission */
    volatile u8 ReceiveComplete;  /* Flag to check completion of Reception */
    XIntc InterruptController;    /* The instance of the Interrupt Controller. */
    XIic Iic;                     /* The instance of the IIC device. */
    XHmc Hmc;                     /* The instance of the HMC device. */
    u8 ReadBuffer[4];  /* Read buffer for reading a page. */
    u8 WriteBuffer[8];  /* Write buffer for writing a page. */
    XGpio hmc_fatal_error;   /* The driver instance for GPIO Device configured as I/P */
    XGpio hmc_lxtxps;        /* The driver instance for GPIO Device configured as I/P */
    XGpio hmc_refclk_sel;   /* The driver instance for GPIO Device configured as O/P */
    XGpio hmc_lxrxps;        /* The driver instance for GPIO Device configured as O/P */
    XGpio hmc_reclk_boot;        /* The driver instance for GPIO Device configured as O/P */
    DSPLL_struct DSPLL;

int main()
{
    int exit_flag, Status;
    int choice;
    //u8 test;
    int i;
    XIic_Config *ConfigPtr = NULL;

    /*
     * Initialize Write and Read Buffers
     */
    memset(WriteBuffer,0,8);
    memset(ReadBuffer,0,4);


    init_platform();
    /*
     * Initialize the IIC Bus
     */

    /*
     * Initialize the IIC driver so that it is ready to use.
     */
    ConfigPtr = XIic_LookupConfig(IIC_DEVICE_ID);
    if (ConfigPtr == NULL) {
       return XST_FAILURE;
    }

    Status = XIic_CfgInitialize(&Iic, ConfigPtr,
          ConfigPtr->BaseAddress);
    if (Status != XST_SUCCESS) {
       return XST_FAILURE;
    }
    /*
     * Setup the Interrupt System.
     */
    Status = SetupInterruptSystem(&Iic);
    if (Status != XST_SUCCESS) {
       return XST_FAILURE;
    }

    /*
     * Set the Handlers for transmit and reception.
     */
    XIic_SetSendHandler  (&Iic, &Iic, (XIic_Handler) SendHandler);
    XIic_SetRecvHandler  (&Iic, &Iic, (XIic_Handler) ReceiveHandler);
    XIic_SetStatusHandler(&Iic, &Iic, (XIic_StatusHandler) StatusHandler);

    ENABLE_ICACHE();
    ENABLE_DCACHE();
    print("\n\r********************************************************");
    print("\n\r**    Xilinx UltraScale FPGA VCU109 Evaluation Kit    **");
    print("\n\r**    HMC 15Gig LOOPBACK TEST          Ver2.01        **");
    print("\n\r********************************************************\r\n");

    //clocks are dead on power turn on HMC clocks
    //setup design for 15G operation, 125 MHz to HMC and 187.5 MHz or 375 Mhz to FPGA
    si5328_set_freq_125_187or375MHz(LINK_SPEED_15GBPS);
    //configure HMC for 15G loopback mode
    hmc_loopback(LINK_SPEED_15GBPS);
    // run menu for modifying design if necessary
    exit_flag = 0;
    while(exit_flag != 1) {
        xil_printf("\r\nChoose Option:\r\n");
        xil_printf("0: HMC LB 15G\t");
        xil_printf("1: HMC LB 12.5G\t");
        xil_printf("2: HMC RW REG\t");
        xil_printf("3: HMC ID\r\n");
        xil_printf("4: Reset HMC\t");
        xil_printf("5: GPIO Init\t");
        xil_printf("6: GPO !RST\r\n");
        xil_printf("7: IIC->HMC\t");
        xil_printf("8: IIC->SI5328\r\n");
        xil_printf("9: SI 125 MHz:187.5 MHz\r\n");
        xil_printf("A: SI 125 MHz:125 MHz\r\n");
        xil_printf("B: HMC Lane Info\r\n");
        xil_printf("C: HMC Pattern Info\r\n");
        xil_printf("D: HMC Pattern Config\r\n");
        xil_printf("Q: Exit\r\n");
        xil_printf("=>");
                    choice = inbyte();
  
              if (isalpha(choice)) {
                 choice = toupper(choice);
              }
            xil_printf("%c\r\n", choice);
  
        switch(choice) {
           case 'Q':
               exit_flag = 1;
               break;
           case '0':
               hmc_loopback(LINK_SPEED_15GBPS);
               break;
           case '1':
               hmc_loopback(LINK_SPEED_12_5GBPS);
               break;
           case '2':
               rw_interface();
               break;
           case '3':
               hmc_id();
               break;
           case '4':
               {
                 XIic_ClearGPO(HMC_P_RST_N);
                 for(i=0;i<10000;i++);     // delay
                 XIic_SetGPO(HMC_P_RST_N);
               }
               break;
           case '5':
               hmc_gpio_init();
               break;
           case '6':
               {
                   XIic_SetGPO(SI5328_RST_N | HMC_P_RST_N | IIC_MUX_RESET_N);
               }
               break;
           case '7':
                hmc_init_iicmux();
               break;
           case '8':
                si5328_init_iicmux();
            break;
         case '9':
         {
          si5328_set_freq_125_187or375MHz(LINK_SPEED_15GBPS);
             if (Status != XST_SUCCESS) {
                return XST_FAILURE;
             }
            }
            break;
         case 'A':{
          si5328_set_freq_125_187or375MHz(LINK_SPEED_12_5GBPS);
             if (Status != XST_SUCCESS) {
                return XST_FAILURE;
             }
               break;
           case 'B':{
               hmc_lane_eye_data();
               }
               break;
           case 'C':{
               hmc_pattern_data("r", 0xDEADBEAF);
               }
               break;
           case 'D':{
               hmc_lane_eye_data();
               hmc_set_prbs_checker();

               }
               break;

           }
           default:
              break;
        }
   }
   /*
    * Stop the IIC device.
    */
   Status = XIic_Stop(&Iic);
   if (Status != XST_SUCCESS) {
      return XST_FAILURE;
   }
   DisableInterruptSystem(&Iic);
   xil_printf("Good-bye!\r\n");

    return 0;
}

/******************hmc_loopback*********************************************/
void hmc_loopback(u32 link_speed)
{
   int i=0;

   //cycle reset to HMC part and MUX
   XIic_ClearGPO(HMC_P_RST_N | IIC_MUX_RESET_N);
   for(i=0;i<10000;i++);     // delay
   XIic_SetGPO(HMC_P_RST_N | IIC_MUX_RESET_N);
   for(i=0;i<10000;i++);     // wait for HMC to settle

   //point the I2C muxes to the HMC part
   hmc_init_iicmux();
   for(i=0;i<10000;i++);     // delay
   xil_printf("Reading HMC Registers\n\r");
   //load registers with values
   hmc_id();
   for(i=0;i<10000;i++);     // delay
   xil_printf("Disabling NVM\n\r");
   Hmc.hmc_bootstrap_register = hmc_rd_wr("rmwv","BOOTSTRAP_REG", BOOTSTRAP_REG, HMC_DISABLE_NVM_WRITE);
   for(i=0;i<10000;i++);     // delay
   xil_printf("Configuring HMC Registers\n\r");
   Hmc.hmc_link0_configuration_register = hmc_rd_wr("rmwv","LNK_CNF_REG_LNK0_ADDR", LNK_CNF_REG_LNK0_ADDR, LINK_PLL_NO_PWR_DOWN);
   for(i=0;i<10000;i++);     // delay
   Hmc.hmc_link1_configuration_register = hmc_rd_wr("rmwv","LNK_CNF_REG_LNK1_ADDR", LNK_CNF_REG_LNK1_ADDR, LINK_PLL_NO_PWR_DOWN);
   for(i=0;i<10000;i++);     // delay

   xil_printf("Configuring Link ERI Registers\n\r");
   // configure the links for loop back using the ERI interface
   Hmc.hmc_external_data_reg0   = hmc_rd_wr("wv","ERIDATA_LNK0", Hmc.hmc_eri_base_addr  , link_speed | FULL_WDTH_TX_RX | PRBS23_PLUS | LNK_LOOP_BK_EN);
   for(i=0;i<10000;i++);     // delay
   Hmc.hmc_external_data_reg1   = hmc_rd_wr("wv","ERIDATA_LNK1", Hmc.hmc_eri_base_addr+1, link_speed | FULL_WDTH_TX_RX | PRBS23_PLUS | LNK_LOOP_BK_EN);
   for(i=0;i<10000;i++);     // delay
   Hmc.hmc_external_data_reg2   = hmc_rd_wr("wv","ERIDATA_LNK2", Hmc.hmc_eri_base_addr+2, link_speed | FULL_WDTH_TX_RX | PRBS23_PLUS | LNK_LOOP_BK_EN);
   for(i=0;i<10000;i++);     // delay
   Hmc.hmc_external_data_reg3   = hmc_rd_wr("wv","ERIDATA_LNK3", Hmc.hmc_eri_base_addr+3, link_speed | FULL_WDTH_TX_RX | PRBS23_PLUS | LNK_LOOP_BK_EN);
   for(i=0;i<10000;i++);     // delay

   Hmc.hmc_external_request_reg = hmc_rd_wr("wv","ERIREQ_REG", Hmc.hmc_eri_base_addr+4, HMC_EFI_CMD_START | LINK_CONFIGURATION);
   for(i=0;i<10000;i++);     // delay

   while (hmc_rd_wr("r","ERIREQ_REG", Hmc.hmc_eri_base_addr+4, LINK_CONFIGURATION) & HMC_EFI_CMD_START){
      for(i=0;i<10000;i++);  //Add a little delay; //wait for Start bit to go inactive
   }

   xil_printf("Configuring Phy ERI Registers\n\r");
   // configure the Phys
   Hmc.hmc_external_data_reg0   = hmc_rd_wr("wv","ERIDATA_LNK0", Hmc.hmc_eri_base_addr  , 0x40000000); //enable AC Caps on RX
   for(i=0;i<10000;i++);     // delay
   Hmc.hmc_external_data_reg1   = hmc_rd_wr("wv","ERIDATA_LNK1", Hmc.hmc_eri_base_addr+1, 0x40000000); //enable AC Caps on RX
   for(i=0;i<10000;i++);     // delay
   Hmc.hmc_external_data_reg2   = hmc_rd_wr("wv","ERIDATA_LNK2", Hmc.hmc_eri_base_addr+2, 0x40000000); //enable AC Caps on RX
   for(i=0;i<10000;i++);     // delay
   Hmc.hmc_external_data_reg3   = hmc_rd_wr("wv","ERIDATA_LNK3", Hmc.hmc_eri_base_addr+3, 0x40000000); //enable AC Caps on RX
   for(i=0;i<10000;i++);     // delay

   Hmc.hmc_external_request_reg = hmc_rd_wr("wv","ERIREQ_REG", Hmc.hmc_eri_base_addr+4, HMC_EFI_CMD_START | PHY_CONFIGURATION);
   for(i=0;i<10000;i++);     // delay

   while (hmc_rd_wr("r","ERIREQ_REG", Hmc.hmc_eri_base_addr+4, PHY_CONFIGURATION) & HMC_EFI_CMD_START){
      for(i=0;i<10000;i++);  //Add a little delay; //wait for Start bit to go inactive
   }

   xil_printf("Configuring Refresh ERI Registers\n\r");
   // configure the Refresh rateto single rate
   Hmc.hmc_external_data_reg0   = hmc_rd_wr("wv","ERIDATA_LNK0", Hmc.hmc_eri_base_addr  , 0x00000000);
   for(i=0;i<10000;i++);     // delay
   Hmc.hmc_external_data_reg1   = hmc_rd_wr("wv","ERIDATA_LNK1", Hmc.hmc_eri_base_addr+1, 0x00000000);
   for(i=0;i<10000;i++);     // delay
   Hmc.hmc_external_data_reg2   = hmc_rd_wr("wv","ERIDATA_LNK2", Hmc.hmc_eri_base_addr+2, 0x00000000);
   for(i=0;i<10000;i++);     // delay
   Hmc.hmc_external_data_reg3   = hmc_rd_wr("wv","ERIDATA_LNK3", Hmc.hmc_eri_base_addr+3, 0x00000000);
   for(i=0;i<10000;i++);     // delay

   Hmc.hmc_external_request_reg = hmc_rd_wr("wv","ERIREQ_REG", Hmc.hmc_eri_base_addr+4, HMC_EFI_CMD_START | REFRESH_RATE_ADJ);
   for(i=0;i<10000;i++);     // delay

   while (hmc_rd_wr("r","ERIREQ_REG", Hmc.hmc_eri_base_addr+4, REFRESH_RATE_ADJ) & HMC_EFI_CMD_START){
      for(i=0;i<10000;i++);  //Add a little delay; //wait for Start bit to go inactive
   }

   xil_printf("Configuring DRAM Pattern\n\r");

   Hmc.hmc_external_data_reg0   = hmc_rd_wr("wv","ERIDATA_LNK0", Hmc.hmc_eri_base_addr  , 0x00000000);
   for(i=0;i<10000;i++);     // delay
   Hmc.hmc_external_data_reg1   = hmc_rd_wr("wv","ERIDATA_LNK1", Hmc.hmc_eri_base_addr+1, 0x00000000);
   for(i=0;i<10000;i++);     // delay
   Hmc.hmc_external_data_reg2   = hmc_rd_wr("wv","ERIDATA_LNK2", Hmc.hmc_eri_base_addr+2, 0x00000000);
   for(i=0;i<10000;i++);     // delay
   Hmc.hmc_external_data_reg3   = hmc_rd_wr("wv","ERIDATA_LNK3", Hmc.hmc_eri_base_addr+3, 0x00000000);
   for(i=0;i<10000;i++);     // delay

   Hmc.hmc_external_request_reg = hmc_rd_wr("wv","ERIREQ_REG", Hmc.hmc_eri_base_addr+4, HMC_EFI_CMD_START | SET_DRAM_PATTERN);
   for(i=0;i<10000;i++);     // delay

   while (hmc_rd_wr("r","ERIREQ_REG", Hmc.hmc_eri_base_addr+4, SET_DRAM_PATTERN) & HMC_EFI_CMD_START); //wait for Start bit to go inactive
   for(i=0;i<10000;i++);     // delay

   xil_printf("Setting INIT Continue\n\r");

   Hmc.hmc_external_request_reg = hmc_rd_wr("wv","ERIREQ_REG", Hmc.hmc_eri_base_addr+4, HMC_EFI_CMD_START | INIT_CONTINUE);
   for(i=0;i<10000;i++);     // delay

   while (hmc_rd_wr("r","ERIREQ_REG", Hmc.hmc_eri_base_addr+4, INIT_CONTINUE) & HMC_EFI_CMD_START){
      for(i=0;i<10000;i++);  //Add a little delay; //wait for Start bit to go inactive
   }

   xil_printf("Reading ERI LINK Configure request Status\n\r");
   Hmc.hmc_external_request_reg = hmc_rd_wr("r","ERIREQ_REG", Hmc.hmc_eri_base_addr+4, LINK_CONFIGURATION);
   for(i=0;i<10000;i++);     // delay

   xil_printf("\n");
}
/******************hmc_id*********************************************/
void hmc_id()
{
   int i=0;
   Hmc.hmc_cfgdata = 0xDEADBEAF;
   //hmc_init_iicmux();

   xil_printf("Reading HMC ID Registers:\r\n");
   for(i=0;i<10000;i++);     // delay

   //read the registers into the structure
   Hmc.hmc_revision_mfg_register           = hmc_rd_wr("r","REVS_MFG_REG", REVS_MFG_REG, 0xDEADBEEF);
   for(i=0;i<10000;i++);     // delay
   Hmc.hmc_chip_revision = ( Hmc.hmc_revision_mfg_register & HMC_REVISION ) >> 8;
   for(i=0;i<10000;i++);     // delay
   xil_printf("HMC Chip Revison:0x%08X\n\r", Hmc.hmc_chip_revision);
   if (Hmc.hmc_chip_revision > 15 ){
      Hmc.hmc_eri_base_addr = ERIDATA_LNK_BASE;
      for(i=0;i<10000;i++);     // delay
   } else {
      Hmc.hmc_eri_base_addr = ERIDATA_LNK_BASE_OLD;
      for(i=0;i<10000;i++);     // delay
   }
      
   Hmc.hmc_global_config_register          = hmc_rd_wr("r","GLB_CFG_REG", GLB_CFG_REG, 0xDEADBEEF);
   Hmc.hmc_global_status_register          = hmc_rd_wr("r","GLB_STATUS_REG", GLB_STATUS_REG, 0xDEADBEEF);
   Hmc.hmc_bootstrap_register              = hmc_rd_wr("r","BOOTSTRAP_REG", BOOTSTRAP_REG, 0xDEADBEEF);
   Hmc.hmc_external_data_reg0              = hmc_rd_wr("r","ERIDATA_LNK0", Hmc.hmc_eri_base_addr   , 0xDEADBEEF);
   Hmc.hmc_external_data_reg1              = hmc_rd_wr("r","ERIDATA_LNK1", Hmc.hmc_eri_base_addr+1, 0xDEADBEEF);
   Hmc.hmc_external_data_reg2              = hmc_rd_wr("r","ERIDATA_LNK2", Hmc.hmc_eri_base_addr+2, 0xDEADBEEF);
   Hmc.hmc_external_data_reg3              = hmc_rd_wr("r","ERIDATA_LNK3", Hmc.hmc_eri_base_addr+3, 0xDEADBEEF);
   Hmc.hmc_external_request_reg            = hmc_rd_wr("r","ERIREQ_REG", Hmc.hmc_eri_base_addr+4, 0xDEADBEEF);
   Hmc.hmc_address_config_register         = hmc_rd_wr("r","ADDR_CFG_REG", ADDR_CFG_REG, 0xDEADBEEF);
   Hmc.hmc_cube_sn1_register               = hmc_rd_wr("r","CUBE_SN1_REG", CUBE_SN1_REG, 0xDEADBEEF);
   Hmc.hmc_cube_sn2_register               = hmc_rd_wr("r","CUBE_SN2_REG", CUBE_SN2_REG, 0xDEADBEEF);
   Hmc.hmc_features_register               = hmc_rd_wr("r","FEATURES_REG", FEATURES_REG, 0xDEADBEEF);
   Hmc.hmc_vault_control_register          = hmc_rd_wr("r","VAULT_CTRL_REG", GLB_CFG_REG, 0xDEADBEEF);

   Hmc.hmc_link0_req_id_register           = hmc_rd_wr("r","RQST_ID_REG_LNK0_ADDR", RQST_ID_REG_LNK0_ADDR, 0xDEADBEEF);
   Hmc.hmc_link0_configuration_register    = hmc_rd_wr("r","LNK_CNF_REG_LNK0_ADDR", LNK_CNF_REG_LNK0_ADDR, 0xDEADBEEF);
   Hmc.hmc_link0_rll_register              = hmc_rd_wr("r","LNK_RLL_REG_LNK0_ADDR", LNK_RLL_REG_LNK0_ADDR, 0xDEADBEEF);
   Hmc.hmc_link0_retry_register            = hmc_rd_wr("r","LNK_RTY_REG_LNK0_ADDR", LNK_RTY_REG_LNK0_ADDR, 0xDEADBEEF);
   Hmc.hmc_link0_status_register           = hmc_rd_wr("r","LNK_STS_REG_LNK0_ADDR", LNK_STS_REG_LNK0_ADDR, 0xDEADBEEF);
   Hmc.hmc_link0_inversion_register        = hmc_rd_wr("r","LNK_INV_REG_LNK0_ADDR", LNK_INV_REG_LNK0_ADDR, 0xDEADBEEF);

   Hmc.hmc_link1_req_id_register           = hmc_rd_wr("r","RQST_ID_REG_LNK1_ADDR", RQST_ID_REG_LNK1_ADDR, 0xDEADBEEF);
   Hmc.hmc_link1_configuration_register    = hmc_rd_wr("r","LNK_CNF_REG_LNK1_ADDR", LNK_CNF_REG_LNK1_ADDR, 0xDEADBEEF);
   Hmc.hmc_link1_rll_register              = hmc_rd_wr("r","LNK_RLL_REG_LNK1_ADDR", LNK_RLL_REG_LNK1_ADDR, 0xDEADBEEF);
   Hmc.hmc_link1_retry_register            = hmc_rd_wr("r","LNK_RTY_REG_LNK1_ADDR", LNK_RTY_REG_LNK1_ADDR, 0xDEADBEEF);
   Hmc.hmc_link1_status_register           = hmc_rd_wr("r","LNK_STS_REG_LNK1_ADDR", LNK_STS_REG_LNK1_ADDR, 0xDEADBEEF);
   Hmc.hmc_link1_inversion_register        = hmc_rd_wr("r","LNK_INV_REG_LNK1_ADDR", LNK_INV_REG_LNK1_ADDR, 0xDEADBEEF);

   Hmc.hmc_link2_req_id_register           = hmc_rd_wr("r","RQST_ID_REG_LNK2_ADDR", RQST_ID_REG_LNK2_ADDR, 0xDEADBEEF);
   Hmc.hmc_link2_configuration_register    = hmc_rd_wr("r","LNK_CNF_REG_LNK2_ADDR", LNK_CNF_REG_LNK2_ADDR, 0xDEADBEEF);
   Hmc.hmc_link2_rll_register              = hmc_rd_wr("r","LNK_RLL_REG_LNK2_ADDR", LNK_RLL_REG_LNK2_ADDR, 0xDEADBEEF);
   Hmc.hmc_link2_retry_register            = hmc_rd_wr("r","LNK_RTY_REG_LNK2_ADDR", LNK_RTY_REG_LNK2_ADDR, 0xDEADBEEF);
   Hmc.hmc_link2_status_register           = hmc_rd_wr("r","LNK_STS_REG_LNK2_ADDR", LNK_STS_REG_LNK2_ADDR, 0xDEADBEEF);
   Hmc.hmc_link2_inversion_register        = hmc_rd_wr("r","LNK_INV_REG_LNK2_ADDR", LNK_INV_REG_LNK2_ADDR, 0xDEADBEEF);
      
   Hmc.hmc_link3_req_id_register           = hmc_rd_wr("r","RQST_ID_REG_LNK3_ADDR", RQST_ID_REG_LNK3_ADDR, 0xDEADBEEF);
   Hmc.hmc_link3_configuration_register    = hmc_rd_wr("r","LNK_CNF_REG_LNK3_ADDR", LNK_CNF_REG_LNK3_ADDR, 0xDEADBEEF);
   Hmc.hmc_link3_rll_register              = hmc_rd_wr("r","LNK_RLL_REG_LNK3_ADDR", LNK_RLL_REG_LNK3_ADDR, 0xDEADBEEF);
   Hmc.hmc_link3_retry_register            = hmc_rd_wr("r","LNK_RTY_REG_LNK3_ADDR", LNK_RTY_REG_LNK3_ADDR, 0xDEADBEEF);
   Hmc.hmc_link3_status_register           = hmc_rd_wr("r","LNK_STS_REG_LNK3_ADDR", LNK_STS_REG_LNK3_ADDR, 0xDEADBEEF);
   Hmc.hmc_link3_inversion_register        = hmc_rd_wr("r","LNK_INV_REG_LNK3_ADDR", LNK_INV_REG_LNK3_ADDR, 0xDEADBEEF);

}

/******************hmc_lane_eye_data*********************************************/

void hmc_lane_eye_data()
{
   Hmc.hmc_cfgdata = 0xDEADBEAF;


   //read the registers into the structure
   xil_printf("Reading RX Width Statistics Registers:\n\r");
    Hmc.lnk0_lane0_rx_eye_wdt              = hmc_rd_wr("r","LNK0_LANE0_RX_EYE_WDT", LNK0_LANE0_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk0_lane1_rx_eye_wdt              = hmc_rd_wr("r","LNK0_LANE1_RX_EYE_WDT", LNK0_LANE1_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk0_lane2_rx_eye_wdt              = hmc_rd_wr("r","LNK0_LANE2_RX_EYE_WDT", LNK0_LANE2_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk0_lane3_rx_eye_wdt              = hmc_rd_wr("r","LNK0_LANE3_RX_EYE_WDT", LNK0_LANE3_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk0_lane4_rx_eye_wdt              = hmc_rd_wr("r","LNK0_LANE4_RX_EYE_WDT", LNK0_LANE4_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk0_lane5_rx_eye_wdt              = hmc_rd_wr("r","LNK0_LANE5_RX_EYE_WDT", LNK0_LANE5_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk0_lane6_rx_eye_wdt              = hmc_rd_wr("r","LNK0_LANE6_RX_EYE_WDT", LNK0_LANE6_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk0_lane7_rx_eye_wdt              = hmc_rd_wr("r","LNK0_LANE7_RX_EYE_WDT", LNK0_LANE7_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk0_lane8_rx_eye_wdt              = hmc_rd_wr("r","LNK0_LANE8_RX_EYE_WDT", LNK0_LANE8_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk0_lane9_rx_eye_wdt              = hmc_rd_wr("r","LNK0_LANE9_RX_EYE_WDT", LNK0_LANE9_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk0_lanea_rx_eye_wdt              = hmc_rd_wr("r","LNK0_LANEA_RX_EYE_WDT", LNK0_LANEA_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk0_laneb_rx_eye_wdt              = hmc_rd_wr("r","LNK0_LANEB_RX_EYE_WDT", LNK0_LANEB_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk0_lanec_rx_eye_wdt              = hmc_rd_wr("r","LNK0_LANEC_RX_EYE_WDT", LNK0_LANEC_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk0_laned_rx_eye_wdt              = hmc_rd_wr("r","LNK0_LANED_RX_EYE_WDT", LNK0_LANED_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk0_lanee_rx_eye_wdt              = hmc_rd_wr("r","LNK0_LANEE_RX_EYE_WDT", LNK0_LANEE_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk0_lanef_rx_eye_wdt              = hmc_rd_wr("r","LNK0_LANEF_RX_EYE_WDT", LNK0_LANEF_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk1_lane0_rx_eye_wdt              = hmc_rd_wr("r","LNK1_LANE0_RX_EYE_WDT", LNK1_LANE0_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk1_lane1_rx_eye_wdt              = hmc_rd_wr("r","LNK1_LANE1_RX_EYE_WDT", LNK1_LANE1_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk1_lane2_rx_eye_wdt              = hmc_rd_wr("r","LNK1_LANE2_RX_EYE_WDT", LNK1_LANE2_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk1_lane3_rx_eye_wdt              = hmc_rd_wr("r","LNK1_LANE3_RX_EYE_WDT", LNK1_LANE3_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk1_lane4_rx_eye_wdt              = hmc_rd_wr("r","LNK1_LANE4_RX_EYE_WDT", LNK1_LANE4_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk1_lane5_rx_eye_wdt              = hmc_rd_wr("r","LNK1_LANE5_RX_EYE_WDT", LNK1_LANE5_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk1_lane6_rx_eye_wdt              = hmc_rd_wr("r","LNK1_LANE6_RX_EYE_WDT", LNK1_LANE6_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk1_lane7_rx_eye_wdt              = hmc_rd_wr("r","LNK1_LANE7_RX_EYE_WDT", LNK1_LANE7_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk1_lane8_rx_eye_wdt              = hmc_rd_wr("r","LNK1_LANE8_RX_EYE_WDT", LNK1_LANE8_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk1_lane9_rx_eye_wdt              = hmc_rd_wr("r","LNK1_LANE9_RX_EYE_WDT", LNK1_LANE9_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk1_lanea_rx_eye_wdt              = hmc_rd_wr("r","LNK1_LANEA_RX_EYE_WDT", LNK1_LANEA_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk1_laneb_rx_eye_wdt              = hmc_rd_wr("r","LNK1_LANEB_RX_EYE_WDT", LNK1_LANEB_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk1_lanec_rx_eye_wdt              = hmc_rd_wr("r","LNK1_LANEC_RX_EYE_WDT", LNK1_LANEC_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk1_laned_rx_eye_wdt              = hmc_rd_wr("r","LNK1_LANED_RX_EYE_WDT", LNK1_LANED_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk1_lanee_rx_eye_wdt              = hmc_rd_wr("r","LNK1_LANEE_RX_EYE_WDT", LNK1_LANEE_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk1_lanef_rx_eye_wdt              = hmc_rd_wr("r","LNK1_LANEF_RX_EYE_WDT", LNK1_LANEF_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk2_lane0_rx_eye_wdt              = hmc_rd_wr("r","LNK2_LANE0_RX_EYE_WDT", LNK2_LANE0_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk2_lane1_rx_eye_wdt              = hmc_rd_wr("r","LNK2_LANE1_RX_EYE_WDT", LNK2_LANE1_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk2_lane2_rx_eye_wdt              = hmc_rd_wr("r","LNK2_LANE2_RX_EYE_WDT", LNK2_LANE2_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk2_lane3_rx_eye_wdt              = hmc_rd_wr("r","LNK2_LANE3_RX_EYE_WDT", LNK2_LANE3_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk2_lane4_rx_eye_wdt              = hmc_rd_wr("r","LNK2_LANE4_RX_EYE_WDT", LNK2_LANE4_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk2_lane5_rx_eye_wdt              = hmc_rd_wr("r","LNK2_LANE5_RX_EYE_WDT", LNK2_LANE5_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk2_lane6_rx_eye_wdt              = hmc_rd_wr("r","LNK2_LANE6_RX_EYE_WDT", LNK2_LANE6_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk2_lane7_rx_eye_wdt              = hmc_rd_wr("r","LNK2_LANE7_RX_EYE_WDT", LNK2_LANE7_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk2_lane8_rx_eye_wdt              = hmc_rd_wr("r","LNK2_LANE8_RX_EYE_WDT", LNK2_LANE8_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk2_lane9_rx_eye_wdt              = hmc_rd_wr("r","LNK2_LANE9_RX_EYE_WDT", LNK2_LANE9_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk2_lanea_rx_eye_wdt              = hmc_rd_wr("r","LNK2_LANEA_RX_EYE_WDT", LNK2_LANEA_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk2_laneb_rx_eye_wdt              = hmc_rd_wr("r","LNK2_LANEB_RX_EYE_WDT", LNK2_LANEB_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk2_lanec_rx_eye_wdt              = hmc_rd_wr("r","LNK2_LANEC_RX_EYE_WDT", LNK2_LANEC_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk2_laned_rx_eye_wdt              = hmc_rd_wr("r","LNK2_LANED_RX_EYE_WDT", LNK2_LANED_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk2_lanee_rx_eye_wdt              = hmc_rd_wr("r","LNK2_LANEE_RX_EYE_WDT", LNK2_LANEE_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk2_lanef_rx_eye_wdt              = hmc_rd_wr("r","LNK2_LANEF_RX_EYE_WDT", LNK2_LANEF_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk3_lane0_rx_eye_wdt              = hmc_rd_wr("r","LNK3_LANE0_RX_EYE_WDT", LNK3_LANE0_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk3_lane1_rx_eye_wdt              = hmc_rd_wr("r","LNK3_LANE1_RX_EYE_WDT", LNK3_LANE1_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk3_lane2_rx_eye_wdt              = hmc_rd_wr("r","LNK3_LANE2_RX_EYE_WDT", LNK3_LANE2_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk3_lane3_rx_eye_wdt              = hmc_rd_wr("r","LNK3_LANE3_RX_EYE_WDT", LNK3_LANE3_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk3_lane4_rx_eye_wdt              = hmc_rd_wr("r","LNK3_LANE4_RX_EYE_WDT", LNK3_LANE4_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk3_lane5_rx_eye_wdt              = hmc_rd_wr("r","LNK3_LANE5_RX_EYE_WDT", LNK3_LANE5_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk3_lane6_rx_eye_wdt              = hmc_rd_wr("r","LNK3_LANE6_RX_EYE_WDT", LNK3_LANE6_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk3_lane7_rx_eye_wdt              = hmc_rd_wr("r","LNK3_LANE7_RX_EYE_WDT", LNK3_LANE7_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk3_lane8_rx_eye_wdt              = hmc_rd_wr("r","LNK3_LANE8_RX_EYE_WDT", LNK3_LANE8_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk3_lane9_rx_eye_wdt              = hmc_rd_wr("r","LNK3_LANE9_RX_EYE_WDT", LNK3_LANE9_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk3_lanea_rx_eye_wdt              = hmc_rd_wr("r","LNK3_LANEA_RX_EYE_WDT", LNK3_LANEA_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk3_laneb_rx_eye_wdt              = hmc_rd_wr("r","LNK3_LANEB_RX_EYE_WDT", LNK3_LANEB_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk3_lanec_rx_eye_wdt              = hmc_rd_wr("r","LNK3_LANEC_RX_EYE_WDT", LNK3_LANEC_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk3_laned_rx_eye_wdt              = hmc_rd_wr("r","LNK3_LANED_RX_EYE_WDT", LNK3_LANED_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk3_lanee_rx_eye_wdt              = hmc_rd_wr("r","LNK3_LANEE_RX_EYE_WDT", LNK3_LANEE_RX_EYE_WDT, 0xDEADBEEF);
    Hmc.lnk3_lanef_rx_eye_wdt              = hmc_rd_wr("r","LNK3_LANEF_RX_EYE_WDT", LNK3_LANEF_RX_EYE_WDT, 0xDEADBEEF);
    xil_printf("Reading RX Height Statistics Registers:\n\r");
    Hmc.lnk0_lane0_rx_eye_hgt              = hmc_rd_wr("r","LNK0_LANE0_RX_EYE_HGT", LNK0_LANE0_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk0_lane1_rx_eye_hgt              = hmc_rd_wr("r","LNK0_LANE1_RX_EYE_HGT", LNK0_LANE1_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk0_lane2_rx_eye_hgt              = hmc_rd_wr("r","LNK0_LANE2_RX_EYE_HGT", LNK0_LANE2_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk0_lane3_rx_eye_hgt              = hmc_rd_wr("r","LNK0_LANE3_RX_EYE_HGT", LNK0_LANE3_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk0_lane4_rx_eye_hgt              = hmc_rd_wr("r","LNK0_LANE4_RX_EYE_HGT", LNK0_LANE4_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk0_lane5_rx_eye_hgt              = hmc_rd_wr("r","LNK0_LANE5_RX_EYE_HGT", LNK0_LANE5_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk0_lane6_rx_eye_hgt              = hmc_rd_wr("r","LNK0_LANE6_RX_EYE_HGT", LNK0_LANE6_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk0_lane7_rx_eye_hgt              = hmc_rd_wr("r","LNK0_LANE7_RX_EYE_HGT", LNK0_LANE7_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk0_lane8_rx_eye_hgt              = hmc_rd_wr("r","LNK0_LANE8_RX_EYE_HGT", LNK0_LANE8_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk0_lane9_rx_eye_hgt              = hmc_rd_wr("r","LNK0_LANE9_RX_EYE_HGT", LNK0_LANE9_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk0_lanea_rx_eye_hgt              = hmc_rd_wr("r","LNK0_LANEA_RX_EYE_HGT", LNK0_LANEA_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk0_laneb_rx_eye_hgt              = hmc_rd_wr("r","LNK0_LANEB_RX_EYE_HGT", LNK0_LANEB_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk0_lanec_rx_eye_hgt              = hmc_rd_wr("r","LNK0_LANEC_RX_EYE_HGT", LNK0_LANEC_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk0_laned_rx_eye_hgt              = hmc_rd_wr("r","LNK0_LANED_RX_EYE_HGT", LNK0_LANED_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk0_lanee_rx_eye_hgt              = hmc_rd_wr("r","LNK0_LANEE_RX_EYE_HGT", LNK0_LANEE_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk0_lanef_rx_eye_hgt              = hmc_rd_wr("r","LNK0_LANEF_RX_EYE_HGT", LNK0_LANEF_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk1_lane0_rx_eye_hgt              = hmc_rd_wr("r","LNK1_LANE0_RX_EYE_HGT", LNK1_LANE0_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk1_lane1_rx_eye_hgt              = hmc_rd_wr("r","LNK1_LANE1_RX_EYE_HGT", LNK1_LANE1_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk1_lane2_rx_eye_hgt              = hmc_rd_wr("r","LNK1_LANE2_RX_EYE_HGT", LNK1_LANE2_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk1_lane3_rx_eye_hgt              = hmc_rd_wr("r","LNK1_LANE3_RX_EYE_HGT", LNK1_LANE3_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk1_lane4_rx_eye_hgt              = hmc_rd_wr("r","LNK1_LANE4_RX_EYE_HGT", LNK1_LANE4_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk1_lane5_rx_eye_hgt              = hmc_rd_wr("r","LNK1_LANE5_RX_EYE_HGT", LNK1_LANE5_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk1_lane6_rx_eye_hgt              = hmc_rd_wr("r","LNK1_LANE6_RX_EYE_HGT", LNK1_LANE6_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk1_lane7_rx_eye_hgt              = hmc_rd_wr("r","LNK1_LANE7_RX_EYE_HGT", LNK1_LANE7_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk1_lane8_rx_eye_hgt              = hmc_rd_wr("r","LNK1_LANE8_RX_EYE_HGT", LNK1_LANE8_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk1_lane9_rx_eye_hgt              = hmc_rd_wr("r","LNK1_LANE9_RX_EYE_HGT", LNK1_LANE9_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk1_lanea_rx_eye_hgt              = hmc_rd_wr("r","LNK1_LANEA_RX_EYE_HGT", LNK1_LANEA_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk1_laneb_rx_eye_hgt              = hmc_rd_wr("r","LNK1_LANEB_RX_EYE_HGT", LNK1_LANEB_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk1_lanec_rx_eye_hgt              = hmc_rd_wr("r","LNK1_LANEC_RX_EYE_HGT", LNK1_LANEC_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk1_laned_rx_eye_hgt              = hmc_rd_wr("r","LNK1_LANED_RX_EYE_HGT", LNK1_LANED_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk1_lanee_rx_eye_hgt              = hmc_rd_wr("r","LNK1_LANEE_RX_EYE_HGT", LNK1_LANEE_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk1_lanef_rx_eye_hgt              = hmc_rd_wr("r","LNK1_LANEF_RX_EYE_HGT", LNK1_LANEF_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk2_lane0_rx_eye_hgt              = hmc_rd_wr("r","LNK2_LANE0_RX_EYE_HGT", LNK2_LANE0_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk2_lane1_rx_eye_hgt              = hmc_rd_wr("r","LNK2_LANE1_RX_EYE_HGT", LNK2_LANE1_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk2_lane2_rx_eye_hgt              = hmc_rd_wr("r","LNK2_LANE2_RX_EYE_HGT", LNK2_LANE2_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk2_lane3_rx_eye_hgt              = hmc_rd_wr("r","LNK2_LANE3_RX_EYE_HGT", LNK2_LANE3_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk2_lane4_rx_eye_hgt              = hmc_rd_wr("r","LNK2_LANE4_RX_EYE_HGT", LNK2_LANE4_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk2_lane5_rx_eye_hgt              = hmc_rd_wr("r","LNK2_LANE5_RX_EYE_HGT", LNK2_LANE5_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk2_lane6_rx_eye_hgt              = hmc_rd_wr("r","LNK2_LANE6_RX_EYE_HGT", LNK2_LANE6_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk2_lane7_rx_eye_hgt              = hmc_rd_wr("r","LNK2_LANE7_RX_EYE_HGT", LNK2_LANE7_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk2_lane8_rx_eye_hgt              = hmc_rd_wr("r","LNK2_LANE8_RX_EYE_HGT", LNK2_LANE8_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk2_lane9_rx_eye_hgt              = hmc_rd_wr("r","LNK2_LANE9_RX_EYE_HGT", LNK2_LANE9_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk2_lanea_rx_eye_hgt              = hmc_rd_wr("r","LNK2_LANEA_RX_EYE_HGT", LNK2_LANEA_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk2_laneb_rx_eye_hgt              = hmc_rd_wr("r","LNK2_LANEB_RX_EYE_HGT", LNK2_LANEB_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk2_lanec_rx_eye_hgt              = hmc_rd_wr("r","LNK2_LANEC_RX_EYE_HGT", LNK2_LANEC_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk2_laned_rx_eye_hgt              = hmc_rd_wr("r","LNK2_LANED_RX_EYE_HGT", LNK2_LANED_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk2_lanee_rx_eye_hgt              = hmc_rd_wr("r","LNK2_LANEE_RX_EYE_HGT", LNK2_LANEE_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk2_lanef_rx_eye_hgt              = hmc_rd_wr("r","LNK2_LANEF_RX_EYE_HGT", LNK2_LANEF_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk3_lane0_rx_eye_hgt              = hmc_rd_wr("r","LNK3_LANE0_RX_EYE_HGT", LNK3_LANE0_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk3_lane1_rx_eye_hgt              = hmc_rd_wr("r","LNK3_LANE1_RX_EYE_HGT", LNK3_LANE1_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk3_lane2_rx_eye_hgt              = hmc_rd_wr("r","LNK3_LANE2_RX_EYE_HGT", LNK3_LANE2_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk3_lane3_rx_eye_hgt              = hmc_rd_wr("r","LNK3_LANE3_RX_EYE_HGT", LNK3_LANE3_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk3_lane4_rx_eye_hgt              = hmc_rd_wr("r","LNK3_LANE4_RX_EYE_HGT", LNK3_LANE4_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk3_lane5_rx_eye_hgt              = hmc_rd_wr("r","LNK3_LANE5_RX_EYE_HGT", LNK3_LANE5_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk3_lane6_rx_eye_hgt              = hmc_rd_wr("r","LNK3_LANE6_RX_EYE_HGT", LNK3_LANE6_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk3_lane7_rx_eye_hgt              = hmc_rd_wr("r","LNK3_LANE7_RX_EYE_HGT", LNK3_LANE7_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk3_lane8_rx_eye_hgt              = hmc_rd_wr("r","LNK3_LANE8_RX_EYE_HGT", LNK3_LANE8_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk3_lane9_rx_eye_hgt              = hmc_rd_wr("r","LNK3_LANE9_RX_EYE_HGT", LNK3_LANE9_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk3_lanea_rx_eye_hgt              = hmc_rd_wr("r","LNK3_LANEA_RX_EYE_HGT", LNK3_LANEA_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk3_laneb_rx_eye_hgt              = hmc_rd_wr("r","LNK3_LANEB_RX_EYE_HGT", LNK3_LANEB_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk3_lanec_rx_eye_hgt              = hmc_rd_wr("r","LNK3_LANEC_RX_EYE_HGT", LNK3_LANEC_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk3_laned_rx_eye_hgt              = hmc_rd_wr("r","LNK3_LANED_RX_EYE_HGT", LNK3_LANED_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk3_lanee_rx_eye_hgt              = hmc_rd_wr("r","LNK3_LANEE_RX_EYE_HGT", LNK3_LANEE_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;
    Hmc.lnk3_lanef_rx_eye_hgt              = hmc_rd_wr("r","LNK3_LANEF_RX_EYE_HGT", LNK3_LANEF_RX_EYE_HGT, 0xDEADBEEF) & 0x0000007F;

    xil_printf("\n\rResults (\%UI:Hgt(mV)(390 Reset value)\n\r");
    xil_printf("Lane :\t0\t1\t2\t3\t4\t5\t6\t7\t8\t9\ta\tb\tc\td\te\tf\n\r");
    //Link0
    printf("Link0:\t%02.0f:%03.0f\t", (float)(Hmc.lnk0_lane0_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk0_lane0_rx_eye_hgt  )* 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk0_lane1_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk0_lane1_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk0_lane2_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk0_lane2_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk0_lane3_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk0_lane3_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk0_lane4_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk0_lane4_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk0_lane5_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk0_lane5_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk0_lane6_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk0_lane6_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk0_lane7_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk0_lane7_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk0_lane8_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk0_lane8_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk0_lane9_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk0_lane9_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk0_lanea_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk0_lanea_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk0_laneb_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk0_laneb_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk0_lanec_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk0_lanec_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk0_laned_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk0_laned_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk0_lanee_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk0_lanee_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\r\n",(float) (Hmc.lnk0_lanef_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk0_lanef_rx_eye_hgt  ) * 7.8 );
    //Link1
    printf("Link1:\t%02.0f:%03.0f\t",(float) (Hmc.lnk1_lane0_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk1_lane0_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk1_lane1_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk1_lane1_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk1_lane2_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk1_lane2_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk1_lane3_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk1_lane3_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk1_lane4_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk1_lane4_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk1_lane5_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk1_lane5_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk1_lane6_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk1_lane6_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk1_lane7_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk1_lane7_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk1_lane8_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk1_lane8_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk1_lane9_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk1_lane9_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk1_lanea_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk1_lanea_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk1_laneb_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk1_laneb_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk1_lanec_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk1_lanec_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk1_laned_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk1_laned_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk1_lanee_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk1_lanee_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\r\n",(float) (Hmc.lnk1_lanef_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk1_lanef_rx_eye_hgt  ) * 7.8 );
    //Link1
    printf("Link2:\t%02.0f:%03.0f\t",(float) (Hmc.lnk2_lane0_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk2_lane0_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk2_lane1_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk2_lane1_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk2_lane2_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk2_lane2_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk2_lane3_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk2_lane3_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk2_lane4_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk2_lane4_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk2_lane5_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk2_lane5_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk2_lane6_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk2_lane6_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk2_lane7_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk2_lane7_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk2_lane8_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk2_lane8_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk2_lane9_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk2_lane9_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk2_lanea_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk2_lanea_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk2_laneb_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk2_laneb_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk2_lanec_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk2_lanec_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk2_laned_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk2_laned_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk2_lanee_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk2_lanee_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\r\n",(float) (Hmc.lnk2_lanef_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk2_lanef_rx_eye_hgt  ) * 7.8 );
    //Link3
    printf("Link3:\t%02.0f:%03.0f\t",(float) (Hmc.lnk3_lane0_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk3_lane0_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk3_lane1_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk3_lane1_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk3_lane2_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk3_lane2_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk3_lane3_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk3_lane3_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk3_lane4_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk3_lane4_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk3_lane5_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk3_lane5_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk3_lane6_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk3_lane6_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk3_lane7_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk3_lane7_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk3_lane8_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk3_lane8_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk3_lane9_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk3_lane9_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk3_lanea_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk3_lanea_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk3_laneb_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk3_laneb_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk3_lanec_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk3_lanec_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk3_laned_rx_eye_wdt >> 10 )/32 *100, ( Hmc.lnk3_laned_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\t",(float) (Hmc.lnk3_lanee_rx_eye_wdt >> 10 ) / 32, ( Hmc.lnk3_lanee_rx_eye_hgt  ) * 7.8 );
    printf("%02.0f:%03.0f\r\n",(float) (Hmc.lnk3_lanef_rx_eye_wdt >> 10 ) / 32, ( Hmc.lnk3_lanef_rx_eye_hgt  ) * 7.8 );

}

/******************hmc_pattern_data*********************************************/

void hmc_pattern_data(char *rw, u32 hmc_cfgdata)
{
   Hmc.hmc_cfgdata = 0xDEADBEAF;

   write_mux(TCA9548_MUX_ADDR, TCA9548_MUX_PORT5);  // Set 8-port IIC Mux to HMC

   xil_printf("HMC Link pattern Registers:\n\r");

   //read the registers into the structure
   Hmc.lnk0_lane0_patrn_ctrl              = hmc_rd_wr(rw,"LNK0_LANE0_PATRN_CTRL", LNK0_LANE0_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk0_lane1_patrn_ctrl              = hmc_rd_wr(rw,"LNK0_LANE1_PATRN_CTRL", LNK0_LANE1_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk0_lane2_patrn_ctrl              = hmc_rd_wr(rw,"LNK0_LANE2_PATRN_CTRL", LNK0_LANE2_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk0_lane3_patrn_ctrl              = hmc_rd_wr(rw,"LNK0_LANE3_PATRN_CTRL", LNK0_LANE3_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk0_lane4_patrn_ctrl              = hmc_rd_wr(rw,"LNK0_LANE4_PATRN_CTRL", LNK0_LANE4_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk0_lane5_patrn_ctrl              = hmc_rd_wr(rw,"LNK0_LANE5_PATRN_CTRL", LNK0_LANE5_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk0_lane6_patrn_ctrl              = hmc_rd_wr(rw,"LNK0_LANE6_PATRN_CTRL", LNK0_LANE6_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk0_lane7_patrn_ctrl              = hmc_rd_wr(rw,"LNK0_LANE7_PATRN_CTRL", LNK0_LANE7_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk0_lane8_patrn_ctrl              = hmc_rd_wr(rw,"LNK0_LANE8_PATRN_CTRL", LNK0_LANE8_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk0_lane9_patrn_ctrl              = hmc_rd_wr(rw,"LNK0_LANE9_PATRN_CTRL", LNK0_LANE9_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk0_lanea_patrn_ctrl              = hmc_rd_wr(rw,"LNK0_LANEA_PATRN_CTRL", LNK0_LANEA_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk0_laneb_patrn_ctrl              = hmc_rd_wr(rw,"LNK0_LANEB_PATRN_CTRL", LNK0_LANEB_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk0_lanec_patrn_ctrl              = hmc_rd_wr(rw,"LNK0_LANEC_PATRN_CTRL", LNK0_LANEC_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk0_laned_patrn_ctrl              = hmc_rd_wr(rw,"LNK0_LANED_PATRN_CTRL", LNK0_LANED_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk0_lanee_patrn_ctrl              = hmc_rd_wr(rw,"LNK0_LANEE_PATRN_CTRL", LNK0_LANEE_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk0_lanef_patrn_ctrl              = hmc_rd_wr(rw,"LNK0_LANEF_PATRN_CTRL", LNK0_LANEF_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk1_lane0_patrn_ctrl              = hmc_rd_wr(rw,"LNK1_LANE0_PATRN_CTRL", LNK1_LANE0_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk1_lane1_patrn_ctrl              = hmc_rd_wr(rw,"LNK1_LANE1_PATRN_CTRL", LNK1_LANE1_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk1_lane2_patrn_ctrl              = hmc_rd_wr(rw,"LNK1_LANE2_PATRN_CTRL", LNK1_LANE2_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk1_lane3_patrn_ctrl              = hmc_rd_wr(rw,"LNK1_LANE3_PATRN_CTRL", LNK1_LANE3_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk1_lane4_patrn_ctrl              = hmc_rd_wr(rw,"LNK1_LANE4_PATRN_CTRL", LNK1_LANE4_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk1_lane5_patrn_ctrl              = hmc_rd_wr(rw,"LNK1_LANE5_PATRN_CTRL", LNK1_LANE5_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk1_lane6_patrn_ctrl              = hmc_rd_wr(rw,"LNK1_LANE6_PATRN_CTRL", LNK1_LANE6_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk1_lane7_patrn_ctrl              = hmc_rd_wr(rw,"LNK1_LANE7_PATRN_CTRL", LNK1_LANE7_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk1_lane8_patrn_ctrl              = hmc_rd_wr(rw,"LNK1_LANE8_PATRN_CTRL", LNK1_LANE8_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk1_lane9_patrn_ctrl              = hmc_rd_wr(rw,"LNK1_LANE9_PATRN_CTRL", LNK1_LANE9_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk1_lanea_patrn_ctrl              = hmc_rd_wr(rw,"LNK1_LANEA_PATRN_CTRL", LNK1_LANEA_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk1_laneb_patrn_ctrl              = hmc_rd_wr(rw,"LNK1_LANEB_PATRN_CTRL", LNK1_LANEB_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk1_lanec_patrn_ctrl              = hmc_rd_wr(rw,"LNK1_LANEC_PATRN_CTRL", LNK1_LANEC_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk1_laned_patrn_ctrl              = hmc_rd_wr(rw,"LNK1_LANED_PATRN_CTRL", LNK1_LANED_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk1_lanee_patrn_ctrl              = hmc_rd_wr(rw,"LNK1_LANEE_PATRN_CTRL", LNK1_LANEE_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk1_lanef_patrn_ctrl              = hmc_rd_wr(rw,"LNK1_LANEF_PATRN_CTRL", LNK1_LANEF_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk2_lane0_patrn_ctrl              = hmc_rd_wr(rw,"LNK2_LANE0_PATRN_CTRL", LNK2_LANE0_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk2_lane1_patrn_ctrl              = hmc_rd_wr(rw,"LNK2_LANE1_PATRN_CTRL", LNK2_LANE1_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk2_lane2_patrn_ctrl              = hmc_rd_wr(rw,"LNK2_LANE2_PATRN_CTRL", LNK2_LANE2_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk2_lane3_patrn_ctrl              = hmc_rd_wr(rw,"LNK2_LANE3_PATRN_CTRL", LNK2_LANE3_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk2_lane4_patrn_ctrl              = hmc_rd_wr(rw,"LNK2_LANE4_PATRN_CTRL", LNK2_LANE4_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk2_lane5_patrn_ctrl              = hmc_rd_wr(rw,"LNK2_LANE5_PATRN_CTRL", LNK2_LANE5_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk2_lane6_patrn_ctrl              = hmc_rd_wr(rw,"LNK2_LANE6_PATRN_CTRL", LNK2_LANE6_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk2_lane7_patrn_ctrl              = hmc_rd_wr(rw,"LNK2_LANE7_PATRN_CTRL", LNK2_LANE7_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk2_lane8_patrn_ctrl              = hmc_rd_wr(rw,"LNK2_LANE8_PATRN_CTRL", LNK2_LANE8_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk2_lane9_patrn_ctrl              = hmc_rd_wr(rw,"LNK2_LANE9_PATRN_CTRL", LNK2_LANE9_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk2_lanea_patrn_ctrl              = hmc_rd_wr(rw,"LNK2_LANEA_PATRN_CTRL", LNK2_LANEA_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk2_laneb_patrn_ctrl              = hmc_rd_wr(rw,"LNK2_LANEB_PATRN_CTRL", LNK2_LANEB_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk2_lanec_patrn_ctrl              = hmc_rd_wr(rw,"LNK2_LANEC_PATRN_CTRL", LNK2_LANEC_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk2_laned_patrn_ctrl              = hmc_rd_wr(rw,"LNK2_LANED_PATRN_CTRL", LNK2_LANED_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk2_lanee_patrn_ctrl              = hmc_rd_wr(rw,"LNK2_LANEE_PATRN_CTRL", LNK2_LANEE_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk2_lanef_patrn_ctrl              = hmc_rd_wr(rw,"LNK2_LANEF_PATRN_CTRL", LNK2_LANEF_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk3_lane0_patrn_ctrl              = hmc_rd_wr(rw,"LNK3_LANE0_PATRN_CTRL", LNK3_LANE0_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk3_lane1_patrn_ctrl              = hmc_rd_wr(rw,"LNK3_LANE1_PATRN_CTRL", LNK3_LANE1_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk3_lane2_patrn_ctrl              = hmc_rd_wr(rw,"LNK3_LANE2_PATRN_CTRL", LNK3_LANE2_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk3_lane3_patrn_ctrl              = hmc_rd_wr(rw,"LNK3_LANE3_PATRN_CTRL", LNK3_LANE3_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk3_lane4_patrn_ctrl              = hmc_rd_wr(rw,"LNK3_LANE4_PATRN_CTRL", LNK3_LANE4_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk3_lane5_patrn_ctrl              = hmc_rd_wr(rw,"LNK3_LANE5_PATRN_CTRL", LNK3_LANE5_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk3_lane6_patrn_ctrl              = hmc_rd_wr(rw,"LNK3_LANE6_PATRN_CTRL", LNK3_LANE6_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk3_lane7_patrn_ctrl              = hmc_rd_wr(rw,"LNK3_LANE7_PATRN_CTRL", LNK3_LANE7_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk3_lane8_patrn_ctrl              = hmc_rd_wr(rw,"LNK3_LANE8_PATRN_CTRL", LNK3_LANE8_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk3_lane9_patrn_ctrl              = hmc_rd_wr(rw,"LNK3_LANE9_PATRN_CTRL", LNK3_LANE9_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk3_lanea_patrn_ctrl              = hmc_rd_wr(rw,"LNK3_LANEA_PATRN_CTRL", LNK3_LANEA_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk3_laneb_patrn_ctrl              = hmc_rd_wr(rw,"LNK3_LANEB_PATRN_CTRL", LNK3_LANEB_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk3_lanec_patrn_ctrl              = hmc_rd_wr(rw,"LNK3_LANEC_PATRN_CTRL", LNK3_LANEC_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk3_laned_patrn_ctrl              = hmc_rd_wr(rw,"LNK3_LANED_PATRN_CTRL", LNK3_LANED_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk3_lanee_patrn_ctrl              = hmc_rd_wr(rw,"LNK3_LANEE_PATRN_CTRL", LNK3_LANEE_PATRN_CTRL, hmc_cfgdata);
   Hmc.lnk3_lanef_patrn_ctrl              = hmc_rd_wr(rw,"LNK3_LANEF_PATRN_CTRL", LNK3_LANEF_PATRN_CTRL, hmc_cfgdata);
}

/******************hmc_set_prbs_checker*********************************************/

void hmc_set_prbs_checker()
{
   
   int choice;
   u32 hmc_cfgdata = 0xDEADBEEF;
   write_mux(TCA9548_MUX_ADDR, TCA9548_MUX_PORT5);  // Set 8-port IIC Mux to HMC
   int exit_flag = 0;
    while(exit_flag != 1) {
        xil_printf("\r\nChoose Option:\r\n");
        xil_printf("0: HMC Check All PRBS7P \t");
        xil_printf("1: HMC Check All PRBS7N\r\n");
        xil_printf("2: HMC Check All PRBS15P\t");
        xil_printf("3: HMC Check All PRBS15N\r\n");
        xil_printf("4: HMC Check All PRBS23P\t");
        xil_printf("5: HMC Check All PRBS23N\r\n");
        xil_printf("6: HMC Check All PRBS31P\t");
        xil_printf("7: HMC Check All PRBS31N\r\n");
        xil_printf("8: HMC Check All PRBS Enable\r\n");
        xil_printf("9: HMC PRBS Check Reset\r\n");
        xil_printf("A: Read PRBS Registers\r\n");
        xil_printf("Q: Exit\r\n");
        xil_printf("=>");
                    choice = inbyte();
  
              if (isalpha(choice)) {
                 choice = toupper(choice);
              }
            xil_printf("%c\r\n", choice);
  
        switch(choice) {
           case 'Q':
              exit_flag = 1;
              break;
           case '0':{
              hmc_cfgdata = LANE_PRBS7P;
              hmc_pattern_data("w", hmc_cfgdata);
              }
              break;
           case '1':{
              hmc_cfgdata = LANE_PRBS7N;
              hmc_pattern_data("w", hmc_cfgdata);
              }
              break;
           case '2':{
              hmc_cfgdata = LANE_PRBS15P;
              hmc_pattern_data("w", hmc_cfgdata);
              }
              break;
           case '3':{
              hmc_cfgdata = LANE_PRBS15N;
              hmc_pattern_data("w", hmc_cfgdata);
              }
              break;
           case '4':{
              hmc_cfgdata = LANE_PRBS23P;
              hmc_pattern_data("w", hmc_cfgdata);
              }
              break;
           case '5':{
              hmc_cfgdata = LANE_PRBS23N;
              hmc_pattern_data("w", hmc_cfgdata);
              }
              break;
           case '6':{
              hmc_cfgdata = LANE_PRBS31P;
              hmc_pattern_data("w", hmc_cfgdata);
              }
              break;
           case '7':{
              Hmc.hmc_cfgdata = LANE_PRBS31P;
              hmc_pattern_data("w", hmc_cfgdata);
              }
              break;
           case '8':{
              hmc_cfgdata = LANE_PRBS_CHKR_EN;
              hmc_pattern_data("rmw", hmc_cfgdata);
              }
              break;
           case '9':{
              hmc_cfgdata = LANE_PRBS_CHKR_RST;
              hmc_pattern_data("rmw", hmc_cfgdata);
              }
              break;
           case 'A':
              hmc_pattern_data("r", hmc_cfgdata);
              break;
           default:
              break;
        }
   }

}

/******************write_mux*********************************************/
int write_mux(u8 Addr, u8 Port)
{
   u8 WriteBuffer;
   int Status;

   /*
    * Set the defaults.
    */
   TransmitComplete = 1;
   Iic.Stats.TxErrors = 0;


    /*
     * Set Mux Channel
     */
     WriteBuffer = Port;


     Status = XIic_SetAddress(&Iic, XII_ADDR_TO_SEND_TYPE, Addr);
     if (Status != XST_SUCCESS) {
       return XST_FAILURE;
     }

     Status = XIic_Start(&Iic);
     if (Status != XST_SUCCESS) {
        xil_printf(" Error XIic_Start in write_mux\r\n");
        return XST_FAILURE;
     }
     /*
     * Send the Data.
     */

     Status = XIic_MasterSend(&Iic, &WriteBuffer, 1);
     if (Status != XST_SUCCESS) {
          xil_printf("Error Writing 0x%02X to MUX ID: 0x%02X\r\n", Port, Addr);
          return XST_FAILURE;
     }
     /*
      * Wait till all the data is written.
      */
     while ((TransmitComplete) || (XIic_IsIicBusy(&Iic) == TRUE)) {

     }

     /*
      * Stop the IIC device.
      */
     Status = XIic_Stop(&Iic);
     if (Status != XST_SUCCESS) {
        return XST_FAILURE;
     }

     return XST_SUCCESS;
}

/******************read_mux*********************************************/
int read_mux(u8 Addr)
{
   int Status = 0;
   u8 Buffer = 0;
   ReceiveComplete = 1;
    /*
     * Wait until bus is idle to start another transfer.
     */
   Status = XIic_Start(&Iic);
   if (Status != XST_SUCCESS) {
      return XST_FAILURE;
   }

   Status = XIic_SetAddress(&Iic, XII_ADDR_TO_SEND_TYPE,Addr);
   if (Status != XST_SUCCESS) {
      return XST_FAILURE;
   }
    /*
     * Receive the Data.
     */
    Status = XIic_MasterRecv(&Iic, &Buffer, 1);
    if (Status != XST_SUCCESS) {
       return XST_FAILURE;
    }

    while ((ReceiveComplete) || (XIic_IsIicBusy(&Iic) == TRUE)) {

    }

   xil_printf("   Read 0x%02X at MUX ID: 0x%02X\r\n", Buffer, Addr);

   Status = XIic_Stop(&Iic);
   if (Status != XST_SUCCESS) {
      return XST_FAILURE;
   }

   return XST_SUCCESS;
}

/******************XIic_SetGPO*********************************************/
void XIic_SetGPO(u32 gpo)
{
   // read the GPO register
   u32 gpo_reg, new_value;

   gpo_reg = XIic_ReadReg(Iic.BaseAddress, XIIC_GPO_REG_OFFSET);
   xil_printf("  GPO -> 0x%08X 0x%08X\n\r", Iic.BaseAddress+XIIC_GPO_REG_OFFSET, gpo_reg);
   new_value = gpo_reg | gpo;
   xil_printf("  GPO will be changed to 0x%08X\n\r", new_value);
   XIic_WriteReg(Iic.BaseAddress, XIIC_GPO_REG_OFFSET, new_value);
}
void XIic_ClearGPO(u32 gpo)
{
    // read the GPO register
    u32 gpo_reg, new_value;

   gpo_reg = XIic_ReadReg(Iic.BaseAddress, XIIC_GPO_REG_OFFSET);
   xil_printf("  GPO -> 0x%08X 0x%08X\n\r", Iic.BaseAddress+XIIC_GPO_REG_OFFSET, gpo_reg);
   new_value = gpo_reg & ~gpo;
   xil_printf("  GPO will be changed to 0x%08X\n\r", new_value);
   XIic_WriteReg(Iic.BaseAddress, XIIC_GPO_REG_OFFSET, new_value );
}

/************************** hmc_init_iicmux ******************************************/
int hmc_init_iicmux()
{
   write_mux(TCA9548_MUX_ADDR, TCA9548_MUX_PORT5);  // Set 8-port IIC Mux to HMC

   write_mux(PCA9544_MUX_ADDR, PCA9544_MUX_OFF);  // Set 4-port IIC Mux to No Connections

   return XST_SUCCESS;
}
/************************** hmc_rst_iicmux ******************************************/
int hmc_rst_iicmux()
{
      /* Reset I2C Expander */
      write_mux(TCA9548_MUX_ADDR, TCA9548_MUX_OFF);

      write_mux(PCA9544_MUX_ADDR, PCA9544_MUX_OFF);

      return XST_SUCCESS;
}
/************************** hmc_read4 ******************************************/
int hmc_read4(u32 hmc_cfgaddr, u8 *BufferPtr)
{
//    u8 WriteBuffer[4]={0,0,0,0};
//    u8 ReadBuffer[4];
    int Status = 0;
    u32 rbuf, xiic_options;
    int i=0;
    /*
     * Set the Defaults.
     */
    TransmitComplete = 1;
    ReceiveComplete = 1;

   //set mux to HMC
   // hmc_init_iicmux();
   // set the repeated start bit


   WriteBuffer[0] = (u8)((hmc_cfgaddr>>24) & 0x000000FF);
   WriteBuffer[1] = (u8)((hmc_cfgaddr>>16) & 0x000000FF);
   WriteBuffer[2] = (u8)((hmc_cfgaddr>>8)  & 0x000000FF);
   WriteBuffer[3] = (u8) (hmc_cfgaddr      & 0x000000FF);


   //write the address to read
   Status = XIic_SetAddress(&Iic, XII_ADDR_TO_SEND_TYPE, HMC_IIC_ADDR);
   for(i=0;i<10000;i++);     // delay

   Status = XIic_Start(&Iic);
   for(i=0;i<10000;i++);     // delay
   if (Status != XST_SUCCESS) {
      xil_printf("XIic_Start Error\r\n");
      return XST_FAILURE;
   }
   xiic_options = XIic_GetOptions(&Iic);
   for(i=0;i<10000;i++);     // delay
   xiic_options = xiic_options | XII_REPEATED_START_OPTION;
   for(i=0;i<10000;i++);     // delay
   XIic_SetOptions(&Iic, xiic_options);
   for(i=0;i<10000;i++);     // delay

   Status = XIic_MasterSend(&Iic, WriteBuffer, 4);
   for(i=0;i<10000;i++);     // delay
   if (Status != XST_SUCCESS) {
       xil_printf("XIic_MasterSend error sending HMC Write\r\n");
       return XST_FAILURE;
   }
   /*
    * Wait till all the data is written.
    */
   while (TransmitComplete) {

   }
   for(i=0;i<10000;i++);  //Add a little delay
   //read the 32 bits of data
   //Status = XIic_SetAddress(&Iic, XII_ADDR_TO_SEND_TYPE, HMC_IIC_ADDR);
   //xil_printf("Readbuffer 0x%08X\r\n",&ReadBuffer[0] );
   xiic_options = XIic_GetOptions(&Iic);
   for(i=0;i<10000;i++);     // delay
   xiic_options = xiic_options & ~XII_REPEATED_START_OPTION;
   for(i=0;i<10000;i++);     // delay
   XIic_SetOptions(&Iic, xiic_options);
   for(i=0;i<10000;i++);     // delay

   Status = XIic_MasterRecv(&Iic, BufferPtr, (int)4);
   for(i=0;i<10000;i++);     // delay
   if (Status != XST_SUCCESS) {
       xil_printf("XIic_MasterRecv error on HMC Write\r\n");
       return XST_FAILURE;
    }
    /*
    * Wait till all the data is received.
    */
   while ((ReceiveComplete) || (XIic_IsIicBusy(&Iic) == TRUE)) {

   }



   rbuf = 0;
   rbuf = ((u32) ReadBuffer[0]) <<24;
   for(i=0;i<10000;i++);     // delay
   rbuf = rbuf | ((u32) ReadBuffer[1]) <<16;
   for(i=0;i<10000;i++);     // delay
   rbuf = rbuf | ((u32) ReadBuffer[2]) <<8;
   for(i=0;i<10000;i++);     // delay
   rbuf = rbuf | ((u32) ReadBuffer[3]);
   for(i=0;i<10000;i++);     // delay

   Hmc.hmc_cfgdata = rbuf;
   for(i=0;i<10000;i++);     // delay
   //xil_printf("Readbuffer 0x%08X\r\n",Hmc.hmc_cfgdata );

   /*
    * Stop the IIC device.
    */
   Status = XIic_Stop(&Iic);
   for(i=0;i<10000;i++);     // delay
   if (Status != XST_SUCCESS) {
      xil_printf("XIic_Stop error\r\n");
      return XST_FAILURE;
   }


   return XST_SUCCESS;
}

/************************** hmc_write4 ******************************************/
int hmc_write4(u32 hmc_cfgaddr, u32 hmc_cfgdata)
{
    int i=0;
    u8 WriteBuffer[BYTES_TO_WRITE];
    int Status = 0;
    TransmitComplete = 1;
    Iic.Stats.TxErrors = 0;

   //hmc_init_iicmux();

   WriteBuffer[0] = (u8)((hmc_cfgaddr>>24) & 0x000000FF);
   WriteBuffer[1] = (u8)((hmc_cfgaddr>>16) & 0x000000FF);
   WriteBuffer[2] = (u8)((hmc_cfgaddr>>8)  & 0x000000FF);
   WriteBuffer[3] = (u8)(hmc_cfgaddr & 0x000000FF);

   WriteBuffer[4] = (u8)((hmc_cfgdata>>24) & 0x000000FF);
   WriteBuffer[5] = (u8)((hmc_cfgdata>>16) & 0x000000FF);
   WriteBuffer[6] = (u8)((hmc_cfgdata>>8)  & 0x000000FF);
   WriteBuffer[7] = (u8)(hmc_cfgdata & 0x000000FF);

   Status = XIic_SetAddress(&Iic, XII_ADDR_TO_SEND_TYPE, HMC_IIC_ADDR);
   for(i=0;i<10000;i++);     // delay
   if (Status != XST_SUCCESS) {
      xil_printf("Error Setting HMC I2C Address\r\n");
            return XST_FAILURE;
   }

   Status = XIic_Start(&Iic);
   for(i=0;i<10000;i++);     // delay
   if (Status != XST_SUCCESS) {
      xil_printf("XIic_Start Error\r\n");
      return XST_FAILURE;
   }
   Status = XIic_MasterSend(&Iic, WriteBuffer, BYTES_TO_WRITE);
   for(i=0;i<10000;i++);     // delay
   if (Status != XST_SUCCESS) {
       xil_printf("XIic_MasterSend error sending HMC Read to CFG\r\n. HMC IIC ADDR = 0x%02X, CFG Reg Addr = 0x%08X, CFG Write Data = 0x%08X\r\n",
                   HMC_IIC_ADDR, hmc_cfgaddr, hmc_cfgdata);
       return XST_FAILURE;
    }
   /*
    * Wait till all the data is written.
    */
   while ((TransmitComplete) || (XIic_IsIicBusy(&Iic) == TRUE)) {

   }

   /*
    * Stop the IIC device.
    */
   Status = XIic_Stop(&Iic);
   for(i=0;i<10000;i++);     // delay
   if (Status != XST_SUCCESS) {
      return XST_FAILURE;
   }
   return XST_SUCCESS;
}

void rw_interface()
{
   int done = 0, count = 0;
   char s[22];
    int Status;
    char *addr;
    char *readOrWrite;
    char *donecheck;
    char *token;
    char *data;
    char *line;
    //char *delimiters = " .,;:!-=";
    //int rorw_cmd;

    // initialize the array
    memset(s, 0, 22);
    xil_printf("\nEnter '0xAddress<:0xData>' in hex format with 0x prefix; Nothing in <:Data> is a read (q to quit):\n\r");

    while(!done) {
       xil_printf("=>");
       stdin_read(s,22);
       if(s == NULL){
         done = 0;
         continue;
       }
       donecheck =  strchr(s,'q');
       if (donecheck != NULL){
          done = 1;
       } else {
          readOrWrite = strchr(s,':');
          //this is a write command. Separate the two strings
          if (readOrWrite != NULL){
             count = 0;
             line = s;
             while ( (token = strsep(&line, ":") ) != NULL && (count < 2))
             {
               if( count == 0 ) addr = token;
               else data = token;
               count++;
             }
             Hmc.hmc_cfgaddr = char2hex(addr);
             Hmc.hmc_cfgdata = char2hex(data);
          } else {
             //this is a read command
             addr = s;
             Hmc.hmc_cfgaddr = char2hex(addr);
          }
          //check the format of the address and data
          if (Hmc.hmc_cfgaddr < 0 || Hmc.hmc_cfgaddr > 0xFFFFFFFF) {
              xil_printf("Address Out of Range (0x00000000 to 0xFFFFFFFF)\n", Hmc.hmc_cfgaddr);
              return;
          }
          if ((Hmc.hmc_cfgdata < 0 || Hmc.hmc_cfgdata > 0xFFFFFFFF) && count > 0) {
              xil_printf("Data Out of Range (0x00000000 to 0xFFFFFFFF)\n", Hmc.hmc_cfgdata);
              return;
          }
          if (count == 0){ //read
             Status = hmc_read4(Hmc.hmc_cfgaddr, ReadBuffer);
          } else { //write
             Status = hmc_write4(Hmc.hmc_cfgaddr, Hmc.hmc_cfgdata);
          }
          if (Status == XST_SUCCESS) {
             xil_printf("0x%08X:0x%08X\n\r", Hmc.hmc_cfgaddr, Hmc.hmc_cfgdata);
          }
       }
      }

   xil_printf("\n");
}

u32 hmc_rd_wr(char *rw,char *regstr,u32 addr, u32 data)
{
      int i=0;
      Hmc.hmc_cfgdata = data;
      Hmc.hmc_cfgaddr = addr;
       int Status = 0;
       u32 initialValue = 0;

       //hmc_init_iicmux();

      if(strcmp(rw, "r") == 0){
         xil_printf("Reading HMC %s Register 0x%08X:", regstr, addr);
         for(i=0;i<10000;i++);     // delay
         Status = hmc_read4( Hmc.hmc_cfgaddr, ReadBuffer);
         for(i=0;i<10000;i++);     // delay
         if (Status != XST_SUCCESS) {
            xil_printf(" !!Error reading!! ");
         }
         xil_printf("0x%08X\n\r",Hmc.hmc_cfgdata);
         return (Hmc.hmc_cfgdata);
      } else if (strcmp(rw, "w") == 0){
         xil_printf("Writing to HMC %s Register 0x%08X with 0x%08X\r\n", regstr, addr, Hmc.hmc_cfgdata);
         for(i=0;i<10000;i++);     // delay
         Status = hmc_write4( Hmc.hmc_cfgaddr, Hmc.hmc_cfgdata);
         for(i=0;i<10000;i++);     // delay
         if (Status != XST_SUCCESS) {
            xil_printf(" !!Error writing!! ");
         }
         return (Hmc.hmc_cfgdata);
      } else if (strcmp(rw, "wv") == 0){
         xil_printf("Writing to HMC %s Register 0x%08X with 0x%08X", regstr, addr, Hmc.hmc_cfgdata);
         for(i=0;i<10000;i++);     // delay
         Status = hmc_write4( Hmc.hmc_cfgaddr, Hmc.hmc_cfgdata);
         for(i=0;i<10000;i++);     // delay
         if (Status != XST_SUCCESS) {
            xil_printf(" !!Error writing!! ");
         }
         Status = hmc_read4( Hmc.hmc_cfgaddr, ReadBuffer);
         for(i=0;i<10000;i++);     // delay
         if (Status != XST_SUCCESS) {
            xil_printf(" !!Error Verifying!! ");
         }
         xil_printf(":v0x%08X\n\r",Hmc.hmc_cfgdata);
         return (Hmc.hmc_cfgdata);

      } else if (strcmp(rw, "rmw") == 0){
         Status = hmc_read4( Hmc.hmc_cfgaddr, ReadBuffer);
         for(i=0;i<10000;i++);     // delay
         if (Status != XST_SUCCESS) {
            xil_printf(" !!Error reading!! ");
         }
         initialValue = Hmc.hmc_cfgdata;
         Hmc.hmc_cfgdata |= data;
         xil_printf("Modifying HMC %s Register 0x%08X:0x%08X with 0x%08X=>0x%08X\r\n", regstr, addr, initialValue, data, Hmc.hmc_cfgdata);
         for(i=0;i<10000;i++);     // delay
         Status = hmc_write4( Hmc.hmc_cfgaddr, Hmc.hmc_cfgdata);
         for(i=0;i<10000;i++);     // delay
         if (Status != XST_SUCCESS) {
            xil_printf(" !!Error writing!! ");
         }
         return (Hmc.hmc_cfgdata);
      } else if (strcmp(rw, "rmwv") == 0){
         Status = hmc_read4( Hmc.hmc_cfgaddr, ReadBuffer);
         for(i=0;i<10000;i++);     // delay
         if (Status != XST_SUCCESS) {
            xil_printf(" !!Error reading!! ");
         }
         initialValue = Hmc.hmc_cfgdata;
         Hmc.hmc_cfgdata |= data;
         xil_printf("Modifying HMC %s Register 0x%08X:0x%08X with 0x%08X=>0x%08X", regstr, addr, initialValue, data, Hmc.hmc_cfgdata);
         for(i=0;i<10000;i++);     // delay
         Status = hmc_write4( Hmc.hmc_cfgaddr, Hmc.hmc_cfgdata);
         for(i=0;i<10000;i++);     // delay
         if (Status != XST_SUCCESS) {
            xil_printf(" !!Error writing!! ");
         }
         Status = hmc_read4( Hmc.hmc_cfgaddr, ReadBuffer);
         for(i=0;i<10000;i++);     // delay
         if (Status != XST_SUCCESS) {
            xil_printf(" !!Error Verifying!! ");
         }
         xil_printf(":v0x%08X\n\r",Hmc.hmc_cfgdata);
         return (Hmc.hmc_cfgdata);
      } else {
         xil_printf("!!Unknown rw command: \"%s\"!!\r\n", rw);
         return 0xDEADBEEF;
      }
}
int hmc_gpio_init (void)
{
   int i=0;
   int Status;
//   u32 InputData;

   //initalize the gpios

   Status = XGpio_Initialize(&hmc_fatal_error, HMC_FATAL_ERROR_GPI);
   for(i=0;i<10000;i++);     // delay
   if (Status != XST_SUCCESS) {
      return XST_FAILURE;
   }
    XGpio_SetDataDirection(&hmc_fatal_error, HMC_FATAL_ERROR_CHANNEL, 0x0);
    for(i=0;i<10000;i++);     // delay
    Hmc.hmc_gpi_fatal_error = XGpio_DiscreteRead(&hmc_fatal_error, HMC_FATAL_ERROR_CHANNEL);
    for(i=0;i<10000;i++);     // delay

   Status = XGpio_Initialize(&hmc_lxtxps, HMC_LXTXPS_GPI);
   for(i=0;i<10000;i++);     // delay
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    XGpio_SetDataDirection(&hmc_lxtxps, HMC_READ_POWER_CHANNEL, 0x0);
    for(i=0;i<10000;i++);     // delay
    Hmc.hmc_gpi_lxtxps = XGpio_DiscreteRead(&hmc_lxtxps, HMC_FATAL_ERROR_CHANNEL);
    for(i=0;i<10000;i++);     // delay

   Status = XGpio_Initialize(&hmc_refclk_sel, HMC_REFCLK_SEL_GPO);
   for(i=0;i<10000;i++);     // delay
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    XGpio_SetDataDirection(&hmc_refclk_sel, HMC_REFCLK_SEL_CHANNEL, 0xFFFFFFFF);
    for(i=0;i<10000;i++);     // delay
    Hmc.hmc_gpo_refclk_sel = XGpio_DiscreteRead(&hmc_refclk_sel, HMC_FATAL_ERROR_CHANNEL);
    for(i=0;i<10000;i++);     // delay

   Status = XGpio_Initialize(&hmc_lxrxps, HMC_LXRXPS_GP0);
   for(i=0;i<10000;i++);     // delay
    if (Status != XST_SUCCESS) {
         return XST_FAILURE;
    }
    XGpio_SetDataDirection(&hmc_lxrxps, HMC_SET_POWER_CHANNEL, 0xFFFFFFFF);
    for(i=0;i<10000;i++);     // delay
    Hmc.hmc_gpo_lxrxps = XGpio_DiscreteRead(&hmc_lxrxps, HMC_FATAL_ERROR_CHANNEL);
    for(i=0;i<10000;i++);     // delay

   Status = XGpio_Initialize(&hmc_reclk_boot, HMC_REFCLK_BOOT_GPO);
   for(i=0;i<10000;i++);     // delay
    if (Status != XST_SUCCESS) {
         return XST_FAILURE;
    }
    XGpio_SetDataDirection(&hmc_reclk_boot, HMC_REFCLK_BOOT_CHANNEL, 0xFFFFFFFF);
    for(i=0;i<10000;i++);     // delay
    Hmc.hmc_gpo_reclk_boot = XGpio_DiscreteRead(&hmc_reclk_boot, HMC_FATAL_ERROR_CHANNEL);
    for(i=0;i<10000;i++);     // delay

   return XST_SUCCESS;
}


int gpio_write(XGpio GpioDevice, u32 bitmask, u32 value)
{

    XGpio_DiscreteWrite(&GpioDevice, bitmask, value);

    return XST_SUCCESS;

}

int gpio_read(XGpio GpioDevice, int Channel)
{

    return (XGpio_DiscreteRead(&GpioDevice, Channel));

}
int si5328_set_freq_125_187or375MHz(u32 linkspeed)
{

   TransmitComplete = 1;
   int Status;
   u8  reg[60];
   u8  i;
   int j;
   int NC1_LS, NC2_LS;
   int N2_LS, N31, N32;

    memset(reg,0,60);


    DSPLL.oFreq[0] = 125.000;
    DSPLL.oFreq[1] = 125.000;
    DSPLL.oFreq[2] = 125.000;
    DSPLL.oFreq[3] = 125.000;
    DSPLL.iFreq[0] = 125.000;
    DSPLL.iFreq[1] = 114.285;
    DSPLL.iFreq[2] = 125.000;
    DSPLL.iFreq[3] = 125.000;
    DSPLL.N1 = 40;
    DSPLL.N1_HS = 10;
    DSPLL.NC1_LS = 4;
    DSPLL.NC2_LS = 4;
    DSPLL.NC3_LS = 4;
    DSPLL.NC4_LS = 4;
    DSPLL.NC5_LS = 4;
    DSPLL.N2 = 1000000;
    DSPLL.N2_HS = 5;
    DSPLL.N2_LS = 200000;
    DSPLL.N31 = 25000;
    DSPLL.N32 = 22857;
    DSPLL.N33 = 25000;
    DSPLL.N34 = 25000;
    DSPLL.BWSEL = 1;
    DSPLL.DSBL1 = 0;
    DSPLL.DSBL2 = 0;
    DSPLL.CLKIN1RATE = 3;
    DSPLL.CLKIN2RATE = 3;
    DSPLL.CLKIN3RATE = 3;
    DSPLL.CLKIN4RATE = 3;

    if (linkspeed == LINK_SPEED_15GBPS){
       DSPLL.BWSEL = 3;
      DSPLL.N1_HS = 7;
      DSPLL.NC1_LS = 6;
      if (FPGA_IBERT == 375) {
          DSPLL.oFreq[1] = 375.000000;
          DSPLL.NC2_LS = 2;
          xil_printf("Programming SI5328 for 125 MHz on CLKOUT1 and 375 MHz on CLKOUT2\r\n");
      } else {
          DSPLL.oFreq[1] = 187.500000;
          xil_printf("Programming SI5328 for 125 MHz on CLKOUT1 and 187.5 MHz on CLKOUT2\r\n");
      }
      DSPLL.N2_LS = 70000;
       DSPLL.N31 = 7619;
       DSPLL.N32 = 7619;

    } else {
        xil_printf("Programming SI5328 for 125 MHz on CLKOUT1 and 125 MHz on CLKOUT2\r\n");
    }
    
    si5328_init_iicmux();

   /* Write New Frequency Settings
    * Change from human readable settings to Si5368 programming values
   */
   reg[0]  = 0x54;                                                         // 0101_0100 - FREE_RUN
   reg[1]  = 0xE1;                                                         // 1110_0001 - CLOCK_PRIORITY
   //ORIG reg[2]  = (DSPLL->BWSEL & 0x0F)*32 + 0x02;                              // xxxx_0010 - BWSEL[3:0], 4'b0010;
   reg[2]  = (DSPLL.BWSEL & 0x0F)*16 + 0x02;                              // xxxx_0010 - BWSEL[3:0], 4'b0010;
   reg[3]  = 0x55;                                                         // 0101_0101 - CKSEL, DHOLD, SQ_ICAL, 4'b0101
   reg[4]  = 0x12;                                                         // 0001_0010 - AUTOSEL, HIST_DEL
   reg[5]  = 0x2D;                                                         // 0010_1101 - ICMOS, 6'b101101
   reg[6]  = 0x3F;                                                         // 0011_1111 - SLEEP,SFOUT2,SFOUT1
   reg[7]  = 0x28;                                                         // 0010_1000 - 5'b00101,FOSREFSEL
   reg[8]  = 0x00;                                                         // 0000_0000 - HLOG2,HLOG1,4'b0000
   reg[9]  = 0xC0;                                                         // 1100_0000 - HIST_AVG,3'b000
   reg[10] = DSPLL.DSBL2*8  + DSPLL.DSBL1*4;                             // 0000_xx00 - 4'b0000,DSBL[2:1],2'b00
    reg[11] = 0x40;                                                         // 0100_0000 - 6'b010000,PD_CK[2:1]

   reg[19] = 0x2C;                                                         // 0010_1100 - FOS_EN..LOCT
   reg[20] = 0x3E;                                                         // 0011_1110 - CK#_BAD,LOL_PIN,INT_PIN
   reg[21] = 0xFC;                                                         // 1111_1100 - 6'b111111,CK1_ACTV,CKSEL_PIN
   reg[22] = 0xDF;                                                         // 1101_1111 - 4'b1101, CK_ACTV_POL..INT_POL
   reg[23] = 0x1F;                                                         // 0001_1111 - LOS#_MSK
   reg[24] = 0x3F;                                                         // 0011_1111 - 5'b00111,LOL#_MSK
   reg[25] = (DSPLL.N1_HS-4)*32;                                          // xxx0_0000 - N1_HS[2:0],5'b00000

   NC1_LS  = DSPLL.NC1_LS-1;                                              // Subtract 1 for register write
   reg[31] = (NC1_LS & 0x0F0000)/two_to_16;                                // 0000_xxxx - NC1_LS[19:16]
   reg[32] = (NC1_LS & 0x00FF00)/two_to_8;                                 // xxxx_xxxx - NC1_LS[15:8]
   reg[33] = (NC1_LS & 0x0000FF);                                          // xxxx_xxxx - NC1_LS[7:0]

   NC2_LS  = DSPLL.NC2_LS-1;                                              // Subtract 1 for register write
   reg[34] = (NC2_LS & 0x0F0000)/two_to_16;                                // 0000_xxxx - NC2_LS[19:16]
   reg[35] = (NC2_LS & 0x00FF00)/two_to_8;                                 // xxxx_xxxx - NC2_LS[15:8]
   reg[36] = (NC2_LS & 0x0000FF);                                          // xxxx_xxxx - NC2_LS[7:0]

   N2_LS   = DSPLL.N2_LS-1;                                               // Subtract 1 for register write
   reg[40] = (DSPLL.N2_HS-4)*32 + (N2_LS & 0x0F0000)/two_to_16;           // xxx0_xxxx - N2_HS[2:0],1'b0,N2_LS[19:16]
   reg[41] = (N2_LS & 0x00FF00)/two_to_8;                                  // xxxx_xxxx - N2_LS[15:8]
   reg[42] = (N2_LS & 0x0000FF);                                           // xxxx_xxxx - N2_LS[7:0]

   N31     = DSPLL.N31-1;                                                 // Subtract 1 for register write
   reg[43] = (N31   & 0x070000)/two_to_16;                                 // 0000_0xxx - N31[18:16]
   reg[44] = (N31   & 0x00FF00)/two_to_8;                                  // xxxx_xxxx - N31[15:8]
   reg[45] = (N31   & 0x0000FF);                                           // xxxx_xxxx - N31[7:0]

   N32     = DSPLL.N32-1;                                                 // Subtract 1 for register write
   reg[46] = (N32   & 0x070000)/two_to_16;                                 // 0000_0xxx - N32[18:16]
   reg[47] = (N32   & 0x00FF00)/two_to_8;                                  // xxxx_xxxx - N32[15:8]
   reg[48] = (N32   & 0x0000FF);                                           // xxxx_xxxx - N32[7:0]

   reg[55] = (DSPLL.CLKIN2RATE & 0x07) * 8 + (DSPLL.CLKIN1RATE & 0x07);  // 00xx_xxxx - 2'b00,C2R[2:0],C1R[2:0]

   Status = XIic_SetAddress(&Iic, XII_ADDR_TO_SEND_TYPE, SI5328_HMC_IIC_ADDR);

    if (Status != XST_SUCCESS) {
         xil_printf(" !!Error XIic_SetAddress!! ");
         return XST_FAILURE;
    }

    Status = XIic_Start(&Iic);
    if (Status != XST_SUCCESS) {
      xil_printf(" !!Error XIic_Start!! ");
       return XST_FAILURE;
    }
    while (TransmitComplete || XIic_IsIicBusy(&Iic) == TRUE) {}

   for (i=0;i<=11;i++) {
      Status = XIic_MasterSend(&Iic, (u8[]){  i,reg[i] }, 2);
      xil_printf("SI5328 Register 0x%02X:0x%02X\r\n", i, reg[i]);
       if (Status != XST_SUCCESS) {
         xil_printf(" !!Error XIic_MasterSend!! ");
          return XST_FAILURE;
       }
       while (TransmitComplete || XIic_IsIicBusy(&Iic) == TRUE) {}
      TransmitComplete = 1;

   }

   for (i=19;i<=25;i++) {
      Status = XIic_MasterSend(&Iic, (u8[]){  i,reg[i] }, 2);
      xil_printf("SI5328 Register 0x%02X:0x%02X\r\n", i, reg[i]);
       if (Status != XST_SUCCESS) {
         xil_printf(" !!Error XIic_MasterSend!! ");
          return XST_FAILURE;
       }
       while (TransmitComplete || XIic_IsIicBusy(&Iic) == TRUE) {}
      TransmitComplete = 1;
    }

   for (i=31;i<=36;i++) {
      Status = XIic_MasterSend(&Iic, (u8[]){  i,reg[i] }, 2);
      xil_printf("SI5328 Register 0x%02X:0x%02X\r\n", i, reg[i]);
       if (Status != XST_SUCCESS) {
         xil_printf(" !!Error XIic_MasterSend!! ");
          return XST_FAILURE;
       }
       while (TransmitComplete || XIic_IsIicBusy(&Iic) == TRUE) {}
      TransmitComplete = 1;

   }

   for (i=40;i<=48;i++) {
      Status = XIic_MasterSend(&Iic, (u8[]){  i,reg[i] }, 2);
      xil_printf("SI5328 Register 0x%02X:0x%02X\r\n", i, reg[i]);
       if (Status != XST_SUCCESS) {
         xil_printf(" !!Error XIic_MasterSend!! ");
          return XST_FAILURE;
       }
       while (TransmitComplete || XIic_IsIicBusy(&Iic) == TRUE) {}
      TransmitComplete = 1;

   }
   Status = XIic_MasterSend(&Iic, (u8[]){ 55,reg[55]}, 2);           //  55:CLKIN#RATE
    xil_printf("SI5328 CLKIN#RATE 0x%02X:0x%02X\r\n", reg[55], reg[56]);
    while (TransmitComplete || XIic_IsIicBusy(&Iic) == TRUE) {}
    if (Status != XST_SUCCESS) {
      xil_printf(" !!Error XIic_MasterSend!! ");
       return XST_FAILURE;
    }
   TransmitComplete = 1;
   Status = XIic_MasterSend(&Iic, (u8[]){131,0x18   }, 2);           // 131:LOS#_FLAG
    xil_printf("SI5328 LOS#_FLAG 0x%02X:0x%02X\r\n",131, 0x18);
   if (Status != XST_SUCCESS) {
      xil_printf(" !!Error XIic_MasterSend!! ");
       return XST_FAILURE;
    }
    while (TransmitComplete || XIic_IsIicBusy(&Iic) == TRUE) {}
   TransmitComplete = 1;
   Status = XIic_MasterSend(&Iic, (u8[]){132,0x00   }, 2);           // 132:FOS#_FLAG
    xil_printf("SI5328 FOS#_FLAG 0x%02X:0x%02X\r\n",132, 0x00);
    if (Status != XST_SUCCESS) {
      xil_printf(" !!Error XIic_MasterSend!! ");
       return XST_FAILURE;
    }
    while (TransmitComplete || XIic_IsIicBusy(&Iic) == TRUE) {}
   TransmitComplete = 1;
   Status = XIic_MasterSend(&Iic, (u8[]){137,0x00   }, 2);           // 137:FASTLOCK
    xil_printf("SI5328 FASTLOCK 0x%02X:0x%02X\r\n",137, 0x00);
    if (Status != XST_SUCCESS) {
      xil_printf(" !!Error XIic_MasterSend!! ");
       return XST_FAILURE;
    }
    while (TransmitComplete || XIic_IsIicBusy(&Iic) == TRUE) {}
   TransmitComplete = 1;
   Status = XIic_MasterSend(&Iic, (u8[]){138,0x0F   }, 2);           // 138:LOS#_EN[1]
    xil_printf("SI5328 LOS#_EN[1] 0x%02X:0x%02X\r\n",138, 0x0F);
    if (Status != XST_SUCCESS) {
      xil_printf(" !!Error XIic_MasterSend!! ");
       return XST_FAILURE;
    }
    while (TransmitComplete || XIic_IsIicBusy(&Iic) == TRUE) {}
   TransmitComplete = 1;
   Status = XIic_MasterSend(&Iic, (u8[]){139,0xFF   }, 2);           // 139:LOS#_EN[0],FOS#_EN
    xil_printf("SI5328 LOS#_EN[0],FOS#_EN 0x%02X:0x%02X\r\n",139, 0xFF);
    if (Status != XST_SUCCESS) {
      xil_printf(" !!Error XIic_MasterSend!! ");
       return XST_FAILURE;
    }
    while (TransmitComplete || XIic_IsIicBusy(&Iic) == TRUE) {}
   TransmitComplete = 1;
   Status = XIic_MasterSend(&Iic, (u8[]){142,0x00   }, 2);           // 142:IND_SKEW1
    xil_printf("SI5328 IND_SKEW1 0x%02X:0x%02X\r\n",142, 0x00);
    if (Status != XST_SUCCESS) {
      xil_printf(" !!Error XIic_MasterSend!! ");
       return XST_FAILURE;
    }
    while (TransmitComplete || XIic_IsIicBusy(&Iic) == TRUE) {}
   TransmitComplete = 1;
   Status = XIic_MasterSend(&Iic, (u8[]){143,0x00   }, 2);           // 143:IND_SKEW2
    xil_printf("SI5328 IND_SKEW2 0x%02X:0x%02X\r\n",143, 0x00);
    if (Status != XST_SUCCESS) {
      xil_printf(" !!Error XIic_MasterSend!! ");
       return XST_FAILURE;
    }
    while (TransmitComplete || XIic_IsIicBusy(&Iic) == TRUE) {}
   TransmitComplete = 1;

   Status = XIic_MasterSend(&Iic, (u8[]){136,0x40   }, 2);           // 136:RESET,ICAL
    xil_printf("SI5328 RESET,ICAL 0x%02X:0x%02X\r\n",136, 0x40);
    if (Status != XST_SUCCESS) {
      xil_printf(" !!Error XIic_MasterSend!! ");
       return XST_FAILURE;
    }
    while (TransmitComplete || XIic_IsIicBusy(&Iic) == TRUE) {}
   TransmitComplete = 1;
    xil_printf("SI5328 Programmed\n\r");

    //added delay once clocks change, need setting time
    for(j=0;j<10000;j++);     // delay

/*
    Status = XIic_Stop(&Iic);
    if (Status != XST_SUCCESS) {
      xil_printf(" !!Error XIic_Stop!! ");
       return XST_FAILURE;
    }
    while (TransmitComplete || XIic_IsIicBusy(&Iic) == TRUE) {}
   TransmitComplete = 1;

*/
    return XST_SUCCESS;

}

int si5328_init_iicmux()
{
   write_mux(TCA9548_MUX_ADDR, TCA9548_MUX_PORT4);  // Set 8-port IIC Mux to HMC

   write_mux(PCA9544_MUX_ADDR, PCA9544_MUX_OFF);  // Set 4-port IIC Mux to No Connections

   return XST_SUCCESS;
}

void stdin_read(char *s, int len)
{
   int i,done;
   char c;
   done=0;
   i=0;
    *s='\0';
   while (!done){
      c = XUartNs550_RecvByte(STDOUT_BASEADDR);
      XUartNs550_SendByte(STDOUT_BASEADDR, c);
      switch (c) {
        case  10: done=1      ;break; // Line Feed
        case  20: done=1      ;break; // Space
        case  13: done=1      ;break; // Carriage Return
        case   8: if (i>0) i--;vt100_erase();break; // Backspace
        case 127:              break; // Delete
        default : *(s+i) = c; i++;
      }
      if (i==len) done=1;
   }
   *(s+i)='\0';
   XUartNs550_SendByte(STDOUT_BASEADDRESS, '\n');
   XUartNs550_SendByte(STDOUT_BASEADDRESS, '\r');
}

void vt100_erase()
{
   // Erase to EOL
   XUartNs550_SendByte(STDOUT_BASEADDRESS, 0x1B);
   XUartNs550_SendByte(STDOUT_BASEADDRESS, '[');
   XUartNs550_SendByte(STDOUT_BASEADDRESS, 'K');
}

u32 char2hex(const char * s) {
 u32 result = 0;
 int c ;
 if ('0' == *s && 'x' == *(s+1)) { s+=2;
  while (*s) {
   result = result << 4;
   if (c=(*s-'0'),(c>=0 && c <=9)) result|=c;
   else if (c=(*s-'A'),(c>=0 && c <=5)) result|=(c+10);
   else if (c=(*s-'a'),(c>=0 && c <=5)) result|=(c+10);
   else break;
   ++s;
  }
 }
 return result;
}

/*****************************************************************************/
/**
* This function setups the interrupt system so interrupts can occur for the
* IIC device. The function is application-specific since the actual system may
* or may not have an interrupt controller. The IIC device could be directly
* connected to a processor without an interrupt controller. The user should
* modify this function to fit the application.
*
* @param IicInstPtr contains a pointer to the instance of the IIC device
*     which is going to be connected to the interrupt controller.
*
* @return   XST_SUCCESS if successful else XST_FAILURE.
*
* @note     None.
*
******************************************************************************/
static int SetupInterruptSystem(XIic *IicInstPtr)
{
   int Status;

   if (InterruptController.IsStarted == XIL_COMPONENT_IS_STARTED) {
      return XST_SUCCESS;
   }

   /*
    * Initialize the interrupt controller driver so that it's ready to use.
    */
   Status = XIntc_Initialize(&InterruptController, INTC_DEVICE_ID);

   if (Status != XST_SUCCESS) {
      return XST_FAILURE;
   }

   /*
    * Connect the device driver handler that will be called when an
    * interrupt for the device occurs, the handler defined above performs
    * the specific interrupt processing for the device.
    */
   Status = XIntc_Connect(&InterruptController, IIC_INTR_ID,
               (XInterruptHandler) XIic_InterruptHandler,
               IicInstPtr);
   if (Status != XST_SUCCESS) {
      return XST_FAILURE;
   }

   /*
    * Start the interrupt controller so interrupts are enabled for all
    * devices that cause interrupts.
    */
   Status = XIntc_Start(&InterruptController, XIN_REAL_MODE);
   if (Status != XST_SUCCESS) {
      return XST_FAILURE;
   }

   /*
    * Enable the interrupts for the IIC device.
    */
   XIntc_Enable(&InterruptController, IIC_INTR_ID);

   /*
    * Initialize the exception table.
    */
   Xil_ExceptionInit();

   /*
    * Register the interrupt controller handler with the exception table.
    */
   Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
             (Xil_ExceptionHandler) XIntc_InterruptHandler,
             &InterruptController);

   /*
    * Enable non-critical exceptions.
    */
   Xil_ExceptionEnable();



   return XST_SUCCESS;
}

/*****************************************************************************/
/**
* This function setups the interrupt system so interrupts can occur for the
* IIC device. The function is application-specific since the actual system may
* or may not have an interrupt controller. The IIC device could be directly
* connected to a processor without an interrupt controller. The user should
* modify this function to fit the application.
*
* @param IicInstPtr contains a pointer to the instance of the IIC device
*     which is going to be connected to the interrupt controller.
*
* @return   XST_SUCCESS if successful else XST_FAILURE.
*
* @note     None.
*
******************************************************************************/
static int DisableInterruptSystem(XIic *IicInstPtr)
{

   /*
    * Disable the interrupt
    */
   XIntc_Disable(&InterruptController, IIC_INTR_ID);
   /*
    * Disconnect the driver handler.
    */
   XIntc_Disconnect(&InterruptController, IIC_INTR_ID);

   /*
    * Disable non-critical exceptions.
    */
   Xil_ExceptionDisable();

   /*
    * Remove the interrupt controller handler from the exception table.
    */
   Xil_ExceptionRemoveHandler(XIL_EXCEPTION_ID_INT);

   /*
    * Stop the interrupt controller such that interrupts are disabled for
    * all devices that cause interrupts
    */
   XIntc_Stop(&InterruptController);

   return XST_SUCCESS;
}

/*****************************************************************************/
/**
* This Send handler is called asynchronously from an interrupt
* context and indicates that data in the specified buffer has been sent.
*
* @param InstancePtr is not used, but contains a pointer to the IIC
*     device driver instance which the handler is being called for.
*
* @return   None.
*
* @note     None.
*
******************************************************************************/
static void SendHandler(XIic *InstancePtr)
{
   TransmitComplete = 0;
}

/*****************************************************************************/
/**
* This Receive handler is called asynchronously from an interrupt
* context and indicates that data in the specified buffer has been Received.
*
* @param InstancePtr is not used, but contains a pointer to the IIC
*     device driver instance which the handler is being called for.
*
* @return   None.
*
* @note     None.
*
******************************************************************************/
static void ReceiveHandler(XIic *InstancePtr)
{
   ReceiveComplete = 0;
}

static void StatusHandler(XIic *InstancePtr, int Event)
{

}
