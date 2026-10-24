module ROM #(
    parameter addr_size = 12,
    parameter mem_size  = (1 << addr_size),
    parameter Bits      = 8,
    parameter Bytes     = 2
)(
    input                          CK,
    input                          CS,
    input                          OE,
    input      [addr_size-1:0]     A,
    output reg [Bytes*Bits-1:0]    DO
);

    reg [Bits-1:0] Memory_byte0 [0:mem_size-1];
    reg [Bits-1:0] Memory_byte1 [0:mem_size-1];
    reg [Bytes*Bits-1:0] latched_DO;

    always @(posedge CK) begin
        if (CS) begin
            DO[0*Bits +: Bits] <= Memory_byte0[A];
            DO[1*Bits +: Bits] <= Memory_byte1[A];
        end
    end

    // always @(*) begin
    //     if (OE)
    //         DO = latched_DO;
    //     else
    //         DO = {(Bytes*Bits){1'bz}};
    // end

endmodule
