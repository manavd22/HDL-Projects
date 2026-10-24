`timescale 1ns/1ps

module SNU #(
    parameter N           = 64,
    parameter INDEX_WIDTH = 6,
    parameter ADDR_WIDTH  = 12,
    parameter DATA_WIDTH  = 8,
    parameter ACC_WIDTH   = 22
)(
    input  logic        CLK,
    input  logic        RST,       
    input  logic        in_valid,  
    input  logic [15:0] S,         
    output logic [15:0] A,
    output logic        A_valid
);

    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        LOAD    = 2'b01,
        PROCESS = 2'b10,
        DONE    = 2'b11
    } state_t;

    state_t      state;
    logic [6:0]  count;       
    logic [15:0] reg_file [0:63]; 
    logic [31:0] row_sum;     
    
    always_ff @(posedge CLK or negedge RST) begin 
        if(!RST) begin
            state   <= IDLE;
            count   <= 7'd0;
            row_sum <= 32'd0;
            A       <= 16'd0;
            A_valid <= 1'b0;
            for(int i = 0; i < 64; i++) reg_file[i] <= 16'd0;
        end else begin
            A_valid <= 1'b0; 
            
            case(state)
                IDLE: begin
                    count   <= 7'd0;
                    row_sum <= 32'd0;
                    
                    if (in_valid) begin
                        reg_file[0] <= S;
                        row_sum     <= S;
                        count       <= 7'd1;
                        state       <= LOAD;
                    end
                end
                LOAD: begin
                    if (in_valid) begin
                        reg_file[count] <= S;
                        row_sum         <= row_sum + S;
                        
                        if (count == 7'd63) begin
                            count <= 7'd0;
                            state <= PROCESS; 
                        end else begin
                            count <= count + 7'd1;
                        end
                    end
                end
                PROCESS: begin
                    // Simulation only divider
                    A       <= (reg_file[count] << 15) / row_sum;
                    A_valid <= 1'b1;
                    
                    if (count == 7'd63) begin
                        count <= 7'd0;
                        state <= DONE;
                    end else begin
                        count <= count + 7'd1;
                    end
                end
                DONE: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule