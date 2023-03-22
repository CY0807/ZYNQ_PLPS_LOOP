`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/15 21:06:28
// Design Name: 
// Module Name: processor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module processor
(
    input clk,
    input rst_n,
    
    input [31:0] reg0,
    input fifo_rden,
    input fifo_wren,
    input  [31:0] fifo_wr_data,
    output [31:0] fifo_rd_data,
    output intr,
    output empty,
    output [9:0] data_count
);

reg [31:0] din;
reg wr_en;


always@(posedge clk) begin
    wr_en <= fifo_wren;
    if(reg0 == 0) 
        din <= ~fifo_wr_data;
    else if(reg0 == 1)
        din <= fifo_wr_data + 1;
    else
        din <= fifo_wr_data;
end

fifo_generator_0 your_instance_name (
  .clk(clk),      // input wire clk
  .srst(~rst_n),    // input wire srst
  .din(din),      // input wire [31 : 0] din
  .wr_en(wr_en),  // input wire wr_en
  .rd_en(fifo_rden),  // input wire rd_en
  .dout(fifo_rd_data),    // output wire [31 : 0] dout
  .full(),    // output wire full
  .empty(empty0),  // output wire empty
  .data_count(data_count)  // output wire [9 : 0] data_count
);

endmodule
