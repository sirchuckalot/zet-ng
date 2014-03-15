/*
 * 16 to 8 bit instruction prefetch fifo
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 * adjusted to 16 to 8 bit by Charley Picker <charleypicker@yahoo.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

module zet_front_fifo16to8(
	input clk_i,
	input rst_i,
	input flush_i,
	
	input stb_i,
	input [15:0] di,
	
	output can_burst_o,
	output do8_valid,
	output reg [7:0] do8,
	input next_i /* should only be asserted when do8_valid = 1 */
);

/*
 * FIFO can hold 8 16-bit words
 * that is 16 8-bit bytes.
 */

reg [15:0] storage[0:7];
reg [2:0] produce; /* in 16-bit words */
reg [3:0] consume; /* in 8-bit bytes */
/*
 * 8-bit bytes stored in the FIFO, 0-15 (16 possible values)
 */

reg [3:0] level;

wire [15:0] do16;
assign do16 = storage[consume[3:1]];

always @(*) begin
  case(consume[0])
    1'd0: do8 <= do16[15:8];
    1'd1: do8 <= do16[7:0];
  endcase
end

always @(posedge clk_i) begin
  if(rst_i) begin
    produce = 3'd0;
    consume = 4'd0;
    level = 4'd0;
  end else begin
    if(stb_i) begin
      storage[produce] = di;
      produce = produce + 3'd1;
      level = level + 4'd2;
    end
    if(next_i) begin /* next should only be asserted when do8_valid = 1 */
      consume = consume + 4'd1;
      level = level - 4'd1;
    end
  end
end

assign do8_valid = ~(level == 4'd0);
assign can_burst_o = level >= 4'd14;

endmodule
