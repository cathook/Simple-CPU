module InstructionMemory (
    input [31:0] addr_i,  // Address of the instruction to get.
    output [31:0] instr_o,  // The instruction.

    input rst_i,  // Reset or not.
    input clk_i  // This module works at posedge.
);

parameter pInstructionSize = 1024;  // Size of the instructions.

reg [31:0] instruction[0 : pInstructionSize - 1];  // Instructions

reg [31:0] instr;


assign instr_o = instr;


integer iter;

always @ (posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        instr <= ~(32'b0);
    end else begin
        instr <= instruction[addr_i >> 2];
    end
end

endmodule
