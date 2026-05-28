module SPI_Slave #(
    parameter DATA_WIDTH = 8
)(
    // System signals
    input  wire clk,           // System clock
    input  wire rst_n,         // Active low reset
    
    // SPI interface
    input  wire sclk,          // SPI clock from master
    input  wire mosi,          // Master Out, Slave In
    output reg  miso,          // Master In, Slave Out
    input  wire cs_n,          // Chip select (active low)
    
    // Data interface
    input  wire [DATA_WIDTH-1:0] tx_data,    // Data to transmit
    output reg  [DATA_WIDTH-1:0] rx_data,    // Received data
    output reg  tx_req,                      // Request for new transmit data
    output reg  rx_valid                     // Received data valid
    
    // Control signals
    //input  wire cpol,          // Clock polarity (0: idle low, 1: idle high)
    //input  wire cpha           // Clock phase (0: sample on first edge, 1: sample on second edge)
);
    wire cpol;
    wire cpha;
    
    assign cpol = 1'b0;
    assign cpha = 1'b0;
    
    // Internal signals
    reg [2:0] sclk_sync;       // Sync for sclk
    reg [2:0] cs_n_sync;       // Sync for cs_n
    reg sclk_prev;             // Previous sclk state
    reg cs_active;             // Chip select active flag
    
    // Shift registers
    reg [DATA_WIDTH-1:0] tx_shift_reg;
    reg [DATA_WIDTH-1:0] rx_shift_reg;
    
    // Bit counter
    reg [$clog2(DATA_WIDTH):0] bit_count;
    
    // Edge detection
    wire sclk_posedge, sclk_negedge;
    wire sample_edge, shift_edge;
    wire cs_falling, cs_rising;
    
    // Synchronize external signals to system clock
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_sync <= 3'b000;
            cs_n_sync <= 3'b111;
        end else begin
            sclk_sync <= {sclk_sync[1:0], sclk};
            cs_n_sync <= {cs_n_sync[1:0], cs_n};
        end
    end
    
    // Edge detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_prev <= 1'b0;
        end else begin
            sclk_prev <= sclk_sync[2];
        end
    end
    
    assign sclk_posedge = !sclk_prev && sclk_sync[2];
    assign sclk_negedge = sclk_prev && !sclk_sync[2];
    assign cs_falling = cs_n_sync[2:1] == 2'b10;
    assign cs_rising = cs_n_sync[2:1] == 2'b01;
    
    // Determine sampling and shifting edges based on CPOL and CPHA
    assign sample_edge = (cpol == cpha) ? sclk_posedge : sclk_negedge;
    assign shift_edge = (cpol == cpha) ? sclk_negedge : sclk_posedge;
    
    // Chip select active detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cs_active <= 1'b0;
        end else begin
            if (cs_falling) begin
                cs_active <= 1'b1;
            end else if (cs_rising) begin
                cs_active <= 1'b0;
            end
        end
    end
    
    // Bit counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_count <= {($clog2(DATA_WIDTH)+1){1'b0}};
        end else begin
            if (!cs_active) begin
                bit_count <= {($clog2(DATA_WIDTH)+1){1'b0}};
            end else if (sample_edge && cs_active) begin
                if (bit_count == DATA_WIDTH - 1) begin
                    bit_count <= {($clog2(DATA_WIDTH)+1){1'b0}};
                end else begin
                    bit_count <= bit_count + 1;
                end
            end
        end
    end
    
    // Transmit shift register and MISO output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_reg <= {DATA_WIDTH{1'b0}};
            miso <= 1'b0;
        end else begin
            if (cs_falling) begin
                // Load new data at start of transaction
                tx_shift_reg <= tx_data;
                miso <= tx_data[DATA_WIDTH-1];
            end else if (shift_edge && cs_active) begin
                // Shift out next bit
                tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0};
                miso <= tx_shift_reg[DATA_WIDTH-2];
            end else if (!cs_active) begin
                miso <= 1'b0;
            end
        end
    end 

    
    // Receive shift register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            if (sample_edge && cs_active) begin
                rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], mosi};
            end
        end
    end
    
    // Output received data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= {DATA_WIDTH{1'b0}};
        end else begin
            if (sample_edge && cs_active && (bit_count == DATA_WIDTH - 1)) begin
                rx_data <= {rx_shift_reg[DATA_WIDTH-2:0], mosi};
            end
        end
    end
    
    // Generate control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_valid <= 1'b0;
            tx_req <= 1'b0;
        end else begin
            // rx_valid pulse when byte is completely received
            rx_valid <= sample_edge && cs_active && (bit_count == DATA_WIDTH - 1);
            
            // tx_req pulse when byte transmission is complete (request next byte)
            tx_req <= shift_edge && cs_active && (bit_count == DATA_WIDTH - 1);
        end
    end

endmodule