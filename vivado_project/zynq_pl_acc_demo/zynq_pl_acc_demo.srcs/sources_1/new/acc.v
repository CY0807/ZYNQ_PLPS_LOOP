`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/21 09:08:21
// Design Name: 
// Module Name: acc
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

//template

/* acc acc_inst(
    .clk(pl_clk),
    .M_AXIS_MM2S_0_tdata(M_AXIS_MM2S_0_tdata),
    .M_AXIS_MM2S_0_tkeep(M_AXIS_MM2S_0_tkeep),
    .M_AXIS_MM2S_0_tlast(M_AXIS_MM2S_0_tlast),
    .M_AXIS_MM2S_0_tready(M_AXIS_MM2S_0_tready),
    .M_AXIS_MM2S_0_tvalid(M_AXIS_MM2S_0_tvalid),    
    .S_AXIS_S2MM_0_tdata(S_AXIS_S2MM_0_tdata),
    .S_AXIS_S2MM_0_tkeep(S_AXIS_S2MM_0_tkeep),
    .S_AXIS_S2MM_0_tlast(S_AXIS_S2MM_0_tlast),
    .S_AXIS_S2MM_0_tready(S_AXIS_S2MM_0_tready),
    .S_AXIS_S2MM_0_tvalid(S_AXIS_S2MM_0_tvalid),
    .mm2s_prmry_reset_out_n_0(mm2s_prmry_reset_out_n_0),    
    .s2mm_prmry_reset_out_n_0(s2mm_prmry_reset_out_n_0),    
    .reg0_0(reg0_0)
    ); */
