//
//  RISCVCPU.h
//  RISCV
//
//  Created by Makigumo on 2016/12/04.
//  Copyright © 2016年 Makigumo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Hopper/Hopper.h>

typedef NS_ENUM(NSUInteger, RISCVRegClass) {
    RegClass_RISCV_PC = RegClass_FirstUserClass,
    RegClass_RISCV_ABI,
    RegClass_RISCV_RetVal,
    RegClass_RISCV_FuncArg,
    RegClass_RISCV_Saved,
    RegClass_RISCV_Temp,
    RegClass_RISCV_Pair64,
    RegClass_RISCV_ABI64,
    RegClass_RISCV_RetVal64,
    RegClass_RISCV_FuncArg64,
    RegClass_RISCV_Saved64,
    RegClass_RISCV_Temp64,
    RegClass_RISCV_Pair128,
    RegClass_RISCV_FPU_Temp,
    RegClass_RISCV_FPU_Arg,
    RegClass_RISCV_FPU_Save,
    RegClass_RISCV_FPU_Pair64,
    RegClass_RISCV_FPU_Temp64,
    RegClass_RISCV_FPU_Arg64,
    RegClass_RISCV_FPU_Save64,
    RegClass_RISCV_FPU_Pair128,
    RegClass_RISCV_Cnt
};

#define REG_MASK(cls, reg) \
    (DISASM_BUILD_REGISTER_CLS_MASK(cls) | DISASM_BUILD_REGISTER_INDEX_MASK(reg))

static DisasmOperandType reg_masks_32[] = {
        REG_MASK(RegClass_RISCV_ABI, 0) /* zero */,
        REG_MASK(RegClass_RISCV_ABI, 1) /* ra */,
        REG_MASK(RegClass_RISCV_ABI, 2) /* sp */,
        REG_MASK(RegClass_RISCV_ABI, 3) /* gp */,
        REG_MASK(RegClass_RISCV_ABI, 4) /* tp */,
        REG_MASK(RegClass_RISCV_ABI, 5) /* t0 */,
        REG_MASK(RegClass_RISCV_ABI, 6) /* t1 */,
        REG_MASK(RegClass_RISCV_ABI, 7) /* t2 */,
        REG_MASK(RegClass_RISCV_ABI, 8) /* fp */,
        REG_MASK(RegClass_RISCV_ABI, 9) /* s1 */,
        REG_MASK(RegClass_RISCV_RetVal, 0) /* a0 */,
        REG_MASK(RegClass_RISCV_RetVal, 1) /* a1 */,
        REG_MASK(RegClass_RISCV_FuncArg, 0) /* a2 */,
        REG_MASK(RegClass_RISCV_FuncArg, 1) /* a3 */,
        REG_MASK(RegClass_RISCV_FuncArg, 2) /* a4 */,
        REG_MASK(RegClass_RISCV_FuncArg, 3) /* a5 */,
        REG_MASK(RegClass_RISCV_FuncArg, 4) /* a6 */,
        REG_MASK(RegClass_RISCV_FuncArg, 5) /* a7 */,
        REG_MASK(RegClass_RISCV_Saved, 0) /* s2 */,
        REG_MASK(RegClass_RISCV_Saved, 1) /* s3 */,
        REG_MASK(RegClass_RISCV_Saved, 2) /* s4 */,
        REG_MASK(RegClass_RISCV_Saved, 3) /* s5 */,
        REG_MASK(RegClass_RISCV_Saved, 4) /* s6 */,
        REG_MASK(RegClass_RISCV_Saved, 5) /* s7 */,
        REG_MASK(RegClass_RISCV_Saved, 6) /* s8 */,
        REG_MASK(RegClass_RISCV_Saved, 7) /* s9 */,
        REG_MASK(RegClass_RISCV_Saved, 8) /* s10 */,
        REG_MASK(RegClass_RISCV_Saved, 9) /* s11 */,
        REG_MASK(RegClass_RISCV_Temp, 0) /* t3 */,
        REG_MASK(RegClass_RISCV_Temp, 1) /* t4 */,
        REG_MASK(RegClass_RISCV_Temp, 2) /* t5 */,
        REG_MASK(RegClass_RISCV_Temp, 3) /* t6 */,
};

static DisasmOperandType reg_masks_64[] = {
        REG_MASK(RegClass_RISCV_ABI64, 0) /* zero_64 */,
        REG_MASK(RegClass_RISCV_ABI64, 1) /* ra_64 */,
        REG_MASK(RegClass_RISCV_ABI64, 2) /* sp_64 */,
        REG_MASK(RegClass_RISCV_ABI64, 3) /* gp_64 */,
        REG_MASK(RegClass_RISCV_ABI64, 4) /* tp_64 */,
        REG_MASK(RegClass_RISCV_ABI64, 5) /* t0_64 */,
        REG_MASK(RegClass_RISCV_ABI64, 6) /* t1_64 */,
        REG_MASK(RegClass_RISCV_ABI64, 7) /* t2_64 */,
        REG_MASK(RegClass_RISCV_ABI64, 8) /* fp_64 */,
        REG_MASK(RegClass_RISCV_ABI64, 9) /* s1_64 */,
        REG_MASK(RegClass_RISCV_RetVal64, 0) /* a0_64 */,
        REG_MASK(RegClass_RISCV_RetVal64, 1) /* a1_64 */,
        REG_MASK(RegClass_RISCV_FuncArg64, 0) /* a2_64 */,
        REG_MASK(RegClass_RISCV_FuncArg64, 1) /* a3_64 */,
        REG_MASK(RegClass_RISCV_FuncArg64, 2) /* a4_64 */,
        REG_MASK(RegClass_RISCV_FuncArg64, 3) /* a5_64 */,
        REG_MASK(RegClass_RISCV_FuncArg64, 4) /* a6_64 */,
        REG_MASK(RegClass_RISCV_FuncArg64, 5) /* a7_64 */,
        REG_MASK(RegClass_RISCV_Saved64, 0) /* s2_64 */,
        REG_MASK(RegClass_RISCV_Saved64, 1) /* s3_64 */,
        REG_MASK(RegClass_RISCV_Saved64, 2) /* s4_64 */,
        REG_MASK(RegClass_RISCV_Saved64, 3) /* s5_64 */,
        REG_MASK(RegClass_RISCV_Saved64, 4) /* s6_64 */,
        REG_MASK(RegClass_RISCV_Saved64, 5) /* s7_64 */,
        REG_MASK(RegClass_RISCV_Saved64, 6) /* s8_64 */,
        REG_MASK(RegClass_RISCV_Saved64, 7) /* s9_64 */,
        REG_MASK(RegClass_RISCV_Saved64, 8) /* s10_64 */,
        REG_MASK(RegClass_RISCV_Saved64, 9) /* s11_64 */,
        REG_MASK(RegClass_RISCV_Temp64, 0) /* t3_64 */,
        REG_MASK(RegClass_RISCV_Temp64, 1) /* t4_64 */,
        REG_MASK(RegClass_RISCV_Temp64, 2) /* t5_64 */,
        REG_MASK(RegClass_RISCV_Temp64, 3) /* t6_64 */,
};

static inline DisasmOperandType getRegMask32(uint8_t reg) {
    if (reg < sizeof(reg_masks_32)) {
        return reg_masks_32[reg];
    }
    return 0;
}

static inline DisasmOperandType getRegMask64(uint8_t reg) {
    if (reg < sizeof(reg_masks_64)) {
        return reg_masks_64[reg];
    }
    return 0;
}


@interface RISCVCPU : NSObject <CPUDefinition>

- (NSObject <HPHopperServices> *)hopperServices;

@end
