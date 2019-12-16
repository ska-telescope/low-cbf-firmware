/*
 * menu.h
 *
 *  Created on: Aug 27, 2014
 *      Author: lsm
 */
//#include "board_test_app.h"
#include <ctype.h>
#include <xil_types.h>
#include "xgpio.h"
#include "stdio.h"
#include "xparameters.h"
#include "xil_cache.h"
#include "xiic.h"
#include "xintc.h"
#include "xil_exception.h"
#include "platform.h"
#include <string.h>
#include <stdio.h>
#include "xuartns550_l.h"
#include "xstatus.h"


// Change this to the clock frequency used by Ibert
//#define FPGA_IBERT 125
#define FPGA_IBERT 187.5
//#define FPGA_IBERT 375

#define ERR_IIC_INIT_1          0x00010001
#define ERR_IIC_INIT_2          0x00010002
#define ERR_IIC_INIT_3          0x00010003
#define ERR_IIC_INIT_4          0x00010004
#define ERR_IIC_WRITE_1         0x00010005
#define ERR_IIC_READ_1          0x00010006
#define ERR_IIC_READ_2          0x00010007
#define ERR_IIC_GPIO_EXPANDER_1 0x00010008
#define ERR_IIC_GPIO_EXPANDER_2 0x00010009
#define ERR_IIC_WRITE_TCA9548   0x0001000A
#define ERR_IIC_WRITE_TCA9544   0x0001000B
#define ERR_IIC_WRITE_TCA9543   0x0001000C
#define ERR_PMBUS_1             0x0002000D
#define ERR_PMBUS_2             0x0002000E
#define ERR_PMBUS_3             0x0002000F
#define ERR_PMBUS_4             0x00020010
#define ERR_PMBUS_5             0x00020011
#define ERR_PMBUS_6             0x00020012
#define ERR_PMBUS_7             0x00020013
#define ERR_SYSMON_1            0x00030014

#define DEBUG 1

#define TEST_BUFFER_SIZE   16
#define BYTES_TO_WRITE 8
#define BYTES_TO_READ 4
#define TEST_FAILED 0
#define TEST_PASSED 1
#define MAX_RETRY_COUNT 3

//I2C MUX to HMC ( U28 - TCA9548 )
#define TCA9548_MUX_ADDR 0x74
#define TCA9548_MUX_PORT0 0x01
#define TCA9548_MUX_PORT1 0x02
#define TCA9548_MUX_PORT2 0x04
#define TCA9548_MUX_PORT3 0x08
#define TCA9548_MUX_PORT4 0x10
#define TCA9548_MUX_PORT5 0x20
#define TCA9548_MUX_PORT6 0x40
#define TCA9548_MUX_PORT7 0x80
#define TCA9548_MUX_OFF   0x00

//I2C Mux to other parts ( U80 - PCA9544)
#define PCA9544_MUX_ADDR  0x75
#define PCA9544_MUX_PORT0 0x04
#define PCA9544_MUX_PORT1 0x05
#define PCA9544_MUX_PORT2 0x06
#define PCA9544_MUX_PORT3 0x07
#define PCA9544_MUX_OFF   0x00

//I2C GPO Bit mapping
#define SI5328_RST_N    0x00000001
#define IIC_MUX_RESET_N 0x00000002
#define HMC_P_RST_N     0x00000004

#define IIC_DEVICE_ID   XPAR_IIC_0_DEVICE_ID
#define INTC_DEVICE_ID  XPAR_INTC_0_DEVICE_ID
#define IIC_INTR_ID  XPAR_INTC_0_IIC_0_VEC_ID

#define CHECK_BIT(var,pos) ((var) & (1<<(pos)))
#define xil_printf xil_printf
#define sscanf gets

#define TEST_FAILED 0
#define TEST_PASSED 1



//HMC IIC ADDRESS
#define HMC_IIC_ADDR 0x14

#define HMC_CUB_ADDR          0x4
#define HMC_SLV_ADDR          0x2
#define HMC_ADDR              0x14

#define RQST_ID_BASE_ADDR     0x00000000
#define IBUF_TK_BASE_ADDR     0x00040000
#define LNK_RTY_BASE_ADDR     0x000C0000
#define LNK_CNF_BASE_ADDR     0x00240000
#define LNK_RLL_BASE_ADDR     0x00240003
#define ADD_CFG_BASE_ADDR     0x002C0000

#define RQST_ID_REG_LNK0_ADDR 0x00000000
#define RQST_ID_REG_LNK1_ADDR 0x00010000
#define RQST_ID_REG_LNK2_ADDR 0x00020000
#define RQST_ID_REG_LNK3_ADDR 0x00030000
#define IBUF_TK_CNT_LNK0_ADDR 0x00040000
#define IBUF_TK_CNT_LNK1_ADDR 0x00050000
#define IBUF_TK_CNT_LNK2_ADDR 0x00060000
#define IBUF_TK_CNT_LNK3_ADDR 0x00070000
#define LNK_RTY_REG_LNK0_ADDR 0x000C0000
#define LNK_RTY_REG_LNK1_ADDR 0x000D0000
#define LNK_RTY_REG_LNK2_ADDR 0x000E0000
#define LNK_RTY_REG_LNK3_ADDR 0x000F0000
#define LNK_CNF_REG_LNK0_ADDR 0x00240000
#define LNK_CNF_REG_LNK1_ADDR 0x00250000
#define LNK_CNF_REG_LNK2_ADDR 0x00260000
#define LNK_CNF_REG_LNK3_ADDR 0x00270000
#define LNK_STS_REG_LNK0_ADDR 0x00240002
#define LNK_STS_REG_LNK1_ADDR 0x00250002
#define LNK_STS_REG_LNK2_ADDR 0x00260002
#define LNK_STS_REG_LNK3_ADDR 0x00270002
#define LNK_RLL_REG_LNK0_ADDR 0x00240003
#define LNK_RLL_REG_LNK1_ADDR 0x00250003
#define LNK_RLL_REG_LNK2_ADDR 0x00260003
#define LNK_RLL_REG_LNK3_ADDR 0x00270003
#define LNK_INV_REG_LNK0_ADDR 0x00240004
#define LNK_INV_REG_LNK1_ADDR 0x00250004
#define LNK_INV_REG_LNK2_ADDR 0x00260004
#define LNK_INV_REG_LNK3_ADDR 0x00270004

