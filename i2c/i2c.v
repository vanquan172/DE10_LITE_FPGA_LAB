module i2c

#(
    parameter SYS_CLK = 27_000_000,
    parameter SCL_CLK = 100_000
)
(
    input clk,
    inout  wire  sda, 
    output reg scl,
    input [1:0] instr,
    input enable,
    input [7:0] byte_tx,
    output reg [7:0] byte_rx = 0,
    output reg complete, error
);
    localparam STATE_START_TX = 0;
    localparam STATE_STOP_TX = 1;
    localparam STATE_READ_BYTE = 2;
    localparam STATE_WRITE_BYTE = 3;

    localparam STATE_IDLE = 4;
    localparam STATE_DONE = 5;
    localparam STATE_SEND_ACK = 6;
    localparam STATE_RCV_ACK = 7;

localparam t_point = SYS_CLK / (4 * SCL_CLK); 

    reg [8:0] clk_div = 0;

    reg [2:0] state = STATE_IDLE;

    reg [2:0] bit_tx = 0;
    reg sda_dr; 
    reg sda_out; 
    assign sda  = sda_dr ? (sda_out) : 1'bz; 
    always @(posedge clk) begin
        case (state)
            STATE_IDLE: begin
                if (enable) begin
                    complete <= 0;
                    clk_div <= 0;
                    bit_tx <= 0;
                    state <= {1'b0,instr};
                    sda_dr <= 0; 
                    error <= 0; 
                end
            end
            STATE_START_TX: begin
                sda_dr <= 1; 
                clk_div <= clk_div + 1;
                if (clk_div == 9'd0 ) begin
                    scl <= 1;
                    sda_out <= 1;
                end 
                else if (clk_div  == t_point - 1) begin  // 67 135 203 271
                    sda_out <= 0;
                end 
                else if (clk_div  == 2*t_point - 1) begin
                    scl <= 0;
                end 
                else if (clk_div  == 3*t_point - 1) begin
                    state <= STATE_DONE;
                end
            end
            STATE_STOP_TX: begin
                sda_dr <= 1; 
                clk_div <= clk_div + 1;
                if (clk_div == 9'd0) begin
                    scl <= 0;
                    sda_out <= 0;
                end 
                else if (clk_div  == t_point - 1) begin
                    scl <= 1;
                end 
                else if (clk_div  == 2*t_point - 1) begin
                    sda_out <= 1;
                end 
                else if (clk_div  == 3*t_point - 1) begin
                    state <= STATE_DONE;
                end
            end
            STATE_READ_BYTE: begin
                sda_dr <= 0; 
                clk_div <= clk_div + 1;
                if (clk_div == 9'd0) begin
                    scl <= 0;
                end else if (clk_div  == t_point - 1) begin
                    scl <= 1;
                end else if (clk_div  == 2*t_point - 1) begin
                    byte_rx <= {byte_rx[6:0], sda ? 1'b1 : 1'b0};
                end 
                else if (clk_div  == 3*t_point - 1) begin
                    scl <= 0;
                end
                else if (clk_div  == 4*t_point - 1) begin
                    bit_tx <= bit_tx + 1;
                    clk_div <= 0; 
                    if (bit_tx == 3'b111) begin
                        state <= STATE_SEND_ACK;
                    end
                end 
            end
            STATE_SEND_ACK: begin
                sda_dr <= 1; 
                sda_out <= 0;
                clk_div <= clk_div + 1;
                if (clk_div == 9'd0) begin
                    scl <= 0;
                end 
                else if (clk_div  == t_point - 1) begin
                    scl <= 1;
                end 
                else if (clk_div  == 3*t_point - 1) begin
                    scl <= 0;
                end
                else if (clk_div  == 4*t_point - 1) begin
                    state <= STATE_DONE;
                end 
            end
            STATE_WRITE_BYTE: begin
                sda_dr <= 1;
                clk_div <= clk_div + 1;
                sda_out <= byte_tx[3'd7-bit_tx] ? 1'b1 : 1'b0;

                if (clk_div == 9'd0) begin
                    scl <= 0;
                end 
                else if (clk_div  == t_point - 1) begin
                    scl <= 1;
                end 
                else if (clk_div  == 3*t_point - 1) begin
                    scl <= 0;
                end
                else if (clk_div  == 4*t_point - 1) begin
                    bit_tx <= bit_tx + 1;
                    clk_div <= 0; 
                    if (bit_tx == 3'b111) begin
                        state <= STATE_RCV_ACK;
                    end
                end 

            end
            STATE_RCV_ACK: begin
                sda_dr <= 0;
                clk_div <= clk_div + 1;
                if (clk_div == 9'd0) begin
                    scl <= 0;
                end 
                else if (clk_div  == t_point - 1)begin
                    scl <= 1;
                end 
                else if (clk_div  == 2*t_point - 1) begin
                    if (sda == 0) begin 
                        error <= 0; 
                    end
                    else begin 
                        error <= 1; 
                    end 
                end 
                else if (clk_div  == 3*t_point - 1) begin
                    scl <= 0;
                end
                else if (clk_div  == 4*t_point - 1) begin
                    clk_div <= 0; 
                    state <= STATE_DONE; 
                end 
                
            end
            STATE_DONE: begin
                complete <= 1;
                if (~enable)
                    state <= STATE_IDLE;
            end
        endcase
    end
endmodule