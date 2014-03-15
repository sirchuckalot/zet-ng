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

    // Wishbone master interface - fetch
    input  [15:0] wbf_dat_i,
    output [19:1] wbf_adr_o,
    output [ 1:0] wbf_sel_o,
    output        wbf_cyc_o,
    output        wbf_stb_o,
    input         wbf_ack_i,

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
  wire [15:0] fetch_dat_o;
  wire wr_fetch_fifo;
  wire fifo_full;
  
  reg [15:0] cs_l;
  reg [15:0] ip_l;
  reg [15:0] fetch_dat_o_l;
  reg wr_fetch_fifo_l;
  
  wire [7:0] instruction_fifo_do;
  wire instruction_fifo_do_valid;
  wire instruction_fifo_next;
  
  wire decoded_valid_o;
  reg next_decoded_i;
  
  reg [19:0] count;


  // Module instantiations
  zet_front_prefetch_wb fetch (
    .clk_i(clk),
    .rst_i(rst),

    // to wb
    .wb_dat_i(wbf_dat_i),
    .wb_adr_o(wbf_adr_o),
    .wb_sel_o(wbf_sel_o),
    .wb_cyc_o(wbf_cyc_o),
    .wb_stb_o(wbf_stb_o),
    .wb_ack_i(wbf_ack_i),

    // fetch flush
    .flush(1'b0),

    // Address stearing from back-end
    .load_cs_ip(1'b0),
    .requested_cs(16'b0),
    .requested_ip(16'b0),

    // Output to instruction fifo stage
    .fifo_cs_o(cs),
    .fifo_ip_o(ip),
    .fetch_dat_o(fetch_dat_o),
    .wr_fetch_fifo(wr_fetch_fifo),
    .fifo_full(fifo_full)
  );
  
  zet_front_fifo16to8 fetch_fifo (
    .clk_i(clk),
    .rst_i(rst),
    .flush_i(1'b0),

    .stb_i(wr_fetch_fifo),
    .di(fetch_dat_o),

    .can_burst_o(fifo_full),
    .do8_valid(instruction_fifo_do_valid),
    .do8(instruction_fifo_do),
    .next_i(instruction_fifo_next) /* should only be asserted when do_valid = 1 */
  );

zet_decode decode (
    .clk(clk),
    .rst_i(rst),
    .flush_i(1'b0),
    .instruction_i(instruction_fifo_do),
    .instruction_valid_i(instruction_fifo_do_valid),
    .next_instruction_o(instruction_fifo_next),

    // current cs and ip of instruction
    .instruction_cs_o(),
    .instruction_ip_o(),

    // {prefix_decoded, repe_repz, repne_repnz, lock}
    .inst_pr_o(),
    // {prefix_decoded, x, x, address size override}
    .adrs_pr_o(),
    // {prefix_decoded, x, x, operand size override}
    .oper_pr_o(),
    // {prefix_decoded, segment override register}
    .sovr_pr_o(),

    .opcode_o(),

    .need_modrm_o(),
    .modrm_o(),

    .need_off_o(),
    .off_size_o(),
    .offset_o(),

    .need_imm_o(),
    .imm_size_o(),
    .immediate_o(),

    // to sequencer
    .seq_addr_o(),
    .src_o(),
    .dst_o(),
    .base_o(),
    .index_o(),
    .seg_o(),

    .decoded_valid_o(decoded_valid_o),
    .next_decoded_i(next_decoded_i)

);

  // Continuous assignments
  //assign fifo_full = 1'b0;

  // Behaviour
  
  always @(posedge clk)
  if (rst)
    begin
      //instruction_valid <= 1'b0;
      count <= 20'd0;
    end
  else
  begin
    //instruction_valid <= 1'b1;
    if (instruction_fifo_next)
      begin
        $display("Address: %d   Data byte: %h", count, instruction_fifo_do);
        count <= count + 20'd1;
      end
    if (decoded_valid_o & !next_decoded_i)
      begin
        $display("Instruction Finished Decoding");
        $display(" ");
        $display("Sending next byte sequence:");
        next_decoded_i <= 1'b1;
      end
    else
      next_decoded_i <= 1'b0;
  end

  always @(posedge clk)
    if (rst)
      begin
        cs_l <= 16'b0;
        ip_l <= 16'b0;
        fetch_dat_o_l <= 16'b0;
        wr_fetch_fifo_l <= 1'b0;
      end
    else
      begin
        cs_l <= cs;
        ip_l <= ip;
        fetch_dat_o_l <= fetch_dat_o;
        wr_fetch_fifo_l <= wr_fetch_fifo;
      end

endmodule