//Eye Statistics by lane
#define LNK0_LANE0_RX_EYE_WDT 0x002000AA
#define LNK1_LANE0_RX_EYE_WDT 0x002100AA
#define LNK2_LANE0_RX_EYE_WDT 0x002200AA
#define LNK3_LANE0_RX_EYE_WDT 0x002300AA
#define LNK0_LANE1_RX_EYE_WDT 0x002000EA
#define LNK1_LANE1_RX_EYE_WDT 0x002100EA
#define LNK2_LANE1_RX_EYE_WDT 0x002200EA
#define LNK3_LANE1_RX_EYE_WDT 0x002300EA
#define LNK0_LANE2_RX_EYE_WDT 0x002001AA
#define LNK1_LANE2_RX_EYE_WDT 0x002101AA
#define LNK2_LANE2_RX_EYE_WDT 0x002201AA
#define LNK3_LANE2_RX_EYE_WDT 0x002301AA
#define LNK0_LANE3_RX_EYE_WDT 0x002001EA
#define LNK1_LANE3_RX_EYE_WDT 0x002101EA
#define LNK2_LANE3_RX_EYE_WDT 0x002201EA
#define LNK3_LANE3_RX_EYE_WDT 0x002301EA
#define LNK0_LANE4_RX_EYE_WDT 0x002002AA
#define LNK1_LANE4_RX_EYE_WDT 0x002102AA
#define LNK2_LANE4_RX_EYE_WDT 0x002202AA
#define LNK3_LANE4_RX_EYE_WDT 0x002302AA
#define LNK0_LANE5_RX_EYE_WDT 0x002002EA
#define LNK1_LANE5_RX_EYE_WDT 0x002102EA
#define LNK2_LANE5_RX_EYE_WDT 0x002202EA
#define LNK3_LANE5_RX_EYE_WDT 0x002302EA
#define LNK0_LANE6_RX_EYE_WDT 0x002003AA
#define LNK1_LANE6_RX_EYE_WDT 0x002103AA
#define LNK2_LANE6_RX_EYE_WDT 0x002203AA
#define LNK3_LANE6_RX_EYE_WDT 0x002303AA
#define LNK0_LANE7_RX_EYE_WDT 0x002003EA
#define LNK1_LANE7_RX_EYE_WDT 0x002103EA
#define LNK2_LANE7_RX_EYE_WDT 0x002203EA
#define LNK3_LANE7_RX_EYE_WDT 0x002303EA
#define LNK0_LANE8_RX_EYE_WDT 0x002008AA
#define LNK1_LANE8_RX_EYE_WDT 0x002108AA
#define LNK2_LANE8_RX_EYE_WDT 0x002208AA
#define LNK3_LANE8_RX_EYE_WDT 0x002308AA
#define LNK0_LANE9_RX_EYE_WDT 0x002008EA
#define LNK1_LANE9_RX_EYE_WDT 0x002108EA
#define LNK2_LANE9_RX_EYE_WDT 0x002208EA
#define LNK3_LANE9_RX_EYE_WDT 0x002308EA
#define LNK0_LANEA_RX_EYE_WDT 0x002009AA
#define LNK1_LANEA_RX_EYE_WDT 0x002109AA
#define LNK2_LANEA_RX_EYE_WDT 0x002209AA
#define LNK3_LANEA_RX_EYE_WDT 0x002309AA
#define LNK0_LANEB_RX_EYE_WDT 0x002009EA
#define LNK1_LANEB_RX_EYE_WDT 0x002109EA
#define LNK2_LANEB_RX_EYE_WDT 0x002209EA
#define LNK3_LANEB_RX_EYE_WDT 0x002309EA
#define LNK0_LANEC_RX_EYE_WDT 0x00200AAA
#define LNK1_LANEC_RX_EYE_WDT 0x00210AAA
#define LNK2_LANEC_RX_EYE_WDT 0x00220AAA
#define LNK3_LANEC_RX_EYE_WDT 0x00230AAA
#define LNK0_LANED_RX_EYE_WDT 0x00200AEA
#define LNK1_LANED_RX_EYE_WDT 0x00210AEA
#define LNK2_LANED_RX_EYE_WDT 0x00220AEA
#define LNK3_LANED_RX_EYE_WDT 0x00230AEA
#define LNK0_LANEE_RX_EYE_WDT 0x00200BAA
#define LNK1_LANEE_RX_EYE_WDT 0x00210BAA
#define LNK2_LANEE_RX_EYE_WDT 0x00220BAA
#define LNK3_LANEE_RX_EYE_WDT 0x00230BAA
#define LNK0_LANEF_RX_EYE_WDT 0x00200BEA
#define LNK1_LANEF_RX_EYE_WDT 0x00210BEA
#define LNK2_LANEF_RX_EYE_WDT 0x00220BEA
#define LNK3_LANEF_RX_EYE_WDT 0x00230BEA

