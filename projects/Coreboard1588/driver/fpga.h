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
	uint16_t triggered;         /* Tirgger is issued before this sample point */
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
#define FPGA_AXI_TOP_RTC_MODE           (FPGA_AXI_TOP + (0x00000040UL))
#define FPGA_AXI_TOP_RTC_SET_SECOND     (FPGA_AXI_TOP + (0x00000044UL))
#define FPGA_AXI_TOP_RTC_SET_NANOSECOND (FPGA_AXI_TOP + (0x00000048UL))
#define FPGA_AXI_TOP_RTC_SET            (FPGA_AXI_TOP + (0x0000004CUL))
#define FPGA_AXI_TOP_RTC_GET            (FPGA_AXI_TOP + (0x00000050UL))
#define FPGA_AXI_TOP_RTC_GET_SECOND     (FPGA_AXI_TOP + (0x00000054UL))
#define FPGA_AXI_TOP_RTC_GET_NANOSECOND (FPGA_AXI_TOP + (0x00000058UL))
#define FPGA_AXI_TOP_TRIGGER_ENABLE     (FPGA_AXI_TOP + (0x00000080UL))
#define FPGA_AXI_TOP_TRIGGER_SROUCE     (FPGA_AXI_TOP + (0x00000084UL))
#define FPGA_AXI_TOP_TRIGGER_SECOND     (FPGA_AXI_TOP + (0x00000088UL))
#define FPGA_AXI_TOP_TRIGGER_NANOSECOND (FPGA_AXI_TOP + (0x0000008CUL))
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

/** @defgroup FPGA_RTC_Mode  FPGA RTC Mode
  * @{
  */
#define FPGA_RTC_MODE_NORMAL            (0x00000000UL) /* External PPS input is ignored */
#define FPGA_RTC_MODE_PPS               (0x00000001UL) /* RTC is sync with external PPS */
/**
  * @}
  */

/** @defgroup FPGA_Trigger_Enable  FPGA Trigger Enable
  * @{
  */
#define FPGA_TRIGGER_ENABLE             (0x00000001UL)
#define FPGA_TRIGGER_DISABLE            (0x00000000UL)
/**
  * @}
  */

/** @defgroup FPGA_Trigger_Source  FPGA Trigger Source
  * @{
  */
#define FPGA_TRIGGER_SOURCE_MCU         (0x00000000UL) /* Trigger by MCU pin */
#define FPGA_TRIGGER_SOURCE_EXT         (0x00000001UL) /* Trigger by EXT pin */
#define FPGA_TRIGGER_SOURCE_RTC         (0x00000003UL) /* Trigger RTC time */
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

void FPGA_Get_ProductId(uint32_t *id);
void FPGA_Get_Version(uint32_t *version);

void FPGA_Get_RtcMode(uint8_t *mode);
void FPGA_Set_RtcMode(uint8_t mode);
void FPGA_Get_RtcTime(uint32_t *second, uint32_t *nanosecond);
void FPGA_Set_RtcTime(uint32_t second, uint32_t nanosecond);

void FPGA_Set_TirggerEnable(uint8_t enable);
void FPGA_Set_TirggerSource(uint8_t source);
void FPGA_Set_TirggerRtcTime(uint32_t second, uint32_t nanosecond);
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
