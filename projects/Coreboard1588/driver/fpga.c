/**
  ******************************************************************************
  * @file    fpga.c
  * @author  Niantong Du
  * @brief   This file provides code for the configuration of FPGA device.
  ******************************************************************************
  * @attention
  *
  * <h2><center>&copy; Copyright (c) 2020 Chengdu JinZhiLi Technology Co., Ltd.
  * All rights reserved.</center></h2>
  *
  ******************************************************************************
  */


/* Includes ------------------------------------------------------------------*/
#include "fpga.h"


/* Data ----------------------------------------------------------------------*/
uint16_t fmc_buff [40];


/* Exported functions --------------------------------------------------------*/

/**
  * @brief GPIO EXTI Callback function
  * @param GPIO_Pin : The pin number triggered the EXTI
  * @retval none
  */
void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin)
{
  if (GPIO_Pin == GPIO_PIN_10)
  {
    HAL_SRAM_Read_16b(&hsram1, (uint32_t *)0x68000000, fmc_buff, 40);
    // printf("%d\r\n", ((int16_t)(fmc_buff[4])));
  }
}


/**
  * @brief Write a register inside FPGA.
  * @param addr    : Address of register on AXI bus
  * @param data    : Data to be write to AXI bus
  * @retval        : 0 if success, other of error
  */
void FPGA_WriteReg(uint32_t addr, uint32_t data)
{
  uint8_t buff[7];
  HAL_StatusTypeDef Status;

  // Build the transmit buffer
  buff[0] = (addr >> 10) & 0x7F | 0x80;
  buff[1] = addr >> 2;
  buff[2] = 0x0; // Dummy byte
  buff[3] = data >> 24;
  buff[4] = data >> 16;
  buff[5] = data >> 8;
  buff[6] = data;

  Status = HAL_SPI_Transmit(&hspi1, buff, 7, 100);
  if (Status != HAL_OK)
  {
    printf("HAL_SPI_Trnsmit error!\r\n");
  }

  return;
}


/**
  * @brief Read a register inside FPGA.
  * @param addr    : Address of register on AXI bus
  * @param data    : Pointer to data to save the data to
  * @retval        : 0 if success, other if error
  */
void FPGA_ReadReg(uint32_t addr, uint32_t *data)
{
  uint8_t buff[7];
  HAL_StatusTypeDef Status;

  buff[0] = (addr >> 10) & 0x7F;
  buff[1] = addr >> 2;

  Status = HAL_SPI_TransmitReceive(&hspi1, buff, buff, 7, 100);
  if (Status != HAL_OK)
  {
    printf("HAL_SPI_TransmitRecivied error!\r\n");
  }

  *data = 0;
  *data = (buff[3] << 24) | (buff[4] << 16) | (buff[5] << 8) | buff[6];
  return;
}


/**
  * @brief Perform soft reset of FPGA. This is done by simply toggle soft reset
  *        pin of reset FPGA.
  * @retval none
  */
void FPGA_Reset(void)
{
  HAL_GPIO_WritePin(FPGA_RESET_GPIO, FPGA_RESET_PIN, FPGA_RESET);
  HAL_Delay(1);
  HAL_GPIO_WritePin(FPGA_RESET_GPIO, FPGA_RESET_PIN, FPGA_UNRESET);
}


/**
  * @brief Do simple self test of FPGA register access
  * @retval 0 if success, other if error
  */
int FPGA_SelfTest(void)
{
  uint32_t result;
  FPGA_WriteReg(FPGA_AXI_TOP_SCRATCH, 0xAA55AA55);
  FPGA_ReadReg(FPGA_AXI_TOP_SCRATCH, &result);

  if (result != 0xAA55AA55)
  {
    printf("FPGA_SelfTest fail!\r\n");
    return -1;
  }

  return 0;
}

/**
  * @brief Initialize FPGA and downstream devices
  * @retval 0 if success, other if error
  */
