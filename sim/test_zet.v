/*
 *  Testbench for Zet processor
 *  Copyright (C) 2008-2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
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

module test_zet;

  // Net declarations
  wire [15:0] dat_o;
  wire [15:0] mem_dat_i, io_dat_i, dat_i;
  wire [19:1] adr;
  wire        we;
  wire        tga;
  wire [ 1:0] sel;
  wire        stb;
  wire        cyc;
  wire        ack, mem_ack, io_ack;
  wire        inta;
  wire [19:0] pc;

  reg         clk;
  reg         rst;

  reg  [15:0] io_reg;

  reg         intr;
  
  // Wishbone master interface - fetch
  wire [15:0] wbf_dat_i;
  wire [19:1] wbf_adr_o;
  wire [ 1:0] wbf_sel_o;
  wire        wbf_cyc_o;
  wire        wbf_stb_o;
  wire        wbf_ack_i;

  // Module instantiations
  memory2prt mem0 (
    .wb1_clk_i (clk),
    .wb1_dat_o(wbf_dat_i),
    .wb1_adr_i(wbf_adr_o),
    .wb1_sel_i(wbf_sel_o),
    .wb1_cyc_i(wbf_cyc_o),
    .wb1_stb_i(wbf_stb_o),
    .wb1_ack_o(wbf_ack_i),

    .wb2_clk_i (clk),
    .wb2_rst_i (rst),
    .wb2_dat_i (dat_o),
    .wb2_dat_o (mem_dat_i),
    .wb2_adr_i (adr),
    .wb2_we_i  (we),
    .wb2_sel_i (sel),
    .wb2_stb_i (stb & !tga),
    .wb2_cyc_i (cyc & !tga),
    .wb2_ack_o (mem_ack)
  );

  zet zet (
    .clk_i (clk),
    .rst_i (rst),
    
    // Wishbone master interface - fetch
    .wbf_dat_i(wbf_dat_i),
    .wbf_adr_o(wbf_adr_o),
    .wbf_sel_o(wbf_sel_o),
    .wbf_cyc_o(wbf_cyc_o),
    .wbf_stb_o(wbf_stb_o),
    .wbf_ack_i(wbf_ack_i),

    .wb_dat_i (dat_i),
    .wb_dat_o (dat_o),
    .wb_adr_o (adr),
    .wb_we_o  (we),
    .wb_tga_o (tga),
    .wb_sel_o (sel),
    .wb_stb_o (stb),
    .wb_cyc_o (cyc),
    .wb_ack_i (ack),

    .intr (1'b0),
    .inta (inta),
    .iid  (4'h0),

    .pc   (pc)
  );

  // Assignments
  assign io_dat_i = (adr[15:1]==15'h5b) ? { io_reg[7:0], 8'h0 }
    : ((adr[15:1]==15'h5c) ? { 8'h0, io_reg[15:8] } : 16'h0);
  assign dat_i = inta ? 16'd3 : (tga ? io_dat_i : mem_dat_i);

  assign ack    = tga ? io_ack : mem_ack;
  assign io_ack = stb;

  // Behaviour
  // IO Stub
  always @(posedge clk)
    if (adr[15:1]==15'h5b && sel[1] && cyc && stb)
      io_reg[7:0] <= dat_o[15:8];
    else if (adr[15:1]==15'h5c & sel[0] && cyc && stb)
      io_reg[15:8] <= dat_o[7:0];

  always #1.5 clk = ~clk;

  initial
    begin
         intr <= 1'b0;
         clk <= 1'b1;
         rst <= 1'b0;
      #5 rst <= 1'b1;
      #2 rst <= 1'b0;

      #1000 intr <= 1'b1;
      //@(posedge inta)
      @(posedge clk) intr <= 1'b0;
    end

  initial
    begin
      $readmemh("data.rtlrom", mem0.ram1, 19'h78000);
      $readmemh("data.rtlrom", mem0.ram2, 19'h78000);
//      $readmemb("../rtl/micro_rom.dat",
//        zet.core.micro_data.micro_rom.rom);
    end
endmodule
