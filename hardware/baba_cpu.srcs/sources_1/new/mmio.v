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
             output reg [31:0] data_out);//data_out����һ����·ѡ���������������addr�������Ӧ�ĵ�ַ���ɴ˿�����data_outҪȥ�����data_out�Ƿ���Ҫ��һ��ָ�������ڲ�һֱ���֣����¸����������㣿
  
  // added button
  // read�źţ������˾�Ҫreset
    reg update;
  
  // ��ť״̬�Ĵ���
    reg [4:0] button_state;

//    always @(posedge clk or posedge rst or posedge update) begin
//        if (rst) begin
//            button_state <= 5'b0; // ��λʱ����
//        end else begin
//            button_state <= {btn_u, btn_d, btn_l, btn_r, btn_c}; // ���°�ť״̬
//        end
//    end
  
//      always @(posedge btn_u or posedge btn_d or posedge btn_l or posedge btn_r or posedge btn_c or posedge rst or negedge  update) begin
//        if (rst || update) begin//һ����read(button_state)�ˣ�Ȼ��Ҫ��λ���о�Ӧ����update��negedge��Ҫ��Ȼ��ǰ��button_state���˻᲻��̫����
//            button_state <= 5'b0; // ��λʱ����
//        end else begin
//            button_state <= {btn_u, btn_d, btn_l, btn_r, btn_c}; // ���°�ť״̬
//        end
//    end
  always @(posedge clk or posedge rst) begin
    if (rst) begin
        button_state <= 5'b0; // ��λʱ����
    end else if ( update) begin//������������£���ʵupdate����һ���Ĵ���������˵�һ����·ѡ������sel�źš�����˵��verilog���ƺ����������Ҫ�������ܣ����������п����߼��Ͽ��еķ��������õģ�����Ҫ��Ӳ��������ȷ���߼����У��㲻����Ƴ���һ�����Լ���Ӳ���϶�������ĵ�·�������
        button_state <= 5'b0; // ����״̬
    end else if (btn_u || btn_d || btn_l || btn_r || btn_c) begin
        button_state <= {btn_u, btn_d, btn_l, btn_r, btn_c}; // ���水ť״̬
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
  double_frame_buffer fb0  (.rst(rst),// ����ϵ��������һ֮֡��д�������ַ�С�
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
  always @(*) begin  //���忴������Ҳ��һ�������ڶ�·ѡ������ģ�飬�������data_out
    vram_store   = 0;
    ram_store    = 0;
    kbd_data_out = 32'b0;
    data_out     = 32'b0;
    commit_vram  = 0;
    uart_w_enable = 0; //��������ṹ�������Ǹ����
    update=0;// ȷ��update�ź�Ҳ��һ����������Ǻ�1.
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
    else if (store && access == 3'b000 && addr == 32'hfbadf000) begin//��ǰ��varm�Ѿ�������ɣ���Ϊ���һ֡��������Ⱦ
      commit_vram = 1;
    end
    else if (store && access == 3'b010 && addr >= 32'hfbad0000 && addr < 32'hfbad0000 + 8192) begin
    vram_store = store;
    end
    else if (load && (access == 3'b000 || access == 3'b100) && addr == 32'hfbadc100) begin// btnu
      // ��ȡ��ť״̬
      // only allow lb, lbu
      data_out = {27'b0, button_state};
      update = 1; //�������ա�������ʲô��Ϊ�أ�����һ������߼���·��updateҲ��һ����·ѡ������������൱�ڣ��������������ʱ��update��ѡ��Ϊ1�����Ȼ�����������źű仯ʱ��update���ٱ��0���������ź�ʲôʱ��仯���ͱ���˵��һ��ģ�飬��ʵ����access��load,store��Щ�źţ�����Щ�ź���һ����һ��ġ������߼�û����
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
