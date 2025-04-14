module ctr_dht

(
    input   clk, rst,
    output  uart_tx,
    inout   data,
    output  data_ready_out,
    output  rs,en,
    output  [3:0]    data_out_lcd
); 

localparam      IDLE = 0; 
localparam      START_DHT = 1; 
localparam      SAVE_VALUE = 2; 
localparam      SEND_VALUE = 3; 
localparam      DONE = 4; 

reg [2:0]   state; 
reg     start_dht; 
 reg [7:0] temp_value = 8'b10111111;
 reg [7:0] hum_value = 8'b10111111;;
//reg [7:0] temp_value, hum_value;
wire [39:0]     data_buffer; 
reg [31:0]   cnt_delay; 
wire    data_ready; 
assign data_ready_out = ~data_ready;

// reg     start_uart; 
// wire    uart_send_done; 
// ctr_uart ins_uart (.clk(clk), .rst_n(rst), .enable(start_uart), .temp_tr(temp_value), 
//                    .hum_tr(hum_value), .uart_tx(uart_tx), .uart_send_done(uart_send_done)); 
 
reg     start_dis; 
wire    rs_reg, en_reg, complete_dis_reg;
wire    [3:0]    data_out_reg; 
assign rs = rs_reg; 
assign en = en_reg; 
assign data_out_lcd = data_out_reg; 

ctr_lcd ins_lcd ( .clk(clk), .rst(rst), .start_dis(start_dis), .temp_dis(temp_value), .hum_dis(hum_value),
                  .data_out(data_out_reg), .rs(rs_reg), .en(en_reg), .complete_dis(complete_dis_reg)); 

dht ins_dht (.clk(clk), .rst(rst), .start_dht(start_dht), .data(data), .data_out(data_buffer),.data_ready(data_ready)); 

always @( posedge clk or negedge rst) begin 
    if (rst == 0 ) begin 
        state <= IDLE; 
        cnt_delay <= 0; 
        start_dht <= 0; 
        start_dis <= 0; 
    end 
    else begin 
        case (state)
            IDLE: begin 
                state <= START_DHT; 
//            state <= SEND_VALUE; 
                cnt_delay <= 0; 
                start_dht <= 0; 
                start_dis <= 0; 
            
            end 
            START_DHT: begin 
                start_dht <= 1; 
                state <= SAVE_VALUE; 
            end 
            SAVE_VALUE: begin 
                if (data_ready) begin 
                    hum_value <= data_buffer[39:32]; 
                    temp_value <= data_buffer[23:16]; 
                    state <= SEND_VALUE; 
                end 
            end 
            SEND_VALUE: begin 
                start_dis <= 1; 
                start_dht <= 0; 
                state <= DONE; 
            end 
            DONE: begin  
                if (cnt_delay == 2 * 27_000_000) begin
                    cnt_delay <= 0; 
                    state <= IDLE;  
                end 
                else begin  
                    cnt_delay <= cnt_delay + 1;
                    if(complete_dis_reg) 
                        start_dis <= 0; 
                end 
            end 
        endcase 
    end 
end 

endmodule 