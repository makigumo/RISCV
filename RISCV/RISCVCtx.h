//
//  RISCVCtx.h
//  RISCV
//
//  Created by Makigumo on 2016/12/04.
//  Copyright © 2016年 Makigumo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Hopper/Hopper.h>

@class RISCVCPU;

@interface RISCVCtx : NSObject <CPUContext>

- (instancetype)initWithCPU:(RISCVCPU *)cpu andFile:(NSObject <HPDisassembledFile> *)file;

@end

#define REG_MASK(cls, reg) \
    (DISASM_BUILD_REGISTER_CLS_MASK(cls) | DISASM_BUILD_REGISTER_INDEX_MASK(reg))

#define OPCODE_MASK     0x0000007f
#define DEST_MASK       0x00000f80
#define SRC1_MASK       0x000F8000
#define SRC2_MASK       0x01F00000
#define FUNCT3_MASK     0x00007000
#define FUNCT7_MASK     0xfe000000
#define IMM_MASK        0xfffff000

#define OPCODE_OPIMM    (uint8_t) 0b0010011
#define OPCODE_AUIPC    (uint8_t) 0b0010111
#define OPCODE_LUI      (uint8_t) 0b0110111
#define OPCODE_BRANCH   (uint8_t) 0b1100011
#define OPCODE_JALR     (uint8_t) 0b1100111
#define OPCODE_JAL      (uint8_t) 0b1101111

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
    return (uint8_t) (((uint8_t)insn) & OPCODE_MASK);
}

// the J-immediate encodes a signed offset in multiples of 2 bytes
static inline int32_t getUJtypeImmediate(uint32_t insn) {
    return ((int32_t)(insn & 0x7FE00000) >> 20 /* bits 30..21 */ |
            (int32_t)(insn & 0x00100000) >> 9  /* bit 20 */ |
            (int32_t)(insn & 0x000ff000)       /* bits 19..12 */ |
            (int32_t)(insn & 0x80000000) >> 11 /* bit 31 */);
}

// the 12-bit B-immediate encodes signed offsets in multiples of 2
static inline int32_t getBtypeImmediate(uint32_t insn) {
    return ((int32_t)(insn & 0x80E00000) >> 19 /* bits 31 -> 12 */ |
            (int32_t)(insn & 0x00000080) >> 9  /* bit 7 -> 11 */ |
            (int32_t)(insn & 0x7D000000) >> 20 /* bits 30..25 -> 10..5 */ |
            (int32_t)(insn & 0x80000f00) >> 8  /* bit 11..8 -> 4..1 */);
}

// returns 12 bit signed I-immediate with LSB cleared
static inline int32_t getItypeImmediate(uint32_t insn) {
    return ((int32_t) (insn & 0xfff00000) >> 20) & ~1 /* bits 31..20 */;
}

static inline int32_t getUtypeImmediate(uint32_t insn) {
    return ((insn & 0xfffff000) >> 12) /* bits 31..12 */;
}
