/*
 *  Zet processor core
 *  Copyright (C) 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
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

`include "defines.v"

module zet_core (
    input clk,
    input rst,

    // UMI slave interface - fetch
    output [19:0] umif_adr_o,
    input  [15:0] umif_dat_i,
    output        umif_stb_o,
    output        umif_by_o,
    input         umif_ack_i,

    // UMI slave interface - exec
    output [19:0] umie_adr_o,
    input  [15:0] umie_dat_i,
    output [15:0] umie_dat_o,
    output        umie_we_o,
    output        umie_by_o,
    output        umie_stb_o,
    input         umie_ack_i,
    output        umie_tga_o,

    // interrupts
    input        intr,
    output       inta,
    input  [3:0] iid
  );
  
  
  // Registers and nets
  wire [15:0] cs;
  wire [15:0] ip;
  wire [15:0] fifo_dat_o;
  wire wr_fifo;
  wire fifo_full;
  
  reg [15:0] cs_l;
  reg [15:0] ip_l;
  reg [15:0] fifo_dat_o_l;
  reg wr_fifo_l;


  // Module instantiations
  zet_front_prefetch_umi fetch (
    .clk(clk),
    .rst(rst),

    // to wb
    .umi_adr_o(umif_adr_o),
    .umi_dat_i(umif_dat_i),
    .umi_stb_o(umif_stb_o),
    .umi_by_o(umif_by_o),
    .umi_ack_i(umif_ack_i),

    // fetch flush
    .flush(1'b0),

    // Address stearing from back-end
    .load_cs_ip(1'b0),
    .requested_cs(16'b0),
    .requested_ip(16'b0),

    // Output to instruction fifo stage
    .cs(cs),
    .ip(ip),
    .fifo_dat_o(fifo_dat_o),
    .wr_fifo(wr_fifo),
    .fifo_full(fifo_full)
  );


  // Continuous assignments
  assign fifo_full = 1'b0;

  // Behaviour

  always @(posedge clk)
    if (rst)
      begin
        cs_l <= 'd0;
        ip_l <= 'd0;
        fifo_dat_o_l <= 'd0;
        wr_fifo_l <= 1'b0;
      end
    else
      begin
        cs_l <= cs;
        ip_l <= ip;
        fifo_dat_o_l <= fifo_dat_o;
        wr_fifo_l <= wr_fifo;
      end

endmodule
