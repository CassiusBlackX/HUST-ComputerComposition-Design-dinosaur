module double_frame_buffer (input rst,
                            input a_clk,
                            input a_wr,
                            input [10:0] a_addr,
                            input [31:0] a_din,
                            input commit,
                            input b_clk,
                            input [10:0] b_addr_x,
                            input [10:0] b_addr_y,
                            output vram_num,
                            output [11:0] vram_data);
  reg wr_sel;
  wire b_wr = 0;
  wire [31:0] b_dout0, b_dout1, b_dout_res;
  wire [10:0] b_addr;

  // y is vertical, x is horizonal
  wire a_wr0, a_wr1;
  assign a_wr0      = wr_sel == 0 && a_wr == 1;
  assign a_wr1      = wr_sel == 1 && a_wr == 1;
  assign b_dout_res = wr_sel == 1 ? b_dout0 : b_dout1;
  assign vram_num   = wr_sel;
  vram vram0(
  .a_clk(a_clk),
  .a_wr(a_wr0),
  .a_din(a_din),
  .a_addr(a_addr[10:0]),
  .b_clk(b_clk),
  .b_addr(b_addr),
  .b_wr(b_wr),
  .b_dout(b_dout0));
  vram vram1(
  .a_clk(a_clk),
  .a_wr(a_wr1),
  .a_din(a_din),
  .a_addr(a_addr[10:0]),
  .b_clk(b_clk),
  .b_addr(b_addr),
  .b_wr(b_wr),
  .b_dout(b_dout1));
    
  
  
  // convert pixel coordinate to chunk coordinate
  wire [10:0] chunk_x, chunk_y;
  assign chunk_x = (b_addr_x - 128) / 3;
  assign chunk_y = (b_addr_y - 48) / 3;

  assign b_addr[10:0] = chunk_y * 16 + chunk_x / 8;  //16*8=128，数组的一行是128个元素了
  
  reg [3:0] color_id;
  reg [2:0] chunk_x_low;
  reg [3:0] last_color_id;
  
  always @(*) begin
    chunk_x_low <= chunk_x[2:0];

    if(b_addr_x < 128 || b_addr_x >= 639 - 127 || b_addr_y < 48 || b_addr_y >= 479 - 47) begin//只取中间的，其他部分全搞成空的。
           color_id <= 2;
           last_color_id<=2;
    end
    else begin
//        if((b_addr_x-128)%24==0||(b_addr_y)%24==0) begin
//                color_id <= 0;
//        end
//        else begin
            case (chunk_x_low)
                3'b000: begin
                  color_id <= b_dout_res[3: 0];
                end
                3'b001: begin
                  color_id <= b_dout_res[7: 4];
                end
                3'b010: begin
                  color_id <= b_dout_res[11: 8];
                end
                3'b011: begin
                  color_id <= b_dout_res[15: 12];
                end
                3'b100: begin
                  color_id <= b_dout_res[19: 16];
                end
                3'b101: begin
                  color_id <= b_dout_res[23: 20];
                end
                3'b110: begin
                  color_id <= b_dout_res[27: 24];
                end
                3'b111: begin
                  color_id <= b_dout_res[31: 28];
                end
            endcase
//        end
    end
  end
  
  
  vram_decode color_decoder(
    .num(color_id),
    .data(vram_data)
  );
   
  
  always @(posedge a_clk) begin
    if (commit == 1) begin
      wr_sel <= ~wr_sel;
    end
    
    if (rst) begin
      wr_sel <= 0;
    end
  end
endmodule

//module double_frame_buffer (input rst,
//                            input a_clk,
//                            input a_wr,
//                            input [10:0] a_addr,
//                            input [31:0] a_din,
//                            input commit,
//                            input b_clk,
//                            input [10:0] b_addr_x,
//                            input [10:0] b_addr_y,
//                            output vram_num,
//                            output [11:0] vram_data);
//  reg wr_sel;
//  wire b_wr = 0;
//  wire [31:0] b_dout0, b_dout1, b_dout_res;
//  wire [10:0] b_addr;

//  // a_wr logic
//  wire a_wr0, a_wr1;
//  assign a_wr0      = wr_sel == 0 && a_wr == 1;
//  assign a_wr1      = wr_sel == 1 && a_wr == 1;
//  assign b_dout_res = wr_sel == 1 ? b_dout0 : b_dout1;
//  assign vram_num   = wr_sel;

//  vram vram0(
//  .a_clk(a_clk),
//  .a_wr(a_wr0),
//  .a_din(a_din),
//  .a_addr(a_addr[10:0]),
//  .b_clk(b_clk),
//  .b_addr(b_addr),
//  .b_wr(b_wr),
//  .b_dout(b_dout0));

//  vram vram1(
//  .a_clk(a_clk),
//  .a_wr(a_wr1),
//  .a_din(a_din),
//  .a_addr(a_addr[10:0]),
//  .b_clk(b_clk),
//  .b_addr(b_addr),
//  .b_wr(b_wr),
//  .b_dout(b_dout1));

//  // Simplified pixel coordinate to VRAM address mapping
////  assign b_addr = b_addr_y * 64 + b_addr_x / 8;//b_addr对应32位，8个像素块的值。一行是640个像素块，所以是640/8=80个存储单位。
//  assign b_addr = b_addr_y * 80 + b_addr_x / 8;//b_addr对应32位，8个像素块的值。一行是640个像素块，所以是640/8=80个存储单位。
//  reg [3:0] color_id;
//  reg [2:0] chunk_x_low;

//  always @(*) begin
//    chunk_x_low <= b_addr_x[2:0];

//    // Simplified color assignment logic
//    case (chunk_x_low)//b_out_res是b_addr在vram中取得的32位数据，每四位对应一个像素点的color_id。128*40
//      3'b000: color_id <= b_dout_res[3: 0];
//      3'b001: color_id <= b_dout_res[7: 4];
//      3'b010: color_id <= b_dout_res[11: 8];
//      3'b011: color_id <= b_dout_res[15: 12];
//      3'b100: color_id <= b_dout_res[19: 16];
//      3'b101: color_id <= b_dout_res[23: 20];
//      3'b110: color_id <= b_dout_res[27: 24];
//      3'b111: color_id <= b_dout_res[31: 28];
//    endcase
//  end

//  vram_decode color_decoder(
//    .num(color_id),
//    .data(vram_data)
//  );

//  always @(posedge a_clk) begin
//    if (commit == 1) begin
//      wr_sel <= ~wr_sel;
//    end

//    if (rst) begin
//      wr_sel <= 0;
//    end
//  end
//endmodule
