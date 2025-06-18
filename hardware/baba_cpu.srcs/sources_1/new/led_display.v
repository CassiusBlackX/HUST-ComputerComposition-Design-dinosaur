
module led_display(input [3:0] data,
                   output reg [7:0] seg);
always@(*)
begin
  case(data[3:0])
    4'b0000 : seg[7:0] = 8'b11000000;
    4'b0001 : seg[7:0] = 8'b11111001;
    4'b0010 : seg[7:0] = 8'b10100100;
    4'b0011 : seg[7:0] = 8'b10110000;
    4'b0100 : seg[7:0] = 8'b10011001;
    4'b0101 : seg[7:0] = 8'b10010010;
    4'b0110 : seg[7:0] = 8'b10000010;
    4'b0111 : seg[7:0] = 8'b11111000;
    4'b1000 : seg[7:0] = 8'b10000000;
    4'b1001 : seg[7:0] = 8'b10011000;
    4'b1010 : seg[7:0] = 8'b10001000;
    4'b1011 : seg[7:0] = 8'b10000011;
    4'b1100 : seg[7:0] = 8'b11000110;
    4'b1101 : seg[7:0] = 8'b10100001;
    4'b1110 : seg[7:0] = 8'b10000110;
    default : seg[7:0] = 8'b10001110;
  endcase
end
endmodule

//module led_decoder_32bit(input [31:0] led_test_data,  // 32 λ��������
//                          output [7:0] SEG [7:0],  // 8 ������ܵ���ʾ���
//                          output reg [7:0] AN);  // �����ĸ��������ʾ���ź�

//  // ����һ���Ĵ������飬���ڴ洢�ָ��� 8 �� 4 λ����
//  wire [3:0] led_data [7:0];

//  // �� 32 λ���ݷָ�� 8 �� 4 λ����
//  assign led_data[0] = led_test_data[3:0];
//  assign led_data[1] = led_test_data[7:4];
//  assign led_data[2] = led_test_data[11:8];
//  assign led_data[3] = led_test_data[15:12];
//  assign led_data[4] = led_test_data[19:16];
//  assign led_data[5] = led_test_data[23:20];
//  assign led_data[6] = led_test_data[27:24];
//  assign led_data[7] = led_test_data[31:28];

//  // Ϊÿ������ܵ��� led_display ģ��
//  led_display led_decoder0(led_data[0], SEG[0]);
//  led_display led_decoder1(led_data[1], SEG[1]);
//  led_display led_decoder2(led_data[2], SEG[2]);
//  led_display led_decoder3(led_data[3], SEG[3]);
//  led_display led_decoder4(led_data[4], SEG[4]);
//  led_display led_decoder5(led_data[5], SEG[5]);
//  led_display led_decoder6(led_data[6], SEG[6]);
//  led_display led_decoder7(led_data[7], SEG[7]);

//  // ��̬��ʾ���ƣ�������ʾ�ĸ������
//  reg [3:0] sel;
//  always @(posedge led_clk) begin
//    if (rst) begin
//      sel <= 4'b0;
//    end else begin
//      sel <= sel + 1;
//    end

//    // ������Щ�������ʾ
//    AN = 8'b11111111;  // �Ƚ������������
//    AN[sel] = 1'b0;  // ʹ��ǰѡ����������ʾ
//endmodule

