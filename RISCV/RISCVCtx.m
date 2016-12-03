//
//  RISCVCtx.m
//  RISCV
//
//  Created by Makigumo on 2016/12/04.
//  Copyright © 2016年 Makigumo. All rights reserved.
//

#import <Hopper/Hopper.h>
#import "RISCVCtx.h"
#import "RISCVCPU.h"

@implementation RISCVCtx {
    RISCVCPU *_cpu;
    NSObject <HPDisassembledFile> *_file;
}

DisasmOperandType (*getRegMask)(uint8_t) = &getRegMask32;

- (instancetype)initWithCPU:(RISCVCPU *)cpu andFile:(NSObject <HPDisassembledFile> *)file {
    if (self = [super init]) {
        _cpu = cpu;
        _file = file;
        if ([_file is64Bits]) {
            getRegMask = &getRegMask64;
        }
    }
    return self;
}

- (void)dealloc {
}

- (NSObject <CPUDefinition> *)cpuDefinition {
    return _cpu;
}

- (void)initDisasmStructure:(DisasmStruct *)disasm withSyntaxIndex:(NSUInteger)syntaxIndex {
    bzero(disasm, sizeof(DisasmStruct));
    for (int i = 0; i < DISASM_MAX_OPERANDS; i++) {
        disasm->operand[i].type = DISASM_OPERAND_NO_OPERAND;
    }
    disasm->instruction.addressValue = 0;
}

// Analysis

- (Address)adjustCodeAddress:(Address)address {
    return address;
}

- (uint8_t)cpuModeFromAddress:(Address)address {
    return 0;
}

- (BOOL)addressForcesACPUMode:(Address)address {
    return NO;
}

- (Address)nextAddressToTryIfInstructionFailedToDecodeAt:(Address)address forCPUMode:(uint8_t)mode {
    return ((address & ~3) + 4);
}

- (int)isNopAt:(Address)address {
    uint32_t word = [_file readUInt32AtVirtualAddress:address];
    return (word == 0x00000013) ? 4 : 0;
}

- (BOOL)hasProcedurePrologAt:(Address)address {
    return NO;
}

- (NSUInteger)detectedPaddingLengthAt:(Address)address {
    NSUInteger len = 0;
    while ([_file readUInt16AtVirtualAddress:address] == 0) {
        address += 4;
        len += 4;
    }

    return len;
}

- (void)analysisBeginsAt:(Address)entryPoint {

}

- (void)analysisEnded {

}

- (void)procedureAnalysisBeginsForProcedure:(NSObject <HPProcedure> *)procedure atEntryPoint:(Address)entryPoint {

}

- (void)procedureAnalysisOfPrologForProcedure:(NSObject <HPProcedure> *)procedure atEntryPoint:(Address)entryPoint {

}

- (void)procedureAnalysisOfEpilogForProcedure:(NSObject <HPProcedure> *)procedure atEntryPoint:(Address)entryPoint {

}

- (void)procedureAnalysisEndedForProcedure:(NSObject <HPProcedure> *)procedure atEntryPoint:(Address)entryPoint {

}

- (void)procedureAnalysisContinuesOnBasicBlock:(NSObject <HPBasicBlock> *)basicBlock {

}

- (Address)getThunkDestinationForInstructionAt:(Address)address {
    return BAD_ADDRESS;
}

- (void)resetDisassembler {

}

- (uint8_t)estimateCPUModeAtVirtualAddress:(Address)address {
    return 0;
}

#define OPCODE_MASK 0x0000007f
#define RD_MASK     0x00000f80
#define SRC_MASK    0x000F8000
#define FUNCT3_MASK 0x00007000
#define IMM_MASK    0xfffff000

typedef struct {
    uint8_t opcode; /* bits 6..0 */
    uint8_t reg_dest; /* bits 11..7 */
    uint8_t funct3; /* bits 14..12 */
    uint8_t reg_src1; /* bits 19..15 */
    uint8_t reg_src2; /* bits 24..20 */
    uint8_t funct7; /* bits 31..25 */
} rtype_insn;

