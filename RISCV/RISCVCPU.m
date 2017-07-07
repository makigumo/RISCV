//
//  RISCVCPU.m
//  RISCV
//
//  Created by Makigumo on 2016/12/04.
//  Copyright © 2016年 Makigumo. All rights reserved.
//

#import "RISCVCtx.h"

@implementation RISCVCPU {
    NSObject <HPHopperServices> *_services;
}

- (instancetype)initWithHopperServices:(NSObject <HPHopperServices> *)services {
    if (self = [super init]) {
        _services = services;
    }
    return self;
}

- (NSObject <HPHopperServices> *)hopperServices {
    return _services;
}

- (Class)cpuContextClass {
    return [RISCVCtx class];
}

- (NSObject <CPUContext> *)buildCPUContextForFile:(NSObject <HPDisassembledFile> *)file {
    return [[RISCVCtx alloc] initWithCPU:self andFile:file];
}

- (HopperUUID *)pluginUUID {
    return [_services UUIDWithString:@"BB67F523-0244-4FBD-8842-ADFE624FB826"];
}

- (HopperPluginType)pluginType {
    return Plugin_CPU;
}

- (NSString *)pluginName {
    return @"RISCV";
}

- (NSString *)pluginDescription {
    return @"RISCV CPU support";
}

- (NSString *)pluginAuthor {
    return @"Makigumo";
}

- (NSString *)pluginCopyright {
    return @"©2016 - Makigumo";
}

- (NSArray<NSString *> *)cpuFamilies {
    return @[@"RISCV"];
}

- (NSString *)pluginVersion {
    return @"0.1.0";
}

- (NSArray<NSString *> *)cpuSubFamiliesForFamily:(NSString *)family {
    if ([family isEqualToString:@"RISCV"])
        return @[
                @"riscv32",
                @"riscv64"
        ];
    return nil;
}

- (int)addressSpaceWidthInBitsForCPUFamily:(NSString *)family andSubFamily:(NSString *)subFamily {
    if ([family isEqualToString:@"RISCV"]) {
        if ([subFamily isEqualToString:@"riscv32"]) return 32;
        if ([subFamily isEqualToString:@"riscv64"]) return 64;
    }
    return 0;
}

- (CPUEndianess)endianess {
    return CPUEndianess_Little;
}

- (NSUInteger)syntaxVariantCount {
    return 1;
}

- (NSUInteger)cpuModeCount {
    return 1;
}

- (NSArray<NSString *> *)syntaxVariantNames {
    return @[@"generic",];
}

- (NSArray<NSString *> *)cpuModeNames {
    return @[@"generic"];
}

- (NSString *)framePointerRegisterNameForFile:(NSObject <HPDisassembledFile> *)file {
    return @"";
}

- (NSUInteger)registerClassCount {
    return RegClass_RISCV_Cnt;
}

- (NSUInteger)registerCountForClass:(RegClass)reg_class {
    switch (reg_class) {
        case (RegClass) RegClass_RISCV_ABI:
            return 10;
        case (RegClass) RegClass_RISCV_RetVal:
            return 2;
        case (RegClass) RegClass_RISCV_FuncArg:
            return 6;
        case (RegClass) RegClass_RISCV_Saved:
            return 10;
        case (RegClass) RegClass_RISCV_Temp:
            return 4;
        case (RegClass) RegClass_RISCV_Pair:
            return 4;
        case (RegClass) RegClass_RISCV_FPU_Temp:
            return 12;
        case (RegClass) RegClass_RISCV_FPU_Save:
            return 12;
        case (RegClass) RegClass_RISCV_FPU_Arg:
            return 8;

        case (RegClass) RegClass_RISCV_CSR:
            // actually up to 4096
            // we use a single register type here and put the real value into the operands userdata[0]
            return 1;

        default:
            break;
    }
    return 0;
}

- (BOOL)registerIndexIsStackPointer:(NSUInteger)reg ofClass:(RegClass)reg_class {
    return reg_class == RegClass_RISCV_ABI && reg == 2;
}

