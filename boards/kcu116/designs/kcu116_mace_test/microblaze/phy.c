
#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"

u32 GPIO_base=0x40000000;


#define CONFIG_LINKSPEED_AUTODETECT 1


/***************** Macros (Inline Functions) Definitions *********************/
#define ITERS_PER_SEC	(XPAR_CPU_CORE_CLOCK_FREQ_HZ / 4)
#define ITERS_PER_MSEC	(ITERS_PER_SEC / 1000)
#define ITERS_PER_USEC	(ITERS_PER_MSEC / 1000)


static void sleep_common(u32 n, u32 iters)
{
	asm volatile (
			"1:               \n\t"
			"addik %1, %1, -1 \n\t"
			"add   r7, r0, %0 \n\t"
			"2:               \n\t"
			"addik r7, r7, -1 \n\t"
			"bneid  r7, 2b    \n\t"
			"or  r0, r0, r0   \n\t"
			"bneid %1, 1b     \n\t"
			"or  r0, r0, r0   \n\t"
			:
			: "r"(iters), "r"(n)
			: "r0", "r7"
	);
}


#define XAE_PHY_TYPE_MII		0
#define XAE_PHY_TYPE_GMII		1
#define XAE_PHY_TYPE_RGMII_1_3		2
#define XAE_PHY_TYPE_RGMII_2_0		3
#define XAE_PHY_TYPE_SGMII		4
#define XAE_PHY_TYPE_1000BASE_X		5

#define XAxiEthernet_GetPhysicalInterface(InstancePtr)	   \
	((InstancePtr)->Config.PhyType)


/*****************************************************************************/
/**
* @brief    Provides delay for requested duration.
* @param	useconds- time in useconds.
* @return	0
*
* @note		Instruction cache should be enabled for this to work.
*
******************************************************************************/
int usleep(unsigned long useconds)
{
	sleep_common((u32)useconds, ITERS_PER_USEC);

	return 0;
}

/*****************************************************************************/
/**
* @brief    Provides delay for requested duration.
* @param	seconds- time in useconds.
* @return	0
*
* @note		Instruction cache should be enabled for this to work.
*
******************************************************************************/
unsigned sleep(unsigned int seconds)
{
	sleep_common(seconds, ITERS_PER_SEC);

	return 0;
}

/*****************************************************************************/
/**
*
* @brief    Provides delay for requested duration..
*
* @param	MilliSeconds- Delay time in milliseconds.
*
* @return	None.
*
* @note		Instruction cache should be enabled for this to work.
*
******************************************************************************/
void MB_Sleep(u32 MilliSeconds)
{
	sleep_common(MilliSeconds, ITERS_PER_MSEC);
}

#define ADVERTISE_10HALF	0x0020  /* Try for 10mbps half-duplex  */
#define ADVERTISE_1000XFULL	0x0020  /* Try for 1000BASE-X full-duplex */
#define ADVERTISE_10FULL	0x0040  /* Try for 10mbps full-duplex  */
#define ADVERTISE_1000XHALF	0x0040  /* Try for 1000BASE-X half-duplex */
#define ADVERTISE_100HALF	0x0080  /* Try for 100mbps half-duplex */
#define ADVERTISE_1000XPAUSE	0x0080  /* Try for 1000BASE-X pause    */
#define ADVERTISE_100FULL	0x0100  /* Try for 100mbps full-duplex */
#define ADVERTISE_1000XPSE_ASYM	0x0100  /* Try for 1000BASE-X asym pause */
#define ADVERTISE_100BASE4	0x0200  /* Try for 100mbps 4k packets  */


#define ADVERTISE_100_AND_10	(ADVERTISE_10FULL | ADVERTISE_100FULL | \
				ADVERTISE_10HALF | ADVERTISE_100HALF)
#define ADVERTISE_100		(ADVERTISE_100FULL | ADVERTISE_100HALF)
#define ADVERTISE_10		(ADVERTISE_10FULL | ADVERTISE_10HALF)

#define ADVERTISE_1000		0x0300


#define IEEE_CONTROL_REG_OFFSET					0
#define IEEE_STATUS_REG_OFFSET					1
#define IEEE_AUTONEGO_ADVERTISE_REG				4
#define IEEE_PARTNER_ABILITIES_1_REG_OFFSET		5
#define IEEE_PARTNER_ABILITIES_2_REG_OFFSET		8
#define IEEE_PARTNER_ABILITIES_3_REG_OFFSET		10
#define IEEE_1000_ADVERTISE_REG_OFFSET			9
#define IEEE_MMD_ACCESS_CONTROL_REG		        13
#define IEEE_MMD_ACCESS_ADDRESS_DATA_REG		14
#define IEEE_COPPER_SPECIFIC_CONTROL_REG		16
#define IEEE_SPECIFIC_STATUS_REG				17
#define IEEE_COPPER_SPECIFIC_STATUS_REG_2		19
#define IEEE_EXT_PHY_SPECIFIC_CONTROL_REG   	20
#define IEEE_CONTROL_REG_MAC					21
#define IEEE_PAGE_ADDRESS_REGISTER				22

#define IEEE_CTRL_1GBPS_LINKSPEED_MASK			0x2040
#define IEEE_CTRL_LINKSPEED_MASK				0x0040
#define IEEE_CTRL_LINKSPEED_1000M				0x0040
#define IEEE_CTRL_LINKSPEED_100M				0x2000
#define IEEE_CTRL_LINKSPEED_10M					0x0000
#define IEEE_CTRL_FULL_DUPLEX				0x100
#define IEEE_CTRL_RESET_MASK					0x8000
#define IEEE_CTRL_AUTONEGOTIATE_ENABLE			0x1000
#define IEEE_STAT_AUTONEGOTIATE_CAPABLE			0x0008
#define IEEE_STAT_AUTONEGOTIATE_COMPLETE		0x0020
#define IEEE_STAT_AUTONEGOTIATE_RESTART			0x0200
#define IEEE_STAT_1GBPS_EXTENSIONS				0x0100
#define IEEE_AN1_ABILITY_MASK					0x1FE0
#define IEEE_AN3_ABILITY_MASK_1GBPS				0x0C00
#define IEEE_AN1_ABILITY_MASK_100MBPS			0x0380
#define IEEE_AN1_ABILITY_MASK_10MBPS			0x0060
#define IEEE_RGMII_TXRX_CLOCK_DELAYED_MASK		0x0030

#define IEEE_ASYMMETRIC_PAUSE_MASK				0x0800
#define IEEE_PAUSE_MASK							0x0400
#define IEEE_AUTONEG_ERROR_MASK					0x8000

#define IEEE_MMD_ACCESS_CTRL_DEVAD_MASK         0x1F
#define IEEE_MMD_ACCESS_CTRL_PIDEVAD_MASK       0x801F
#define IEEE_MMD_ACCESS_CTRL_NOPIDEVAD_MASK     0x401F

#define PHY_R0_ISOLATE  						0x0400
#define PHY_DETECT_REG  						1
#define PHY_IDENTIFIER_1_REG					2
#define PHY_IDENTIFIER_2_REG					3
#define PHY_DETECT_MASK 						0x1808
#define PHY_MARVELL_IDENTIFIER					0x0141
#define PHY_TI_IDENTIFIER					    0x2000

/* Marvel PHY flags */
#define MARVEL_PHY_IDENTIFIER 					0x141
#define MARVEL_PHY_MODEL_NUM_MASK				0x3F0
#define MARVEL_PHY_88E1111_MODEL				0xC0
#define MARVEL_PHY_88E1116R_MODEL				0x240
#define PHY_88E1111_RGMII_RX_CLOCK_DELAYED_MASK	0x0080

/* TI PHY Flags */
#define TI_PHY_DETECT_MASK 						0x796D
#define TI_PHY_IDENTIFIER 						0x2000
#define TI_PHY_DP83867_MODEL					0xA231
#define DP83867_RGMII_CLOCK_DELAY_CTRL_MASK		0x0003
#define DP83867_RGMII_TX_CLOCK_DELAY_MASK		0x0030
#define DP83867_RGMII_RX_CLOCK_DELAY_MASK		0x0003

