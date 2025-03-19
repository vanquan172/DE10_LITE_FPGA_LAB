module uart_top(
	input                        clk,
	input                        rst_n,
//	input     [15:0]             temp_tr,
//	input     [15:0]             hum_tr,
//	input 						 enable_uart,
	output                       uart_tx
);

parameter                        CLK_FRE  = 50;//Mhz
parameter                        UART_FRE = 115200;//Mhz
localparam                       IDLE =  0;
localparam                       SEND =  1;   //send 
localparam                       WAIT =  2;   //wait 1 second and send uart received data
reg[7:0]                         tx_data;
reg[7:0]                         tx_str;
reg                              tx_data_valid;
wire                             tx_data_ready;
reg[7:0]                         tx_cnt;
wire[7:0]                        rx_data;
wire                             rx_data_valid;
wire                             rx_data_ready;
reg[31:0]                        wait_cnt;
reg[31:0]                        cnt_delay;
reg[3:0]                         state;
reg                              enable_uart;
reg [8*12-1:0] lcd_data_temp; // Chuỗi 10 ký tự
reg [15:0] temp_value = 0; 

reg [7:0]   tmp_dv,tmp_ch;
always @(posedge clk)begin
    if(cnt_delay == CLK_FRE * 1000_000)begin
        cnt_delay <= 0; 
        temp_value <= temp_value + 1; // Giả lập thay đổi nhiệt độ
        tmp_ch <= "0" + (temp_value / 10);
        tmp_dv <= "0" + (temp_value % 10);
    end
    else 
        cnt_delay <= cnt_delay + 1; 
end
always @(temp_value) begin
    lcd_data_temp <= {"temp: ",
                      tmp_ch, // Hàng chục
                      tmp_dv,// Hàng đơn vị
                      " ", "C", 8'h0d, 8'h0a};
end



reg [8*9-1:0] lcd_data_hum; // Chuỗi 9 ký tự
reg [15:0] humidity_value = 0; 

always @(posedge clk) begin
    humidity_value = 15; // Giả lập giá trị độ ẩm
    lcd_data_hum = {"H", "u", "m", ":", " ", 
                    "0" + (humidity_value / 10), "0" + (humidity_value % 10), " ", "%"};
end

always @(tx_cnt) begin
    tx_str <= lcd_data_temp[(12 - 1 - tx_cnt) * 8 +: 8];
end

always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
	begin
		wait_cnt <= 32'd0;
		tx_data <= 8'd0;
		state <= IDLE;
		tx_cnt <= 8'd0;
		tx_data_valid <= 1'b0;
	end
	else
	case(state)
		IDLE:
				state <= SEND;
		SEND:
		begin
			wait_cnt <= 32'd0;
			tx_data <= tx_str;

			if(tx_data_valid == 1'b1 && tx_data_ready == 1'b1 && tx_cnt < 12 - 1)//Send 12 bytes data
			begin
				tx_cnt <= tx_cnt + 8'd1; //Send data counter
			end
			else if(tx_data_valid && tx_data_ready)//last byte sent is complete
			begin
				tx_cnt <= 8'd0;
				tx_data_valid <= 1'b0;
				state <= WAIT;
			end
			else if(~tx_data_valid)
			begin
				tx_data_valid <= 1'b1;
			end
		end
		WAIT:
		begin
			wait_cnt <= wait_cnt + 32'd1;
 //     tx_data_valid <= 1; 
 
			 if(rx_data_valid == 1'b1)
			 begin
			 	tx_data_valid <= 1'b1;
			 	tx_data <= rx_data;   // send uart received data
			 end
			 else if(tx_data_valid && tx_data_ready)
			 begin
			 	tx_data_valid <= 1'b0;
			 end
			 else if(wait_cnt >= CLK_FRE * 1000_000) // wait for 1 second
			 	state <= SEND;
//		if(wait_cnt >= CLK_FRE * 1000_000) // wait for 1 second
//				state <= SEND;
		end
		default:
			state <= IDLE;
	endcase
end

//combinational logic

// `define example_1

// `ifdef example_1

// // Example 1

// parameter 	ENG_NUM  = 14;//非中文字符数
// parameter 	CHE_NUM  = 2 + 1;//  中文字符数
// parameter 	DATA_NUM = CHE_NUM * 3 + ENG_NUM; //中文字符使用UTF8，占用3个字节
// wire [ DATA_NUM * 8 - 1:0] send_data = {"你好 Tang Nano 20K",16'h0d0a};

// `else

// // Example 2

// parameter 	ENG_NUM  = 19 + 1;//非中文字符数
// parameter 	CHE_NUM  = 0;//  中文字符数
// parameter 	DATA_NUM = CHE_NUM * 3 + ENG_NUM + 1; //中文字符使用UTF8，占用3个字节
// wire [ DATA_NUM * 8 - 1:0] send_data = {"Hello Tang Nano 20K",16'h0d0a};

// `endif

//always@(*)
//	tx_str <= lcd_data_temp[(18 - 1 - tx_cnt) * 8 +: 8];

// uart_rx#
// (
// 	.CLK_FRE(CLK_FRE),
// 	.BAUD_RATE(UART_FRE)
// ) uart_rx_inst
// (
// 	.clk                        (clk                      ),
// 	.rst_n                      (rst_n                    ),
// 	.rx_data                    (rx_data                  ),
// 	.rx_data_valid              (rx_data_valid            ),
// 	.rx_data_ready              (rx_data_ready            ),
// 	.rx_pin                     (uart_rx                  )
// );

uart_tx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_tx_inst
(
	.clk                        (clk                      ),
	.rst_n                      (rst_n                    ),
	.tx_data                    (tx_data                  ),
	.tx_data_valid              (tx_data_valid            ),
	.tx_data_ready              (tx_data_ready            ),
	.tx_pin                     (uart_tx                  )
);
endmodule