- (int)disassembleSingleInstruction:(DisasmStruct *)disasm usingProcessorMode:(NSUInteger)mode {
    if (disasm->bytes == NULL) return DISASM_UNKNOWN_OPCODE;

    uint32_t insncode = disasm->bytes[3] << 24 | disasm->bytes[2] << 16 | disasm->bytes[1] << 8 | disasm->bytes[0];
    uint32_t opcode = insncode & OPCODE_MASK;

    // all instructions are 32 bit
    int len = 4;
    disasm->instruction.length = 4;
    uint8_t dest_reg = (uint8_t) ((insncode & RD_MASK) >> 7);
    uint8_t src_reg = (uint8_t) ((insncode & SRC_MASK) >> 15);
    uint8_t funct3 = (uint8_t) ((insncode & FUNCT3_MASK) >> 11);

    switch (opcode) {

        case 0b0010111 /* AUIPC adds a 20-bit upper immediate to the PC */:
            strcpy(disasm->instruction.mnemonic, "auipc");
            disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
            disasm->operand[0].type |= getRegMask(dest_reg);
            disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE;
            disasm->operand[1].immediateValue = (insncode & IMM_MASK) >> 12;
            disasm->operand[1].accessMode = DISASM_ACCESS_READ;
            disasm->instruction.addressValue = (Address) (disasm->operand[1].immediateValue << 12);
            break;

        case 0b0110111 /* LUI */:
            strcpy(disasm->instruction.mnemonic, "lui");
            disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
            disasm->operand[0].type |= getRegMask(dest_reg);
            disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE;
            disasm->operand[1].immediateValue = (insncode & IMM_MASK) >> 12;
            disasm->operand[1].accessMode = DISASM_ACCESS_READ;
            disasm->instruction.addressValue = (Address) (disasm->operand[1].immediateValue << 12);
            break;

        case 0b1101111 /* JAL */:
            if (dest_reg == 0 /* zero */) {
                // plain unconditional jump
                // j offset
                strcpy(disasm->instruction.mnemonic, "j");
                disasm->operand[0].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                disasm->operand[0].immediateValue = getUJtypeImmediate(insncode);
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[0].isBranchDestination = 1;
                disasm->instruction.branchType = DISASM_BRANCH_JMP;
                disasm->instruction.addressValue = disasm->virtualAddr + disasm->operand[0].immediateValue;
            } else if (dest_reg == 1 /* ra */) {
                // jal offset
                strcpy(disasm->instruction.mnemonic, "jal");
                disasm->operand[0].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                disasm->operand[0].immediateValue = getUJtypeImmediate(insncode);
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[0].isBranchDestination = 1;
                disasm->instruction.branchType = DISASM_BRANCH_JMP;
                disasm->instruction.addressValue = disasm->virtualAddr + disasm->operand[0].immediateValue;
            } else {
                // jal rd, offset
                strcpy(disasm->instruction.mnemonic, "jal");
                disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                disasm->operand[0].type |= getRegMask(dest_reg);
                disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                disasm->operand[1].immediateValue = getUJtypeImmediate(insncode);
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].isBranchDestination = 1;
                disasm->instruction.branchType = DISASM_BRANCH_JMP;
                disasm->instruction.addressValue = disasm->virtualAddr + disasm->operand[0].immediateValue;
            }
            break;

        case 0b1100111 /* JALR */: {
            int32_t imm = getItypeImmediate(insncode);
            if (imm == 0) {
                if (dest_reg == 0 /* zero */) {
                    if (src_reg == 1 /* ra */) {
                        // ret = jalr zero, ra, 0
                        strcpy(disasm->instruction.mnemonic, "ret");
                        disasm->instruction.branchType = DISASM_BRANCH_RET;
                    } else {
                        // jr rs = jalr zero, rs, 0
                        strcpy(disasm->instruction.mnemonic, "jr");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getRegMask(src_reg);
                        disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[0].isBranchDestination = 1;
                        disasm->instruction.branchType = DISASM_BRANCH_CALL;
                    }
                } else if (dest_reg == 1 /* ra */) {
                    // jalr rs = jalr ra, rs, 0
                    strcpy(disasm->instruction.mnemonic, "jalr");
                    disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                    disasm->operand[0].type |= getRegMask(src_reg);
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[0].isBranchDestination = 1;
                    disasm->instruction.branchType = DISASM_BRANCH_CALL;
                }
            } else if (dest_reg == 0 /* zero */) {
                // result (PC + 4) is discarded
                // jalr rs, imm
                strcpy(disasm->instruction.mnemonic, "jalr");
                disasm->operand[0].type = DISASM_OPERAND_MEMORY_TYPE;
                disasm->operand[0].type |= getRegMask(src_reg);
                disasm->operand[0].memory.baseRegistersMask = getRegMask(src_reg);
                disasm->operand[0].memory.displacement = imm;
                disasm->operand[0].memory.scale = 1;
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[0].isBranchDestination = 1;
                disasm->instruction.branchType = DISASM_BRANCH_CALL;
                disasm->instruction.addressValue = (Address) imm + disasm->virtualAddr /* + src_reg */;
            }
            if (disasm->instruction.mnemonic[0] == 0) {
                // jalr rd, rs, imm
                strcpy(disasm->instruction.mnemonic, "jalr");
                disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                disasm->operand[0].type |= getRegMask(dest_reg);
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].type = DISASM_OPERAND_MEMORY_TYPE;
                disasm->operand[1].type |= getRegMask(src_reg);
                disasm->operand[1].memory.baseRegistersMask = getRegMask(src_reg);
                disasm->operand[1].memory.displacement = imm;
                disasm->operand[1].memory.scale = 1;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].isBranchDestination = 1;
                disasm->instruction.branchType = DISASM_BRANCH_CALL;
                disasm->instruction.addressValue = (Address) imm + disasm->virtualAddr /* + src_reg */;
            }
        }
            break;

        case 0b0010011 /* OP-IMM */:
            if ((disasm->virtualAddr & 0xffffffff) == 0x80000018) {
                NSObject <HPHopperServices> *services = _cpu.hopperServices;
                [services logMessage:[NSString stringWithFormat:@"funct3: %d, rd: %d, rs: %d, imm: %0x", funct3, dest_reg, src_reg, getItypeImmediate(insncode)]];
            }
            switch (funct3) {
                case 0b000 /* addi */:
                    if (dest_reg == src_reg && dest_reg == 0 && getItypeImmediate(insncode) == 0) {
                        // addi zero, zero, 0
                        strcpy(disasm->instruction.mnemonic, "nop");
                    } else if (dest_reg != src_reg && src_reg == 0) {
                        // addi rd, zero, imm
                        strcpy(disasm->instruction.mnemonic, "li");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getRegMask(dest_reg);
                        disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                        disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE;
                        disasm->operand[1].immediateValue = getItypeImmediate(insncode);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                    } else if (getItypeImmediate(insncode) == 0) {
                        // addi rd, rs, 0
                        strcpy(disasm->instruction.mnemonic, "mv");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getRegMask(dest_reg);
                        disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type |= getRegMask(src_reg);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                    } else {
                        strcpy(disasm->instruction.mnemonic, "addi");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getRegMask(dest_reg);
                        disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type |= getRegMask(src_reg);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE;
                        disasm->operand[2].immediateValue = getItypeImmediate(insncode);
                        disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                    }
                    break;

                case 0b010 /* slti */:
                    break;
                case 0b011 /* sltiu */:
                    break;
                case 0b111 /* andi */:
                    break;
                case 0b110 /* ori */:
                    break;
                case 0b100 /* xori */:
                    break;
            }

        case 0b1100011 /* BRANCH */:
            switch (funct3) {
                case 0b000 /* BEQ */:
                    break;
                case 0b001 /* BNE */:
                    break;
                case 0b100 /* BLT */:
                    break;
                case 0b110 /* BLTU */:
                    break;
                case 0b101 /* BGE */:
                    break;
                case 0b111 /* BGEU */:
                    break;
            }
            break;
        default:
            break;
    }

    return len;
}