/* TI DP83867 PHY Registers */
#define DP83867_R32_RGMIICTL1					0x32
#define DP83867_R86_RGMIIDCTL					0x86

#define TI_PHY_REGCR			0xD
#define TI_PHY_ADDDR			0xE
#define TI_PHY_PHYCTRL			0x10
#define TI_PHY_CFGR2			0x14
#define TI_PHY_SGMIITYPE		0xD3
#define TI_PHY_CFGR2_SGMII_AUTONEG_EN	0x0080
#define TI_PHY_SGMIICLK_EN		0x4000
#define TI_PHY_REGCR_DEVAD_EN		0x001F
#define TI_PHY_REGCR_DEVAD_DATAEN	0x4000
#define TI_PHY_CFGR2_MASK		0x003F
#define TI_PHY_REGCFG4			0x31
#define TI_PHY_REGCR_DATA		0x401F
#define TI_PHY_CFG4RESVDBIT7		0x80
#define TI_PHY_CFG4RESVDBIT8		0x100
#define TI_PHY_CFG4_AUTONEG_TIMER	0x60

#define TI_PHY_CFG2_SPEEDOPT_10EN          0x0040
#define TI_PHY_CFG2_SGMII_AUTONEGEN        0x0080
#define TI_PHY_CFG2_SPEEDOPT_ENH           0x0100
#define TI_PHY_CFG2_SPEEDOPT_CNT           0x0800
#define TI_PHY_CFG2_SPEEDOPT_INTLOW        0x2000

#define TI_PHY_CR_SGMII_EN		0x0800

/* Loop counters to check for reset done
 */
#define RESET_TIMEOUT							0xFFFF
#define AUTO_NEG_TIMEOUT 						0x00FFFFFF

#if XPAR_GIGE_PCS_PMA_1000BASEX_CORE_PRESENT == 1 || \
	XPAR_GIGE_PCS_PMA_SGMII_CORE_PRESENT == 1
#define PCM_PMA_CORE_PRESENT
#else
#undef PCM_PMA_CORE_PRESENT
#endif

#ifdef PCM_PMA_CORE_PRESENT
#define IEEE_CTRL_RESET                         0x9140
#define IEEE_CTRL_ISOLATE_DISABLE               0xFBFF
#endif




/** @name Axi Ethernet registers offset
 *  @{
 */
#define XAE_RAF_OFFSET		0x00000000 /**< Reset and Address filter */
#define XAE_TPF_OFFSET		0x00000004 /**< Tx Pause Frame */
#define XAE_IFGP_OFFSET		0x00000008 /**< Tx Inter-frame gap adjustment*/
#define XAE_IS_OFFSET		0x0000000C /**< Interrupt status */
#define XAE_IP_OFFSET		0x00000010 /**< Interrupt pending */
#define XAE_IE_OFFSET		0x00000014 /**< Interrupt enable */
#define XAE_TTAG_OFFSET		0x00000018 /**< Tx VLAN TAG */
#define XAE_RTAG_OFFSET		0x0000001C /**< Rx VLAN TAG */
#define XAE_UAWL_OFFSET		0x00000020 /**< Unicast address word lower */
#define XAE_UAWU_OFFSET		0x00000024 /**< Unicast address word upper */
#define XAE_TPID0_OFFSET	0x00000028 /**< VLAN TPID0 register */
#define XAE_TPID1_OFFSET	0x0000002C /**< VLAN TPID1 register */

/*
 * Statistics Counter Registers are from offset 0x200 to 0x3FF
 * They are defined from offset 0x200 to 0x34C in this device.
 * The offsets from 0x350 to 0x3FF are reserved.
 * The counters are 64 bit.
 * The Least Significant Word (LSW) are stored in one 32 bit register and
 * the Most Significant Word (MSW) are stored in one 32 bit register
 */
/* Start of Statistics Counter Registers Definitions */
#define XAE_RXBL_OFFSET		0x00000200 /**< Received Bytes, LSW */
#define XAE_RXBU_OFFSET		0x00000204 /**< Received Bytes, MSW */
#define XAE_TXBL_OFFSET		0x00000208 /**< Transmitted Bytes, LSW */
#define XAE_TXBU_OFFSET		0x0000020C /**< Transmitted Bytes, MSW */
#define XAE_RXUNDRL_OFFSET	0x00000210 /**< Count of undersize(less than
					     *  64 bytes) frames received,
					     *  LSW
					     */
#define XAE_RXUNDRU_OFFSET	0x00000214 /**< Count of undersize(less than
					     *  64 bytes) frames received,
					     *  MSW
					     */
#define XAE_RXFRAGL_OFFSET	0x00000218 /**< Count of undersized(less
					     *  than 64 bytes) and bad FCS
					     *  frames received, LSW
					     */
#define XAE_RXFRAGU_OFFSET	0x0000021C /**< Count of undersized(less
					     *  than 64 bytes) and bad FCS
					     *  frames received, MSW
					     */
#define XAE_RX64BL_OFFSET	0x00000220 /**< Count of 64 bytes frames
					     *  received, LSW
					     */
#define XAE_RX64BU_OFFSET	0x00000224 /**< Count of 64 bytes frames
					     *  received, MSW
					     */
#define XAE_RX65B127L_OFFSET	0x00000228 /**< Count of 65-127 bytes
					     *  Frames received, LSW
					     */
#define XAE_RX65B127U_OFFSET	0x0000022C /**< Count of 65-127 bytes
					     *  Frames received, MSW
					     */
#define XAE_RX128B255L_OFFSET	0x00000230 /**< Count of 128-255 bytes
					     *  Frames received, LSW
					     */
#define XAE_RX128B255U_OFFSET	0x00000234 /**< Count of 128-255 bytes
					     *  frames received, MSW
					     */
#define XAE_RX256B511L_OFFSET	0x00000238 /**< Count of 256-511 bytes
					     *  Frames received, LSW
					     */
#define XAE_RX256B511U_OFFSET	0x0000023C /**< Count of 256-511 bytes
					     *  frames received, MSW
					     */
#define XAE_RX512B1023L_OFFSET	0x00000240 /**< Count of 512-1023 bytes
					     *  frames received, LSW
					     */
#define XAE_RX512B1023U_OFFSET	0x00000244 /**< Count of 512-1023 bytes
					     *  frames received, MSW
					     */
#define XAE_RX1024BL_OFFSET	0x00000248 /**< Count of 1024-MAX bytes
					     *  frames received, LSW
					     */
#define XAE_RX1024BU_OFFSET	0x0000024C /**< Count of 1024-MAX bytes
					     *  frames received, MSW
					     */
#define XAE_RXOVRL_OFFSET	0x00000250 /**< Count of oversize frames
					     *  received, LSW
					     */
#define XAE_RXOVRU_OFFSET	0x00000254 /**< Count of oversize frames
					     *  received, MSW
					     */
#define XAE_TX64BL_OFFSET	0x00000258 /**< Count of 64 bytes frames
					     *  transmitted, LSW
					     */
#define XAE_TX64BU_OFFSET	0x0000025C /**< Count of 64 bytes frames
					     *  transmitted, MSW
					     */
#define XAE_TX65B127L_OFFSET	0x00000260 /**< Count of 65-127 bytes
					     *  frames transmitted, LSW
					     */
#define XAE_TX65B127U_OFFSET	0x00000264 /**< Count of 65-127 bytes
					     *  frames transmitted, MSW
					     */
#define XAE_TX128B255L_OFFSET	0x00000268 /**< Count of 128-255 bytes
					     *  frames transmitted, LSW
					     */
#define XAE_TX128B255U_OFFSET	0x0000026C /**< Count of 128-255 bytes
					     *  frames transmitted, MSW
					     */
#define XAE_TX256B511L_OFFSET	0x00000270 /**< Count of 256-511 bytes
					     *  frames transmitted, LSW
					     */
#define XAE_TX256B511U_OFFSET	0x00000274 /**< Count of 256-511 bytes
					     *  frames transmitted, MSW
					     */
#define XAE_TX512B1023L_OFFSET	0x00000278 /**< Count of 512-1023 bytes
					     *  frames transmitted, LSW
					     */
#define XAE_TX512B1023U_OFFSET	0x0000027C /**< Count of 512-1023 bytes
					     *  frames transmitted, MSW
					     */