- (BOOL)registerIndexIsFrameBasePointer:(NSUInteger)reg ofClass:(RegClass)reg_class {
    return NO;
}

- (BOOL)registerIndexIsProgramCounter:(NSUInteger)reg {
    return reg == 0;
}

- (NSString *)registerIndexToString:(NSUInteger)reg
                            ofClass:(RegClass)reg_class
                        withBitSize:(NSUInteger)size
                           position:(DisasmPosition)position
                     andSyntaxIndex:(NSUInteger)syntaxIndex {
    switch (reg_class) {
        case (RegClass) RegClass_RISCV_ABI:
            if (reg < 10) {
                static NSString *names[] = {
                        @"zero", @"ra", @"sp", @"gp",
                        @"tp", @"t0", @"t1", @"t2",
                        @"fp" /* s0 */, @"s1"
                };
                return names[reg];
            }
            return [NSString stringWithFormat:@"UNKNOWN_ABI_REG<%lld>", (long long) reg];
        case (RegClass) RegClass_RISCV_RetVal:
            return [NSString stringWithFormat:@"a%d", (int) reg];
        case (RegClass) RegClass_RISCV_FuncArg:
            return [NSString stringWithFormat:@"a%d", (int) reg + 2];
        case (RegClass) RegClass_RISCV_Saved:
            return [NSString stringWithFormat:@"s%d", (int) reg + 2];
        case (RegClass) RegClass_RISCV_Temp:
            return [NSString stringWithFormat:@"t%d", (int) reg + 2];
        case (RegClass) RegClass_RISCV_Pair:
            if (reg < 4) {
                static NSString *names32[] = {
                        @"a0_p64" /*a0,a1*/, @"a1_p64" /*a2,a3*/, @"a2_p64" /*a4,a5*/, @"a3_p64" /*a6,a7*/,
                };
                return names32[reg];
            }
            return [NSString stringWithFormat:@"UNKNOWN_PAIR64_REG<%lld>", (long long) reg];

            // FPU 32 bit
        case (RegClass) RegClass_RISCV_FPU_Temp:
            return [NSString stringWithFormat:@"ft%d", (int) reg];
        case (RegClass) RegClass_RISCV_FPU_Arg:
            return [NSString stringWithFormat:@"fa%d", (int) reg];
        case (RegClass) RegClass_RISCV_FPU_Save:
            return [NSString stringWithFormat:@"fs%d", (int) reg];
        case (RegClass) RegClass_RISCV_CSR:
            return @"csr";

        case (RegClass) -1:
            break;
        default:
            return [NSString stringWithFormat:@"class%d_reg%d", (int) reg_class, (int) reg];
    }
    return nil;
}

- (NSString *)cpuRegisterStateMaskToString:(uint32_t)cpuState {
    return @"";
}

- (BOOL)registerHasSideEffectForIndex:(NSUInteger)reg andClass:(RegClass)reg_class {
    return NO;
}

- (NSData *)nopWithSize:(NSUInteger)size
                andMode:(NSUInteger)cpuMode
                forFile:(NSObject <HPDisassembledFile> *)file {
    // Instruction size is always a multiple of 4
    if (size % 4 != 0) return nil;
    NSMutableData *nopArray = [[NSMutableData alloc] initWithCapacity:size];
    [nopArray setLength:size];
    uint32_t *ptr = (uint32_t *) [nopArray mutableBytes];
    for (NSUInteger i = 0; i < size; i += 4) {
        OSWriteBigInt32(ptr, i, 0x13 /* nop = addi zero, zero, 0 */);
    }
    return [NSData dataWithData:nopArray];
}

- (BOOL)canAssembleInstructionsForCPUFamily:(NSString *)family andSubFamily:(NSString *)subFamily {
    return NO;
}

- (BOOL)canDecompileProceduresForCPUFamily:(NSString *)family andSubFamily:(NSString *)subFamily {
    return NO;
}

@end
