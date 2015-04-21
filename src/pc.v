module PC (
    input [31:0] pc_i,  // The new value for PC if stall_ctrl_i is not asserted.
    input stall_ctrl_i,  // Stall or not.
    output [31:0] pc_o,  // The value of the PC.

    input rst_i,  // Reset or not.
    input clk_i  // Note: this module works at posedge.
);

reg [31:0] pc;


assign pc_o = pc;


always @ (posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        pc <= 32'b0;
    end else begin
        if (~stall_ctrl_i) begin
            pc <= pc_i;
        end
    end
end

endmodule