#define XAE_TX1024L_OFFSET	0x00000280 /**< Count of 1024-MAX bytes
					     *  frames transmitted, LSW
					     */
#define XAE_TX1024U_OFFSET	0x00000284 /**< Count of 1024-MAX bytes
					     *  frames transmitted, MSW
					     */
#define XAE_TXOVRL_OFFSET	0x00000288 /**< Count of oversize frames
					     *  transmitted, LSW
					     */
#define XAE_TXOVRU_OFFSET	0x0000028C /**< Count of oversize frames
					     *  transmitted, MSW
					     */
#define XAE_RXFL_OFFSET		0x00000290 /**< Count of frames received OK,
					     *  LSW
					     */
#define XAE_RXFU_OFFSET		0x00000294 /**< Count of frames received OK,
					     *  MSW
					     */
#define XAE_RXFCSERL_OFFSET	0x00000298 /**< Count of frames received with
					     *  FCS error and at least 64
					     *  bytes, LSW
					     */
#define XAE_RXFCSERU_OFFSET	0x0000029C /**< Count of frames received with
					     *  FCS error and at least 64
					     *  bytes,MSW
					     */
#define XAE_RXBCSTFL_OFFSET	0x000002A0 /**< Count of broadcast frames
					     *  received, LSW
					     */
#define XAE_RXBCSTFU_OFFSET	0x000002A4 /**< Count of broadcast frames
					     *  received, MSW
					     */
#define XAE_RXMCSTFL_OFFSET	0x000002A8 /**< Count of multicast frames
					     *  received, LSW
					     */
#define XAE_RXMCSTFU_OFFSET	0x000002AC /**< Count of multicast frames
					     *  received, MSW
					     */
#define XAE_RXCTRFL_OFFSET	0x000002B0 /**< Count of control frames
					     *  received, LSW
					     */
#define XAE_RXCTRFU_OFFSET	0x000002B4 /**< Count of control frames
					     *  received, MSW
					     */
#define XAE_RXLTERL_OFFSET	0x000002B8 /**< Count of frames received
					     *  with length error, LSW
					     */
#define XAE_RXLTERU_OFFSET	0x000002BC /**< Count of frames received
					     *  with length error, MSW
					     */
#define XAE_RXVLANFL_OFFSET	0x000002C0 /**< Count of VLAN tagged
					     *  frames received, LSW
					     */
#define XAE_RXVLANFU_OFFSET	0x000002C4 /**< Count of VLAN tagged frames
					     *  received, MSW
					     */
#define XAE_RXPFL_OFFSET	0x000002C8 /**< Count of pause frames received,
					     *  LSW
					     */
#define XAE_RXPFU_OFFSET	0x000002CC /**< Count of pause frames received,
					     *  MSW
					     */
#define XAE_RXUOPFL_OFFSET	0x000002D0 /**< Count of control frames
					     *  received with unsupported
					     *  opcode, LSW
					     */
#define XAE_RXUOPFU_OFFSET	0x000002D4 /**< Count of control frames
					     *  received with unsupported
					     *  opcode, MSW
					     */
#define XAE_TXFL_OFFSET		0x000002D8 /**< Count of frames transmitted OK,
					     *  LSW
					     */
#define XAE_TXFU_OFFSET		0x000002DC /**< Count of frames transmitted OK,
					     *  MSW
					     */
#define XAE_TXBCSTFL_OFFSET	0x000002E0 /**< Count of broadcast frames
					     *  transmitted OK, LSW
					     */
#define XAE_TXBCSTFU_OFFSET	0x000002E4 /**< Count of broadcast frames
					     *  transmitted, MSW
					     */
#define XAE_TXMCSTFL_OFFSET	0x000002E8 /**< Count of multicast frames
					     *  transmitted, LSW
					     */
#define XAE_TXMCSTFU_OFFSET	0x000002EC /**< Count of multicast frames
					     *  transmitted, MSW
					     */
#define XAE_TXUNDRERL_OFFSET	0x000002F0 /**< Count of frames transmitted
					     *  underrun error, LSW
					     */
#define XAE_TXUNDRERU_OFFSET	0x000002F4 /**< Count of frames transmitted
					     *  underrun error, MSW
					     */
#define XAE_TXCTRFL_OFFSET	0x000002F8 /**< Count of control frames
					     *  transmitted, LSW
					     */
#define XAE_TXCTRFU_OFFSET	0x000002FC /**< Count of control frames,
					     *  transmitted, MSW
					     */
#define XAE_TXVLANFL_OFFSET	0x00000300 /**< Count of VLAN tagged frames
					     *  transmitted, LSW
					     */
#define XAE_TXVLANFU_OFFSET	0x00000304 /**< Count of VLAN tagged
					     *  frames transmitted, MSW
					     */
#define XAE_TXPFL_OFFSET	0x00000308 /**< Count of pause frames
					     *  transmitted, LSW
					     */
#define XAE_TXPFU_OFFSET	0x0000030C /**< Count of pause frames
					     *  transmitted, MSW
					     */
#define XAE_TXSCL_OFFSET	0x00000310 /**< Single Collision Frames
					     *  Transmitted OK, LSW
					     */
#define XAE_TXSCU_OFFSET	0x00000314 /**< Single Collision Frames
					     *  Transmitted OK, MSW
					     */
#define XAE_TXMCL_OFFSET	0x00000318 /**< Multiple Collision Frames
					     *  Transmitted OK, LSW
					     */
#define XAE_TXMCU_OFFSET	0x0000031C /**< Multiple Collision Frames
					     *  Transmitted OK, MSW
					     */
#define XAE_TXDEFL_OFFSET	0x00000320 /**< Deferred Tx Frames, LSW */
#define XAE_TXDEFU_OFFSET	0x00000324 /**< Deferred Tx Frames, MSW */
#define XAE_TXLTCL_OFFSET	0x00000328 /**< Frames transmitted with late
					     *  Collisions, LSW
					     */
#define XAE_TXLTCU_OFFSET	0x0000032C /**< Frames transmitted with late
					     *  Collisions, MSW
					     */
#define XAE_TXAECL_OFFSET	0x00000330 /**< Frames aborted with excessive
					     *  Collisions, LSW
					     */
#define XAE_TXAECU_OFFSET	0x00000334 /**< Frames aborted with excessive
					     *  Collisions, MSW
					     */
#define XAE_TXEDEFL_OFFSET	0x00000338 /**< Transmit Frames with excessive
					     *  Defferal, LSW
					     */
#define XAE_TXEDEFU_OFFSET	0x0000033C /**< Transmit Frames with excessive
					     *  Defferal, MSW
					     */
#define XAE_RXAERL_OFFSET	0x00000340 /**< Frames received with alignment
					     *  errors, LSW
					     */
#define XAE_RXAERU_OFFSET	0x0000034C /**< Frames received with alignment
					     *  errors, MSW
					     */
/* End of Statistics Counter Registers Offset definitions */

#define XAE_RCW0_OFFSET			0x00000400 /**< Rx Configuration Word 0 */
#define XAE_RCW1_OFFSET			0x00000404 /**< Rx Configuration Word 1 */
#define XAE_TC_OFFSET			0x00000408 /**< Tx Configuration */
#define XAE_FCC_OFFSET			0x0000040C /**< Flow Control Configuration */
#define XAE_EMMC_OFFSET			0x00000410 /**< EMAC mode configuration */
#define XAE_RXFC_OFFSET			0x00000414 /**< Rx Max Frm Config Register */
#define XAE_TXFC_OFFSET			0x00000418 /**< Tx Max Frm Config Register */
#define XAE_TX_TIMESTAMP_ADJ_OFFSET		0x0000041C /**< Transmitter time stamp
										* adjust control Register
										*/
#define XAE_PHYC_OFFSET		0x00000420 /**< RGMII/SGMII configuration */

/* 0x00000424 to 0x000004F4 are reserved */

#define XAE_IDREG_OFFSET	0x000004F8 /**< Identification Register */
#define XAE_ARREG_OFFSET	0x000004FC /**< Ability Register */
#define XAE_MDIO_MC_OFFSET	0x00000500 /**< MII Management Config */
#define XAE_MDIO_MCR_OFFSET	0x00000504 /**< MII Management Control */
#define XAE_MDIO_MWD_OFFSET	0x00000508 /**< MII Management Write Data */
#define XAE_MDIO_MRD_OFFSET	0x0000050C /**< MII Management Read Data */

