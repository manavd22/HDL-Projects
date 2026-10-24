module SRAM #(
    parameter integer WORDS = 4096,
    parameter integer DATA_WIDTH = 16,
    parameter integer ADDR_WIDTH = 12
)(
    input  logic                  CK,
    input  logic                  CEB,
    input  logic                  WEB,
    input  logic [ADDR_WIDTH-1:0] A,
    input  logic [DATA_WIDTH-1:0] D,
    output logic [DATA_WIDTH-1:0] Q
);

    logic [DATA_WIDTH-1:0] MEMORY [0:WORDS-1];

    always_ff @(posedge CK) begin
        if (!CEB) begin
            if (!WEB)
                MEMORY[A] <= D;
            else
                Q <= MEMORY[A];
        end
    end

endmodule