#define LNK0_LANE0_RX_EYE_HGT 0x00200093
#define LNK1_LANE0_RX_EYE_HGT 0x00210093
#define LNK2_LANE0_RX_EYE_HGT 0x00220093
#define LNK3_LANE0_RX_EYE_HGT 0x00230093
#define LNK0_LANE1_RX_EYE_HGT 0x002000D3
#define LNK1_LANE1_RX_EYE_HGT 0x002100D3
#define LNK2_LANE1_RX_EYE_HGT 0x002200D3
#define LNK3_LANE1_RX_EYE_HGT 0x002300D3
#define LNK0_LANE2_RX_EYE_HGT 0x00200193
#define LNK1_LANE2_RX_EYE_HGT 0x00210193
#define LNK2_LANE2_RX_EYE_HGT 0x00220193
#define LNK3_LANE2_RX_EYE_HGT 0x00230193
#define LNK0_LANE3_RX_EYE_HGT 0x002001D3
#define LNK1_LANE3_RX_EYE_HGT 0x002101D3
#define LNK2_LANE3_RX_EYE_HGT 0x002201D3
#define LNK3_LANE3_RX_EYE_HGT 0x002301D3
#define LNK0_LANE4_RX_EYE_HGT 0x00200293
#define LNK1_LANE4_RX_EYE_HGT 0x00210293
#define LNK2_LANE4_RX_EYE_HGT 0x00220293
#define LNK3_LANE4_RX_EYE_HGT 0x00230293
#define LNK0_LANE5_RX_EYE_HGT 0x002002D3
#define LNK1_LANE5_RX_EYE_HGT 0x002102D3
#define LNK2_LANE5_RX_EYE_HGT 0x002202D3
#define LNK3_LANE5_RX_EYE_HGT 0x002302D3
#define LNK0_LANE6_RX_EYE_HGT 0x00200393
#define LNK1_LANE6_RX_EYE_HGT 0x00210393
#define LNK2_LANE6_RX_EYE_HGT 0x00220393
#define LNK3_LANE6_RX_EYE_HGT 0x00230393
#define LNK0_LANE7_RX_EYE_HGT 0x002003D3
#define LNK1_LANE7_RX_EYE_HGT 0x002103D3
#define LNK2_LANE7_RX_EYE_HGT 0x002203D3
#define LNK3_LANE7_RX_EYE_HGT 0x002303D3
#define LNK0_LANE8_RX_EYE_HGT 0x00200893
#define LNK1_LANE8_RX_EYE_HGT 0x00210893
#define LNK2_LANE8_RX_EYE_HGT 0x00220893
#define LNK3_LANE8_RX_EYE_HGT 0x00230893
#define LNK0_LANE9_RX_EYE_HGT 0x002008D3
#define LNK1_LANE9_RX_EYE_HGT 0x002108D3
#define LNK2_LANE9_RX_EYE_HGT 0x002208D3
#define LNK3_LANE9_RX_EYE_HGT 0x002308D3
#define LNK0_LANEA_RX_EYE_HGT 0x00200993
#define LNK1_LANEA_RX_EYE_HGT 0x00210993
#define LNK2_LANEA_RX_EYE_HGT 0x00220993
#define LNK3_LANEA_RX_EYE_HGT 0x00230993
#define LNK0_LANEB_RX_EYE_HGT 0x002009D3
#define LNK1_LANEB_RX_EYE_HGT 0x002109D3
#define LNK2_LANEB_RX_EYE_HGT 0x002209D3
#define LNK3_LANEB_RX_EYE_HGT 0x002309D3
#define LNK0_LANEC_RX_EYE_HGT 0x00200A93
#define LNK1_LANEC_RX_EYE_HGT 0x00210A93
#define LNK2_LANEC_RX_EYE_HGT 0x00220A93
#define LNK3_LANEC_RX_EYE_HGT 0x00230A93
#define LNK0_LANED_RX_EYE_HGT 0x00200AD3
#define LNK1_LANED_RX_EYE_HGT 0x00210AD3
#define LNK2_LANED_RX_EYE_HGT 0x00220AD3
#define LNK3_LANED_RX_EYE_HGT 0x00230AD3
#define LNK0_LANEE_RX_EYE_HGT 0x00200B93
#define LNK1_LANEE_RX_EYE_HGT 0x00210B93
#define LNK2_LANEE_RX_EYE_HGT 0x00220B93
#define LNK3_LANEE_RX_EYE_HGT 0x00230B93
#define LNK0_LANEF_RX_EYE_HGT 0x00200BD3
#define LNK1_LANEF_RX_EYE_HGT 0x00210BD3
#define LNK2_LANEF_RX_EYE_HGT 0x00220BD3
#define LNK3_LANEF_RX_EYE_HGT 0x00230BD3

