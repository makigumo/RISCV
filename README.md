[![Build Status](https://travis-ci.org/makigumo/RISCV.svg?branch=master)](https://travis-ci.org/makigumo/RISCV)

# RISC-V CPU module for Hopper Disassembler

Supported instruction sets:

DONE | Name | Version
-----|------|--------
[x] | RV32I Base Integer Instruction Set | 2.0
[x] | RV64I Base Integer Instruction Set | 2.0
[x] | RV128I Base Integer Instruction Set | 1.7
[x] | RV32E Base Integer Instruction Set (limited to 16 registers) | 1.9
[x] | RV32M/RV64M/RV128M Standard Extension for Integer Multiplication and Division | 2.0
[x] | RV32A/RV64A/RV128A Standard Extension for Atomic Instructions | 2.0
[x] | RV32F/RV64F Standard Extension for Single-Precision Floating-Point | 2.0
[x] | RV32D/RV64D Standard Extension for Double-Precision Floating-Point | 2.0
[x] | RV32Q/RV64Q Standard Extension for Quad-Precision Floating-Point | 2.0
[ ] | RV32L/RV64L Standard Extension for Decimal Floating-Point | 0.0
[ ] | RV32C/RV64C Standard Extension for Compressed Instructions | 1.9
[ ] | RV32V/RV64V Standard Extension for Vector Operations | 0.0
[ ] | RV32B/RV64B Standard Extension for Bit Manipulation | 0.0
[ ] | RV32T/RV64T Standard Extension for Transactional Memory | 0.0
[ ] | RV32P/RV64P Standard Extension for Packed-SIMD Instructions | 0.1
[x] | Trap-Return Instructions | 1.9
[x] | Interrupt-Management Instructions | 1.9
[x] | Memory-Management Instructions | 1.9

## Requirements

* [Hopper Disassembler v4+](https://www.hopperapp.com/)

## Building

* build with Xcode
* or, via `xcodebuild`
* or, using *cmake*
    ```
    mkdir build
    cd build
    cmake ..
    make
    make install
    ```
    
### Linux

Install [GNUstep](https://github.com/gnustep/base), [libobjc2](https://github.com/gnustep/libobjc2) and [libdispatch](https://github.com/nickhutchinson/libdispatch), e.g. by using the script in https://github.com/ckuethe/HopperSDK-Linux.
Then adjust your `PATH` to include `~/GNUstep/Library/ApplicationSupport/Hopper/gnustep-x86_64/bin/`.    

## Resources

* [The RISC-V Instruction Set Manual, Volume I: User-Level ISA, Version 2.2](https://github.com/riscv/riscv-isa-manual/releases/tag/riscv-user-2.2)
* [The RISC-V Instruction Set Manual, Volume II: Privileged Architecture, Version 1.10](https://github.com/riscv/riscv-isa-manual/releases/tag/riscv-priv-1.10)

