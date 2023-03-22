/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "sleep.h"
#include "dma_intr.h"
#include "sys_intr.h"
#include "xparameters.h"

static XScuGic Intc; //GIC
static  XAxiDma AxiDma;

u32 *TxBufferPtr= (u32 *)TX_BUFFER_BASE;
u32 *RxBufferPtr=(u32 *)RX_BUFFER_BASE;

extern volatile int TxDone;
extern volatile int RxDone;

int init_intr_system(void);
int pl_acc_test(int);

int main()
{
    init_platform();
    print("UART OK!\n\r");
    init_intr_system();
    print("System Initiate OK!\n\r");

    while(1){
    //0:~, 1:+1, default:+0
    pl_acc_test(2);
    print("Test End!\n\r");
    sleep(1);
    }

    cleanup_platform();

    return 0;
}

int init_intr_system(void)
{
	DMA_Intr_Init(&AxiDma,0);// initial DMA interrupt system
	Init_Intr_System(&Intc); //initial interrupt system
	Setup_Intr_Exception(&Intc);
	DMA_Setup_Intr_System(&Intc,&AxiDma,TX_INTR_ID,RX_INTR_ID);//setup dma interrpt system
	DMA_Intr_Enable(&Intc,&AxiDma);
	return 0;
}

int pl_acc_test(int mode)
{
	// initiate
	int Status;
	TxDone = 0;
	RxDone = 0;
	int Index;
	int Len = 128;

	xil_printf("\r\n----DMA Test----\r\n");
	xil_printf("Len=%d\r\n",Len);

	//config the reg0 in pl processor
	//0:~, 1:+1, default:+0
	Xil_Out32(XPAR_MYIP_0_S00_AXI_BASEADDR, mode);

	// set TX data
	for(Index = 0; Index < Len; Index ++) {
		TxBufferPtr[Index] = Index;
	}
	xil_printf("TX data ready!\r\n");

	// TX data to DMA
	Xil_DCacheFlushRange((u32)TxBufferPtr, Len);
	Status = XAxiDma_SimpleTransfer(&AxiDma,(u32) TxBufferPtr,
			Len, XAXIDMA_DMA_TO_DEVICE);
	if (Status != XST_SUCCESS) {
		xil_printf("TX data to DMA Fail!\r\n");
		return XST_FAILURE;

	}
	// Wait util complete
	while(TxDone == 0);
	xil_printf("TX data to DMA OK!\r\n");

	// DMA data to RX
	Status = XAxiDma_SimpleTransfer(&AxiDma,(u32) RxBufferPtr,
				Len, XAXIDMA_DEVICE_TO_DMA);
	if (Status != XST_SUCCESS) {
		xil_printf("DMA data to RX Fail!\r\n");
		return XST_FAILURE;
	}	
#ifndef __aarch64__
	Xil_DCacheInvalidateRange((u32)RxBufferPtr, Len);
#endif
	// Wait util complete
	while(RxDone == 0);
	xil_printf("DMA data to RX OK!\r\n");

	return 0;
}
