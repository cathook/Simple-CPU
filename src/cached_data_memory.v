module CachedDataMemory (
    input [31:0] addr_i,  // The address to access.
    input read_ctrl_i,  // Flag for whether reading the data or not.
    input write_ctrl_i,  // Flag for whether writing the data or not.
    input [31:0] write_data_i,  // Data to be written if needed.

    output [31:0] read_data_o,  // The data got from the data cache.
    output stall_ctrl_o,  // Stall the pipelines or not.

    input rst_i,  // Reset flag.
    input clk_i
);

// Cache memory.
parameter pCachedSize = 1024;

`define dBlockNumber (pCachedSize / DataMemory.pBlockSize)
`define dOffsetWidth ($clog2(DataMemory.pBlockSize))
`define dIndexWidth ($clog2(`dBlockNumber))
`define dTagWidth (32 - `dOffsetWidth - `dIndexWidth)
`define dBlockBitsSize (DataMemory.pBlockSize * 8)

reg cache_valid[0 : `dBlockNumber - 1];
reg cache_dirty[0 : `dBlockNumber - 1];
reg [`dTagWidth - 1:0] cache_tag[0 : `dBlockNumber - 1];
reg [`dBlockBitsSize - 1:0] cache_data[0 : `dBlockNumber - 1];


// State about DataMemory.
parameter STATE_IDLE                = 2'h0;
parameter STATE_WAITING_FOR_WRITING = 2'h1;
parameter STATE_WAITING_FOR_READING = 2'h2;

reg [1:0] state;


// Connection to the data memory.
reg data_memory_enable;
reg [31:0] data_memory_addr;
reg data_memory_write_ctrl;
reg [`dBlockBitsSize - 1:0] data_memory_write_data;

DataMemory DataMemory (
    .enable_i (data_memory_enable),
    .addr_i (data_memory_addr),
    .write_ctrl_i (data_memory_write_ctrl),
    .write_data_i (data_memory_write_data),

    .rst_i (rst_i),
    .clk_i (~clk_i)
);


// Register for output data.
reg [31:0] read_data;
reg stall_ctrl;


assign read_data_o = read_data;
assign stall_ctrl_o = stall_ctrl;


wire [`dTagWidth - 1:0] tag = addr_i[31:32 - `dTagWidth];
wire [`dIndexWidth - 1:0] index = addr_i[31 - `dTagWidth:`dOffsetWidth];
wire [`dOffsetWidth - 1:0] offset = addr_i[`dOffsetWidth - 1:0];
wire [31:0] mem_addr = {{`dOffsetWidth{1'b0}}, tag, index};
wire [`dBlockBitsSize - 1:0] mask = ~({{(`dBlockBitsSize - 32){1'b0}},
                                       ~(32'b0)} << offset * 8);
wire [`dBlockBitsSize - 1:0] applier = {{(`dBlockBitsSize - 32){1'b0}},
                                        write_data_i} << offset * 8;

reg need_access_data_memory_ctrl;  // Flag indicates that it should access the memory


integer i;

// Implement flow:
// For reading request:
//     Case 1 -- The block is already in the cache memory:
//         Just return it.
//     Case 2 -- The block is not in the cache memory (i.e. miss occured):
//         Check if the original data in this cache block is dirty or not.
//         If it is valid and dirty, then first write it back to DataMemory.
//         Finally, read the block from the DataMemory.
// For writing request:
//     Case 1 -- The block is already in the cache memory:
//         Update the cache memory.
//     Case 2 -- The block us not in the cache memory (i.e. miss occured):
//         Check if the original data in this cache block is dirty or not.
//         If it is valid and dirty, then first write it back to DataMemory.
//         Finally, read the block from the DataMemory and handle it like Case 1.
always @ (posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        for (i = 0; i < `dBlockNumber; i = i + 1) begin
            cache_valid[i] <= 1'b0;
            cache_dirty[i] <= 1'b0;
        end
        state <= STATE_IDLE;
        data_memory_enable <= 1'b0;
        stall_ctrl <= 1'b0;
        need_access_data_memory_ctrl = 1'b0;
    end else begin
        if (read_ctrl_i) begin
            if (cache_valid[index] && cache_tag[index] == tag) begin
                read_data <= cache_data[index] >> offset * 8;
                stall_ctrl <= 0;
                need_access_data_memory_ctrl = 1'b0;
            end else begin
                read_data <= 32'b0;
                stall_ctrl <= 1;
                need_access_data_memory_ctrl = 1'b1;
            end
        end else if (write_ctrl_i) begin
            if (cache_valid[index] && cache_tag[index] == tag) begin
                cache_data[index] <= (cache_data[index] & mask) | applier;
                cache_dirty[index] <= 1'b1;
                stall_ctrl <= 0;
                need_access_data_memory_ctrl = 1'b0;
            end else begin
                stall_ctrl <= 1;
                need_access_data_memory_ctrl = 1'b1;
            end
        end
        case (state)
            STATE_IDLE: begin
                if (need_access_data_memory_ctrl) begin
                    if (cache_valid[index] && cache_dirty[index]) begin
                        data_memory_enable <= 1'b1;
                        data_memory_addr <= {{`dOffsetWidth{1'b0}}, cache_tag[index], index};
                        data_memory_write_ctrl <= 1'b1;
                        data_memory_write_data <= cache_data[index];
                        state <= STATE_WAITING_FOR_WRITING;
                        need_access_data_memory_ctrl = 1'b0;
                    end else begin
                        data_memory_enable <= 1'b1;
                        data_memory_addr <= mem_addr;
                        data_memory_write_ctrl <= 1'b0;
                        state <= STATE_WAITING_FOR_READING;
                        need_access_data_memory_ctrl = 1'b0;
                   end
                end
            end
            STATE_WAITING_FOR_READING: begin
                if (DataMemory.ack_o) begin
                    data_memory_enable <= 1'b0;
                    cache_valid[index] <= 1'b1;
                    cache_dirty[index] <= 1'b0;
                    cache_tag[index] <= tag;
                    cache_data[index] <= DataMemory.read_data_o;
                    state <= STATE_IDLE;
                end
            end
            STATE_WAITING_FOR_WRITING: begin
                if (DataMemory.ack_o) begin
                    data_memory_enable <= 1'b0;
                    cache_dirty[index] <= 1'b0;
                    state <= STATE_IDLE;
                end
            end
        endcase
    end
end

endmodule
