/**
  ******************************************************************************
  * @file    fpga.h
  * @author  Niantong Du
  * @brief   Header file of FPGA driver module.
  ******************************************************************************
  * @attention
  *
  * <h2><center>&copy; Copyright (c) 2020 Chengdu JinZhiLi Technology Co., Ltd.
  * All rights reserved.</center></h2>
  *
  ******************************************************************************
  */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __FPGA_H
#define __FPGA_H

#ifdef __cplusplus
 extern "c" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "fmc.h"
#include "spi.h"
#include <stdio.h>

/** @defgroup FPGA_Driver
  * @{
  */

/* Exported types ------------------------------------------------------------*/
/** @defgroup FPGA_Exported_Types FPGA Exported Types
  * @{
  */

/**
  * @brief  FPGA FMC buffer structure definition
  */
typedef struct
{
    uint32_t Second;            /* Sample second value */
    uint32_t Nanosecond;        /* Sample nanosecond value */
    uint16_t PCH_data[16];      /* PCH data from channel 0 to channel 15 */
    uint16_t TCH_data[16];      /* TCH data from channel 0 to channel 15 */
    uint32_t PT100[2];          /* PT100 data from channel 0 to channel 1 */
} FPGA_FMCBufferTypeDef;

/**
  * @}
  */

/* Exported constants --------------------------------------------------------*/

/** @defgroup FPGA_Exported_Constants FPGA Exported Constants
  * @{
  */

/** @defgroup FPGA_GPIO_GROUP FPGA GPIO Group
  * @{
  */
#define FPGA_RESET_GPIO GPIOC
/**
  * @}
  */

/** @defgroup FPGA_GPIO_GROUP FPGA GPIO Group
  * @{
  */
#define FPGA_RESET_PIN  GPIO_PIN_10
/**
  * @}
  */

/** @defgroup FPGA_Reset_Value  FPGA Reset Pin Value
  * @{
  */
#define FPGA_RESET   GPIO_PIN_RESET
#define FPGA_UNRESET GPIO_PIN_SET
/**
  * @}
  */


/** @defgroup FPGA_Module_Base  FPGA Module Base Address
  * @{
  */
#define FPGA_AXI_TOP                    (0x00000000UL)
#define FPGA_AXI_QUAD_SPI               (0x00000400UL)
#define FPGA_AXI_BRAM_CTRL              (0x00000800UL)
#define FPGA_AXI_ADS868X                (0x00000C00UL)
#define FPGA_AXI_ADS124X                (0x00001000UL)
/**
  * @}
  */


/** @defgroup FPGA_AXI_TOP_Register FPGA AXI Top Module Register Address
  * @{
  */
#define FPGA_AXI_TOP_PRODUCT_ID         (FPGA_AXI_TOP + (0x00000004UL))
#define FPGA_AXI_TOP_VERSION            (FPGA_AXI_TOP + (0x00000008UL))
#define FPGA_AXI_TOP_BUILD_DATA         (FPGA_AXI_TOP + (0x0000000CUL))
#define FPGA_AXI_TOP_BUILD_TIME         (FPGA_AXI_TOP + (0x00000010UL))
#define FPGA_AXI_TOP_SCRATCH            (FPGA_AXI_TOP + (0x00000020UL))
/**
  * @}
  */


/** @defgroup FPGA_AXI_ADS868X_Register FPGA AXI_ADS868x Module Register Address
  * @{
  */
#define FPGA_AXI_ADS868X_SOFTRESET      (FPGA_AXI_ADS868X + (0x00000000UL))
#define FPGA_AXI_ADS868X_POWERDOWN      (FPGA_AXI_ADS868X + (0x00000004UL))
#define FPGA_AXI_ADS868X_AUTOSPI        (FPGA_AXI_ADS868X + (0x00000008UL))
#define FPGA_AXI_ADS868X_EXTMUXSEL      (FPGA_AXI_ADS868X + (0x0000000CUL))
#define FPGA_AXI_ADS868X_EXTMUXEN       (FPGA_AXI_ADS868X + (0x00000010UL))
#define FPGA_AXI_ADS868X_SPITXBYTE      (FPGA_AXI_ADS868X + (0x00000014UL))
#define FPGA_AXI_ADS868X_SPITXDATA      (FPGA_AXI_ADS868X + (0x00000018UL))
#define FPGA_AXI_ADS868X_SPIRXDATA      (FPGA_AXI_ADS868X + (0x0000001CUL))
#define FPGA_AXI_ADS868X_SPIRXVALID     (FPGA_AXI_ADS868X + (0x00000020UL))
/**
  * @}
  */


/** @defgroup FPGA_AXI_ADS124X_Register FPGA AXI_ADS124X Module Register Address
  * @{
  */
#define FPGA_AXI_ADS124X_SOFTRESET      (FPGA_AXI_ADS124X + (0x00000000UL))
#define FPGA_AXI_ADS124X_OPMODE         (FPGA_AXI_ADS124X + (0x00000004UL))
#define FPGA_AXI_ADS124X_ADSTART        (FPGA_AXI_ADS124X + (0x00000008UL))
#define FPGA_AXI_ADS124X_ADRESET        (FPGA_AXI_ADS124X + (0x0000000CUL))
#define FPGA_AXI_ADS124X_ADDRDY         (FPGA_AXI_ADS124X + (0x00000010UL))
#define FPGA_AXI_ADS124X_SPITXBYTE      (FPGA_AXI_ADS124X + (0x00000014UL))
#define FPGA_AXI_ADS124X_SPITXDATA      (FPGA_AXI_ADS124X + (0x00000018UL))
#define FPGA_AXI_ADS124X_SPIRXDATA      (FPGA_AXI_ADS124X + (0x0000001CUL))
#define FPGA_AXI_ADS124X_SPIRXVALID     (FPGA_AXI_ADS124X + (0x00000020UL))
/**
  * @}
  */

/**
  * @}
  */


/* Exported functions --------------------------------------------------------*/

/** @defgroup FPGA_Exported_Functions FPGA Exported Functions
  * @{
  */
void FPGA_WriteReg(uint32_t addr, uint32_t data);
void FPGA_ReadReg(uint32_t addr, uint32_t *data);
void FPGA_Reset(void);
int  FPGA_SelfTest(void);
int  FPGA_Init(void);
/**
  * @}
  */


/* Private functions --------------------------------------------------------*/

/** @defgroup FPGA_Private_Functions FPGA Private Functions
  * @{
  */
void FPGA_ADS124x_SPITransRecv(uint8_t nbyte, uint32_t txdata, uint32_t *rxdata);
void FPGA_ADS124x_GetData(uint32_t *data);
void FPGA_ADS124x_WriteReg(uint8_t addr, uint8_t data);
void FPGA_ADS124x_ReadReg(uint8_t addr, uint8_t *data);
/**
  * @}
  */


#ifdef __cplusplus
 }
#endif
#endif /* __FPGA_H */
