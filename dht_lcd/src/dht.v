module dht
(
    input       clk,rst,
    input       start_dht,
    inout       data,
    output   reg   data_ready,
    output  [5*8-1:0]   data_out
    // output      [2:0] state,
    // output   [6:0] timh_out, timl_out, cntus_out
);

reg data_dr; 
reg data_reg ; 
assign data = (data_dr) ? data_reg : 1'bz; 

localparam IDLE = 0; 
localparam START = 1; 
localparam READ = 2; 
localparam DONE = 3; 

localparam step1 = 0;
localparam step2 = 1;
localparam step3 = 2;
localparam step4 = 3;
localparam step_wait = 5;


localparam pre_read = 0; 
localparam read = 1; 
localparam next_read = 2; 
localparam done_read = 3; 

reg [1:0] state; 
reg [1:0] state_read; 
reg [2:0] state_start; 
reg [6:0] tim_h, tim_l; 
reg [21:0] cnt_us; 

reg [5*8 -1:0]  data_buffer; 
reg [6:0]    index; 

assign timh_out = tim_h; 
assign timl_out = tim_l; 
assign cntus_out = cnt_us; 

assign data_out = data_buffer; 
always @(posedge clk or negedge rst) begin
    if (rst == 0) begin
        state <= IDLE; 
        cnt_us <= 0; 
        tim_h <= 0; 
        tim_l <= 0; 
    end 
    else begin
        case (state)
            IDLE: begin 
                if (start_dht) begin
                    state <= START; 
                    cnt_us <= 0; 
                    tim_h <= 0; 
                    tim_l <= 0; 
                    index <= 0; 
                    data_ready <= 0;
                    data_buffer <= 0; 
                    state_start <= 0; 
                    state_read <= 0; 
                end 
            end 
            START: begin 
                case (state_start)
                    step1: begin
                        data_dr <= 1; 
                        data_reg <= 0; 
                        if(cnt_us == 540_000) begin     // delay 20 ms begin start dht
                            cnt_us <= 0; 
                            state_start <= step_wait;
                            data_dr <= 0; 
                        end 
                        else 
                            cnt_us <= cnt_us + 1;
                    end 
                    step_wait: begin 
                        if (data == 1) begin 
                            state_start <= step2; 
                            cnt_us <= 0; 
                        end 
                        else begin 
                            cnt_us <= cnt_us + 1; 
                            if (cnt_us >= 405) begin  // 15 us for wait to catch data_line high 1
                                cnt_us <= 0; 
                                state <= IDLE; 
                            end 
                        end 
                    end 
                    step2: begin
                        if (data == 1) begin          // check time data_line = 1  
                            if (tim_h >= 60)
                                state <= IDLE;
                            if (cnt_us == 27) begin  // delay 1 us 
                                tim_h <= tim_h + 1; 
                                cnt_us <= 0; 
                            end 
                            else begin 
                                cnt_us <= cnt_us + 1; 
                            end  
                        end 
                        else if (data == 0) begin 
                            if (tim_h >= 5 && tim_h <= 50) begin // high from range 20 - 40 us 
                                state_start <= step3;            // xac nhan slave respone 0 
                                cnt_us <= 0; 
                                tim_h = 0; 
                            end 
                            else begin
                                state <= IDLE; 
                            end 
                        end 
                        

                    end 
                    step3: begin
                        if (data == 0) begin          // check time data_line = 0  
                            if (tim_l >= 110)
                                state <= IDLE;
                            if (cnt_us == 27) begin  // delay 1 us 
                                tim_l <= tim_l + 1; 
                                cnt_us <= 0; 
                            end 
                            else 
                                cnt_us <= cnt_us + 1; 
                        end 
                        else if (data == 1) begin 
                            if (tim_l >= 60 && tim_l <= 100) begin       // keep low 80 us 
                                state_start <= step4;                    // step check keep 1 
                                cnt_us <= 0; 
                                tim_l = 0; 
                            end
                            else begin 
                                state <= IDLE;
                            end 
                        end 
                    end 
                    step4: begin 
                        if (data == 1) begin 
                            if (tim_h >= 110)
                                state <= IDLE;
                            if (cnt_us == 27) begin  // delay 1 us 
                                tim_h <= tim_h + 1; 
                                cnt_us <= 0; 
                            end 
                            else 
                                cnt_us <= cnt_us + 1; 
                        end 
                        else if (data == 0) begin 
                            if (tim_h >= 60 && tim_h <= 100) begin 
                                state <= READ; 
                                cnt_us <= 0; 
                                tim_h = 0;  
                            end 
                            else begin 
                                state <= IDLE;
                            end 
                        end 
                    end 

                endcase 
            end 
            READ: begin 
                case(state_read) 
                    pre_read: begin
                        if (data == 0) begin 
                            if (tim_l >= 70)
                                state <= IDLE;
                            if (cnt_us == 27) begin  // delay 1 us 
                                tim_l <= tim_l + 1; 
                                cnt_us <= 0; 
                            end 
                            else 
                                cnt_us <= cnt_us + 1; 
                        end 
                        else if (data == 1) begin 
                            if (tim_l >= 35 && tim_l <= 65) begin 
                                state_read <= read;
                                cnt_us <= 0; 
                                tim_l = 0;  
                                data_buffer <= data_buffer << 1;                                 
                            end 
                            else begin 
                                state <= IDLE;
                            end 
                        end 
                    end 
                    read: begin
                        if (data == 1) begin 
                            if (tim_h >= 100)
                                state <= IDLE;
                            if (cnt_us == 27) begin  // delay 1 us 
                                tim_h <= tim_h + 1; 
                                cnt_us <= 0; 
                            end 
                            else 
                                cnt_us <= cnt_us + 1; 
                        end 
                        else if (data == 0) begin 
                            index <= index + 1; 
                            if (tim_h >= 15 && tim_h <= 40) begin 
                                
                                state_read <= next_read; 
                            //    data_buffer = data_buffer << 1;
                                data_buffer <= data_buffer | 40'd0; 
                                cnt_us <= 0; 
                                tim_h <= 0;  
                            end 
                            else if ( tim_h >= 50 && tim_h <= 90) begin 
                               
                                state_read <= next_read; 
                            //    data_buffer = data_buffer << 1;
                                data_buffer <= data_buffer | 40'd1;
                                cnt_us <= 0; 
                                tim_h <= 0; 
                            end 
                            else begin 
                                state <= IDLE;
                            end 
                        end 
                    end 
                    next_read: begin 
                        if (index == 40) begin 
                            state_read <= done_read; 
                        end 
                        else 
                            state_read <= pre_read; 
                    end
                    done_read: begin 
                       
                        state <= DONE; 
                    end 
                endcase 
            end 
            DONE: begin 
                data_ready <= 1; 
                if(~start_dht) 
                    state <= IDLE; 
            end 
        endcase 
    end 
end 
endmodule 