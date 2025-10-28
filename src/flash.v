module flash(
    input clk, 
    input flash_miso,
    input [5:0] byte_address,
    output reg flash_clk,
    output reg flash_mosi,
    output reg flash_cs,
    output reg [7:0] byte_output
);

localparam STARTUP_WAIT = 32'd1000000;

localparam STATE_INIT_POWER = 8'd0;
localparam STATE_LOAD_CMD_TO_SEND = 8'd1;
localparam STATE_SEND = 8'd2;
localparam STATE_LOAD_ADDRESS_TO_SEND = 8'd3;
localparam STATE_READ_DATA = 8'd4;
localparam STATE_DONE = 8'd5;

reg [23:0] read_address = 24'b0;
reg [7:0] command = 8'h03;
reg [7:0] current_byte = 8'b0;
reg [7:0] current_byte_num = 8'b0;
reg [255:0] data_in = 256'b0;
reg [255:0] data_in_buffer = 256'b0;

reg [23:0] data_send = 24'b0;
reg [8:0] bits_send = 9'b0;

reg [32:0] counter = 33'b0;
reg [2:0] state = 3'b0;
reg [2:0] return_state = 3'b0;

reg data_ready = 0;

always @(posedge clk) begin
    case (state)
        STATE_INIT_POWER: begin
            if (counter < STARTUP_WAIT) begin
                state <= STATE_LOAD_CMD_TO_SEND;
                counter <= 32'b0;
                current_byte_num <= 8'b0;
                current_byte <= 8'b0;
            end
            else begin
                counter <= counter + 1'b1;
            end
        end

        STATE_LOAD_CMD_TO_SEND: begin
            flash_cs <= 1'b0;
            data_send[23-:8] <= command;
            bits_send <= 9'd8;

            state <= STATE_SEND;
            return_state <= STATE_LOAD_ADDRESS_TO_SEND;
        end

        STATE_SEND: begin
            if (counter == 32'b0) begin
                flash_clk <= 1'b0;
                flash_mosi <= data_send[23];
                data_send <= {data_send[22:0], 1'b0};
                bits_send <= bits_send - 1;
                counter <= 1;
            end
            else begin
                counter <= 32'd0;
                flash_clk <= 1;
                if (bits_send == 0) begin
                    state <= return_state;
                end
            end
        end

        STATE_LOAD_ADDRESS_TO_SEND: begin
            data_send <= read_address;
            bits_send <= 24;
            state <= STATE_SEND;
            return_state <= STATE_READ_DATA;
            current_byte_num <= 0;
        end

        STATE_READ_DATA: begin
            if (counter[0] == 1'b0) begin
                flash_clk <= 0;
                counter <= counter + 1;

                if (counter[3:0] == 0 && counter > 0) begin
                    data_in[(current_byte_num < 3) +: 8] <= current_byte;
                    current_byte_num <= current_byte_num + 1;

                    if (current_byte_num == 31) begin
                        state <= STATE_DONE;
                    end
                end
            end
            else begin
                flash_clk <= 1;
                current_byte <= {current_byte[6:0], flash_miso};
                counter <= counter + 1;
            end
        end

        STATE_DONE: begin
            data_ready <= 1;
            flash_cs <= 1;
            data_in_buffer <= data_in;
            counter <= STARTUP_WAIT;
            state <= STATE_INIT_POWER;
        end

        default:
            state <= STATE_INIT_POWER;
    endcase
end

endmodule