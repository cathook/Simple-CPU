module MemToWB (
    input reg_write_ctrl_i,  // Control flag for writing back or not.
    input [4:0] reg_write_addr_i,  // The address of the register.
    input [31:0] reg_write_data_i,  // The data to be write.

    output reg_write_ctrl_o,  // Control flag for writing back or not.
    output [4:0] reg_write_addr_o,  // The address of the register.
    output [31:0] reg_write_data_o,  // The data to be write.

    input stall_ctrl_i,  // Stall or not.
    input rst_i,  // Reset or not.
    input clk_i  // Note: this module works at posedge.
);

reg reg_write_ctrl;
reg [4:0] reg_write_addr;
reg [31:0] reg_write_data;


assign reg_write_ctrl_o = reg_write_ctrl;
assign reg_write_addr_o = reg_write_addr;
assign reg_write_data_o = reg_write_data;


always @ (posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        reg_write_ctrl <= 1'b0;
        reg_write_addr <= 5'b0;
        reg_write_data <= 32'b0;
    end else begin
        if (stall_ctrl_i) begin
        end else begin
            reg_write_ctrl <= reg_write_ctrl_i;
            reg_write_addr <= reg_write_addr_i;
            reg_write_data <= reg_write_data_i;
        end
    end
end

endmodule
