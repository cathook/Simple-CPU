module IFToID (
    input [31:0] pc_i,  // The pc next to the instruction's.
    input [31:0] instr_i,  // 32-bits input instruction.
    input flush_ctrl_i,  // Flag for flushing or not.

    output [31:0] pc_o,  // The pc next to the instruction's.
    output [31:0] instr_o,  // The instruction.

    input stall_ctrl_i,  // Stall or not.
    input rst_i,  // Reset or not.
    input clk_i  // Note: this module works on posedge.
);

reg [31:0] pc;
reg [31:0] instr;

assign pc_o = pc;
assign instr_o = instr;


always @ (posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        pc <= 32'b0;
        instr <= 32'b0;
    end else begin
        if (stall_ctrl_i) begin
        end else if (flush_ctrl_i) begin
            pc <= 32'b0;
            instr <= {32{1'b1}};
        end else begin
            pc <= pc_i;
            instr <= instr_i;
        end
    end
end

endmodule
