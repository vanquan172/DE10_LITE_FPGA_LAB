

module ctr_sht30 
 
(
    input clk,
    output reg [47:0] data_out,
    output reg data_ready = 1,
    input enable,
    // output reg [1:0] instr_i2c,
    // output reg enable_i2c,
    // output reg [7:0] byte_tx_i2c,
    // output sda,scl,complete_i2c
    output      scl,
    inout       sda

 //   input [7:0] byte_rx_i2c,
 //   input complete_I2C
);

reg [1:0]   instr_i2c; 
reg enable_i2c; 
reg [7:0]   byte_tx_i2c; 
wire     complete_I2C; 
  wire   [7:0] byte_rx_i2c; 
//   wire   complete_I2C; 
//   assign complete_i2c = complete_I2C; 
// setup config
reg [15:0] reg_setup = 16'h2400;//2C06 ;

localparam TASK_SETUP = 0;
localparam TASK_DELAY = 1;
localparam TASK_READ_VALUE = 2;

localparam STATE_START_TX = 0;
localparam STATE_STOP_TX = 1;
localparam STATE_READ_BYTE = 2;
localparam STATE_WRITE_BYTE = 3;

localparam STATE_IDLE = 0;
localparam STATE_RUN_TASK = 1;
localparam STATE_WAIT_I2C = 2;
localparam STATE_INC_TASK = 3;
localparam STATE_DONE = 4;
localparam STATE_DELAY = 5;

reg [1:0] state_task = 0;
reg [3:0] sub_task = 0;
reg [4:0] state = STATE_IDLE;
reg [19:0] cnt_delay = 0;
reg process = 0;
reg [6:0]   address = 7'b1000100;
wire error_ack; 

i2c #(.SYS_CLK(27_000_000), .SCL_CLK(200_000))  
    ins_i2c (.clk(clk), .instr(instr_i2c), .enable(enable_i2c), .byte_tx(byte_tx_i2c),
             .byte_rx(byte_rx_i2c),.complete(complete_I2C),.sda(sda),.scl(scl),.error(error_ack)); 

