module ctr_lcd (
    input             clk, rst,
    input             start_dis,
    input   [15:0]    temp_dis,hum_dis,
    output  [3:0]     data_out,
    output            rs, en,
    output            complete_dis
);

// ====== Register & Wire Declaration ======
//reg                  start_dis; 
reg                  start_send; 
reg   [2:0]          state;
reg   [4:0]          sub_task;
reg   [2:0]          state_dislay;
reg                  complete_dis_reg; 
reg   [7:0]          data_send;
wire  [3:0]          data_out_reg;
wire                 en_reg;
reg                  rs_reg; 
wire                 send_done; 
reg                  process; 
reg   [17:0]         cnt_delay;

parameter wid_t =  11; 
parameter wid_h =  9; 
reg   [8*wid_t-1:0]     lcd_data_temp;   // Chuỗi 5 ký tự (40 bit)
reg   [8*wid_h-1:0]      lcd_data_hum;    // Chuỗi 5 ký tự (40 bit)

// ====== LCD Module Instance ======
lcd16_02 ins_lcd (
    .clk(clk), 
    .rst(rst), 
    .start(start_send), 
    .data_in(data_send), 
    .data_out(data_out_reg),
    .done(send_done), 
    .en(en_reg)
);

// ====== Output Assign ======
assign data_out      = data_out_reg;
assign en            = en_reg; 
assign rs            = rs_reg; 
assign complete_dis  = complete_dis_reg;

// ====== State Machine Parameter ======
localparam STATE_TASK_INIT   = 3'd0; 
localparam STATE_IDLE        = 3'd1; 
localparam STATE_TASK_DIS    = 3'd2;
localparam STATE_WAIT_INIT    = 3'd3;
localparam STATE_WAIT_DIS   = 3'd4;
localparam STATE_INC_TASK_INIT    = 3'd5;
localparam STATE_INC_TASK_DIS    = 3'd6;
localparam STATE_DONE        = 3'd7;


localparam DISLAY0           = 3'd0;
localparam DISLAY1           = 3'd1;
localparam DISLAY2           = 3'd2;
localparam DISLAY3           = 3'd3;
localparam DISLAY4           = 3'd4;
reg [7:0]   value = 0;  
reg [31:0]   delay = 0;  
reg [31:0]   delay_done = 0;  
reg [3:0]   cnt; 
// always @(posedge clk) begin
//     if (rst == 0) begin
//         cnt <= 0; 
//         value <= 8'd48; // ASCII '0'
//         delay <= 0;
//     end 
//     else if (delay == 27_000_000) begin 
//         delay <= 0;
//         if (cnt == 4'd9)
//             cnt <= 0;
//         else
//             cnt <= cnt + 1;
//         value <= "0" + cnt;  
//     end else begin
//         delay <= delay + 1; 
//     end
// end 

reg 	[7:0] 	temp_ch, temp_dv, hum_ch, hum_dv; 

always @(temp_dis or hum_dis) begin
	temp_ch <= "0" + (temp_dis / 10); 
	temp_dv <= "0" + (temp_dis % 10); 
	hum_ch  <= "0" + (hum_dis / 10); 
	hum_dv  <= "0" + (hum_dis % 10); 
end 