/* 0x00000510 to 0x000005FC are reserved */

#define XAE_MDIO_MIS_OFFSET	0x00000600 /**< MII Management Interrupt
					    *   Status
					    */
/* 0x00000604-0x0000061C are reserved */

#define XAE_MDIO_MIP_OFFSET	0x00000620 /**< MII Management Interrupt
					    *   Pending register offse
					    */
/* 0x00000624-0x0000063C are reserved */

#define XAE_MDIO_MIE_OFFSET	0x00000640 /**< MII Management Interrupt
					    *   Enable register offset
					    */
/* 0x00000644-0x0000065C are reserved */

#define XAE_MDIO_MIC_OFFSET	0x00000660 /**< MII Management Interrupt
					    *   Clear register offset.
					    */

/* 0x00000664-0x000006FC are reserved */

#define XAE_UAW0_OFFSET		0x00000700  /**< Unicast address word 0 */
#define XAE_UAW1_OFFSET		0x00000704  /**< Unicast address word 1 */
#define XAE_FMI_OFFSET		0x00000708  /**< Filter Mask Index */
/* 0x0000070C is reserved */
#define XAE_AF0_OFFSET		0x00000710  /**< Address Filter 0 */
#define XAE_AF1_OFFSET		0x00000714  /**< Address Filter 1 */

/* 0x00000718-0x00003FFC are reserved */

/*
 * Transmit VLAN Table is from 0x00004000 to 0x00007FFC
 * This offset defines an offset to table that has provisioned transmit
 * VLAN data. The VLAN table will be used by hardware to provide
 * transmit VLAN tagging, stripping, and translation.
 */
#define XAE_TX_VLAN_DATA_OFFSET 0x00004000 /**< TX VLAN data table address */


/*
 * Receive VLAN Data Table is from 0x00008000 to 0x0000BFFC
 * This offset defines an offset to table that has provisioned receive
 * VLAN data. The VLAN table will be used by hardware to provide
 * receive VLAN tagging, stripping, and translation.
 */
#define XAE_RX_VLAN_DATA_OFFSET 0x00008000 /**< RX VLAN data table address */

/* 0x0000C000-0x0000FFFC are reserved */

/* 0x00010000-0x00013FFC are Ethenet AVB address offset */

/* 0x00014000-0x0001FFFC are reserved */

/*
 * Extended Multicast Address Table is from 0x0020000 to 0x0003FFFC.
 * This offset defines an offset to table that has provisioned multicast
 * addresses. It is stored in BRAM and will be used by hardware to provide
 * first line of address matching when a multicast frame is reveived. It
 * can minimize the use of CPU/software hence minimize performance impact.
 */
#define XAE_MCAST_TABLE_OFFSET   0x00020000 /**< Multicast table address */
/*@}*/


/* Register masks. The following constants define bit locations of various
 * bits in the registers. Constants are not defined for those registers
 * that have a single bit field representing all 32 bits. For further
 * information on the meaning of the various bit masks, refer to the HW spec.
 */

/** @name Reset and Address Filter (RAF) Register bit definitions.
 *  These bits are associated with the XAE_RAF_OFFSET register.
 * @{
 */
#define XAE_RAF_MCSTREJ_MASK	     	0x00000002 /**< Reject receive
						    *   multicast destination
						    *   address
						    */
#define XAE_RAF_BCSTREJ_MASK	     	0x00000004 /**< Reject receive
						    *   broadcast destination
						    *   address
						    */
#define XAE_RAF_TXVTAGMODE_MASK  	0x00000018 /**< Tx VLAN TAG mode */
#define XAE_RAF_RXVTAGMODE_MASK  	0x00000060 /**< Rx VLAN TAG mode */
#define XAE_RAF_TXVSTRPMODE_MASK 	0x00000180 /**< Tx VLAN STRIP mode */
#define XAE_RAF_RXVSTRPMODE_MASK 	0x00000600 /**< Rx VLAN STRIP mode */
#define XAE_RAF_NEWFNCENBL_MASK  	0x00000800 /**< New function mode */
#define XAE_RAF_EMULTIFLTRENBL_MASK 	0x00001000 /**< Exteneded Multicast
						     *  Filtering mode
						     */
#define XAE_RAF_STATSRST_MASK  	0x00002000 	   /**< Statistics Counter
						    *   Reset
						    */
#define XAE_RAF_RXBADFRMEN_MASK     	0x00004000 /**< Receive Bad Frame
						    *   Enable
						    */
#define XAE_RAF_TXVTAGMODE_SHIFT 	3	/**< Tx Tag mode shift bits */
#define XAE_RAF_RXVTAGMODE_SHIFT 	5	/**< Rx Tag mode shift bits */
#define XAE_RAF_TXVSTRPMODE_SHIFT	7	/**< Tx strip mode shift bits*/
#define XAE_RAF_RXVSTRPMODE_SHIFT	9	/**< Rx Strip mode shift bits*/
/*@}*/

/** @name Transmit Pause Frame Register (TPF) bit definitions
 *  @{
 */
#define XAE_TPF_TPFV_MASK		0x0000FFFF /**< Tx pause frame value */
/*@}*/

/** @name Transmit Inter-Frame Gap Adjustement Register (TFGP) bit definitions
 *  @{
 */
#define XAE_TFGP_IFGP_MASK		0x0000007F /**< Transmit inter-frame
					            *   gap adjustment value
					            */
/*@}*/

/** @name Interrupt Status/Enable/Mask Registers bit definitions
 *  The bit definition of these three interrupt registers are the same.
 *  These bits are associated with the XAE_IS_OFFSET, XAE_IP_OFFSET, and
 *  XAE_IE_OFFSET registers.
 * @{
 */
#define XAE_INT_HARDACSCMPLT_MASK	0x00000001 /**< Hard register
						     *	access complete
						     */
#define XAE_INT_AUTONEG_MASK		0x00000002 /**< Auto negotiation
						     *  complete
						     */
#define XAE_INT_RXCMPIT_MASK		0x00000004 /**< Rx complete */
#define XAE_INT_RXRJECT_MASK		0x00000008 /**< Rx frame rejected */
#define XAE_INT_RXFIFOOVR_MASK		0x00000010 /**< Rx fifo overrun */
#define XAE_INT_TXCMPIT_MASK		0x00000020 /**< Tx complete */
#define XAE_INT_RXDCMLOCK_MASK		0x00000040 /**< Rx Dcm Lock */
#define XAE_INT_MGTRDY_MASK		0x00000080 /**< MGT clock Lock */
#define XAE_INT_PHYRSTCMPLT_MASK	0x00000100 /**< Phy Reset complete */

#define XAE_INT_ALL_MASK		0x0000003F /**< All the ints */

#define XAE_INT_RECV_ERROR_MASK			\
	(XAE_INT_RXRJECT_MASK | XAE_INT_RXFIFOOVR_MASK) /**< INT bits that
							 *   indicate receive
							 *   errors
							 */
/*@}*/


/** @name TPID Register (TPID) bit definitions
 *  @{
 */
#define XAE_TPID_0_MASK			0x0000FFFF   /**< TPID 0 */
#define XAE_TPID_1_MASK			0xFFFF0000   /**< TPID 1 */
/*@}*/


/** @name Receive Configuration Word 1 (RCW1) Register bit definitions
 *  @{
 */
#define XAE_RCW1_RST_MASK	0x80000000 /**< Reset */
#define XAE_RCW1_JUM_MASK	0x40000000 /**< Jumbo frame enable */
#define XAE_RCW1_FCS_MASK	0x20000000 /**< In-Band FCS enable
					     *  (FCS not stripped) */
#define XAE_RCW1_RX_MASK	0x10000000 /**< Receiver enable */
#define XAE_RCW1_VLAN_MASK	0x08000000 /**< VLAN frame enable */
#define XAE_RCW1_LT_DIS_MASK	0x02000000 /**< Length/type field valid check
					     *  disable
					     */
#define XAE_RCW1_CL_DIS_MASK	0x01000000 /**< Control frame Length check
					     *  disable
					     */
