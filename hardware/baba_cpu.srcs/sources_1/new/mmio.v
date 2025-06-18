module mmio (input clk,
             input bram_clk,
             input rst,
             input load,
             input store,
             input [2:0] access, //to 12--14bit in instruction
             input [31:0] addr,
             input [31:0] data_in,
             input kbd_ready,
             input kbd_overflow,
             input [7:0] kbd_data,
             input [31:0] clk_cnt,
             input vga_clk,
             input [10:0] vram_addr_x,
             input [10:0] vram_addr_y,
             input uart_r_ready,
             input uart_w_ready, 
             input [7:0] uart_r_data,
             input btn_u,// new added
             input btn_d,
             input btn_l,
             input btn_r,
             input btn_c,
          
             output reg [4:0] button_state,// new added ,to test the button
             output reg uart_r_enable, 
             output reg uart_w_enable,
             output [7:0] uart_w_data,
             output vram_num,
             output [11:0] vram_data,
             output reg [31:0] led_data,
             output reg kbd_read_enable,
             output reg [31:0] data_out);//data_out就是一个多路选择器的输出，根据addr来输出对应的地址。由此看来，data_out要去到哪里？data_out是否需要在一个指令周期内部一直保持，而下个周期再清零？
  
  // added button
  // read信号，发生了就要reset
    reg update;
  
  // 按钮状态寄存器
    reg [4:0] button_state;

//    always @(posedge clk or posedge rst or posedge update) begin
//        if (rst) begin
//            button_state <= 5'b0; // 复位时清零
//        end else begin
//            button_state <= {btn_u, btn_d, btn_l, btn_r, btn_c}; // 更新按钮状态
//        end
//    end
  
//      always @(posedge btn_u or posedge btn_d or posedge btn_l or posedge btn_r or posedge btn_c or posedge rst or negedge  update) begin
//        if (rst || update) begin//一般是read(button_state)了，然后要复位。感觉应该是update的negedge，要不然提前把button_state改了会不会太合适
//            button_state <= 5'b0; // 复位时清零
//        end else begin
//            button_state <= {btn_u, btn_d, btn_l, btn_r, btn_c}; // 更新按钮状态
//        end
//    end
  always @(posedge clk or posedge rst) begin
    if (rst) begin
        button_state <= 5'b0; // 复位时清零
    end else if ( update) begin//按照这种设计下，其实update像是一个寄存器的输入端的一个多路选择器的sel信号。所以说，verilog看似很灵活，但是如果要让他能跑，并不是所有看似逻辑上可行的方法都能用的，必须要在硬件上是明确的逻辑才行，你不能设计出来一个你自己在硬件上都不清楚的电路组件出来
        button_state <= 5'b0; // 清零状态
    end else if (btn_u || btn_d || btn_l || btn_r || btn_c) begin
        button_state <= {btn_u, btn_d, btn_l, btn_r, btn_c}; // 锁存按钮状态
    end