#define LNK0_LANE0_PATRN_CTRL 0x00200081
#define LNK1_LANE0_PATRN_CTRL 0x00210081
#define LNK2_LANE0_PATRN_CTRL 0x00220081
#define LNK3_LANE0_PATRN_CTRL 0x00230081
#define LNK0_LANE1_PATRN_CTRL 0x002000C1
#define LNK1_LANE1_PATRN_CTRL 0x002100C1
#define LNK2_LANE1_PATRN_CTRL 0x002200C1
#define LNK3_LANE1_PATRN_CTRL 0x002300C1
#define LNK0_LANE2_PATRN_CTRL 0x00200181
#define LNK1_LANE2_PATRN_CTRL 0x00210181
#define LNK2_LANE2_PATRN_CTRL 0x00220181
#define LNK3_LANE2_PATRN_CTRL 0x00230181
#define LNK0_LANE3_PATRN_CTRL 0x002001C1
#define LNK1_LANE3_PATRN_CTRL 0x002101C1
#define LNK2_LANE3_PATRN_CTRL 0x002201C1
#define LNK3_LANE3_PATRN_CTRL 0x002301C1
#define LNK0_LANE4_PATRN_CTRL 0x00200281
#define LNK1_LANE4_PATRN_CTRL 0x00210281
#define LNK2_LANE4_PATRN_CTRL 0x00220281
#define LNK3_LANE4_PATRN_CTRL 0x00230281
#define LNK0_LANE5_PATRN_CTRL 0x002002C1
#define LNK1_LANE5_PATRN_CTRL 0x002102C1
#define LNK2_LANE5_PATRN_CTRL 0x002202C1
#define LNK3_LANE5_PATRN_CTRL 0x002302C1
#define LNK0_LANE6_PATRN_CTRL 0x00200381
#define LNK1_LANE6_PATRN_CTRL 0x00210381
#define LNK2_LANE6_PATRN_CTRL 0x00220381
#define LNK3_LANE6_PATRN_CTRL 0x00230381
#define LNK0_LANE7_PATRN_CTRL 0x002003C1
#define LNK1_LANE7_PATRN_CTRL 0x002103C1
#define LNK2_LANE7_PATRN_CTRL 0x002203C1
#define LNK3_LANE7_PATRN_CTRL 0x002303C1
#define LNK0_LANE8_PATRN_CTRL 0x00200881
#define LNK1_LANE8_PATRN_CTRL 0x00210881
#define LNK2_LANE8_PATRN_CTRL 0x00220881
#define LNK3_LANE8_PATRN_CTRL 0x00230881
#define LNK0_LANE9_PATRN_CTRL 0x002008C1
#define LNK1_LANE9_PATRN_CTRL 0x002108C1
#define LNK2_LANE9_PATRN_CTRL 0x002208C1
#define LNK3_LANE9_PATRN_CTRL 0x002308C1
#define LNK0_LANEA_PATRN_CTRL 0x00200981
#define LNK1_LANEA_PATRN_CTRL 0x00210981
#define LNK2_LANEA_PATRN_CTRL 0x00220981
#define LNK3_LANEA_PATRN_CTRL 0x00230981
#define LNK0_LANEB_PATRN_CTRL 0x002009C1
#define LNK1_LANEB_PATRN_CTRL 0x002109C1
#define LNK2_LANEB_PATRN_CTRL 0x002209C1
#define LNK3_LANEB_PATRN_CTRL 0x002309C1
#define LNK0_LANEC_PATRN_CTRL 0x00200A81
#define LNK1_LANEC_PATRN_CTRL 0x00210A81
#define LNK2_LANEC_PATRN_CTRL 0x00220A81
#define LNK3_LANEC_PATRN_CTRL 0x00230A81
#define LNK0_LANED_PATRN_CTRL 0x00200AC1
#define LNK1_LANED_PATRN_CTRL 0x00210AC1
#define LNK2_LANED_PATRN_CTRL 0x00220AC1
#define LNK3_LANED_PATRN_CTRL 0x00230AC1
#define LNK0_LANEE_PATRN_CTRL 0x00200B81
#define LNK1_LANEE_PATRN_CTRL 0x00210B81
#define LNK2_LANEE_PATRN_CTRL 0x00220B81
#define LNK3_LANEE_PATRN_CTRL 0x00230B81
#define LNK0_LANEF_PATRN_CTRL 0x00200BC1
#define LNK1_LANEF_PATRN_CTRL 0x00210BC1
#define LNK2_LANEF_PATRN_CTRL 0x00220BC1
#define LNK3_LANEF_PATRN_CTRL 0x00230BC1

//LANE Configuration Control Bits
#define LANE_PRBS7P           0x00000000
#define LANE_PRBS7N           0x00000001
#define LANE_PRBS15P          0x00000002
#define LANE_PRBS15N          0x00000003
#define LANE_PRBS23P          0x00000004
#define LANE_PRBS23N          0x00000005
#define LANE_PRBS31P          0x00000006
#define LANE_PRBS31N          0x00000007
#define LANE_PRBS_CHKR_EN     0x00000008
#define LANE_PRBS_CHKR_RST    0x00000010
#define LANE_PRBS_SYNC_STATUS 0x00000100
#define LANE_PRBS_CHK_ERROR   0x00000200

#define GLB_CFG_REG           0x00280000
#define GLB_STATUS_REG        0x00280001
#define BOOTSTRAP_REG         0x00280002

//Rev 0x10 and before ERI addresses
//#define ERIDATA_LNK0_OLD      0x002B01E0
//#define ERIDATA_LNK1_OLD      0x002B01E1
//#define ERIDATA_LNK2_OLD      0x002B01E2
//#define ERIDATA_LNK3_OLD      0x002B01E3
//#define ERIREQ_REG_OLD        0x002B01E4

//Rev 0x10 or greater ERI addresses
#define ERIDATA_LNK_BASE      0x002B0000
#define ERIDATA_LNK_BASE_OLD  0x002B01E0
//#define ERIDATA_LNK0          0x002B0000
//#define ERIDATA_LNK1          0x002B0001
//#define ERIDATA_LNK2          0x002B0002
//#define ERIDATA_LNK3          0x002B0003
//#define ERIREQ_REG            0x002B0004

#define ADDR_CFG_REG          0x002C0000
#define CUBE_SN1_REG          0x002C0001
#define CUBE_SN2_REG          0x002C0002
#define FEATURES_REG          0x002C0003
#define REVS_MFG_REG          0x002C0004
#define VAULT_CTRL_REG        0x01080000

//BOOSTRAP bits
#define HMC_DISABLE_NVM_WRITE 0x00010000

//Reading HMC REVS_MFG_REG Register 0x002C0004:0x0111082C VCU109 RevA Parts
//Reading HMC REVS_MFG_REG Register 0x002C0004:0x0111122C VCU109 RevB Parts

#define HMC_VENDOR_ID         0x000000FF
#define HMC_REVISION          0x0000FF00
#define HMC_PROTO_REV         0x00FF0000
#define HMC_PHY_REV           0xFF000000