#define XAE_RCW1_1588_TIMESTAMP_EN_MASK		0x00400000 /**< Inband 1588 time
											* stamp enable
											*/
#define XAE_RCW1_PAUSEADDR_MASK 0x0000FFFF /**< Pause frame source
					     *  address bits [47:32].Bits
					     *	[31:0] are stored in register
					     *  RCW0
					     */
/*@}*/


/** @name Transmitter Configuration (TC) Register bit definitions
 *  @{
 */
#define XAE_TC_RST_MASK		0x80000000 /**< Reset */
#define XAE_TC_JUM_MASK		0x40000000 /**< Jumbo frame enable */
#define XAE_TC_FCS_MASK		0x20000000 /**< In-Band FCS enable
					     *  (FCS not generated)
					     */
#define XAE_TC_TX_MASK		0x10000000 /**< Transmitter enable */
#define XAE_TC_VLAN_MASK	0x08000000 /**< VLAN frame enable */
#define XAE_TC_IFG_MASK		0x02000000 /**< Inter-frame gap adjustment
					      * enable
					      */
#define XAE_TC_1588_CMD_EN_MASK		0x00400000 /**< 1588 Cmd field enable */
/*@}*/


/** @name Flow Control Configuration (FCC) Register Bit definitions
 *  @{
 */
#define XAE_FCC_FCRX_MASK	0x20000000   /**< Rx flow control enable */
#define XAE_FCC_FCTX_MASK	0x40000000   /**< Tx flow control enable */
/*@}*/


/** @name Ethernet MAC Mode Configuration (EMMC) Register bit definitions
 * @{
 */
#define XAE_EMMC_LINKSPEED_MASK 	0xC0000000 /**< Link speed */
#define XAE_EMMC_RGMII_MASK	 	0x20000000 /**< RGMII mode enable */
#define XAE_EMMC_SGMII_MASK	 	0x10000000 /**< SGMII mode enable */
#define XAE_EMMC_GPCS_MASK	 	0x08000000 /**< 1000BaseX mode enable*/
#define XAE_EMMC_HOST_MASK	 	0x04000000 /**< Host interface enable*/
#define XAE_EMMC_TX16BIT	 	0x02000000 /**< 16 bit Tx client
						    *   enable
						    */
#define XAE_EMMC_RX16BIT	 	0x01000000 /**< 16 bit Rx client
						    *   enable
						    */
#define XAE_EMMC_LINKSPD_10		0x00000000 /**< Link Speed mask for
						    *   10 Mbit
						    */
#define XAE_EMMC_LINKSPD_100		0x40000000 /**< Link Speed mask for 100
						    *   Mbit
						    */
#define XAE_EMMC_LINKSPD_1000		0x80000000 /**< Link Speed mask for
						    *   1000 Mbit
						    */
/*@}*/


/** @name RGMII/SGMII Configuration (PHYC) Register bit definitions
 * @{
 */
#define XAE_PHYC_SGMIILINKSPEED_MASK 	0xC0000000 /**< SGMII link speed mask*/
#define XAE_PHYC_RGMIILINKSPEED_MASK 	0x0000000C /**< RGMII link speed */
#define XAE_PHYC_RGMIIHD_MASK	 	0x00000002 /**< RGMII Half-duplex */
#define XAE_PHYC_RGMIILINK_MASK 	0x00000001 /**< RGMII link status */
#define XAE_PHYC_RGLINKSPD_10		0x00000000 /**< RGMII link 10 Mbit */
#define XAE_PHYC_RGLINKSPD_100		0x00000004 /**< RGMII link 100 Mbit */
#define XAE_PHYC_RGLINKSPD_1000 	0x00000008 /**< RGMII link 1000 Mbit */
#define XAE_PHYC_SGLINKSPD_10		0x00000000 /**< SGMII link 10 Mbit */
#define XAE_PHYC_SGLINKSPD_100		0x40000000 /**< SGMII link 100 Mbit */
#define XAE_PHYC_SGLINKSPD_1000 	0x80000000 /**< SGMII link 1000 Mbit */
/*@}*/


/** @name MDIO Management Configuration (MC) Register bit definitions
 * @{
 */
#define XAE_MDIO_MC_MDIOEN_MASK		0x00000040 /**< MII management enable*/
#define XAE_MDIO_MC_CLOCK_DIVIDE_MAX	0x3F	   /**< Maximum MDIO divisor */
/*@}*/


/** @name MDIO Management Control Register (MCR) Register bit definitions
 * @{
 */
#define XAE_MDIO_MCR_PHYAD_MASK		0x1F000000 /**< Phy Address Mask */
#define XAE_MDIO_MCR_PHYAD_SHIFT	24	   /**< Phy Address Shift */
#define XAE_MDIO_MCR_REGAD_MASK		0x001F0000 /**< Reg Address Mask */
#define XAE_MDIO_MCR_REGAD_SHIFT	16	   /**< Reg Address Shift */
#define XAE_MDIO_MCR_OP_MASK		0x0000C000 /**< Operation Code Mask */
#define XAE_MDIO_MCR_OP_SHIFT		13	   /**< Operation Code Shift */
#define XAE_MDIO_MCR_OP_READ_MASK	0x00008000 /**< Op Code Read Mask */
#define XAE_MDIO_MCR_OP_WRITE_MASK	0x00004000 /**< Op Code Write Mask */
#define XAE_MDIO_MCR_INITIATE_MASK	0x00000800 /**< Ready Mask */
#define XAE_MDIO_MCR_READY_MASK		0x00000080 /**< Ready Mask */

/*@}*/

/** @name MDIO Interrupt Enable/Mask/Status Registers bit definitions
 *  The bit definition of these three interrupt registers are the same.
 *  These bits are associated with the XAE_IS_OFFSET, XAE_IP_OFFSET, and
 *  XAE_IE_OFFSET registers.
 * @{
 */
#define XAE_MDIO_INT_MIIM_RDY_MASK	0x00000001 /**< MIIM Interrupt */
/*@}*/


/** @name Axi Ethernet Unicast Address Register Word 1 (UAW1) Register Bit
 *  definitions
 * @{
 */
#define XAE_UAW1_UNICASTADDR_MASK 	0x0000FFFF  /**< Station address bits
						     *  [47:32]
						     *  Station address bits [31:0]
						     *  are stored in register
						     *  UAW0 */
/*@}*/


/** @name Filter Mask Index (FMI) Register bit definitions
 * @{
 */
#define XAE_FMI_PM_MASK			0x80000000   /**< Promiscuous mode
						      *   enable
						      */
#define XAE_FMI_IND_MASK		0x00000003   /**< Index Mask */

/*@}*/


/** @name Extended multicast buffer descriptor bit mask
 * @{
 */
#define XAE_BD_RX_USR2_BCAST_MASK	0x00000004
#define XAE_BD_RX_USR2_IP_MCAST_MASK	0x00000002
#define XAE_BD_RX_USR2_MCAST_MASK	0x00000001
/*@}*/

/** @name Axi Ethernet Multicast Address Register Word 1 (MAW1)
 * @{
 */
#define XAE_MAW1_RNW_MASK         	0x00800000   /**< Multicast address
						      * table register read
						      * enable
						      */
#define XAE_MAW1_ADDR_MASK        	0x00030000   /**< Multicast address
						      *  table register address
						      */
#define XAE_MAW1_MULTICADDR_MASK  	0x0000FFFF   /**< Multicast address
						      *  bits [47:32]
						      *  Multicast address
						      *  bits [31:0] are stored
						      *  in register MAW0
						      */
#define XAE_MAW1_MATADDR_SHIFT_MASK 	16	 /**< Number of bits to shift
						  *  right to align with
						  *  XAE_MAW1_CAMADDR_MASK
						  */
/*@}*/


/** @name Other Constant definitions used in the driver
 * @{
 */

#define XAE_SPEED_10_MBPS		10	/**< Speed of 10 Mbps */
#define XAE_SPEED_100_MBPS		100	/**< Speed of 100 Mbps */
#define XAE_SPEED_1000_MBPS		1000	/**< Speed of 1000 Mbps */
#define XAE_SPEED_2500_MBPS		2500	/**< Speed of 2500 Mbps */

