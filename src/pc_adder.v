module PCAdder (
    input [31:0] pc_i,  // The original pc.
    output [31:0] pc_o,  // The result pc (pc + 4).

    input rst_i,  // Reset or not.
    input clk_i  // Note: this module works at posedge.
);

reg [31:0] pc;

assign pc_o = pc;

always @ (posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        pc <= 32'b0;
    end else begin
        pc <= pc_i + 4;
    end
end

endmodule