- (BOOL)instructionHaltsExecutionFlow:(DisasmStruct *)disasm {
    return NO;
}

- (void)performBranchesAnalysis:(DisasmStruct *)disasm computingNextAddress:(Address *)next andBranches:(NSMutableArray *)branches forProcedure:(NSObject <HPProcedure> *)procedure basicBlock:(NSObject <HPBasicBlock> *)basicBlock ofSegment:(NSObject <HPSegment> *)segment calledAddresses:(NSMutableArray *)calledAddresses callsites:(NSMutableArray *)callSitesAddresses {

}

- (void)performInstructionSpecificAnalysis:(DisasmStruct *)disasm forProcedure:(NSObject <HPProcedure> *)procedure inSegment:(NSObject <HPSegment> *)segment {

}

- (void)performProcedureAnalysis:(NSObject <HPProcedure> *)procedure basicBlock:(NSObject <HPBasicBlock> *)basicBlock disasm:(DisasmStruct *)disasm {

}

- (void)updateProcedureAnalysis:(DisasmStruct *)disasm {

}

// Printing

static inline int firstBitIndex(uint64_t mask) {
    for (int i = 0, j = 1; i < 64; i++, j <<= 1) {
        if (mask & j) {
            return i;
        }
    }
    return -1;
}

static inline RegClass regClassFromType(uint64_t type) {
    return (RegClass) firstBitIndex(DISASM_GET_REGISTER_CLS_MASK(type));
}

