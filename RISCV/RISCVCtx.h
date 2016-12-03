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

//  the J-immediate encodes a signed offset in multiples of 2 bytes
static inline int32_t getUJtypeImmediate(uint32_t insn) {
    return ((int32_t)(insn & 0x7FE00000) >> 20 /* bits 30..21 */ |
            (int32_t)(insn & 0x100000) >> 9 /* bit 20 */ |
            (int32_t)(insn & 0x0ff000) /* bits 19..12 */ |
            (int32_t)(insn & 0x80000000) >> 11 /* bit 31 */);
}

// returns 12 bit signed I-immediate with LSB cleared
static inline int32_t getItypeImmediate(uint32_t insn) {
    return ((int32_t) (insn & 0xfff00000) >> 20) & ~1 /* bits 31..20 */;
}

static inline int32_t getUtypeImmediate(uint32_t insn) {
    return ((insn & 0xfffff000) >> 12) /* bits 31..12 */;
}