int FPGA_Init(void)
{
  int Status;

  FPGA_Reset();
  Status = FPGA_SelfTest();
  if (Status != 0)
  {
    printf("FPGA initialize fail!\r\n");
  }

  /* Initialize ADS124x */

  // Soft reset of core
  FPGA_WriteReg(FPGA_AXI_ADS124X_SOFTRESET, 1);
  HAL_Delay(1);
  FPGA_WriteReg(FPGA_AXI_ADS124X_SOFTRESET, 0);

  // Ensure OPMODE is 0 (manual mode)
  FPGA_WriteReg(FPGA_AXI_ADS124X_OPMODE, 0);

  // Ensure START pin is 1 (SPI access is OK)
  FPGA_WriteReg(FPGA_AXI_ADS124X_ADSTART, 1);

  // Write ADS124x Registers

  // IDAC0, set IMAG = 0b100 (500uA)
  FPGA_ADS124x_WriteReg(0x0A, 0x4);
  // IDAC1, set I1DIR = 0b0011 (AIN3)
  FPGA_ADS124x_WriteReg(0x0B, 0x3F);

  // Set OPMODE is 1 (auto mode)
  FPGA_WriteReg(FPGA_AXI_ADS124X_OPMODE, 1);

  /* Initialize ADS868x */

  FPGA_WriteReg(FPGA_AXI_ADS868X_SOFTRESET, 1);
  HAL_Delay(1);
  FPGA_WriteReg(FPGA_AXI_ADS868X_SOFTRESET, 0);

  // Set MUXEN to all 1
  FPGA_WriteReg(FPGA_AXI_ADS868X_EXTMUXEN, 0xF);

  // Set AUTOSPI to 1, this enables FMC IRQ
  FPGA_WriteReg(FPGA_AXI_ADS868X_AUTOSPI, 1);

  return 0;
}


/* Private functions --------------------------------------------------------*/

/**
  * @brief Transmit and Receive a SPI frame to ADS124x
  * @param    nbyte : Number of byte to transmit and receive, max 4
  * @param    txdata: Data to be transmit, is nbyte is less than 4, LSByte is
  *                   transmitted. MSBit is transfer first.
  * @param    rxdata: Data received at SPI line.
  * @retval   None
  */
void FPGA_ADS124x_SPITransRecv(uint8_t nbyte, uint32_t txdata, uint32_t *rxdata)
{
  uint32_t result;

  // Write TXDATA/TXBYTE registers
  FPGA_WriteReg(FPGA_AXI_ADS124X_SPITXBYTE, nbyte - 1);
  FPGA_WriteReg(FPGA_AXI_ADS124X_SPITXDATA, txdata);

  // Wait 1 ms, assume SPI operation is done
  HAL_Delay(1);

  // Read RXDATA register
  FPGA_ReadReg(FPGA_AXI_ADS124X_SPIRXDATA, &result);

  if (rxdata != NULL)
  {
    *rxdata = result;
  }

  return;
}


/**
  * @brief Get sample data from ADS124x
  * @param    data: Pointer to sampled data.
  * @retval   None
  */
void FPGA_ADS124x_GetData(uint32_t *data)
{
  uint32_t result;
  FPGA_ADS124x_SPITransRecv(3, 0x00FFFFFFUL, &result);

  if (data != NULL)
  {
    *data = result;
  }

  return;
}


/**
  * @brief Write ADS124x internal register
  * @param    addr: ADS124x Register address
  * @param    data: ADS124x Register value
  * @retval   None
  */
void FPGA_ADS124x_WriteReg(uint8_t addr, uint8_t data)
{
  uint32_t txdata;

  txdata = 0x00400000 | ((addr & 0xF) << 16) | data;
  FPGA_ADS124x_SPITransRecv(3, txdata, NULL);

  return;
}


/**
  * @brief Write ADS124x internal register
  * @param    addr: ADS124x Register address
  * @param    data: ADS124x Register value
  * @retval       : 0 if success, other if error
  */
void FPGA_ADS124x_ReadReg(uint8_t addr, uint8_t *data)
{
  uint32_t txdata;
  uint32_t rxdata;

  txdata = 0x002000FF | ((addr & 0xF) << 16);
  FPGA_ADS124x_SPITransRecv(3, txdata, &rxdata);

  if (data != NULL)
  {
    *data = rxdata & 0xFF;
  }

  return;
}