static inline int regIndexFromType(uint64_t type) {
    return firstBitIndex(DISASM_GET_REGISTER_INDEX_MASK(type));
}

- (NSObject <HPASMLine> *)buildMnemonicString:(DisasmStruct *)disasm
                                       inFile:(NSObject <HPDisassembledFile> *)file {
    NSObject <HPHopperServices> *services = _cpu.hopperServices;
    NSObject <HPASMLine> *line = [services blankASMLine];
    [line appendMnemonic:@(disasm->instruction.mnemonic)];
    return line;
}

- (NSObject <HPASMLine> *)buildOperandString:(DisasmStruct *)disasm
                             forOperandIndex:(NSUInteger)operandIndex
                                      inFile:(NSObject <HPDisassembledFile> *)file
                                         raw:(BOOL)raw {
    if (operandIndex >= DISASM_MAX_OPERANDS) return nil;
    DisasmOperand *operand = disasm->operand + operandIndex;
    if (operand->type == DISASM_OPERAND_NO_OPERAND) return nil;

    uint8_t bitsize = (uint8_t) ([file is64Bits] ? 64 : 32);

    // Get the format requested by the user
    ArgFormat format = [file formatForArgument:operandIndex atVirtualAddress:disasm->virtualAddr];

    NSObject <HPHopperServices> *services = _cpu.hopperServices;

    NSObject <HPASMLine> *line = [services blankASMLine];

    if (operand->type & DISASM_OPERAND_CONSTANT_TYPE) {
        if (operand->isBranchDestination) {
            uint64_t value = (operand->type & DISASM_OPERAND_RELATIVE) ?
                    disasm->virtualAddr + operand->immediateValue :
                    (Address) operand->immediateValue;
            NSString *symbol = [_file nameForVirtualAddress:value];
            if (symbol) {
                [line appendName:symbol atAddress:value];
            } else {
                // TODO is there a better way to get the local name (?)
                [line appendLocalName:[NSString stringWithFormat:@"loc_%x", (int64_t) value]
                            atAddress:(Address) value];
            }
        } else {
            if (format == Format_Default) {
                // small values in decimal
                if (operand->immediateValue > -100 && operand->immediateValue < 100) {
                    format = Format_Decimal;
                }
            }
            [line appendRawString:@"#"];
/*
        uint64_t val = operand->type & DISASM_OPERAND_RELATIVE ?
                disasm->virtualAddr + operand->immediateValue :
                (Address) operand->immediateValue;
*/
            uint64_t val = (Address) operand->immediateValue;

            [line append:[file formatNumber:val
                                         at:disasm->virtualAddr
                                usingFormat:format
                                 andBitSize:bitsize]];
        }
    } else if (operand->type & DISASM_OPERAND_REGISTER_TYPE) {
        RegClass regCls = regClassFromType(operand->type);
        int regIdx = regIndexFromType(operand->type);
        NSString *reg_name = [_cpu registerIndexToString:regIdx
                                                 ofClass:regCls
                                             withBitSize:bitsize
                                             andPosition:DISASM_LOWPOSITION];
        [line appendRegister:reg_name
                     ofClass:regCls
                    andIndex:regIdx];

    } else if (operand->type & DISASM_OPERAND_MEMORY_TYPE) {

        if (operand->type & DISASM_OPERAND_REGISTER_INDEX_MASK) {
            RegClass regCls = regClassFromType(operand->type);
            int regIdx = regIndexFromType(operand->type);

            NSString *reg_name = [_cpu registerIndexToString:regIdx
                                                     ofClass:regCls
                                                 withBitSize:bitsize
                                                 andPosition:DISASM_LOWPOSITION];

            if (format & Format_Default) {
                // clear default Format types
                //format = format & Format_Negate;
                if ([reg_name isEqualToString:@"sp"] || [reg_name isEqualToString:@"sp_64"]) {
                    format |= Format_StackVariable;
                } else {
                    format |= Format_Offset;
                }
            }

            if (operand->memory.displacement != 0) {
                format |= Format_Signed;
                BOOL varNameAdded = NO;
                if (format & Format_StackVariable) {
                    NSObject <HPProcedure> *proc = [file procedureAt:disasm->virtualAddr];
                    if (proc) {
                        NSString *varName = [proc resolvedVariableNameForDisplacement:operand->memory.displacement
                                                                      usingCPUContext:self];
                        if (varName) {
                            [line appendVariableName:varName
                                    withDisplacement:operand->memory.displacement];
                            varNameAdded = YES;
                        }
                    }
                }
                if (!varNameAdded) {
                    [line append:[file formatNumber:(uint64_t) operand->memory.displacement
                                                 at:disasm->virtualAddr
                                        usingFormat:format
                                         andBitSize:operand->size]];
                }
            }

            [line appendRawString:@"("];
            [line appendRegister:reg_name
                         ofClass:regCls
                        andIndex:regIdx];

            [line appendRawString:@")"];
        } else {
            [line append:[file formatNumber:(uint64_t) operand->memory.displacement
                                         at:disasm->virtualAddr
                                usingFormat:format
                                 andBitSize:operand->size]];
        }

    }

    [file setFormat:format forArgument:operandIndex atVirtualAddress:disasm->virtualAddr];
    [line setIsOperand:operandIndex startingAtIndex:0];

    return line;
}

