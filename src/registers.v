module Registers (
    input [4:0] read_addr1_i,  // Address of the first register to be read.
    input [4:0] read_addr2_i,  // Address of the second register to be read.
    input [4:0] write_addr_i,  // Address of the register to be write if needs.
    input [31:0] write_data_i,  // Data to be write if needs.
    input write_ctrl_i,  // Flag for writing the data or not.

    output [31:0] read_data1_o,  // Content of the first register.
    output [31:0] read_data2_o,  // Content of the second register.

    input rst_i,  // Reset the register or not.
    input clk_i  // This module works at posedge.
);

reg [31:0] register[0 : 31];  // Registers.

assign read_data1_o = register[read_addr1_i];
assign read_data2_o = register[read_addr2_i];

integer iter;

always @ (posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        for (iter = 0; iter < 32; iter = iter + 1) begin
            register[iter] <= 32'b0;
        end
    end else begin
        if (write_ctrl_i) begin
            register[write_addr_i] <= write_data_i[31:0];
        end
    end
end

endmodule