#define XAE_SOFT_TEMAC_LOW_SPEED	0	/**< For soft cores with 10/100
						 *   Mbps speed.
						 */
#define XAE_SOFT_TEMAC_HIGH_SPEED	1	/**< For soft cores with
						 *   10/100/1000 Mbps speed.
						 */
#define XAE_HARD_TEMAC_TYPE		2	/**< For hard TEMAC cores used
						 *   virtex-6.
						 */
#define XAE_PHY_ADDR_LIMIT		31	/**< Max limit while accessing
						  *  and searching for available
						  * PHYs.
						  */
#define XAE_PHY_REG_NUM_LIMIT		31	/**< Max register limit in PHY
						  * as mandated by the spec.
						  */
#define XAE_LOOPS_TO_COME_OUT_OF_RST	10000000 /**< Number of loops in the driver
						  *   API to wait for before
						  *   returning a failure case.
						  */

#define XAE_RST_DELAY_LOOPCNT_VAL	10000000 /**< Timeout in ticks used
						  *  while checking if the core
						  *  had come out of reset. The
						  *  exact tick time is defined
						  *  in each case/loop where it
						  *  will be used
						  */
#define XAE_VLAN_TABL_STRP_FLD_LEN	1	/**< Strip field length in vlan
						 *   table used for extended
						 *   vlan features.
						 */
#define XAE_VLAN_TABL_TAG_FLD_LEN	1	/**< Tag field length in vlan
						 *   table used for extended
						 *   vlan features.
						 */
#define XAE_MAX_VLAN_TABL_ENTRY		0xFFF	/**< Max possible number of
						 *   entries in vlan table used
						 *   for extended vlan
						 *   features.
						 */
#define XAE_VLAN_TABL_VID_START_OFFSET	2	/**< VID field start offset in
						 *   each entry in the VLAN
						 *   table.
						 */
#define XAE_VLAN_TABL_STRP_STRT_OFFSET	1	/**< Strip field start offset
						 *   in each entry in the VLAN
						 *  table.
						 */
#define XAE_VLAN_TABL_STRP_ENTRY_MASK	0x01	/**< Mask used to extract the
						 *   the strip field from an
						 *   entry in VLAN table.
						 */
#define XAE_VLAN_TABL_TAG_ENTRY_MASK	0x01	/**< Mask used to extract the
						 *   the tag field from an
						 *   entry in VLAN table.
						 */

/*@}*/





/****************************************************************************/
/**
*
* XAxiEthernet_ReadReg returns the value read from the register specified by
* <i>RegOffset</i>.
*
* @param	BaseAddress is the base address of the Axi Ethernet device.
* @param	RegOffset is the offset of the register to be read.
*
* @return	Returns the 32-bit value of the register.
*
* @note		C-style signature:
*		u32 XAxiEthernet_ReadReg(u32 BaseAddress, u32 RegOffset)
*
*****************************************************************************/
#define XAxiEthernet_ReadReg(BaseAddress, RegOffset) 			\
	(Xil_In32(((BaseAddress) + (RegOffset))))

/****************************************************************************/
/**
*
* XAxiEthernet_WriteReg, writes <i>Data</i> to the register specified by
* <i>RegOffset</i>.
*
* @param	BaseAddress is the base address of the Axi Ethernet device.
* @param	RegOffset is the offset of the register to be written.
* @param	Data is the 32-bit value to write to the register.
*
* @return	None.
*
* @note
* 	C-style signature:
*	void XAxiEthernet_WriteReg(u32 BaseAddress, u32 RegOffset, u32 Data)
*
*****************************************************************************/
#define XAxiEthernet_WriteReg(BaseAddress, RegOffset, Data) \
	Xil_Out32(((BaseAddress) + (RegOffset)), (Data))



/**
 * This typedef contains configuration information for a Axi Ethernet device.
 */
typedef struct XAxiEthernet_Config {
	u16 DeviceId;	/**< DeviceId is the unique ID  of the device */
	UINTPTR BaseAddress;/**< BaseAddress is the physical base address of the
			  *  device's registers
			  */
	u8 TemacType;   /**< Temac Type can have 3 possible values. They are
			  *  0 for SoftTemac at 10/100 Mbps, 1 for SoftTemac
			  *  at 10/100/1000 Mbps and 2 for Vitex6 Hard Temac
			  */
	u8 TxCsum;	/**< TxCsum indicates that the device has checksum
			  *  offload on the Tx channel or not.
			  */
	u8 RxCsum;	/**< RxCsum indicates that the device has checksum
			  *  offload on the Rx channel or not.
			  */
	u8 PhyType;	/**< PhyType indicates which type of PHY interface is
			  *  used (MII, GMII, RGMII, etc.
			  */
	u8 TxVlanTran;  /**< TX VLAN Translation indication */
	u8 RxVlanTran;  /**< RX VLAN Translation indication */
	u8 TxVlanTag;   /**< TX VLAN tagging indication */
	u8 RxVlanTag;   /**< RX VLAN tagging indication */
	u8 TxVlanStrp;  /**< TX VLAN stripping indication */
	u8 RxVlanStrp;  /**< RX VLAN stripping indication */
	u8 ExtMcast;    /**< Extend multicast indication */
	u8 Stats;	/**< Statistics gathering option */
	u8 Avb;		/**< Avb option */
	u8 EnableSgmiiOverLvds;	/**< Enable LVDS option */
	u8 Enable_1588;	/**< Enable 1588 option */
	u32 Speed;	/**< Tells whether MAC is 1G or 2p5G */

	u8 TemacIntr;	/**< Axi Ethernet interrupt ID */

	int AxiDevType;  /**< AxiDevType is the type of device attached to the
			  *   Axi Ethernet's AXI4-Stream interface.
			  */
	u32 AxiDevBaseAddress; /**< AxiDevBaseAddress is the base address of
				 *  the device attached to the Axi Ethernet's
				 *  AXI4-Stream interface.
				 */
	u8 AxiFifoIntr;	/**< AxiFifoIntr interrupt ID (unused if DMA) */
	u8 AxiDmaRxIntr;/**< Axi DMA RX interrupt ID (unused if FIFO) */
	u8 AxiDmaTxIntr;/**< Axi DMA TX interrupt ID (unused if FIFO) */
	u8 AxiMcDmaChan_Cnt;  /**< Axi MCDMA Channel Count */
	u8 AxiMcDmaRxIntr[16]; /**< Axi MCDMA Rx interrupt ID (unused if AXI DMA or FIFO) */
	u8 AxiMcDmaTxIntr[16]; /**< AXI MCDMA TX interrupt ID (unused if AXIX DMA or FIFO) */
} XAxiEthernet_Config;

/**
 * struct XAxiEthernet is the type for Axi Ethernet driver instance data.
 * The calling code is required to use a unique instance of this structure
 * for every Axi Ethernet device used in the system. A reference to a structure
 * of this type is then passed to the driver API functions.
 */
typedef struct XAxiEthernet {
	XAxiEthernet_Config Config; /**< Hardware configuration */
	u32 IsStarted;		 /**< Device is currently started */
	u32 IsReady;		 /**< Device is initialized and ready */
	u32 Options;		 /**< Current options word */
	u32 Flags;		 /**< Internal driver flags */
} XAxiEthernet;


