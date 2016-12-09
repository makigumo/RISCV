//
//  RISCVCtx.h
//  RISCV
//
//  Created by Makigumo on 2016/12/04.
//  Copyright © 2016年 Makigumo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Hopper/Hopper.h>
#import "RISCVCPU.h"

@class RISCVCPU;

@interface RISCVCtx : NSObject <CPUContext>

- (instancetype)initWithCPU:(RISCVCPU *)cpu andFile:(NSObject <HPDisassembledFile> *)file;

@end

extern NSString *getCsrName(uint64_t csr);

#define OPCODE_MASK     0x0000007f
#define DEST_MASK       0x00000f80
#define SRC1_MASK       0x000F8000
#define SRC2_MASK       0x01F00000
#define FUNCT3_MASK     0x00007000
#define FUNCT5_MASK     0xf8000000
#define FUNCT7_MASK     0xfe000000
#define FUNCT6_MASK     0xfc000000
#define IMM_MASK        0xfffff000
#define SHAMT_MASK      0x01F00000
#define SHAMT64_MASK    0x03F00000
#define PRED_MASK       0x0f000000
#define SUCC_MASK       0x00f00000

#define OPCODE_OPIMM    (uint8_t) 0b0010011
#define OPCODE_OPIMM32  OPCODE_OPIMM
#define OPCODE_OPIMM64  (uint8_t) 0b0011011
#define OPCODE_LOAD     (uint8_t) 0b0000011
#define OPCODE_STORE    (uint8_t) 0b0100011
#define OPCODE_OP       (uint8_t) 0b0110011
#define OPCODE_OP32     (uint8_t) 0b0111011
#define OPCODE_AUIPC    (uint8_t) 0b0010111
#define OPCODE_LUI      (uint8_t) 0b0110111
#define OPCODE_BRANCH   (uint8_t) 0b1100011
#define OPCODE_JALR     (uint8_t) 0b1100111
#define OPCODE_JAL      (uint8_t) 0b1101111
#define OPCODE_MISC_MEM (uint8_t) 0b0001111
#define OPCODE_SYSTEM   (uint8_t) 0b1110011
#define OPCODE_AMO      (uint8_t) 0b0101111
#define OPCODE_LOADFP   (uint8_t) 0b0000111
#define OPCODE_STOREFP  (uint8_t) 0b0100111
#define OPCODE_FMADD    (uint8_t) 0b1000011
#define OPCODE_FMSUB    (uint8_t) 0b1000111
#define OPCODE_FNMSUB   (uint8_t) 0b1001011
#define OPCODE_FNMADD   (uint8_t) 0b1001111
#define OPCODE_FP       (uint8_t) 0b1010011

typedef struct {
    uint8_t opcode; /* bits 6..0 */
    uint8_t reg_dest; /* bits 11..7 */
    uint8_t funct3; /* bits 14..12 */
    uint8_t reg_src1; /* bits 19..15 */
    uint8_t reg_src2; /* bits 24..20 */
    uint8_t funct7; /* bits 31..25 */
} rtype_insn;

// return the 7-bit opcode, bits 6..0
static inline uint8_t getOpcode(uint32_t insn) {
    return (uint8_t) (((uint8_t) insn) & OPCODE_MASK);
}

// the J-immediate encodes a signed offset in multiples of 2 bytes
static inline int32_t getUJtypeImmediate(uint32_t insn) {
    return ((int32_t) (insn & 0x7FE00000) >> 20 /* bits 30..21 */ |
            (int32_t) (insn & 0x00100000) >> 9  /* bit 20 */ |
            (int32_t) (insn & 0x000ff000)       /* bits 19..12 */ |
            (int32_t) (insn & 0x80000000) >> 11 /* bit 31 */);
}

// the 12-bit B-immediate encodes signed offsets in multiples of 2
static inline int32_t getBtypeImmediate(uint32_t insn) {
    return (((int32_t) (insn & 0x00000080) << 4  /* bit 7 -> 11 */ |
            (int32_t) (insn & 0x7E000000) >> 20 /* bits 30..25 -> 10..5 */ |
            (int32_t) (insn & 0x00000f00) >> 7  /* bit 11..8 -> 4..1 */ |
            (int32_t) (-((insn >> 31) & 1)) << 12 /* bits 31 -> 12 */)
    ) & ~1;
}

