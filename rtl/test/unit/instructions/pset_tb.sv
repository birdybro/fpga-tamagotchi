`include "vunit_defines.svh"

module pset_tb;
  bench bench();

  `TEST_SUITE begin
    `TEST_CASE("PSET should set NPP") begin
      bench.initialize(12'hE4F); // PSET p

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(5);

      bench.assert_np(5'h0F);
    end

    `TEST_CASE("PSET should set NBP") begin
      bench.initialize(12'hE54); // PSET p

      bench.run_until_complete();
      #1;
      bench.assert_expected(bench.prev_pc + 1, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_cycle_length(5);

      bench.assert_np(5'h14);
    end

    `TEST_CASE("NBP and NPP should be reset after non-PSET") begin
      bench.initialize(12'hFFB); // NOP5

      bench.cpu_uut.core.regs.np = 5'h1A;

      bench.run_until_final_stage_fetch();

      // Set up next instruction
      bench.rom_data = 12'h0A5; // JP 0xA5

      bench.run_until_complete();
      #1;
      bench.assert_np(5'h01); // Default starting NP

      bench.run_until_complete();
      #1;
      bench.assert_expected(13'h01A5, bench.prev_a, bench.prev_b, bench.prev_x, bench.prev_y, bench.prev_sp);
      bench.assert_np(5'h01);
    end

    `TEST_CASE("Interrupt should wait until after instruction after PSET") begin
      bench.initialize(12'hE59); // PSET p
      bench.cpu_uut.core.regs.interrupt = 1;
      bench.cpu_uut.input_k0_mask = 4'h1;
      bench.input_k0 = 4'h1;
      
      // Wait some time for instruction to start
      #4;
      bench.input_k0 = 0;

      bench.run_until_final_stage_fetch();
      bench.rom_data = 12'h0E1; // JP 0xE1
      bench.run_until_complete();

      #1;
      // JP is executing
      `CHECK_EQUAL(bench.cpu_uut.core.microcode.performing_interrupt, 0);

      bench.run_until_complete();
      #1;

      #1;
      `CHECK_EQUAL(bench.cpu_uut.core.microcode.performing_interrupt, 1);

      @(posedge bench.clk iff bench.cpu_uut.core.microcode.stage == 3); // STEP2
      #1;
      bench.assert_interrupt(0);

      bench.run_until_complete();
      // Interrupt should start
      #1;
      bench.assert_cycle_length(12 + 5 + 5);
      bench.assert_pc(13'h1106);
      bench.assert_ram(bench.prev_sp - 1, 4'h9);
      bench.assert_ram(bench.prev_sp - 2, 4'hE);
      bench.assert_ram(bench.prev_sp - 3, 4'h1);
    end
  end;

  // The watchdog macro is optional, but recommended. If present, it
  // must not be placed inside any initial or always-block.
  `WATCHDOG(1ns);
endmodule
