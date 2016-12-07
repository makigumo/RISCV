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
    RegClass_RISCV_Pair,
    RegClass_RISCV_FPU_Temp,
    RegClass_RISCV_FPU_Arg,
    RegClass_RISCV_FPU_Save,
    RegClass_RISCV_FPU_Pair64,
    RegClass_RISCV_CSR,
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

static inline DisasmOperandType getRegMask(uint8_t reg) {
    if (reg < sizeof(reg_masks_32)/sizeof(reg_masks_32[0])) {
        return reg_masks_32[reg];
    }
    return 0;
}

static inline DisasmOperandType getCsrMask() {
    return REG_MASK(RegClass_RISCV_CSR, 0);
}

static NSString *getCsrName(uint64_t csr) {
    switch (csr) {
        case 0x000: return @"ustatus";
        case 0x001: return @"flags";
        case 0x002: return @"frm";
        case 0x003: return @"fcsr";
        case 0x004: return @"uie";
        case 0x005: return @"utvec";

        case 0x040: return @"uscratch";
        case 0x041: return @"uepc";
        case 0x042: return @"ucause";
        case 0x043: return @"ubadaddr";
        case 0x044: return @"uip";

        case 0x100: return @"sstatus";
        case 0x102: return @"sedeleg";
        case 0x103: return @"sideleg";
        case 0x104: return @"sie";
        case 0x105: return @"stvec";

        case 0x140: return @"sscratch";
        case 0x141: return @"sepc";
        case 0x142: return @"scause";
        case 0x143: return @"sbadaddr";
        case 0x144: return @"sip";

        case 0x180: return @"sptbr";

        case 0x200: return @"hstatus";
        case 0x202: return @"hedeleg";
        case 0x203: return @"hideleg";
        case 0x204: return @"hie";
        case 0x205: return @"htvec";

        case 0x300: return @"mstatus";
        case 0x301: return @"misa";
        case 0x302: return @"medeleg";
        case 0x303: return @"mideleg";
        case 0x304: return @"mie";
        case 0x305: return @"mtvec";

        case 0x320: return @"mucounteren";
        case 0x321: return @"mscounteren";
        case 0x322: return @"mhcounteren";
        case 0x323: return @"mhpmevent3";
        case 0x324: return @"mhpmevent4";
        case 0x325: return @"mhpmevent5";
        case 0x326: return @"mhpmevent6";
        case 0x327: return @"mhpmevent7";
        case 0x328: return @"mhpmevent8";
        case 0x329: return @"mhpmevent9";
        case 0x32a: return @"mhpmevent10";
        case 0x32b: return @"mhpmevent11";
        case 0x32c: return @"mhpmevent12";
        case 0x32d: return @"mhpmevent13";
        case 0x32e: return @"mhpmevent14";
        case 0x32f: return @"mhpmevent15";
        case 0x330: return @"mhpmevent16";
        case 0x331: return @"mhpmevent17";
        case 0x332: return @"mhpmevent18";
        case 0x333: return @"mhpmevent19";
        case 0x334: return @"mhpmevent20";
        case 0x335: return @"mhpmevent21";
        case 0x336: return @"mhpmevent22";
        case 0x337: return @"mhpmevent23";
        case 0x338: return @"mhpmevent24";
        case 0x339: return @"mhpmevent25";
        case 0x33a: return @"mhpmevent26";
        case 0x33b: return @"mhpmevent27";
        case 0x33c: return @"mhpmevent28";
        case 0x33d: return @"mhpmevent29";
        case 0x33e: return @"mhpmevent30";
        case 0x33f: return @"mhpmevent31";

        case 0x340: return @"mscratch";
        case 0x341: return @"mepc";
        case 0x342: return @"mcause";
        case 0x343: return @"mbadaddr";
        case 0x344: return @"mip";

        case 0x380: return @"mbase";
        case 0x381: return @"mbound";
        case 0x382: return @"mibase";
        case 0x383: return @"mibound";
        case 0x384: return @"mdbase";
        case 0x385: return @"mdbound";

        case 0x7a0: return @"tselect";
        case 0x7a1: return @"tdata1";
        case 0x7a2: return @"tdata2";
        case 0x7a3: return @"tdata3";

        case 0x7b0: return @"dcsr";
        case 0x7b1: return @"dpc";
        case 0x7b2: return @"dscratch";

        case 0xb00: return @"mcycle";
        case 0xb02: return @"minstret";
        case 0xb03: return @"mhpmcounter3";
        case 0xb04: return @"mhpmcounter4";
        case 0xb05: return @"mhpmcounter5";
        case 0xb06: return @"mhpmcounter6";
        case 0xb07: return @"mhpmcounter7";
        case 0xb08: return @"mhpmcounter8";
        case 0xb09: return @"mhpmcounter9";
        case 0xb0a: return @"mhpmcounter10";
        case 0xb0b: return @"mhpmcounter11";
        case 0xb0c: return @"mhpmcounter12";
        case 0xb0d: return @"mhpmcounter13";
        case 0xb0e: return @"mhpmcounter14";
        case 0xb0f: return @"mhpmcounter15";
        case 0xb10: return @"mhpmcounter16";
        case 0xb11: return @"mhpmcounter17";
        case 0xb12: return @"mhpmcounter18";
        case 0xb13: return @"mhpmcounter19";
        case 0xb14: return @"mhpmcounter20";
        case 0xb15: return @"mhpmcounter21";
        case 0xb16: return @"mhpmcounter22";
        case 0xb17: return @"mhpmcounter23";
        case 0xb18: return @"mhpmcounter24";
        case 0xb19: return @"mhpmcounter25";
        case 0xb1a: return @"mhpmcounter26";
        case 0xb1b: return @"mhpmcounter27";
        case 0xb1c: return @"mhpmcounter28";
        case 0xb1d: return @"mhpmcounter29";
        case 0xb1e: return @"mhpmcounter30";
        case 0xb1f: return @"mhpmcounter31";

        case 0xb80: return @"mcycleh";
        case 0xb82: return @"minstreth";
        case 0xb83: return @"mhpmcounter3h";
        case 0xb84: return @"mhpmcounter4h";
        case 0xb85: return @"mhpmcounter5h";
        case 0xb86: return @"mhpmcounter6h";
        case 0xb87: return @"mhpmcounter7h";
        case 0xb88: return @"mhpmcounter8h";
        case 0xb89: return @"mhpmcounter9h";
        case 0xb8a: return @"mhpmcounter10h";
        case 0xb8b: return @"mhpmcounter11h";
        case 0xb8c: return @"mhpmcounter12h";
        case 0xb8d: return @"mhpmcounter13h";
        case 0xb8e: return @"mhpmcounter14h";
        case 0xb8f: return @"mhpmcounter15h";
        case 0xb90: return @"mhpmcounter16h";
        case 0xb91: return @"mhpmcounter17h";
        case 0xb92: return @"mhpmcounter18h";
        case 0xb93: return @"mhpmcounter19h";
        case 0xb94: return @"mhpmcounter20h";
        case 0xb95: return @"mhpmcounter21h";
        case 0xb96: return @"mhpmcounter22h";
        case 0xb97: return @"mhpmcounter23h";
        case 0xb98: return @"mhpmcounter24h";
        case 0xb99: return @"mhpmcounter25h";
        case 0xb9a: return @"mhpmcounter26h";
        case 0xb9b: return @"mhpmcounter27h";
        case 0xb9c: return @"mhpmcounter28h";
        case 0xb9d: return @"mhpmcounter29h";
        case 0xb9e: return @"mhpmcounter30h";
        case 0xb9f: return @"mhpmcounter31h";

        case 0xc00: return @"cycle";
        case 0xc01: return @"time";
        case 0xc02: return @"instret";
        case 0xc03: return @"hpmcounter3";
        case 0xc04: return @"hpmcounter4";
        case 0xc05: return @"hpmcounter5";
        case 0xc06: return @"hpmcounter6";
        case 0xc07: return @"hpmcounter7";
        case 0xc08: return @"hpmcounter8";
        case 0xc09: return @"hpmcounter9";
        case 0xc0a: return @"hpmcounter10";
        case 0xc0b: return @"hpmcounter11";
        case 0xc0c: return @"hpmcounter12";
        case 0xc0d: return @"hpmcounter13";
        case 0xc0e: return @"hpmcounter14";
        case 0xc0f: return @"hpmcounter15";
        case 0xc10: return @"hpmcounter16";
        case 0xc11: return @"hpmcounter17";
        case 0xc12: return @"hpmcounter18";
        case 0xc13: return @"hpmcounter19";
        case 0xc14: return @"hpmcounter20";
        case 0xc15: return @"hpmcounter21";
        case 0xc16: return @"hpmcounter22";
        case 0xc17: return @"hpmcounter23";
        case 0xc18: return @"hpmcounter24";
        case 0xc19: return @"hpmcounter25";
        case 0xc1a: return @"hpmcounter26";
        case 0xc1b: return @"hpmcounter27";
        case 0xc1c: return @"hpmcounter28";
        case 0xc1d: return @"hpmcounter29";
        case 0xc1e: return @"hpmcounter30";
        case 0xc1f: return @"hpmcounter31";

        case 0xc80: return @"cycleh";
        case 0xc81: return @"timeh";
        case 0xc82: return @"instreth";
        case 0xc83: return @"hpmcounter3h";
        case 0xc84: return @"hpmcounter4h";
        case 0xc85: return @"hpmcounter5h";
        case 0xc86: return @"hpmcounter6h";
        case 0xc87: return @"hpmcounter7h";
        case 0xc88: return @"hpmcounter8h";
        case 0xc89: return @"hpmcounter9h";
        case 0xc8a: return @"hpmcounter10h";
        case 0xc8b: return @"hpmcounter11h";
        case 0xc8c: return @"hpmcounter12h";
        case 0xc8d: return @"hpmcounter13h";
        case 0xc8e: return @"hpmcounter14h";
        case 0xc8f: return @"hpmcounter15h";
        case 0xc90: return @"hpmcounter16h";
        case 0xc91: return @"hpmcounter17h";
        case 0xc92: return @"hpmcounter18h";
        case 0xc93: return @"hpmcounter19h";
        case 0xc94: return @"hpmcounter20h";
        case 0xc95: return @"hpmcounter21h";
        case 0xc96: return @"hpmcounter22h";
        case 0xc97: return @"hpmcounter23h";
        case 0xc98: return @"hpmcounter24h";
        case 0xc99: return @"hpmcounter25h";
        case 0xc9a: return @"hpmcounter26h";
        case 0xc9b: return @"hpmcounter27h";
        case 0xc9c: return @"hpmcounter28h";
        case 0xc9d: return @"hpmcounter29h";
        case 0xc9e: return @"hpmcounter30h";
        case 0xc9f: return @"hpmcounter31h";

        case 0xf11: return @"mvendorid";
        case 0xf12: return @"marchid";
        case 0xf13: return @"mimpid";
        case 0xf14: return @"mhartid";

        default:
            return [NSString stringWithFormat:@"csr_0x%x", csr];
    }
}


@interface RISCVCPU : NSObject <CPUDefinition>

- (NSObject <HPHopperServices> *)hopperServices;

@end