//Point the ERI to the corect address based on the chip revision.
//#define ERIDATA_LNK0( CHIP_REV ) ((CHIP_REV < 0x00000010) ? ERIDATA_LNK0_OLD : ERIDATA_LNK0_NEW )
//#define ERIDATA_LNK1( CHIP_REV ) ((CHIP_REV < 0x00000010) ? ERIDATA_LNK1_OLD : ERIDATA_LNK1_NEW )
//#define ERIDATA_LNK2( CHIP_REV ) ((CHIP_REV < 0x00000010) ? ERIDATA_LNK2_OLD : ERIDATA_LNK2_NEW )
//#define ERIDATA_LNK3( CHIP_REV ) ((CHIP_REV < 0x00000010) ? ERIDATA_LNK3_OLD : ERIDATA_LNK3_NEW )
//#define ERIREQ_REG( CHIP_REV ) ((CHIP_REV < 0x00000010) ? ERIDATA_LNK0_OLD : ERIDATA_LNK0_NEW )

//LINK Configuration ERI Bits
#define LINK_SPEED_10GBPS     0x00000000
#define LINK_SPEED_12_5GBPS   0x00000001
#define LINK_SPEED_15GBPS     0x00000002
#define LINK_SPEED_RSVD       0x00000003
#define FULL_WDTH_TX_RX       0x00000000
#define HALF_WDTH_TX_RX       0x00010000
#define FULL_TX_HALF_RX       0x00020000
#define FULL_RX_HALF_TX       0x00030000
#define PRBS7_PLUS            0x00000000
#define PRBS7_MINUS           0x08000000
#define PRBS15_PLUS           0x10000000
#define PRBS15_MINUS          0x18000000
#define PRBS23_PLUS           0x20000000
#define PRBS23_MINUS          0x28000000
#define PRBS31_PLUS           0x30000000
#define PRBS31_MINUS          0x38000000
#define LNK_PTN_GEN_DIS       0x00000000
#define LNK_PTN_GEN_EN        0x40000000
#define LNK_LOOP_BK_DIS       0x00000000
#define LNK_LOOP_BK_EN        0x80000000
#define LINK_CONF_ERI_MASK    0xF8030003

//LINK CONFIGURATION REGISTER

#define LINK_MODE_HOST_SRC     0x00000001
#define LINK_MODE_HOST_NOT_SRC 0x00000002
#define LINK_MODE_PASS_THRU    0x00000003
#define LINK_RSP_OPEN_LOOP     0x00000004
#define LINK_PKT_SQNC_DETECT   0x00000008
#define LINK_CRC_DETECT        0x00000010
#define LINK_DLN_DETECT        0x00000020
#define LINK_DECODE_PKT        0x00000040
#define LINK_TRANSMIT_PKT      0x00000080
#define LINK_PLL_NO_PWR_DOWN   0x00000100
#define LINK_RCVR_DESCRAM      0x00000200
#define LINK_XMTR_SCRAMBL      0x00000400
#define LINK_SEND_ERR_RESP     0x00000800
#define LINK_CONF_MASK         0x00000FFF

//EFI COMMAND CONFIGURATION REGISTER
#define NOP                    0x00000000
#define RSVD1                  0x00000001
#define RSVD2                  0x00000002
#define RSVD3                  0x00000003
#define RSVD4                  0x00000004
#define LINK_CONFIGURATION     0x00000005
#define PHY_CONFIGURATION      0x00000006
#define DRAM_BIST_WITH_REPAIR  0x00000007
#define DRAM_BIST_W0_REPAIR    0x00000008
#define DRAM_REPAIR_HEALTH     0x00000009
#define TEMPERATURE_MOITOR     0x0000000A
#define TEMPERATURE_HISTORY    0x0000000B
#define REFRESH_RATE_ADJ       0x0000000C
#define RSVD5                  0x0000000D
#define RSVD6                  0x0000000E
#define SET_DRAM_PATTERN       0x0000000F
#define INIT_CONTINUE          0x0000003F
#define LINK_RCVR_DESCRAM      0x00000200
#define LINK_XMTR_SCRAMBL      0x00000400
#define LINK_SEND_ERR_RESP     0x00000800
#define LINK_CONF_MASK         0x00000FFF

//EFI COMMAND START BIT
#define HMC_EFI_CMD_START      0x80000000

//HMC GPIO Stuff
#define HMC_FATAL_ERROR_BITWIDTH 1
#define HMC_READ_POWER_BITWIDTH 2
#define HMC_REFCLK_SEL_BITWIDTH 1
#define HMC_SET_POWER_BITWIDTH 2
#define HMC_REFCLK_BOOT_BITWIDTH 2

#define HMC_FATAL_ERROR_CHANNEL 1
#define HMC_READ_POWER_CHANNEL 1
#define HMC_REFCLK_SEL_CHANNEL 1
#define HMC_SET_POWER_CHANNEL 1
#define HMC_REFCLK_BOOT_CHANNEL 1

//GPIO bit locations
#define HMC_FATAL_ERROR 1
#define HMC_L0TXPS 0
#define HMC_L1TXPS 1
#define HMC_REFCLK_SEL 0
#define HMC_L0RXPS 0
#define HMC_L1RXPS 1
#define HMC_REFCLK_BOOT0 0
#define HMC_REFCLK_BOOT1 1

#define HMC_FATAL_ERROR_GPI  XPAR_HMC_FATAL_ERROR_DEVICE_ID        //GPIO 0 1 Input
#define HMC_LXTXPS_GPI       XPAR_HMC_READ_POWER_DEVICE_ID         //GPIO 1 2 Inputs
#define HMC_REFCLK_SEL_GPO   XPAR_HMC_REFCLK_SELECT_DEVICE_ID      //GPIO 2 1 Outputs Default:0xFFFFFFFF
#define HMC_LXRXPS_GP0       XPAR_HMC_SET_POWER_DEVICE_ID          //GPIO 3 2 Outputs Default:0xFFFFFFFF
#define HMC_REFCLK_BOOT_GPO  XPAR_REFCLK_BOOT_DEVICE_ID            //GPIO 4 2 Outputs Default:0x00000000

