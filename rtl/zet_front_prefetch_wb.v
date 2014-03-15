
/*
 *  Front-end instruction pre-fetch unit with wishbone master interface
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


module zet_front_prefetch_wb (
  // Wishbone master signals
  input             clk_i,
  input             rst_i,

  input      [15:0] wb_dat_i,
  output     [19:1] wb_adr_o,
  output     [ 1:0] wb_sel_o,
  //output reg        wb_cyc_o,
  output            wb_cyc_o,
  //output reg        wb_stb_o,
  output            wb_stb_o,
  input             wb_ack_i,

  // Invalidate current fetch cycle
  input             flush,

  // Address stearing from back-end
  input             load_cs_ip,
  input      [15:0] requested_cs,
  input      [15:0] requested_ip,

  // Output to instruction fifo stage
  output reg [15:0] fifo_cs_o,
  //output     [15:0] fifo_cs_o,
  output reg [15:0] fifo_ip_o,
  //output       [15:0] fifo_ip_o,
  output reg [15:0] fetch_dat_o,
  //output     [15:0] fetch_dat_o,
  output reg        wr_fetch_fifo,
  //output            wr_fetch_fifo,
  input             fifo_full

);

// Registers and nets

wire abort_fetch;
wire stalled;
wire wb_cyc_complete;

reg valid_cyc;
reg wb_cyc;

reg [15:0] cs;
reg [15:0] ip;

// Continuous assignments

// The system reset, flush, load_cs_ip will cause fetch operations to be aborted
assign abort_fetch = rst_i || flush || load_cs_ip;

// The fifo_full signal will cause the fetch to be stalled
// Any other time, it should be ok to start another fetch cycle
assign stalled = fifo_full;

// Calculate address for wb_adr_o
assign wb_adr_o = (cs << 4) + ip;

// We are always fetching two bytes at a time
assign wb_sel_o = 2'b11;

// Wishbone cycle
assign wb_cyc_o = (!abort_fetch & !stalled) || wb_cyc;

// Wishbone strobe
assign wb_stb_o = (!abort_fetch & !stalled) || wb_cyc;

// This signals that a wishbone cycle has completed
assign wb_cyc_complete = wb_cyc_o & wb_stb_o & wb_ack_i;

// Pass wishbone data to fifo
//assign fetch_dat_o = wb_dat_i;
//assign fifo_cs_o = cs;
//assign fifo_ip_o = ip;

// Write fifo
//assign wr_fetch_fifo = valid_cyc;

// behaviour

// Is this an active wishbone cycle?
// Master devices MUST complete the wishbone cycle even if the request
// has been invalidated!!
always @(posedge clk_i)
  if (rst_i) wb_cyc <= 1'b0;
  else wb_cyc <= !abort_fetch & !stalled ? 1'b1
               : wb_cyc_complete ? 1'b0
               : wb_cyc;
  
// Does the wishbone cycle need to be invalidated?
// Master devices MUST complete the wishbone cycle even if the request
// has been invalidated!!
always @(posedge clk_i)
  if (rst_i) valid_cyc <= 1'b0;
  else valid_cyc <= abort_fetch ? 1'b0
                  : wb_cyc_complete ? 1'b1
                  : valid_cyc;

// cs and ip logic
always @(posedge clk_i)
  if (rst_i) begin
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
    else if (!stalled & wb_cyc & valid_cyc & wb_cyc_complete)
        ip <= ip + 1; 
  end

// wb_cyc_o
// When a stall condition is encountered at or during wb cycle,
// follow through until wishbone cycle completes. This essentially forces one
// complete wb cycle before the abort fetch or stall condition is acknowledge.
//always @(posedge clk_i)
//  if (rst_i) wb_stb_o <= 1'b0;
//  else wb_cyc_o <= (!abort_fetch & !stalled) ? 1'b1 : (wb_cyc_complete ? 1'b0 : wb_cyc_o);

// wb_stb_o
// When a stall condition is encountered at or during wb strobe,
// follow through until wishbone cycle completes. This essentially forces one
// complete wb cycle before the stall condition is acknowledge.
//always @(posedge clk_i)
//  if (rst_i) wb_stb_o <= 1'b0;
//  else wb_stb_o <= (!abort_fetch & !stalled) ? 1'b1 : (wb_cyc_complete ? 1'b0 : wb_stb_o);

// Pass wishbone data to fifo
// We MUST hold the data if the fifo becomes full
always @(posedge clk_i)
  if (rst_i) begin
    fetch_dat_o <= 16'b0;
    fifo_cs_o  <= 16'b0;
    fifo_ip_o  <= 16'b0;
  end
  else if (wb_cyc & valid_cyc & wb_cyc_complete) begin
    fetch_dat_o <= wb_dat_i;
    fifo_cs_o  <= cs;
    fifo_ip_o  <= ip;
  end

// write fifo
always @(posedge clk_i)
  if (rst_i) wr_fetch_fifo <= 1'b0;
  else wr_fetch_fifo <= !abort_fetch & !stalled & wb_cyc & valid_cyc & wb_cyc_complete;

endmodule