module lcd16_02 
(
    input       clk,rst,
    input       start,
    input   [7:0]     data_in,
    output  reg [3:0]     data_out,
    output  reg   done,
    output  reg   en
 //   output  reg [2:0] state

); 

localparam  IDLE           = 3'd0;
localparam  PRE_SEND_H     = 3'd1;
localparam  SEND_H         = 3'd2;
localparam  PRE_SEND_L     = 3'd3;
localparam  SEND_L         = 3'd4;
localparam  DONE           = 3'd5;

reg [14:0] cnt_delay;
//always @(posedge clk)
//    begin 
//        if(rst)
//            cnt_delay <= 0; 
//        else 
//            cnt_delay <= cnt_delay + 1;
//    end 
//reg     en; 
reg [2:0]   state; 
always @(posedge clk or negedge rst)
    begin 
        if (rst == 0)
            begin
                state <= IDLE;   
                en <= 0; 
			       cnt_delay <= 0;  
            end 
        else 
            case(state)
                IDLE: 
                    begin 
                        if (start)
                            begin 
                                state <= PRE_SEND_H; 
						        done <= 0; 
                                en <= 0; 
                                data_out <= 0; 
                                cnt_delay <= 0; 
                            end 
                    end 
                PRE_SEND_H:
                    begin 
                        data_out <= data_in[7:4];
                        en <= 1;
                        if (cnt_delay == 27)
                            begin 
                                cnt_delay <= 0;
                                state <= SEND_H;
                            end 
						else 
							cnt_delay <= cnt_delay + 1; 
                    end 
                SEND_H: 
                    begin
                        en <= 0; 
                        if (cnt_delay == 27)
                            begin 
                                cnt_delay <= 0;
                                state <= PRE_SEND_L;
                            end 
                        else 
                            cnt_delay <= cnt_delay + 1; 
                    end
                PRE_SEND_L: 
                    begin
                        data_out <= data_in[3:0];
                        en <= 1;
                        if (cnt_delay == 27)
                            begin 
                                cnt_delay <= 0;
                                state <= SEND_L;
                            end 
                        else 
                            cnt_delay <= cnt_delay + 1; 
                    end 
                SEND_L:
                    begin 
                        en <= 0; 
                        if (cnt_delay == 27)
                            begin 
                                cnt_delay <= 0;
                                state <= DONE;
                            end 
                        else 
                            cnt_delay <= cnt_delay + 1; 
                    end 

                DONE:
                    begin
                        done <= 1; 
                        if(~start)
                            state <= IDLE; 
                    end 
            endcase 

    end 

endmodule 