#define two_to_37 (double) 137438953472.0
#define two_to_32 (double)   4294967296.0
#define two_to_28 (double)    268435456.0
#define two_to_24 (double)     16777216.0
#define two_to_20 (double)      1048576.0
#define two_to_19 (double)       524288.0
#define two_to_16 (double)        65536.0
#define two_to_8  (double)          256.0

#define SI53XX_XA 114.285

#define SI5368_XM104_0_HPC 0
#define SI5368_XM104_0_LPC 1
#define SI5328_VCU109 0
#define SI5328_VCU109_ILKN 0
#define SI5328_VCU109_CFP4 1
#define SI5328_VCU109_HMC  2

#define SI5328_ILKN_IIC_ADDR 0x68
#define SI5328_CFP4_IIC_ADDR 0x69
#define SI5328_HMC_IIC_ADDR  0x6A

/*
 * Macros to enable/disable caches.
 */
#ifndef ENABLE_ICACHE
#define ENABLE_ICACHE()    Xil_ICacheEnable()
#endif
#ifndef  ENABLE_DCACHE
#define ENABLE_DCACHE()    Xil_DCacheEnable()
#endif
#ifndef  DISABLE_ICACHE
#define DISABLE_ICACHE()   Xil_ICacheDisable()
#endif
#ifndef DISABLE_DCACHE
#define DISABLE_DCACHE()   Xil_DCacheDisable()
#endif

typedef struct
{
 double oFreq[4];
 double iFreq[4];
 int   N1;
 int   N1_HS;
 int   NC1_LS;
 int   NC2_LS;
 int   NC3_LS;
 int   NC4_LS;
 int   NC5_LS;
 int   N2;
 int   N2_HS;
 int   N2_LS;
 int   N31;
 int   N32;
 int   N33;
 int   N34;
 int   BWSEL;
 int   DSBL1;
 int   DSBL2;
 int   DSBL3;
 int   DSBL4;
 int   DSBL5;
 int   CLKIN1RATE;
 int   CLKIN2RATE;
 int   CLKIN3RATE;
 int   CLKIN4RATE;
} DSPLL_struct;


typedef struct {
    u32 hmc_reg_addr;
    u32 hmc_reg_data;
}volatile Hmc_reg;

