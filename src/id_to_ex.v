module IDToEx (
    input [4:0] reg_read_addr1_i,  // The address of the first register.
    input [4:0] reg_read_addr2_i,  // The address of the second register.
    input [4:0] reg_write_addr_i,  // The address of the writing register.
    input [31:0] reg_read_data1_i,  // The data from the first register.
    input [31:0] reg_read_data2_i,  // The data from the second register.
    input [4:0] shift_i,  // Shift info.
    input [31:0] sign_extended_value_i,  // The data from the sign extend operation.
    input [2:0] alu_ctrl_i,  // Control flag for ALU.
    input use_shift_ctrl_i,  // Use shift amount as reg1 or not.
    input use_sign_extend_ctrl_i,  // Use sign extended value or not.
    input reg_write_ctrl_i,  // Control flag for writing back or not.
    input mem_read_ctrl_i,  // Control flag for reading memory or not.
    input mem_write_ctrl_i,  // Control flag for writing memory or not.

    output [4:0] reg_read_addr1_o,  // The address of the first register.
    output [4:0] reg_read_addr2_o,  // The address of the second register.
    output [4:0] reg_write_addr_o,  // The address of the writing register.
    output [31:0] reg_read_data1_o,  // The data from the first register.
    output [31:0] reg_read_data2_o,  // The data from the second register.
    output [4:0] shift_o,  // Shift info.
    output [31:0] sign_extended_value_o,  // The data from the sign extend operation.
    output [2:0] alu_ctrl_o,  // Control flag for ALU.
    output use_shift_ctrl_o,  // Use shift amount as reg1 or not.
    output use_sign_extend_ctrl_o,  // Use sign extended value or not.
    output reg_write_ctrl_o,  // Control flag for writing back or not.
    output mem_read_ctrl_o,  // Control flag for reading memory or not.
    output mem_write_ctrl_o,  // Control flag for writing memory or not.

    input stall_ctrl_i,  // Stall or not.
    input rst_i,  // Reset or not.
    input clk_i  // Note: this module works at posedge.
);

reg [4:0] reg_read_addr1;
reg [4:0] reg_read_addr2;
reg [4:0] reg_write_addr;
reg [31:0] reg_read_data1;
reg [31:0] reg_read_data2;
reg [4:0] shift;
reg [31:0] sign_extended_value;
reg [2:0] alu_ctrl;
reg use_shift_ctrl;
reg use_sign_extend_ctrl;
reg reg_write_ctrl;
reg mem_read_ctrl;
reg mem_write_ctrl;


assign reg_read_addr1_o = reg_read_addr1;
assign reg_read_addr2_o = reg_read_addr2;
assign reg_write_addr_o = reg_write_addr;
assign reg_read_data1_o = reg_read_data1;
assign reg_read_data2_o = reg_read_data2;
assign shift_o = shift;
assign sign_extended_value_o = sign_extended_value;
assign alu_ctrl_o = alu_ctrl;
assign use_shift_ctrl_o = use_shift_ctrl;
assign use_sign_extend_ctrl_o = use_sign_extend_ctrl;
assign reg_write_ctrl_o = reg_write_ctrl;
assign mem_read_ctrl_o = mem_read_ctrl;
assign mem_write_ctrl_o = mem_write_ctrl;


always @ (posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        reg_read_addr1 <= 5'b0;
        reg_read_addr2 <= 5'b0;
        reg_write_addr <= 5'b0;
        reg_read_data1 <= 32'b0;
        reg_read_data2 <= 32'b0;
        shift <= 5'b0;
        sign_extended_value <= 32'b0;
        alu_ctrl <= 3'b00;
        use_shift_ctrl <= 1'b0;
        use_sign_extend_ctrl <= 1'b0;
        reg_write_ctrl <= 1'b0;
        mem_read_ctrl <= 1'b0;
        mem_write_ctrl <= 1'b0;
    end else begin
        if (stall_ctrl_i) begin
        end else begin
            reg_read_addr1 <= reg_read_addr1_i;
            reg_read_addr2 <= reg_read_addr2_i;
            reg_write_addr <= reg_write_addr_i;
            reg_read_data1 <= reg_read_data1_i;
            reg_read_data2 <= reg_read_data2_i;
            shift <= shift_i;
            sign_extended_value <= sign_extended_value_i;
            alu_ctrl <= alu_ctrl_i;
            use_shift_ctrl <= use_shift_ctrl_i;
            use_sign_extend_ctrl <= use_sign_extend_ctrl_i;
            reg_write_ctrl <= reg_write_ctrl_i;
            mem_read_ctrl <= mem_read_ctrl_i;
            mem_write_ctrl <= mem_write_ctrl_i;
        end
    end
end

endmodule