// returns 12 bit signed I-immediate with LSB cleared
static inline int32_t getItypeImmediateLSBcleared(uint32_t insn) {
    return ((int32_t) (insn & 0xfff00000) >> 20) & ~1 /* bits 31..20 */;
}

static inline int32_t getItypeImmediate(uint32_t insn) {
    return ((int32_t) (insn & 0xfff00000) >> 20) /* bits 31..20 */;
}

static inline int32_t getStypeImmediate(uint32_t insn) {
    return ((int32_t) (insn & 0x00000f80) >> 7) /* bits 11..7 -> 4..0 */ |
            ((int32_t) (insn & 0xfe000000) >> 20) /* bits 31..25 -> 11..5 */;
}

static inline int32_t getUtypeImmediate(uint32_t insn) {
    return ((insn & 0xfffff000) >> 12) /* bits 31..12 */;
}

static inline uint32_t getCsr(uint32_t insn) {
    return ((insn & 0xfff00000) >> 20) /* bits 31..20 */;
}

// get funct3
static inline uint8_t getFunct3(uint32_t insncode) {
    return (uint8_t) ((insncode & FUNCT3_MASK) >> 12);
}

// get funct5
static inline uint8_t getFunct5(uint32_t insncode) {
    return (uint8_t) ((insncode & FUNCT5_MASK) >> 27);
}

// get funct7
static inline uint8_t getFunct7(uint32_t insncode) {
    return (uint8_t) ((insncode & FUNCT7_MASK) >> 25);
}

// get funct7 64 bit extension
static inline uint8_t getFunct6(uint32_t insncode) {
    return (uint8_t) ((insncode & FUNCT6_MASK) >> 26);
}

// get source register 2
static inline uint8_t getRS2(uint32_t insncode) {
    return (uint8_t) ((insncode & SRC2_MASK) >> 20);
}

// get source register 1
static inline uint8_t getRS1(uint32_t insncode) {
    return (uint8_t) ((insncode & SRC1_MASK) >> 15);
}

// get destination register
static inline uint8_t getRD(uint32_t insncode) {
    return (uint8_t) ((insncode & DEST_MASK) >> 7);
}

// get shift amount
static inline uint8_t getShamt(uint32_t insncode) {
    return (uint8_t) (((uint32_t) (insncode & SHAMT_MASK)) >> 20);
}

// get shift amount 64 bit extension
static inline uint8_t getShamt64(uint32_t insncode) {
    return (uint8_t) (((uint32_t) (insncode & SHAMT64_MASK)) >> 20);
}

// get predecessor for fence instruction bits 27..24
static inline uint8_t getPredecessor(uint32_t insncode) {
    return (uint8_t) (((uint32_t) (insncode & PRED_MASK)) >> 24);
}

// get predecessor for fence instruction bits 23..20
static inline uint8_t getSuccessor(uint32_t insncode) {
    return (uint8_t) (((uint32_t) (insncode & SUCC_MASK)) >> 20);
}

static inline NSString *getIorw(uint8_t insncode) {
    NSString *res = @"";
    if (insncode & 0b1000) res = [res stringByAppendingString:@"i"];
    if (insncode & 0b0100) res = [res stringByAppendingString:@"o"];
    if (insncode & 0b0010) res = [res stringByAppendingString:@"r"];
    if (insncode & 0b0001) res = [res stringByAppendingString:@"w"];
    return res;
}

static inline void populateOP(DisasmStruct *disasm, uint32_t insn, const char *mnemonic) {
    strcpy(disasm->instruction.mnemonic, mnemonic);
    disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
    disasm->operand[0].type |= getRegMask(getRD(insn));
    disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
    disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
    disasm->operand[1].type |= getRegMask(getRS1(insn));
    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
    disasm->operand[2].type = DISASM_OPERAND_REGISTER_TYPE;
    disasm->operand[2].type |= getRegMask(getRS2(insn));
    disasm->operand[2].accessMode = DISASM_ACCESS_READ;
}

