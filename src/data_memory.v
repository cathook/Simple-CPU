module DataMemory (
    enable_i,
    addr_i,
    write_ctrl_i,
    write_data_i,

    read_data_o,
    ack_o,

    rst_i,
    clk_i
);

// Size of the data memory and the block size with unit = byte.
parameter pMemorySize = 16384;
parameter pBlockSize = 32;


// input and output
input enable_i;  // Whether the input is meaningful or not.
input [31:0] addr_i;  // Address of the memory to be operated (unit = block)
input write_ctrl_i;  // Flag for writing data or not (if false, reading).
input [pBlockSize * 8 - 1:0] write_data_i;  // Data to be write if needs.

output [pBlockSize * 8 - 1:0] read_data_o;  // Data in the specified memory.
output ack_o;  // The ack to indicate that it is finished.

input rst_i;  // Reset or not.
input clk_i;  // This module works at posedge.


reg [pBlockSize * 8 - 1:0] memory[0 : pMemorySize / pBlockSize - 1];

reg do_access;  // Do the read/write or not.


reg [pBlockSize * 8 - 1:0] read_data;
reg ack;


// State.
parameter STATE_IDLE    = 2'h0;
parameter STATE_WAIT    = 2'h1;
parameter STATE_ACK     = 2'h2;
parameter STATE_FINISH  = 2'h3;
reg [3:0] count;  // For delaying.
reg [1:0] state;


assign read_data_o = read_data;
assign ack_o = ack;


// Accessing the data memory.
always @ (posedge clk_i) begin
    if (do_access) begin
        if (write_ctrl_i) begin
            memory[addr_i] <= write_data_i;
        end else begin
            read_data <= memory[addr_i];
        end
    end
end


integer iter;

always @ (posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        for (iter = 0; iter < pMemorySize / pBlockSize; iter = iter + 1) begin
            memory[iter] = {(pBlockSize * 8){1'b0}};
        end
        do_access <= 1'b0;
        ack <= 1'b0;
        count <= 4'b0;
        state <= STATE_IDLE;
    end else begin
        case (state)
            STATE_IDLE: begin
                if ((~rst_i) && enable_i) begin
                    count <= count + 1;
                    state <= STATE_WAIT;
                end
            end
            STATE_WAIT: begin
                if (count < 4'd6) begin
                    count <= count + 1;
                end else begin
                    count <= 4'd0;
                    do_access <= 1'b1;
                    state <= STATE_ACK;
                end
            end
            STATE_ACK: begin
                ack <= 1'b1;
                do_access <= 1'b0;
                state <= STATE_FINISH;
            end
            STATE_FINISH: begin
                ack <= 1'b0;
                state <= STATE_IDLE;
            end
        endcase
    end
end

endmodule