- (NSObject <HPASMLine> *)buildCompleteOperandString:(DisasmStruct *)disasm
                                              inFile:(NSObject <HPDisassembledFile> *)file
                                                 raw:(BOOL)raw {
    NSObject <HPHopperServices> *services = _cpu.hopperServices;

    NSObject <HPASMLine> *line = [services blankASMLine];

    for (int op_index = 0; op_index <= DISASM_MAX_OPERANDS; op_index++) {
        NSObject <HPASMLine> *part = [self buildOperandString:disasm forOperandIndex:op_index inFile:file raw:raw];
        if (part == nil) break;
        if (op_index) [line appendRawString:@", "];
        [line append:part];
    }

    return line;
}

// Decompiler

- (BOOL)canDecompileProcedure:(NSObject <HPProcedure> *)procedure {
    return NO;
}

- (Address)skipHeader:(NSObject <HPBasicBlock> *)basicBlock
          ofProcedure:
                  (NSObject <HPProcedure> *)procedure {
    return basicBlock.from;
}

- (Address)skipFooter:(NSObject <HPBasicBlock> *)basicBlock
          ofProcedure:
                  (NSObject <HPProcedure> *)procedure {
    return basicBlock.to;
}

- (ASTNode *)decompileInstructionAtAddress:(Address)a
                                    disasm:(DisasmStruct *)d
                                 addNode_p:(BOOL *)addNode_p
                           usingDecompiler:(Decompiler *)decompiler {
    return nil;
}

// Assembler

- (NSData *)assembleRawInstruction:(NSString *)instr
                         atAddress:(Address)addr
                           forFile:(NSObject <HPDisassembledFile> *)file
                       withCPUMode:(uint8_t)cpuMode
                usingSyntaxVariant:(NSUInteger)syntax
                             error:(NSError **)error {
    return nil;
}

- (BOOL)instructionCanBeUsedToExtractDirectMemoryReferences:(DisasmStruct *)disasmStruct {
    return YES;
}

- (BOOL)instructionMayBeASwitchStatement:(DisasmStruct *)disasmStruct {
    return NO;
}

@end
