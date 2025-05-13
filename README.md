# Single Cycle RISC-V Core Processor Design
The team project involved the development of a RISC-V processor core from scratch, capable of
executing all instructions defined in the RV32I integer instruction subset, extended to support
integer multiplication, integer division, and the Wait for Interrupt instruction. The processor was
designed to be single-cycle, meaning each instruction is fetched, decoded, and executed within one
clock cycle, without the use of pipelining stages. The RTL implementation was made in VHDL and
the testing was carried out through a custom testbench, both were handled using Vivado.
