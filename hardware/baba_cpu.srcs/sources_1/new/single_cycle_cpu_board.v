`timescale 1ns/10ps

module single_cycle_cpu_board(input clk,
                              input rst,
                              input halt,
                              input PS2_CLK,
                              input PS2_DATA,
                              input UART_TXD_IN, //is the hardware port
                              output UART_RXD_OUT,
                              input BTNU,// it is used! what?
                              input BTND,
                              input BTNL,
                              input BTNR,
                              input BTNC,
                              output [3:0]VGA_R,//是VGA协议下的输出，工作所需的原料。
                              output [3:0]VGA_G,
                              output [3:0]VGA_B,
                              output VGA_HS,
                              output VGA_VS,
                              output reg [7:0] AN,
                              output [7:0] SEG,
                              output [15:0] LED);// It is hardware output.defined in constrainsts
  wire [31:0] led_data; //此led非彼led，是用来数码管显示用的。
  wire [31:0] led_test_data; //连接single_cpu的current_pc。
  wire kbd_read_enable, kbd_ready, kbd_overflow;
  wire [7:0] kbd_data;
  wire [31:0] kbd_display;
  wire vram_num;
  
  
  wire [4:0]button_state;
  
  assign LED[0] = PS2_CLK;
  assign LED[1] = PS2_DATA;
  assign LED[2] = cpu_clk;
  assign LED[3] = kbd_ready;
  assign LED[4] = kbd_overflow;
  assign LED[5] = kbd_read_enable;
  assign LED[6] = vram_num;
  
  
  
  // test button
  assign LED[14] = BTNU;
  assign LED[15] = BTND;
  
   // test button_state
  assign LED[13] = button_state[4];
  assign LED[12] = button_state[3];
  assign LED[11] = button_state[2];
  assign LED[10] = button_state[1];
  assign LED[9] = button_state[0];

  wire cpu_clk_p, led_clk_p, us_clk_p, vga_clk_p, bram_clk_p;
  wire cpu_clk, led_clk, us_clk, vga_clk, bram_clk;
  

  
  // assign cpu_clk = cpu_clk_p;
  // assign led_clk = led_clk_p;
  // assign vga_clk = vga_clk_p;
  divider #(4) div1(clk, cpu_clk_p); //10MHz
  divider #(2500) div2(clk, led_clk_p); // 20kHz
  divider #(500) div3(clk, us_clk_p); // 100kHz
  divider #(2) div4(clk,vga_clk_p); // 25MHz
  //divider #(1) div4(clk, vga_clk_p); // 50MHz // There's some problem (expected 65MHz)
//  clk_wiz vga_clk_gen(
//  .clk_in1(clk),
//  .vga_clk(vga_clk_p));// vga_clk expected 25MHz
  
//  clk_wiz_1 bram_clk_gen(                          
//  .clk_in1(clk),                                
//  .vga_clk(bram_clk_p));// bram_clk expected 200MHz
  assign bram_clk = clk;// 
  
  BUFG bufg_cpu (.O(cpu_clk), .I(cpu_clk_p));
  BUFG bufg_counter (.O(led_clk), .I(led_clk_p));
  BUFG bufg_led (.O(us_clk), .I(us_clk_p));
  BUFG bufg_vga (.O(vga_clk), .I(vga_clk_p));
  //BUFG bufg_bram (.O(bram_clk), .I(bram_clk_p));
  
  wire [10:0] next_x, next_y;
  wire [11:0] vram_data;
  
  vga_driver vga0(.clk(vga_clk),
  .rst(rst),
  .color_in(vram_data),
  .next_x(next_x),
  .next_y(next_y),
  .red(VGA_R),
  .green(VGA_G),
  .blue(VGA_B),
  .hsync(VGA_HS),
  .vsync(VGA_VS));
  
  ps2_kbd kbd(.clk(cpu_clk),// what is this module used for?it seems to be important. just process the hardware input
  .rst(rst),
  .ps2_clk(PS2_CLK),  // input,the trigger to sample ps2_data
  .ps2_data(PS2_DATA), //input,data,include 11 bit ,10 begin 9--2 data 1  1 stop
  .btn_u(BTNU),
  .btn_d(BTND),
  .btn_l(BTNL),
  .btn_r(BTNR),
  .btn_c(BTNC),
  .read_enable(kbd_read_enable),// input,reed FIFO enable
  .data(kbd_data), //output, fifo output,8bit
  .ready(kbd_ready), //show that fifo is not empty
  .overflow(kbd_overflow)); //when is is 1 ,shows that the fifo is full
  wire [31:0] clk_cnt;
  counter cnt0(
  .clk(us_clk),
  .rst(rst),
  .cnt(clk_cnt)
  );
  wire uart_r_enable, uart_r_ready;
  wire uart_w_ready, uart_w_enable;
//  assign LED[8] = uart_r_enable;
//  assign LED[9] = uart_r_ready;
//  assign LED[10] = uart_w_enable;
//  assign LED[11] = uart_w_ready;
  wire [7:0] uart_r_data;
  wire [7:0] uart_w_data;
  uart uart0 (  //so it is realized by seting a new module
    .cpu_clk(cpu_clk),
    .rst(rst),
    
    .rx(UART_TXD_IN),
    .r_enable(uart_r_enable),
    .r_ready(uart_r_ready),
    .r_overflow(LED[7]),
    .r_data_out(uart_r_data[7:0]),
    
    .tx(UART_RXD_OUT),
    .w_ready(uart_w_ready),
    .w_enable(uart_w_enable),
    .w_data_in(uart_w_data[7:0])
  );
  single_cycle_cpu my_cpu(
  .bram_clk(bram_clk),
  .clk(cpu_clk),
  .vga_clk(vga_clk),
  .rst(rst),
  .halt(halt),
  .kbd_ready(kbd_ready),
  .kbd_overflow(kbd_overflow),
  .kbd_data(kbd_data),
  .clk_cnt(clk_cnt),
  .vram_addr_x(next_x),
  .vram_addr_y(next_y),
  .current_pc(led_test_data),//new added
  .button_state(button_state),
  
  .uart_r_ready(uart_r_ready),
  .uart_w_ready(uart_w_ready), 
  .uart_r_data(uart_r_data),
  
  .uart_r_enable(uart_r_enable), 
  .uart_w_enable(uart_w_enable),
  .uart_w_data(uart_w_data),
  
  .vram_num(vram_num),
  .vram_data(vram_data),
  .kbd_read_enable(kbd_read_enable),
  .led_data(led_data),
  .BTNU(BTNU),// ADDED TO NEW FUNCTION
  .BTND(BTND),
  .BTNL(BTNL),
  .BTNR(BTNR),
  .BTNC(BTNC)                      
  );
  reg [3:0] sel;
  always @(posedge led_clk) begin
    if (rst) begin
      sel = 4'b0;
      end else begin
      sel = sel + 1;
    end
    AN[7:0] = 8'hff;
    AN[sel] = 1'b0;
  end
  

led_display led_decoder(led_data[(sel * 4) +: 4], SEG[7:0]);
//  led_display led_decoder(led_test_data[(sel * 4) +: 4], SEG[7:0]);
// led_decoder_32bit led_decoder(led_test_data, SEG[7:0]);
 

endmodule
