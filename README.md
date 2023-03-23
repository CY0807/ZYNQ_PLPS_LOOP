# ZYNQ_PLPS_LOOP

摘要：在ZYNQ中设计了自定义的PL端数据处理器，通过DMA连接到AXI总线，完成了PS和该PL端的数据交互等功能。

开发板型号：Zynq-7000 SoC XC7Z305 FPGA

开发平台：Vivado 2019.1； Vivado SDK 2019.1

## 1 文件描述：

（1）vivado_project存放了vivado和sdk原始工程文件

（2）c_project_demo存放了sdk工程中所用的核心代码

（3）image中存放了项目运行中间过程的重要截图

## 2 硬件设计

Block Design如图所示：

![block design](https://user-images.githubusercontent.com/95362898/227087287-836e9278-493c-4f0f-ace3-e81e4ec11c0d.PNG)

（1）例化了vivado库的AXI DMA挂在ZYNQ的AXI4 HP总线上，并将DMA的两个AXI4-Stream输入输入出接口引到Block Design的接口上，这两个接口在Block Design的上层模块中与自定义设计的PL端数据处理器连接，实现PS端与自定义PL端的大批量数据流交互。

（2）例化了自定义的AXI-Lite外设（图中为myip）含有4个32位寄存器，可供PS端寻址并进行读写，并将myip中的一个寄存器引出到Block Design的接口上，在上层模块中与PL端连接作为PL端的配置寄存器。此外，在PL端中也设置了中断输出intr可通过myip外设输入到PS中断。

（3）DMA的两路中断输出也连接到了PS的中断输入口，分别在DMA<搬数据从DDR到外设>、<搬数据从外设到DDR>完成时引发中断。

PS端通过配置寄存器控制着DMA的传输方向、坐标和开始，在AXI DMA的两个接口上例化了system ila用于观察波形，得到有PS到PL传输、PL到PS传输的波形图如下所示：

![PS2PL](https://user-images.githubusercontent.com/95362898/227091570-ca13e28f-04bf-4b47-8551-07263b43a1d1.PNG)

![PL2PS](https://user-images.githubusercontent.com/95362898/227091597-aa894cc1-a096-4417-857f-0cfcf56e8f55.PNG)

有意思的是，笔者发现无论怎么调试，PL到PS的传输中，即使PS端没有发起请求，DMA也会自动的发送从PL端接收数据的请求，且只接受4 Word的数据量，但这并不影响最终逻辑结果，个人猜测这4 Word存在DMA的buffer中，当PS发起请求时才会从DMA的buffer传输到DDR3中。

PL端外设的核心代码如下

````
module acc(
    input clk,

    input wire [31:0]M_AXIS_MM2S_0_tdata,
    input wire [3:0]M_AXIS_MM2S_0_tkeep,
    input wire M_AXIS_MM2S_0_tlast,
    output wire M_AXIS_MM2S_0_tready,
    input wire M_AXIS_MM2S_0_tvalid,
    
    output wire [31:0]S_AXIS_S2MM_0_tdata,
    output wire [3:0]S_AXIS_S2MM_0_tkeep,
    output wire S_AXIS_S2MM_0_tlast,
    input wire S_AXIS_S2MM_0_tready,
    output wire S_AXIS_S2MM_0_tvalid,
    
    input wire mm2s_prmry_reset_out_n_0,    
    input wire s2mm_prmry_reset_out_n_0,
    
    input wire [31:0]reg0_0
    );

wire empty, full, almost_empty, almost_full, valid, rd_en, wr_en, srst;
wire [31:0] din, dout;
wire [8:0] data_count;

// MM2S
assign S_AXIS_S2MM_0_tdata = dout;
assign S_AXIS_S2MM_0_tkeep = 4'b1111;
assign S_AXIS_S2MM_0_tvalid = valid;
assign S_AXIS_S2MM_0_tlast = almost_empty & (~empty);

// S2MM
assign M_AXIS_MM2S_0_tready = ~almost_full;

// FIFO
assign srst = ~(mm2s_prmry_reset_out_n_0 | s2mm_prmry_reset_out_n_0);
assign wr_en = M_AXIS_MM2S_0_tready & M_AXIS_MM2S_0_tvalid;
assign din = M_AXIS_MM2S_0_tdata;
assign rd_en = S_AXIS_S2MM_0_tready & S_AXIS_S2MM_0_tvalid;
    
fifo_generator_0 fifo0 (
  .clk(clk),                    // input wire clk
  .srst(srst),                  // input wire srst
  .din(din),                    // input wire [31 : 0] din
  .wr_en(wr_en),                // input wire wr_en
  .rd_en(rd_en),                // input wire rd_en
  .dout(dout),                  // output wire [31 : 0] dout
  .full(full),                  // output wire full
  .empty(empty),                // output wire empty
  .almost_empty(almost_empty),  // output wire almost_empty
  .almost_full(almost_full),
  .valid(valid),                // output wire valid
  .data_count(data_count)      // output wire [8 : 0] data_count
);    
    
endmodule

````

## 3 软件设计

在Vivado SDK中设计了C语言裸机程序，可以通过配置寄存器来控制DMA的传输长度、坐标、方向，同时也编写了DMA完成传输的中断函数，反映在main函数中为RxDone和TxDone变量，分别表示<外设到DDR>和<DDR到外设>传输的完成，主体部分如下所示。

````
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
````

其中在DDR中TxBuffer和RxBuffer的地址分别是0x01100000和0x01300000，在SDK中观察两地址的Memory如下：

（1）传输开始前：这片地址的数据是随机未知的

![memory1](https://user-images.githubusercontent.com/95362898/227094169-81b2819b-21ed-4466-8292-404b659a2177.PNG)

（2）TX传输后：首先通过PS端对TxBuffer数据进行赋值，再通过DMA传输到PL端

![memory2 ](https://user-images.githubusercontent.com/95362898/227094182-8311f947-7ce8-4602-ba23-d31568088482.PNG)

（3）TX传输后：PL端接收到数据后，在PS端的控制下通过DMA将处理的结果传输到RxBuffer，本demo对数据处理的方式是保持不变

![memory3](https://user-images.githubusercontent.com/95362898/227094194-8ed80756-60c7-47e6-acb7-574502446ad8.PNG)