always @(posedge clk) begin
    case (state)
        STATE_IDLE: 
            begin
                if (enable) 
                    begin
                        state <= STATE_RUN_TASK;
                        state_task <= 0;
                        sub_task <= 0;
                        data_ready <= 0;
                        cnt_delay <= 0;
                    end
            end
        STATE_RUN_TASK: 
            begin
                case ({state_task, sub_task})
                        {TASK_SETUP, 4'd0}, {TASK_READ_VALUE, 4'd0}: 
                            begin
                                instr_i2c <= STATE_START_TX;
                                enable_i2c <= 1;
                                state <= STATE_WAIT_I2C;
                            end
                        {TASK_SETUP, 4'd1}, {TASK_READ_VALUE, 4'd1}: 
                            begin
                                instr_i2c <= STATE_WRITE_BYTE;
                                byte_tx_i2c <= {address, (state_task == TASK_READ_VALUE) ? 1'b1 : 1'b0};
                                enable_i2c <= 1;
                                state <= STATE_WAIT_I2C;
                            end
                        {TASK_SETUP, 4'd4}, {TASK_READ_VALUE, 4'd9}: 
                            begin
                                instr_i2c <= STATE_STOP_TX;
                                enable_i2c <= 1;
                                state <= STATE_WAIT_I2C;
                            endz
                        {TASK_SETUP, 4'd2}: 
                            begin
                                instr_i2c <= STATE_WRITE_BYTE;
                                byte_tx_i2c <= reg_setup[15:8];
                                enable_i2c <= 1;
                                state <= STATE_WAIT_I2C;
                            end
                        {TASK_SETUP, 4'd3}: 
                            begin
                                instr_i2c <= STATE_WRITE_BYTE;
                                byte_tx_i2c <= reg_setup[7:0];
                                enable_i2c <= 1;
                                state <= STATE_WAIT_I2C;
                            end
                        {TASK_DELAY, 4'd0}: 
                            begin
                                state <= STATE_DELAY;
                            end
                        {TASK_READ_VALUE, 4'd2}: 
                            begin
                                instr_i2c <= STATE_READ_BYTE;
                                enable_i2c <= 1;
                                state <= STATE_WAIT_I2C;
                            end
                        {TASK_READ_VALUE, 4'd3}: 
                            begin
                                instr_i2c <= STATE_READ_BYTE; // đọc byte 2
                                data_out[47:40] <= byte_rx_i2c; // lưu byte 1
                                enable_i2c <= 1;
                                state <= STATE_WAIT_I2C;
                            end
                        {TASK_READ_VALUE, 4'd4}: 
                            begin
                                instr_i2c <= STATE_READ_BYTE;
                                data_out[39:32] <= byte_rx_i2c;
                                enable_i2c <= 1;
                                state <= STATE_WAIT_I2C;
                            end
                        {TASK_READ_VALUE, 4'd5}:
                            begin
                                instr_i2c <= STATE_READ_BYTE;
                                data_out[31:24] <= byte_rx_i2c;
                                enable_i2c <= 1;
                                state <= STATE_WAIT_I2C;
                            end
                        {TASK_READ_VALUE, 4'd6}: 
                            begin
                                instr_i2c <= STATE_READ_BYTE;
                                data_out[23:16] <= byte_rx_i2c;
                                enable_i2c <= 1;
                                state <= STATE_WAIT_I2C;
                            end
                        {TASK_READ_VALUE, 4'd7}: 
                            begin
                                instr_i2c <= STATE_READ_BYTE;
                                data_out[15:8] <= byte_rx_i2c;
                                enable_i2c <= 1;
                                state <= STATE_WAIT_I2C;
                            end
                        {TASK_READ_VALUE, 4'd8}: 
                            begin
                                state <= STATE_INC_TASK;
                                data_out[7:0] <= byte_rx_i2c;
                            end
                        default: 
                            begin
                                state <= STATE_INC_TASK;
                            end
                 endcase
            end
        STATE_WAIT_I2C: begin
            if (~process && ~complete_I2C)
                process <= 1;
            else if (complete_I2C && process) 
                begin
                    if(error_ack) begin 
                        state <= STATE_IDLE; 
                    end 
                    else begin 
                        state <= STATE_INC_TASK;
                        process <= 0;
                        enable_i2c <= 0;
                    end 
                end
        end
        STATE_INC_TASK: begin
            state <= STATE_RUN_TASK;
            case(state_task)
                TASK_SETUP: 
                    begin 
                        if (sub_task == 4'd4)
                            begin 
                                sub_task <= 4'd0;
                                state_task <= state_task + 1; 
                                //state_task <= 0; 
                            end 
                        else 
                            sub_task <= sub_task + 1;
                    end 
                TASK_DELAY:
                    begin
                        if (sub_task == 4'd0)
                            begin 
                                sub_task <= 4'd0;
                                state_task <= state_task + 1; 
                            end                            
                        else 
                            sub_task <= sub_task + 1;
                    end 
                TASK_READ_VALUE:
                    begin 
                        if (sub_task == 4'd9) 
                            begin 
                                sub_task <= 4'd0;
                                state_task <= state_task + 1; 
                                state <= STATE_DONE; 
                            end 
                        else 
                            sub_task <= sub_task + 1;
                    end 
            endcase

        end
        STATE_DELAY: begin
            if (cnt_delay == 20'd540000) 
                begin
                    cnt_delay <= 0; 
                    state <= STATE_INC_TASK;
                end
            else 
                cnt_delay <= cnt_delay + 1;
        end
        STATE_DONE: begin
            data_ready <= 1;
            if (~enable)
                state <= STATE_IDLE;
        end
    endcase
end

endmodule