void XAxiEthernet_PhyRead2(XAxiEthernet *InstancePtr, u32 PhyAddress,
			   u32 RegisterNum, u16 *PhyDataPtr)
{
	u32 MdioCtrlReg = 0;

	xil_printf("XAxiEthernet_PhyRead: Address: 0x%08x + 0x%04x\r\n", InstancePtr->Config.BaseAddress, RegisterNum);

	/*
	 * Wait till MDIO interface is ready to accept a new transaction.
	 */
	while (!(XAxiEthernet_ReadReg(InstancePtr->Config.BaseAddress, XAE_MDIO_MCR_OFFSET) & XAE_MDIO_MCR_READY_MASK)) {
		;
	}

	MdioCtrlReg =   ((PhyAddress << XAE_MDIO_MCR_PHYAD_SHIFT) & XAE_MDIO_MCR_PHYAD_MASK) |
			((RegisterNum << XAE_MDIO_MCR_REGAD_SHIFT) & XAE_MDIO_MCR_REGAD_MASK) |
			XAE_MDIO_MCR_INITIATE_MASK |
			XAE_MDIO_MCR_OP_READ_MASK;

	XAxiEthernet_WriteReg(InstancePtr->Config.BaseAddress, XAE_MDIO_MCR_OFFSET, MdioCtrlReg);


	/*
	 * Wait till MDIO transaction is completed.
	 */
	while (!(XAxiEthernet_ReadReg(InstancePtr->Config.BaseAddress, XAE_MDIO_MCR_OFFSET) & XAE_MDIO_MCR_READY_MASK)) {
		;
	}

	/* Read data */
	*PhyDataPtr = (u16) XAxiEthernet_ReadReg(InstancePtr->Config.BaseAddress,XAE_MDIO_MRD_OFFSET);
	xil_printf("XAxiEthernet_PhyRead: Value retrieved: 0x%0x\r\n", *PhyDataPtr);

}



void XAxiEthernet_PhyWrite(XAxiEthernet *InstancePtr, u32 PhyAddress, u32 RegisterNum, u16 PhyData)
{
	u32 MdioCtrlReg = 0;

	/*
	 * Wait till the MDIO interface is ready to accept a new transaction.
	 */
	while (!(XAxiEthernet_ReadReg(InstancePtr->Config.BaseAddress, XAE_MDIO_MCR_OFFSET) & XAE_MDIO_MCR_READY_MASK)) {
		;
	}

	MdioCtrlReg =   ((PhyAddress << XAE_MDIO_MCR_PHYAD_SHIFT) & XAE_MDIO_MCR_PHYAD_MASK) |
			((RegisterNum << XAE_MDIO_MCR_REGAD_SHIFT) & XAE_MDIO_MCR_REGAD_MASK) |
			XAE_MDIO_MCR_INITIATE_MASK |
			XAE_MDIO_MCR_OP_WRITE_MASK;

	XAxiEthernet_WriteReg(InstancePtr->Config.BaseAddress, XAE_MDIO_MWD_OFFSET, PhyData);

	XAxiEthernet_WriteReg(InstancePtr->Config.BaseAddress, XAE_MDIO_MCR_OFFSET, MdioCtrlReg);

	/*
	 * Wait till the MDIO interface is ready to accept a new transaction.
	 */
	while (!(XAxiEthernet_ReadReg(InstancePtr->Config.BaseAddress, XAE_MDIO_MCR_OFFSET) & XAE_MDIO_MCR_READY_MASK)) {
		;
	}

}




unsigned int get_phy_negotiated_speed (XAxiEthernet *xaxiemacp, u32 phy_addr)
{
	u16 control=0xffff;
	u16 status=0;
	u16 partner_capabilities;
	u16 partner_capabilities_1000;
	u16 phylinkspeed;
	u16 temp=0;
	u32 v;
	u16 it;

	//phy_addr = XPAR_PCSPMA_SGMII_PHYADDR;

	xil_printf("Start PHY autonegotiation \r\n");

    v = Xil_In32(0x40c00000+0x500);
    xil_printf("MDIO Setup: %x\n\r", v);

    v = Xil_In32(0x40c00000+0x504);
    xil_printf("MDIO Control: %x\n\r", v);


	xil_printf("PHY Address: %x\r\n", phy_addr);

	it=0;
	while (control==0xffff && it<10) {
		sleep(1);
		XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, IEEE_CONTROL_REG_OFFSET,	&control);

		v = Xil_In32(GPIO_base);
		if ((v>>24)==1) return 0;

		it++;
	}

	control |= IEEE_CTRL_AUTONEGOTIATE_ENABLE;
	control |= IEEE_STAT_AUTONEGOTIATE_RESTART;
    control &= IEEE_CTRL_ISOLATE_DISABLE;

    xil_printf("Control: %x\r\n", control);

	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, IEEE_CONTROL_REG_OFFSET, control);
	XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, IEEE_STATUS_REG_OFFSET, &status);
	xil_printf("Waiting for PHY to  complete autonegotiation \r\n");
    xil_printf("Status: %x\r\n", status);
	while ( !(status & IEEE_STAT_AUTONEGOTIATE_COMPLETE) ) {
		//AxiEthernetUtilPhyDelay(1);
		sleep(1);
		XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, IEEE_STATUS_REG_OFFSET, &status);
	    xil_printf("Status: %x\r\n", status);
	}

	xil_printf("Autonegotiation complete \r\n");

	xil_printf("Waiting for Link to be up; Polling for SGMII core Reg \r\n");
	XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, IEEE_PARTNER_ABILITIES_1_REG_OFFSET, &temp);
	while(!(temp & 0x8000)) {
		XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, IEEE_PARTNER_ABILITIES_1_REG_OFFSET, &temp);
	}
	if((temp & 0x0C00) == 0x0800) {
		return 1000;
	}
	else if((temp & 0x0C00) == 0x0400) {
		return 100;
	}
	else if((temp & 0x0C00) == 0x0000) {
		return 10;
	} else {
		xil_printf("get_IEEE_phy_speed(): Invalid speed bit value, Deafulting to Speed = 10 Mbps\r\n");
		XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, IEEE_CONTROL_REG_OFFSET, &temp);
		XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, IEEE_CONTROL_REG_OFFSET, 0x0100);
		return 10;
	}

	/* Read PHY control and status registers is successful. */
	XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, IEEE_CONTROL_REG_OFFSET, &control);
	XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, IEEE_STATUS_REG_OFFSET,	&status);
	if ((control & IEEE_CTRL_AUTONEGOTIATE_ENABLE) && (status & IEEE_STAT_AUTONEGOTIATE_CAPABLE)) {
		xil_printf("Waiting for PHY to complete autonegotiation.\r\n");
		while ( !(status & IEEE_STAT_AUTONEGOTIATE_COMPLETE) ) {
			XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, IEEE_STATUS_REG_OFFSET, &status);
	    }

		xil_printf("autonegotiation complete \r\n");

		XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, IEEE_PARTNER_ABILITIES_1_REG_OFFSET, &partner_capabilities);
		if (status & IEEE_STAT_1GBPS_EXTENSIONS) {
			XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, IEEE_PARTNER_ABILITIES_3_REG_OFFSET,	&partner_capabilities_1000);
			if (partner_capabilities_1000 &	IEEE_AN3_ABILITY_MASK_1GBPS)
				return 1000;
		}

		if (partner_capabilities & IEEE_AN1_ABILITY_MASK_100MBPS)
			return 100;
		if (partner_capabilities & IEEE_AN1_ABILITY_MASK_10MBPS)
			return 10;

		xil_printf("%s: unknown PHY link speed, setting TEMAC speed to be 10 Mbps\r\n",	__FUNCTION__);
		return 10;
	} else {
		/* Update TEMAC speed accordingly */
		if (status & IEEE_STAT_1GBPS_EXTENSIONS) {

			/* Get commanded link speed */
			phylinkspeed = control & IEEE_CTRL_1GBPS_LINKSPEED_MASK;

			switch (phylinkspeed) {
				case (IEEE_CTRL_LINKSPEED_1000M):
					return 1000;
				case (IEEE_CTRL_LINKSPEED_100M):
					return 100;
				case (IEEE_CTRL_LINKSPEED_10M):
					return 10;
				default:
					xil_printf("%s: unknown PHY link speed (%d), setting TEMAC speed to be 10 Mbps\r\n",__FUNCTION__, phylinkspeed);
					return 10;
			}
		} else {
			return (control & IEEE_CTRL_LINKSPEED_MASK) ? 100 : 10;
		}
	}
}


