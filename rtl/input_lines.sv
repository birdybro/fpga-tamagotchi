import ss_addresses::*;

module input_lines (
    input wire clk,
    input wire clk_en,

    input wire reset,

    input wire [3:0] input_k0,
    input wire [3:0] input_k1,

    input wire [3:0] input_relation_k0,
    input wire [3:0] input_k0_mask,
    input wire [3:0] input_k1_mask,

    input wire reset_factor,
    output reg [1:0] factor_flags = 0,

    // Savestates
    input wire [31:0] ss_bus_in,
    input wire [7:0] ss_bus_addr,
    input wire ss_bus_wren,
    input wire ss_bus_reset,
    output wire [31:0] ss_bus_out
);
  reg [3:0] prev_input_k0 = 0;
  reg [3:0] prev_input_k1 = 0;

  wire [31:0] ss_current_data = {30'b0, factor_flags};
  wire [31:0] ss_new_data;

  always @(posedge clk) begin
    if (reset) begin
      factor_flags <= ss_new_data[1:0];
    end else if (clk_en) begin
      reg k00_factor;
      reg k01_factor;
      reg k02_factor;
      reg k03_factor;

      reg k10_factor;
      reg k11_factor;
      reg k12_factor;
      reg k13_factor;

      prev_input_k0 <= input_k0;
      prev_input_k1 <= input_k1;

      // Relation high detects the falling edge
      k00_factor = input_k0_mask[0] && (input_relation_k0[0] ? ~input_k0[0] && prev_input_k0[0] : input_k0[0] && ~prev_input_k0[0]);
      k01_factor = input_k0_mask[1] && (input_relation_k0[1] ? ~input_k0[1] && prev_input_k0[1] : input_k0[1] && ~prev_input_k0[1]);
      k02_factor = input_k0_mask[2] && (input_relation_k0[2] ? ~input_k0[2] && prev_input_k0[2] : input_k0[2] && ~prev_input_k0[2]);
      k03_factor = input_k0_mask[3] && (input_relation_k0[3] ? ~input_k0[3] && prev_input_k0[3] : input_k0[3] && ~prev_input_k0[3]);

      // K1* only detects the falling edge
      k10_factor = input_k1_mask[0] && ~input_k1[0] && prev_input_k1[0];
      k11_factor = input_k1_mask[1] && ~input_k1[1] && prev_input_k1[1];
      k12_factor = input_k1_mask[2] && ~input_k1[2] && prev_input_k1[2];
      k13_factor = input_k1_mask[3] && ~input_k1[3] && prev_input_k1[3];

      factor_flags[0] <= factor_flags[0] | k00_factor | k01_factor | k02_factor | k03_factor;
      factor_flags[1] <= factor_flags[1] | k10_factor | k11_factor | k12_factor | k13_factor;

      if (reset_factor) begin
        factor_flags <= 0;
      end
    end
  end

  bus_connector #(
      .ADDRESS(SS_INPUT),
      .DEFAULT_VALUE(0)
  ) ss (
      .clk(clk),

      .bus_in(ss_bus_in),
      .bus_addr(ss_bus_addr),
      .bus_wren(ss_bus_wren),
      .bus_reset(ss_bus_reset),
      .bus_out(ss_bus_out),

      .current_data(ss_current_data),
      .new_data(ss_new_data)
  );
endmodule
