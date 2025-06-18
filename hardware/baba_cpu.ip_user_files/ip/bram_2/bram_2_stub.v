// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.1 (win64) Build 3865809 Sun May  7 15:05:29 MDT 2023
// Date        : Wed Dec 25 11:20:36 2024
// Host        : LAPTOP-MQUPHI73 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub -rename_top bram_2 -prefix
//               bram_2_ bram_2_stub.v
// Design      : bram_2
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_6,Vivado 2023.1" *)
module bram_2(clka, wea, addra, dina, clkb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="wea[0:0],addra[14:0],dina[7:0],addrb[14:0],doutb[7:0]" */
/* synthesis syn_force_seq_prim="clka" */
/* synthesis syn_force_seq_prim="clkb" */;
  input clka /* synthesis syn_isclock = 1 */;
  input [0:0]wea;
  input [14:0]addra;
  input [7:0]dina;
  input clkb /* synthesis syn_isclock = 1 */;
  input [14:0]addrb;
  output [7:0]doutb;
endmodule
