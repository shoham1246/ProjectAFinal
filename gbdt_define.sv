/*------------------------------------------------------------------------------
 * File          : gbdt_define.v
 * Project       : RTL
 * Author        : ephssm
 * Creation date : Oct 5, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

// gbdt Registers address.
`define GBDT_RAM_ADDR_ADDR  8'h00
`define GBDT_RAM_DATA_ADDR  8'h01
`define GBDT_SEL_ADDR		8'h02
`define GBDT_START_ADDR     8'h03
`define GBDT_USEDCLASS_ADDR  8'h04
`define REG_MAX_CLASS		8'h05
`define REG_MAX_SCORE		8'h06




// Transport Clock Generator
`define GBDTCLK_PERIOD  5


// APB PARAMS
 `define ADDR_WIDTH 8
 `define DATA_WIDTH 32
 
 //RAM PARAMS
 `define RAM_ADDR_WIDTH 14
 `define RAM_DATA_WIDTH 32

 
//ARCHITECTURE PARAMS
`define RESULT_WIDTH 32
`define MAX_CLASS_WIDTH 5

//DMA PARAMS
`define DMA_RATE 144 ///should be 9*2^something, add in report
`define CYCLES_NUM (9 * 256) / `DMA_RATE //we currently assume that DMA_RATE must be a multiply...
`define DMA_BITS_NUM   $clog2(`CYCLES_NUM)

`define just_started_d 8