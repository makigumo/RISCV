[![Build Status](https://travis-ci.org/makigumo/RISCV.svg?branch=master)](https://travis-ci.org/makigumo/RISCV)

# RISC-V CPU module for Hopper Disassembler

Supported instruction sets:
* [x] RV32I Base Integer Instruction Set
* [X] RV64I Base Integer Instruction Set
* [ ] RV128I Base Integer Instruction Set
* [x] RV32E Base Integer Instruction Set
   * limited to 16 registers
* [x] RV32M/RV64M Standard Extension for Integer Multiplication and Division
* [x] RV32A/RV64A Standard Extension for Atomic Instructions
* [x] RV32F/RV64F Standard Extension for Single-Precision Floating-Point
* [x] RV32D/RV64D Standard Extension for Double-Precision Floating-Point
* [ ] RV32Q/RV64Q Standard Extension for Quad-Precision Floating-Point
* [ ] RV32L/RV64L Standard Extension for Decimal Floating-Point
* [ ] RV32C/RV64C Standard Extension for Compressed Instructions
* [ ] RV32V/RV64V Standard Extension for Vector Operations
* [ ] RV32B/RV64B Standard Extension for Bit Manipulation
* [ ] RV32T/RV64T Standard Extension for Transactional Memory
* [ ] RV32P/RV64P Standard Extension for Packed-SIMD Instructions
* [x] Trap-Return Instructions
* [x] Interrupt-Management Instructions
* [x] Memory-Management Instructions

## Requirements

* [Hopper Disassembler v4](https://www.hopperapp.com/)

## Resources

* [The RISC-V Instruction Set Manual, Volume I: User-Level ISA, Version 2.1](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2016/EECS-2016-118.html)
* [The RISC-V Instruction Set Manual Volume II: Privileged Architecture Version 1.9.1](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2016/EECS-2016-161.html)