// ====== Cập nhật LCD Data ======
always @(temp_ch or hum_ch) begin
    lcd_data_temp <= {"temp: ", temp_ch, temp_dv," ",8'b11011111,"C"}; // lcd_data_temp khai báo [79:0]
    lcd_data_hum  <= {"hum: ", hum_ch, hum_dv, " %"};             // lcd_data_hum khai báo [39:0] nếu HOLLO
   // start_dis     <= 1;  
end


// ====== Main FSM ======
always @(posedge clk or negedge rst) begin
    if (rst == 0) begin 
        state <= STATE_TASK_INIT; 
        sub_task <= 0; 
        process <= 0; 
        cnt_delay <= 0; 
    end else begin 
        case (state) 
            
            // ----- LCD INIT -----
            STATE_TASK_INIT: begin 
                rs_reg <= 0; 
                case (sub_task)
                    5'd0: begin
                        start_send <= 1; 
                        data_send  <= 8'h33; 
                        process <= 1;
                        if (cnt_delay == 135000) begin      
                            state      <= STATE_WAIT_INIT; 
                            cnt_delay  <= 0; 
                        end else begin
                            cnt_delay  <= cnt_delay + 1; 
                        end 
                    end
                    5'd1: begin
                        start_send <= 1; 
                        data_send  <= 8'h33;
                        process <= 1;    
                        if (cnt_delay == 2700) begin      
                            state      <= STATE_WAIT_INIT; 
                            cnt_delay  <= 0; 
                        end else begin
                            cnt_delay  <= cnt_delay + 1; 
                        end 
                    end
                    5'd2: begin
                        start_send <= 1; 
                        data_send  <= 8'h33; 
                        process <= 1;       
                        if (cnt_delay == 2700) begin      
                            state      <= STATE_WAIT_INIT; 
                            cnt_delay  <= 0; 
                        end else begin
                            cnt_delay  <= cnt_delay + 1; 
                        end 
                    end
                    5'd3: begin
                        start_send <= 1; 
                        data_send  <= 8'h22;    
                        process <= 1;    
                        if (cnt_delay == 2700) begin      
                            state      <= STATE_WAIT_INIT; 
                            cnt_delay  <= 0; 
                        end else begin
                            cnt_delay  <= cnt_delay + 1; 
                        end 
                    end
                    5'd4: begin
                        start_send <= 1; 
                        data_send  <= 8'h28;    // font 5*8, 2 lines 
                        process <= 1;       
                        if (cnt_delay == 1080) begin      
                            state      <= STATE_WAIT_INIT; 
                            cnt_delay  <= 0; 
                        end else begin
                            cnt_delay  <= cnt_delay + 1; 
                        end 
                    end
                    5'd5: begin
                        start_send <= 1; 
                        data_send  <= 8'h08;  // turn off dislay 
                        process <= 1;      
                        if (cnt_delay == 1080) begin      
                            state      <= STATE_WAIT_INIT; 
                            cnt_delay  <= 0; 
                        end else begin
                            cnt_delay  <= cnt_delay + 1; 
                        end 
                    end
                    5'd6: begin
                        start_send <= 1; 
                        data_send  <= 8'h01; // clear dislay 
                        process <= 1;       
                        if (cnt_delay == 54000) begin      
                            state      <= STATE_WAIT_INIT; 
                            cnt_delay  <= 0; 
                        end else begin
                            cnt_delay  <= cnt_delay + 1; 
                        end 
                    end
                    5'd7: begin
                        start_send <= 1; 
                        data_send  <= 8'h06; // entry mode 
                        process <= 1;       
                        if (cnt_delay == 1080) begin      
                            state      <= STATE_WAIT_INIT; 
                            cnt_delay  <= 0; 
                        end else begin
                            cnt_delay  <= cnt_delay + 1; 
                        end 
                    end
                    5'd8: begin
                        start_send <= 1; 
                        data_send  <= 8'h0C;  // turn on dislay 
                        process <= 1;      
                        if (cnt_delay == 1080) begin      
                            state      <= STATE_WAIT_INIT; 
                            cnt_delay  <= 0; 
                        end else begin
                            cnt_delay  <= cnt_delay + 1; 
                        end 
                    end
                    default: state <= STATE_IDLE; 
                endcase 
            end
            // ====== IDLE STATE ======
            STATE_IDLE: begin 
                if (start_dis) begin 
                    state          <= STATE_TASK_DIS; 
                    sub_task       <= 0; 
                    state_dislay   <= 0; 
                    cnt_delay      <= 0; 
                    process        <= 0; 
                    complete_dis_reg <= 0; 
                end
            end 
            // ====== RUN TASK ======
            STATE_TASK_DIS: begin
                case (state_dislay)
                    DISLAY0: begin
                        rs_reg <= 0; 
                        start_send <= 1; 
                        data_send  <= 8'h01;  // clear dislay 
                        process <= 1;      
                        if (cnt_delay == 54000) begin      
                            state      <= STATE_WAIT_DIS; 
                            cnt_delay  <= 0; 
                        end else begin
                            cnt_delay  <= cnt_delay + 1; 
                        end 
                    end 
                    DISLAY1: begin 
                        rs_reg     <= 0;
                        start_send <= 1; 
                        data_send  <= 8'h83; 
                        process <= 1;
                        if (cnt_delay == 1080) begin 
                            state      <= STATE_WAIT_DIS; 
                            cnt_delay  <= 0;
                        end else begin   
                            cnt_delay  <= cnt_delay + 1;
                        end
                    end 
                    DISLAY2: begin 
                        rs_reg     <= 1; 
                        start_send <= 1; 
                        process <= 1;
                        data_send  <= lcd_data_temp[((wid_t - 1 - sub_task) * 8) +: 8];
                        if (cnt_delay == 1080) begin 
                            state      <= STATE_WAIT_DIS; 
                            cnt_delay  <= 0;
                        end else begin
                            cnt_delay  <= cnt_delay + 1;
                        end
                    end 
                    DISLAY3: begin 
                        rs_reg     <= 0;
                        start_send <= 1; 
                        data_send  <= 8'hC4; 
                        process <= 1;
                        if (cnt_delay == 1080) begin 
                            state      <= STATE_WAIT_DIS; 
                            cnt_delay  <= 0;
                        end else begin   
                            cnt_delay  <= cnt_delay + 1;
                        end
                    end 
                    DISLAY4: begin 
                        rs_reg     <= 1; 
                        start_send <= 1; 
                        process <= 1;
                        data_send  <= lcd_data_hum[((wid_h - 1 - sub_task) * 8) +: 8];
                        if (cnt_delay == 1080) begin 
                            state      <= STATE_WAIT_DIS; 
                            cnt_delay  <= 0;
                        end else begin   
                            cnt_delay  <= cnt_delay + 1;
                        end
                    end 
                endcase
            end 
            // ====== WAIT SEND DONE ======
            STATE_WAIT_INIT: begin 
                if (process && send_done) begin 
                        process <= 0; 
                        start_send <= 0; 
                        state <= STATE_INC_TASK_INIT;
                end 
            end
            // ====== WAIT SEND DONE ======
            STATE_WAIT_DIS: begin 
                if (process && send_done) begin 
                        process <= 0; 
                        start_send <= 0; 
                        state <= STATE_INC_TASK_DIS;
                end 
            end
            STATE_INC_TASK_INIT: begin
                state <= STATE_TASK_INIT;
                if (sub_task == 5'd8) begin
                    sub_task <= 0;
                    state <= STATE_IDLE;
                end else begin
                    sub_task <= sub_task + 1; 
                end 
            end 
            // ====== INCREMENT TASK ======
            STATE_INC_TASK_DIS: begin
                    state <= STATE_TASK_DIS;
                    case (state_dislay)
                        DISLAY0: state_dislay <= DISLAY1; 
                        DISLAY1: state_dislay <= DISLAY2;
                        DISLAY2: begin 
                            if (sub_task == wid_t-1) begin 
                                sub_task    <= 0; 
                                state_dislay <= DISLAY3;
                            end else begin
                                sub_task <= sub_task + 1; 
                            end 
                        end 
                        DISLAY3: state_dislay <= DISLAY4;
                        DISLAY4: begin
                            if (sub_task == wid_h-1) begin 
                                sub_task <= 0; 
                                state    <= STATE_DONE; 
                            end else begin
                                sub_task <= sub_task + 1; 
                            end 
                        end 
                    endcase 
            end 
            // ====== DONE STATE ======
            STATE_DONE: begin 
                complete_dis_reg <= 1; 
                if (~start_dis)
                    state <= STATE_IDLE; 
                // if (delay_done == 27_000_000) begin
                //     delay_done <= 0; 
                //     state <= STATE_IDLE;
                // end 
                // else
                //     delay_done <= delay_done + 1; 
            end 
        endcase
    end 
end 

endmodule  