static int detect_phy(XAxiEthernet *xaxiemacp)
{
	u16 phy_reg;
	u32 phy_addr;

	for (phy_addr = 1; phy_addr < 32; phy_addr++) {
		XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, PHY_DETECT_REG, &phy_reg);

		if ((phy_reg != 0xFFFF) &&
			((phy_reg & PHY_DETECT_MASK) == PHY_DETECT_MASK)) {
			/* Found a valid PHY address */
			xil_printf ("XAxiEthernet detect_phy: PHY detected at address %d.\r\n", phy_addr);
			xil_printf ("XAxiEthernet detect_phy: PHY detected.\r\n");
			XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, PHY_IDENTIFIER_1_REG,
										&phy_reg);
			if ((phy_reg != PHY_MARVELL_IDENTIFIER) &&
                (phy_reg != TI_PHY_IDENTIFIER)){
				xil_printf("WARNING: Not a Marvell or TI Ethernet PHY. Please verify the initialization sequence\r\n");
			}
			return phy_addr;
		}
	}

	xil_printf("XAxiEthernet detect_phy: No PHY detected.  Assuming a PHY at address 0\r\n");

        /* default to zero */
	return 0;
}


unsigned int get_phy_speed_TI_DP83867_SGMII(XAxiEthernet *xaxiemacp, u32 phy_addr)
{
	u16 control;
	u16 temp=0;
	u16 phyregtemp;

	xil_printf("Start TI PHY autonegotiation \r\n");

	/* Enable SGMII Clock */
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, TI_PHY_REGCR, TI_PHY_REGCR_DEVAD_EN);
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, TI_PHY_ADDDR, TI_PHY_SGMIITYPE);
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, TI_PHY_REGCR, TI_PHY_REGCR_DEVAD_EN | TI_PHY_REGCR_DEVAD_DATAEN);
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, TI_PHY_ADDDR, TI_PHY_SGMIICLK_EN);

	XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, IEEE_CONTROL_REG_OFFSET, &control);
	control |= (IEEE_CTRL_AUTONEGOTIATE_ENABLE | IEEE_CTRL_LINKSPEED_1000M | IEEE_CTRL_FULL_DUPLEX);
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, IEEE_CONTROL_REG_OFFSET, control);

	XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, TI_PHY_CFGR2, &control);
	control &= TI_PHY_CFGR2_MASK;
	control |= (TI_PHY_CFG2_SPEEDOPT_10EN   |
				TI_PHY_CFG2_SGMII_AUTONEGEN |
				TI_PHY_CFG2_SPEEDOPT_ENH    |
				TI_PHY_CFG2_SPEEDOPT_CNT    |
				TI_PHY_CFG2_SPEEDOPT_INTLOW);
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, TI_PHY_CFGR2, control);

	/* Disable RGMII */
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, TI_PHY_REGCR, TI_PHY_REGCR_DEVAD_EN);
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, TI_PHY_ADDDR, DP83867_R32_RGMIICTL1);
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, TI_PHY_REGCR, TI_PHY_REGCR_DEVAD_EN | TI_PHY_REGCR_DEVAD_DATAEN);
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, TI_PHY_ADDDR, 0);

	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, TI_PHY_PHYCTRL, TI_PHY_CR_SGMII_EN);

	xil_printf("Waiting for Link to be up \r\n");
	XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, IEEE_PARTNER_ABILITIES_1_REG_OFFSET, &temp);
	while(!(temp & 0x4000)) {
		XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, IEEE_PARTNER_ABILITIES_1_REG_OFFSET, &temp);
	}
	xil_printf("Auto negotiation completed for TI PHY\n\r");

	/* SW workaround for unstable link when RX_CTRL is not STRAP MODE 3 or 4 */
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, TI_PHY_REGCR, TI_PHY_REGCR_DEVAD_EN);
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, TI_PHY_ADDDR, TI_PHY_REGCFG4);
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, TI_PHY_REGCR, TI_PHY_REGCR_DATA);
	XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, TI_PHY_ADDDR, (u16 *)&phyregtemp);
	phyregtemp &= ~(TI_PHY_CFG4RESVDBIT7);
	phyregtemp |= TI_PHY_CFG4RESVDBIT8;
	phyregtemp &= ~(TI_PHY_CFG4_AUTONEG_TIMER);
	phyregtemp |= TI_PHY_CFG4_AUTONEG_TIMER;
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, TI_PHY_REGCR, TI_PHY_REGCR_DEVAD_EN);
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, TI_PHY_ADDDR, TI_PHY_REGCFG4);
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, TI_PHY_REGCR, TI_PHY_REGCR_DATA);
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, TI_PHY_ADDDR, phyregtemp);

	XAxiEthernet_PhyRead2(xaxiemacp, phy_addr, TI_PHY_ADDDR, (u16 *)&phyregtemp);
	xil_printf("Last TI message: %x\r\n", phyregtemp);

	/* Connect to internal PHY */
	return get_phy_negotiated_speed(xaxiemacp, XPAR_PCSPMA_SGMII_PHYADDR);

}







unsigned Phy_Setup (XAxiEthernet *xaxiemacp)
{
	unsigned link_speed = 1000;

	xil_printf("D1\r\n");

	u32 phy_wr_data = IEEE_CTRL_AUTONEGOTIATE_ENABLE | IEEE_CTRL_LINKSPEED_1000M;
	phy_wr_data &= (~PHY_R0_ISOLATE);

	XAxiEthernet_PhyWrite(xaxiemacp, XPAR_AXIETHERNET_0_PHYADDR, IEEE_CONTROL_REG_OFFSET, phy_wr_data);

	/* set PHY <--> MAC data clock */
	xil_printf("D2\r\n");

	u32 phy_addr = detect_phy(xaxiemacp);

	link_speed = get_phy_speed_TI_DP83867_SGMII(xaxiemacp, phy_addr);

	xil_printf("auto-negotiated link speed: %d\r\n", link_speed);

	return link_speed;
}





int main()
{
	u32 v;
	XAxiEthernet eth_inst;
	u32 p;

    while (1) {

    	init_platform();

		Xil_Out32(GPIO_base+0x8, 0x200);

		eth_inst.Config.BaseAddress=0x40c00000;
		eth_inst.Config.PhyType=XAE_PHY_TYPE_SGMII;

		print("\n\n\n\n\n\n\n\rHello World\n\r");


		//Xil_Out32(eth_inst.Config.BaseAddress+0x404, 0x80000000);
		//Xil_Out32(eth_inst.Config.BaseAddress+0x408, 0x80000000);

		//sleep(1);

		Xil_Out32(eth_inst.Config.BaseAddress+0x404, 0x5300ffff);
		Xil_Out32(eth_inst.Config.BaseAddress+0x408, 0x50000000);

		v = Xil_In32(eth_inst.Config.BaseAddress+0x404);
		xil_printf("Config 0x404: %x\n\r", v);

		v = Xil_In32(eth_inst.Config.BaseAddress+0x408);
		xil_printf("Config 0x408: %x\n\r", v);


		v = Xil_In32(eth_inst.Config.BaseAddress+0x500);
		xil_printf("MDIO Setup: %x\n\r", v);

    	Xil_Out32(eth_inst.Config.BaseAddress+0x500, 0x5F);
		//Xil_Out32(eth_inst.Config.BaseAddress+0x504, 0x00);

		v = Xil_In32(eth_inst.Config.BaseAddress+0x500);
		xil_printf("MDIO Setup: %x\n\r", v);

		v = Xil_In32(eth_inst.Config.BaseAddress+0x504);
		xil_printf("MDIO Control: %x\n\r", v);


		xil_printf("\r\n\r\n\r\n\r\nSETUP\r\n\r\n");

		if (Phy_Setup(&eth_inst)!=0) break;

		Xil_Out32(GPIO_base+0x8, 0x300);

		cleanup_platform();

    }



	p=0;
	xil_printf("\r\n\r\n\r\n\r\nDATA\r\n\r\n");

    v=0;
	while(((v>>24)&0x1)==0) {
		v = Xil_In32(GPIO_base);
		xil_printf("Button: %02x\r", (v>>24));
	}

	while(1) {

		v = Xil_In32(GPIO_base);
		//xil_printf("%x\r\n", v);

		if ((v&(0x400000))==0) {
			xil_printf("%02x ", (v>>12)&0xFF);
			Xil_Out32(GPIO_base+0x8, 0x302);
			Xil_Out32(GPIO_base+0x8, 0x300);

			p++;

			if ((v&(0x100000))!=0) {
				p=0;
				xil_printf("\r\n--EOP--\r\n\r\n");
			}

			if (p==8) xil_printf(" ");
			if (p==16) {
				p=0;
				xil_printf("\r\n");
			}
		}

    }

    cleanup_platform();
    return 0;
}