end

  wire [31:0] ram_data_out;
  reg [31:0] kbd_data_out;
  reg commit_vram;
  reg ram_store, vram_store;
  wire b_wr = 0;
  assign uart_w_data[7:0] = data_in[7:0];
  ram ram0(
  .cpu_clk(clk),
  .clk(bram_clk),
  .rst(rst),
  .load(load),
  .store(ram_store),
  .access(access),
  .addr(addr),
  .data_in(data_in),
  .data_out(ram_data_out)
  );
  double_frame_buffer fb0  (.rst(rst),// 软件上的数组完成一帧之后，写到这个地址中。
  .a_clk(clk),
  .a_wr(vram_store),
  .a_addr({addr[12:2]}),
  .a_din(data_in),
  .commit(commit_vram),
  .b_clk(vga_clk),
  .b_addr_x(vram_addr_x),
  .b_addr_y(vram_addr_y),
  .vram_data(vram_data),
  .vram_num(vram_num)
  );
  always @(*) begin  //整体看来，这也是一个类似于多路选择器的模块，用来输出data_out
    vram_store   = 0;
    ram_store    = 0;
    kbd_data_out = 32'b0;
    data_out     = 32'b0;
    commit_vram  = 0;
    uart_w_enable = 0; //发明这个结构的人真是个天才
    update=0;// 确保update信号也是一个脉冲而不是恒1.
    if (load && (access == 3'b000 || access == 3'b100) && addr == 32'hfbadbeef) begin // imagine one instruction comes ,it is a load type ins,
      // read kbd
      // only allow lb lbu
      if (kbd_ready) begin
        kbd_data_out = {24'b0, kbd_data[7:0]};
      end
      else begin
        kbd_data_out = 32'b0;
      end
      data_out[31:0] = kbd_data_out[31:0];
    end
    else if (load && (access == 3'b000 || access == 3'b100) && addr == 32'hfbadbeee) begin
      // read kbd_ready
      // only allow lb, lbu
      data_out[31:0] = { 31'b0, kbd_ready };
    end
    else if (load && access == 3'b010 && addr == 32'hfbadbedf) begin
    // read us clock
    // only allow lw
    data_out[31:0] = clk_cnt;
    end
    else if (load && (access == 3'b000 || access == 3'b100) && addr == 32'hfbada000) begin
      // uart read ready
      // allow lb lbu
      data_out[31:0] = {31'b0, uart_r_ready};
    end
    else if (load && (access == 3'b000 || access == 3'b100) && addr == 32'hfbada001) begin
      // uart write ready
      // allow lb lbu
      data_out[31:0] = {31'b0, uart_w_ready};
    end
    else if (load && (access == 3'b000 || access == 3'b100) && addr == 32'hfbada002) begin
      // uart read data
      // allow lb lbu
      if (uart_r_ready) begin
        data_out[31:0] = {24'b0, uart_r_data[7:0]};        
      end else begin
        data_out[31:0] = 32'b0;
      end
    end
    else if (store && access == 3'b000 && addr == 32'hfbada003) begin
      // uart write data
      // allow sb
      if (uart_w_ready) begin
        uart_w_enable = 1;        
      end
    end
    else if (store && access == 3'b000 && addr == 32'hfbadf000) begin//当前的varm已经加载完成，认为完成一帧，进行渲染
      commit_vram = 1;
    end
    else if (store && access == 3'b010 && addr >= 32'hfbad0000 && addr < 32'hfbad0000 + 8192) begin
    vram_store = store;
    end
    else if (load && (access == 3'b000 || access == 3'b100) && addr == 32'hfbadc100) begin// btnu
      // 读取按钮状态
      // only allow lb, lbu
      data_out = {27'b0, button_state};
      update = 1; //代表会清空。具体是什么行为呢？这是一个组合逻辑电路，update也是一个多路选择器的输出。相当于，当满足这个条件时，update被选择为1输出，然后再有其他信号变化时，update就再变成0，那其他信号什么时候变化？就比如说这一个模块，其实就是access和load,store这些信号，而这些信号是一周期一变的。所以逻辑没问题
    end
    else begin
      ram_store      = store;
      data_out[31:0] = ram_data_out[31:0];
    end
  end
  always @(posedge clk) begin
    if (load && (access == 3'b000 || access == 3'b100) && addr == 32'hfbadbeef) begin
      // read kbd
      // only allow lb lbu
      kbd_read_enable <= 1;
      end else begin
      kbd_read_enable <= 0;
    end
    if (load && (access == 3'b000 || access == 3'b100) && addr == 32'hfbada002) begin
      // read uart fifo
      // only allow lb lbu
      uart_r_enable <= 1;
    end else begin
      uart_r_enable <= 0;
    end
    
    if (store && access == 3'b010 && addr == 32'hfbadc0fe) begin
      led_data[31:0] <= data_in[31:0];
    end
  end
endmodule
