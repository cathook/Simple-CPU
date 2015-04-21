module ExToMem (
    input [4:0] reg_write_addr_i,  // Address of the register to write back.
    input reg_write_ctrl_i,  // Flag for writing back or not.
    input [31:0] reg_write_data_i,  // Data to be write back into the register.
    input [31:0] mem_addr_i,  // Address of the data memory to access.
    input mem_read_ctrl_i,  // Flag for reading the memory.
    input mem_write_ctrl_i,  // Flag for writing the memory.
    input [31:0] mem_write_data_i,  // Data to be wrote to the memory.

    output [4:0] reg_write_addr_o,  // Address of the register to be write.
    output [31:0] reg_write_data_o,  // Data to be write back into the register.
    output reg_write_ctrl_o,  // Flag for writing back or not.
    output [31:0] mem_addr_o,  // Address of the data memory to access.
    output mem_read_ctrl_o,  // Flag for reading the memory.
    output mem_write_ctrl_o,  // Flag for writing the memory.
    output [31:0] mem_write_data_o,  // Data to be wrote to the memory.

    input stall_ctrl_i,  // Stall or not.
    input rst_i,  // Reset or not.
    input clk_i  // Note: this module works at posedge.
);

reg [4:0] reg_write_addr;
reg [31:0] reg_write_data;
reg reg_write_ctrl;
reg [31:0] mem_addr;
reg mem_read_ctrl;
reg mem_write_ctrl;
reg [31:0] mem_write_data;


assign reg_write_addr_o = reg_write_addr;
assign reg_write_data_o = reg_write_data;
assign reg_write_ctrl_o = reg_write_ctrl;
assign mem_addr_o = mem_addr;
assign mem_read_ctrl_o = mem_read_ctrl;
assign mem_write_ctrl_o = mem_write_ctrl;
assign mem_write_data_o = mem_write_data;


always @ (posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        reg_write_addr <= 5'b0;
        reg_write_data <= 32'b0;
        reg_write_ctrl <= 1'b0;
        mem_addr <= 32'b0;
        mem_read_ctrl <= 1'b0;
        mem_write_ctrl <= 1'b0;
        mem_write_data <= 32'b0;
    end else begin
        if (stall_ctrl_i) begin
        end else begin
            reg_write_addr <= reg_write_addr_i;
            reg_write_data <= reg_write_data_i;
            reg_write_ctrl <= reg_write_ctrl_i;
            mem_addr <= mem_addr_i;
            mem_read_ctrl <= mem_read_ctrl_i;
            mem_write_ctrl <= mem_write_ctrl_i;
            mem_write_data <= mem_write_data_i;
        end
    end
end

endmodule