static inline void populateOPIMM(DisasmStruct *disasm, uint32_t insn, const char *mnemonic) {
    strcpy(disasm->instruction.mnemonic, mnemonic);
    disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
    disasm->operand[0].type |= getRegMask(getRD(insn));
    disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
    disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
    disasm->operand[1].type |= getRegMask(getRS1(insn));
    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
    disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE;
    disasm->operand[2].immediateValue = getItypeImmediate(insn);
    disasm->operand[2].accessMode = DISASM_ACCESS_READ;
}

static inline void populateOPIMMShift(DisasmStruct *disasm, uint32_t insn, const char *mnemonic) {
    strcpy(disasm->instruction.mnemonic, mnemonic);
    disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
    disasm->operand[0].type |= getRegMask(getRD(insn));
    disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
    disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
    disasm->operand[1].type |= getRegMask(getRS1(insn));
    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
    disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE;
    disasm->operand[2].immediateValue = getShamt(insn);
    disasm->operand[2].accessMode = DISASM_ACCESS_READ;
}

static inline void populateOPIMMShift64(DisasmStruct *disasm, uint32_t insn, const char *mnemonic) {
    strcpy(disasm->instruction.mnemonic, mnemonic);
    disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
    disasm->operand[0].type |= getRegMask(getRD(insn));
    disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
    disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
    disasm->operand[1].type |= getRegMask(getRS1(insn));
    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
    disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE;
    disasm->operand[2].immediateValue = getShamt64(insn);
    disasm->operand[2].accessMode = DISASM_ACCESS_READ;
}

static inline void populateLOAD(DisasmStruct *disasm, uint32_t insn, const char *mnemonic) {
    strcpy(disasm->instruction.mnemonic, mnemonic);
    disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
    disasm->operand[0].type |= getRegMask(getRD(insn));
    disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
    disasm->operand[1].type = DISASM_OPERAND_MEMORY_TYPE;
    disasm->operand[1].type |= getRegMask(getRS1(insn));
    disasm->operand[1].memory.baseRegistersMask = getRegMask(getRS1(insn));
    disasm->operand[1].memory.displacement = getItypeImmediate(insn);
    disasm->operand[1].memory.scale = 1;
    disasm->operand[2].accessMode = DISASM_ACCESS_READ;
}

static inline void populateSTORE(DisasmStruct *disasm, uint32_t insn, const char *mnemonic) {
    strcpy(disasm->instruction.mnemonic, mnemonic);
    disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
    disasm->operand[0].type |= getRegMask(getRS2(insn));
    disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
    disasm->operand[1].type = DISASM_OPERAND_MEMORY_TYPE;
    disasm->operand[1].type |= getRegMask(getRS1(insn));
    disasm->operand[1].memory.baseRegistersMask = getRegMask(getRS1(insn));
    disasm->operand[1].memory.displacement = getStypeImmediate(insn);
    disasm->operand[1].memory.scale = 1;
    disasm->operand[2].accessMode = DISASM_ACCESS_READ;
}

static inline void populateLR(DisasmStruct *disasm, uint32_t insn, const char *mnemonic) {
    strcpy(disasm->instruction.mnemonic, mnemonic);
    disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
    disasm->operand[0].type |= getRegMask(getRD(insn));
    disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
    disasm->operand[1].type = DISASM_OPERAND_MEMORY_TYPE;
    disasm->operand[1].type |= getRegMask(getRS1(insn));
    disasm->operand[1].memory.baseRegistersMask = getRegMask(getRS1(insn));
    disasm->operand[1].memory.displacement = 0;
    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
}

static inline void populateAMO(DisasmStruct *disasm, uint32_t insn, const char *mnemonic) {
    strcpy(disasm->instruction.mnemonic, mnemonic);
    disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
    disasm->operand[0].type |= getRegMask(getRD(insn));
    disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
    disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
    disasm->operand[1].type |= getRegMask(getRS2(insn));
    disasm->operand[1].accessMode = DISASM_ACCESS_WRITE;
    disasm->operand[2].type = DISASM_OPERAND_MEMORY_TYPE;
    disasm->operand[2].type |= getRegMask(getRS1(insn));
    disasm->operand[2].memory.baseRegistersMask = getRegMask(getRS1(insn));
    disasm->operand[2].memory.displacement = 0;
    disasm->operand[2].accessMode = DISASM_ACCESS_READ;
}