typedef struct {
    u32 hmc_cfgaddr;
    u32 hmc_cfgdata;      
    u32 hmc_chip_revision;
    u32 hmc_eri_base_addr;
    u32 hmc_global_config_register;
    u32 hmc_global_status_register;
    u32 hmc_bootstrap_register;
    u32 hmc_external_data_reg0;
    u32 hmc_external_data_reg1;
    u32 hmc_external_data_reg2;
    u32 hmc_external_data_reg3;
    u32 hmc_external_request_reg;
    u32 hmc_address_config_register;
    u32 hmc_cube_sn1_register;
    u32 hmc_cube_sn2_register;
    u32 hmc_features_register;
    u32 hmc_revision_mfg_register;
    u32 hmc_vault_control_register;
    u32 hmc_link0_req_id_register;
    u32 hmc_link0_configuration_register;
    u32 hmc_link0_rll_register;
    u32 hmc_link0_retry_register;
    u32 hmc_link0_status_register;
    u32 hmc_link0_inversion_register;
    u32 hmc_link1_req_id_register;
    u32 hmc_link1_configuration_register;
    u32 hmc_link1_rll_register;
    u32 hmc_link1_retry_register;
    u32 hmc_link1_status_register;
    u32 hmc_link1_inversion_register;
    u32 hmc_link2_req_id_register;
    u32 hmc_link2_configuration_register;
    u32 hmc_link2_rll_register;
    u32 hmc_link2_status_register;
    u32 hmc_link2_retry_register;
    u32 hmc_link2_inversion_register;
    u32 hmc_link3_req_id_register;
    u32 hmc_link3_configuration_register;
    u32 hmc_link3_rll_register;
    u32 hmc_link3_retry_register;
    u32 hmc_link3_status_register;
    u32 hmc_link3_inversion_register;
    u32 hmc_gpi_fatal_error;
    u32 hmc_gpi_lxtxps;
    u32 hmc_gpo_refclk_sel;
    u32 hmc_gpo_lxrxps;
    u32 hmc_gpo_reclk_boot;
    u32 lnk0_lane0_rx_eye_wdt;
    u32 lnk1_lane0_rx_eye_wdt;
    u32 lnk2_lane0_rx_eye_wdt;
    u32 lnk3_lane0_rx_eye_wdt;
    u32 lnk0_lane1_rx_eye_wdt;
    u32 lnk1_lane1_rx_eye_wdt;
    u32 lnk2_lane1_rx_eye_wdt;
    u32 lnk3_lane1_rx_eye_wdt;
    u32 lnk0_lane2_rx_eye_wdt;
    u32 lnk1_lane2_rx_eye_wdt;
    u32 lnk2_lane2_rx_eye_wdt;
    u32 lnk3_lane2_rx_eye_wdt;
    u32 lnk0_lane3_rx_eye_wdt;
    u32 lnk1_lane3_rx_eye_wdt;
    u32 lnk2_lane3_rx_eye_wdt;
    u32 lnk3_lane3_rx_eye_wdt;
    u32 lnk0_lane4_rx_eye_wdt;
    u32 lnk1_lane4_rx_eye_wdt;
    u32 lnk2_lane4_rx_eye_wdt;
    u32 lnk3_lane4_rx_eye_wdt;
    u32 lnk0_lane5_rx_eye_wdt;
    u32 lnk1_lane5_rx_eye_wdt;
    u32 lnk2_lane5_rx_eye_wdt;
    u32 lnk3_lane5_rx_eye_wdt;
    u32 lnk0_lane6_rx_eye_wdt;
    u32 lnk1_lane6_rx_eye_wdt;
    u32 lnk2_lane6_rx_eye_wdt;
    u32 lnk3_lane6_rx_eye_wdt;
    u32 lnk0_lane7_rx_eye_wdt;
    u32 lnk1_lane7_rx_eye_wdt;
    u32 lnk2_lane7_rx_eye_wdt;
    u32 lnk3_lane7_rx_eye_wdt;
    u32 lnk0_lane8_rx_eye_wdt;
    u32 lnk1_lane8_rx_eye_wdt;
    u32 lnk2_lane8_rx_eye_wdt;
    u32 lnk3_lane8_rx_eye_wdt;
    u32 lnk0_lane9_rx_eye_wdt;
    u32 lnk1_lane9_rx_eye_wdt;
    u32 lnk2_lane9_rx_eye_wdt;
    u32 lnk3_lane9_rx_eye_wdt;
    u32 lnk0_lanea_rx_eye_wdt;
    u32 lnk1_lanea_rx_eye_wdt;
    u32 lnk2_lanea_rx_eye_wdt;
    u32 lnk3_lanea_rx_eye_wdt;
    u32 lnk0_laneb_rx_eye_wdt;
    u32 lnk1_laneb_rx_eye_wdt;
    u32 lnk2_laneb_rx_eye_wdt;
    u32 lnk3_laneb_rx_eye_wdt;
    u32 lnk0_lanec_rx_eye_wdt;
    u32 lnk1_lanec_rx_eye_wdt;
    u32 lnk2_lanec_rx_eye_wdt;
    u32 lnk3_lanec_rx_eye_wdt;
    u32 lnk0_laned_rx_eye_wdt;
    u32 lnk1_laned_rx_eye_wdt;
    u32 lnk2_laned_rx_eye_wdt;
    u32 lnk3_laned_rx_eye_wdt;
    u32 lnk0_lanee_rx_eye_wdt;
    u32 lnk1_lanee_rx_eye_wdt;
    u32 lnk2_lanee_rx_eye_wdt;
    u32 lnk3_lanee_rx_eye_wdt;
    u32 lnk0_lanef_rx_eye_wdt;
    u32 lnk1_lanef_rx_eye_wdt;
    u32 lnk2_lanef_rx_eye_wdt;
    u32 lnk3_lanef_rx_eye_wdt;
    u32 lnk0_lane0_rx_eye_hgt;
    u32 lnk1_lane0_rx_eye_hgt;
    u32 lnk2_lane0_rx_eye_hgt;
    u32 lnk3_lane0_rx_eye_hgt;
    u32 lnk0_lane1_rx_eye_hgt;
    u32 lnk1_lane1_rx_eye_hgt;
    u32 lnk2_lane1_rx_eye_hgt;
    u32 lnk3_lane1_rx_eye_hgt;
    u32 lnk0_lane2_rx_eye_hgt;
    u32 lnk1_lane2_rx_eye_hgt;
    u32 lnk2_lane2_rx_eye_hgt;
    u32 lnk3_lane2_rx_eye_hgt;
    u32 lnk0_lane3_rx_eye_hgt;
    u32 lnk1_lane3_rx_eye_hgt;
    u32 lnk2_lane3_rx_eye_hgt;
    u32 lnk3_lane3_rx_eye_hgt;
    u32 lnk0_lane4_rx_eye_hgt;
    u32 lnk1_lane4_rx_eye_hgt;
    u32 lnk2_lane4_rx_eye_hgt;
    u32 lnk3_lane4_rx_eye_hgt;
    u32 lnk0_lane5_rx_eye_hgt;
    u32 lnk1_lane5_rx_eye_hgt;
    u32 lnk2_lane5_rx_eye_hgt;
    u32 lnk3_lane5_rx_eye_hgt;
    u32 lnk0_lane6_rx_eye_hgt;
    u32 lnk1_lane6_rx_eye_hgt;
    u32 lnk2_lane6_rx_eye_hgt;
    u32 lnk3_lane6_rx_eye_hgt;
    u32 lnk0_lane7_rx_eye_hgt;
    u32 lnk1_lane7_rx_eye_hgt;
    u32 lnk2_lane7_rx_eye_hgt;
    u32 lnk3_lane7_rx_eye_hgt;
    u32 lnk0_lane8_rx_eye_hgt;
    u32 lnk1_lane8_rx_eye_hgt;
    u32 lnk2_lane8_rx_eye_hgt;
    u32 lnk3_lane8_rx_eye_hgt;
    u32 lnk0_lane9_rx_eye_hgt;
    u32 lnk1_lane9_rx_eye_hgt;
    u32 lnk2_lane9_rx_eye_hgt;
    u32 lnk3_lane9_rx_eye_hgt;
    u32 lnk0_lanea_rx_eye_hgt;
    u32 lnk1_lanea_rx_eye_hgt;
    u32 lnk2_lanea_rx_eye_hgt;
    u32 lnk3_lanea_rx_eye_hgt;
    u32 lnk0_laneb_rx_eye_hgt;
    u32 lnk1_laneb_rx_eye_hgt;
    u32 lnk2_laneb_rx_eye_hgt;
    u32 lnk3_laneb_rx_eye_hgt;
    u32 lnk0_lanec_rx_eye_hgt;
    u32 lnk1_lanec_rx_eye_hgt;
    u32 lnk2_lanec_rx_eye_hgt;
    u32 lnk3_lanec_rx_eye_hgt;
    u32 lnk0_laned_rx_eye_hgt;
    u32 lnk1_laned_rx_eye_hgt;
    u32 lnk2_laned_rx_eye_hgt;
    u32 lnk3_laned_rx_eye_hgt;
    u32 lnk0_lanee_rx_eye_hgt;
    u32 lnk1_lanee_rx_eye_hgt;
    u32 lnk2_lanee_rx_eye_hgt;
    u32 lnk3_lanee_rx_eye_hgt;
    u32 lnk0_lanef_rx_eye_hgt;
    u32 lnk1_lanef_rx_eye_hgt;
    u32 lnk2_lanef_rx_eye_hgt;
    u32 lnk3_lanef_rx_eye_hgt;
    u32 lnk0_lane0_patrn_ctrl;
    u32 lnk1_lane0_patrn_ctrl;
    u32 lnk2_lane0_patrn_ctrl;
    u32 lnk3_lane0_patrn_ctrl;
    u32 lnk0_lane1_patrn_ctrl;
    u32 lnk1_lane1_patrn_ctrl;
    u32 lnk2_lane1_patrn_ctrl;
    u32 lnk3_lane1_patrn_ctrl;
    u32 lnk0_lane2_patrn_ctrl;
    u32 lnk1_lane2_patrn_ctrl;
    u32 lnk2_lane2_patrn_ctrl;
    u32 lnk3_lane2_patrn_ctrl;
    u32 lnk0_lane3_patrn_ctrl;
    u32 lnk1_lane3_patrn_ctrl;
    u32 lnk2_lane3_patrn_ctrl;
    u32 lnk3_lane3_patrn_ctrl;
    u32 lnk0_lane4_patrn_ctrl;
    u32 lnk1_lane4_patrn_ctrl;
    u32 lnk2_lane4_patrn_ctrl;
    u32 lnk3_lane4_patrn_ctrl;
    u32 lnk0_lane5_patrn_ctrl;
    u32 lnk1_lane5_patrn_ctrl;
    u32 lnk2_lane5_patrn_ctrl;
    u32 lnk3_lane5_patrn_ctrl;
    u32 lnk0_lane6_patrn_ctrl;
    u32 lnk1_lane6_patrn_ctrl;
    u32 lnk2_lane6_patrn_ctrl;
    u32 lnk3_lane6_patrn_ctrl;
    u32 lnk0_lane7_patrn_ctrl;
    u32 lnk1_lane7_patrn_ctrl;
    u32 lnk2_lane7_patrn_ctrl;
    u32 lnk3_lane7_patrn_ctrl;
    u32 lnk0_lane8_patrn_ctrl;
    u32 lnk1_lane8_patrn_ctrl;
    u32 lnk2_lane8_patrn_ctrl;
    u32 lnk3_lane8_patrn_ctrl;
    u32 lnk0_lane9_patrn_ctrl;
    u32 lnk1_lane9_patrn_ctrl;
    u32 lnk2_lane9_patrn_ctrl;
    u32 lnk3_lane9_patrn_ctrl;
    u32 lnk0_lanea_patrn_ctrl;
    u32 lnk1_lanea_patrn_ctrl;
    u32 lnk2_lanea_patrn_ctrl;
    u32 lnk3_lanea_patrn_ctrl;
    u32 lnk0_laneb_patrn_ctrl;
    u32 lnk1_laneb_patrn_ctrl;
    u32 lnk2_laneb_patrn_ctrl;
    u32 lnk3_laneb_patrn_ctrl;
    u32 lnk0_lanec_patrn_ctrl;
    u32 lnk1_lanec_patrn_ctrl;
    u32 lnk2_lanec_patrn_ctrl;
    u32 lnk3_lanec_patrn_ctrl;
    u32 lnk0_laned_patrn_ctrl;
    u32 lnk1_laned_patrn_ctrl;
    u32 lnk2_laned_patrn_ctrl;
    u32 lnk3_laned_patrn_ctrl;
    u32 lnk0_lanee_patrn_ctrl;
    u32 lnk1_lanee_patrn_ctrl;
    u32 lnk2_lanee_patrn_ctrl;
    u32 lnk3_lanee_patrn_ctrl;
    u32 lnk0_lanef_patrn_ctrl;
    u32 lnk1_lanef_patrn_ctrl;
    u32 lnk2_lanef_patrn_ctrl;
    u32 lnk3_lanef_patrn_ctrl;
} XHmc;

