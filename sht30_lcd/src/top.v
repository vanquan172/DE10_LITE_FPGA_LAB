
module top

(
    input clk,rst,
    inout i2c_sda,
    output i2c_scl,
    output rs,en,
    output [3:0]    data_out_lcd
);

    wire [47:0] data_rx_sht;
    wire     data_ready_sht;
    reg enable_sht;
    wire      scl_reg;
    wire      sda_reg; 
 assign i2c_scl = scl_reg; 
 assign i2c_sda = sda_reg; 

ctr_sht30 ins_sht30 ( .clk(clk), .data_out(data_rx_sht), .data_ready(data_ready_sht),
                      .enable(enable_sht), .scl(scl_reg), .sda(sda_reg) ); 

// wire    uart_tx_reg; 
// wire    uart_send_done;
// assign  uart_tx = uart_tx_reg; 
// reg     enable_uart; 

// ctr_uart ins_uart ( .clk(clk), .rst_n(rst), .temp_tr(temp), .hum_tr(hum), .uart_tx(uart_tx_reg),
//                     .uart_send_done(uart_send_done), .enable(enable_uart)); 
reg     start_dis; 
wire    rs_reg, en_reg, complete_dis_reg;
wire    [3:0]    data_out_reg; 
assign rs = rs_reg; 
assign en = en_reg; 
assign data_out_lcd = data_out_reg; 

ctr_lcd ins_lcd ( .clk(clk), .rst(rst), .start_dis(start_dis), .temp_dis(temp), .hum_dis(hum),
                  .data_out(data_out_reg), .rs(rs_reg), .en(en_reg), .complete_dis(complete_dis_reg)); 




    reg [47:0] sht_buffer_data = 0;
    reg [15:0] temp = 0;
    reg [15:0] hum = 0;
    reg [15:0] raw_temp = 0;
    reg [15:0] raw_hum = 0;
    
    localparam STATE_TRIGGER_CONV = 0;
    localparam STATE_SAVE_VALUE = 1;
    localparam STATE_CALC_VALUE = 2;
    localparam STATE_DELAY = 3;

    reg [2:0] state = 0;
    reg [32:0]  cnt_delay;
    always @(posedge clk or negedge rst) begin
        if (rst == 0) begin
            state <= STATE_TRIGGER_CONV;
        end else begin 
            case (state)
                STATE_TRIGGER_CONV: begin
                    enable_sht <= 1;
                    cnt_delay<= 0; 
                    state <= STATE_SAVE_VALUE;
                    sht_buffer_data <= 0; 
                    temp <= 0; 
                    hum <= 0; 
                    raw_hum <= 0; 
                    raw_temp <= 0; 
                end
                STATE_SAVE_VALUE: begin
                    if(data_ready_sht) begin
                        sht_buffer_data[47:0] <= data_rx_sht[47:0];
                        state <= STATE_CALC_VALUE;
                    end 
                end 
                STATE_CALC_VALUE: begin
                    raw_temp = {sht_buffer_data[47:40], sht_buffer_data[39:32]};
                    raw_hum  = {sht_buffer_data[23:16], sht_buffer_data[15:8]};

                    temp = -45 + (175 * raw_temp) / 65536;
                    hum  = (100 * raw_hum) / 65536;

                    state <= STATE_DELAY;
                    start_dis <= 1; 
                end
                STATE_DELAY: begin 
                        if(cnt_delay== 2 * 27_000_000)begin 
                            state <= STATE_TRIGGER_CONV;
                        //   sht_enable <= 1; 
                        end else begin
                            if(complete_dis_reg)
                                start_dis <= 0; 
                            enable_sht <= 0; 
                            cnt_delay<= cnt_delay + 1;
                        end
                end 
            endcase
        end 
    end

endmodule