
/*
 *  Front-end instruction pre-fetch unit with umi master interface
 *  Copyright (C) 2013  Charley Picker <charleypicker@yahoo.com>
 *
 *  This file is part of the Zet processor. This processor is free
 *  hardware; you can redistribute it and/or modify it under the terms of
 *  the GNU General Public License as published by the Free Software
 *  Foundation; either version 3, or (at your option) any later version.
 *
 *  Zet is distrubuted in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
 *  License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Zet; see the file COPYING. If not, see
 *  <http://www.gnu.org/licenses/>.
 */


module zet_front_prefetch_umi (
  // common signals
  input             clk,
  input             rst,

  // UMI master interface - fetch
  output     [19:0] umi_adr_o,
  input      [15:0] umi_dat_i,
  output reg        umi_stb_o,
  output            umi_by_o,
  input             umi_ack_i,

  // Invalidate current fetch cycle
  input             flush,

  // Address stearing from back-end
  input             load_cs_ip,
  input      [15:0] requested_cs,
  input      [15:0] requested_ip,

  // Output to instruction fifo stage
  output reg [15:0] cs,
  output reg [15:0] ip,
  output reg [15:0] fifo_dat_o,
  output reg        wr_fifo,
  input             fifo_full
);

// Registers and nets

wire stalled;

// Continuous assignments

// The flush, load_cs_ip and fifo_full signals will cause the fetch to be stalled
// Any other time, it should be ok to start another fetch cycle
assign stalled = flush || load_cs_ip || fifo_full;

// Calculate address for wb_adr_o
assign umi_adr_o = (cs << 4) + ip;

// We are always fetching two bytes at a time
assign umi_by_o = 1'b0;

// behaviour

// cs and ip logic
always @(posedge clk)
  if (rst) begin
    cs <= 16'hf000;
    ip <= 16'hfff0;
  end
  else begin
    if (flush) begin
      cs <= requested_cs;
      ip <= requested_ip;
    end
    else if (load_cs_ip) begin
        cs <= requested_cs;
        ip <= requested_ip;
    end
    else if (!stalled & umi_ack_i)
        ip <= ip + 2; 
  end

// wb_stb_o
// When a stall condition is encountered at or during wb strobe,
// follow through until wishbone cycle completes. This essentially forces one
// complete wb cycle before the stall condition is acknowledge.
always @(posedge clk)
  if (rst) umi_stb_o <= 1'b0;
  else umi_stb_o <= !stalled ? 1'b1 : (umi_ack_i ? 1'b0 : umi_stb_o);

// write fifo
always @(posedge clk)
  if (rst) wr_fifo <= 1'b0;
  else wr_fifo <= (!stalled & umi_ack_i);

// Pass wishbone data to fifo
always @(posedge clk)
  if (rst) wr_fifo <= 1'b0;
  else fifo_dat_o <= umi_dat_i;

endmodule