extern void hmc_loopback( u32 link_speed);
extern void hmc_read_menu();
extern void hmc_write_menu();
extern void stdin_read(char *s, int len);
extern void rw_interface();
extern void hmc_id();
extern u32 hmc_rd_wr(char *rw,char *regstr,u32 addr, u32 data);
extern int hmc_rst_iicmux();
extern int hmc_init_iicmux();
extern int hmc_read4(u32 hmc_cfgaddr, u8 *BufferPtr);
extern int hmc_write4(u32 hmc_cfgaddr, u32 hmc_cfgdata);
extern u32 hmc_rd_wr(char *rw,char *regstr,u32 addr, u32 data);
extern void rw_interface();
extern void hmc_lane_eye_data();
extern void hmc_pattern_data(char *rw, u32 hmc_cfgdata);
extern void hmc_set_prbs_checker();

// I2C Basic Routines
extern int Iic_init(u16 iic_device_id);
extern int write_mux(u8 Addr, u8 Port);

//vcu109 HMC gpios
extern int hmc_gpio_init();
extern int gpio_read(XGpio GpioDevice, int Channel);
extern int gpio_write(XGpio GpioDevice, u32 bitmask, u32 value);
extern void XIic_SetGPO(u32 gpo);
extern void XIic_ClearGPO(u32 gpo);

//VCU109 HMC clock setup
extern int si5328_set_freq_125_187or375MHz(u32 linkspeed);

//misc routines for user input
extern void vt100_erase();
extern void stdin_read(char *s, int len);
extern u32 char2hex(const char * s);
extern char inbyte(void );

//interrupts
static int SetupInterruptSystem(XIic *IicInstPtr);
static int DisableInterruptSystem(XIic *IicInstPtr);
static void SendHandler(XIic *InstancePtr);
static void ReceiveHandler(XIic *InstancePtr);
static void StatusHandler(XIic *InstancePtr, int Event);
extern void GpioDriverHandler(void *CallBackRef);

extern int sys_errno;
extern char sys_errmsg[20][80];
extern int si5328_init_iicmux();


//#define printf xil_printf
//#define sscanf sscanf


