//
//  RISCVCtx.m
//  RISCV
//
//  Created by Makigumo on 2016/12/04.
//  Copyright © 2016年 Makigumo. All rights reserved.
//

#import <Hopper/Hopper.h>
#import "RISCVCtx.h"

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
    disasm->instruction.branchType = DISASM_BRANCH_NONE;
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

- (int)disassembleSingleInstruction:(DisasmStruct *)disasm usingProcessorMode:(NSUInteger)mode {
    if (disasm->bytes == NULL) return DISASM_UNKNOWN_OPCODE;

    uint32_t insncode = disasm->bytes[3] << 24 | disasm->bytes[2] << 16 | disasm->bytes[1] << 8 | disasm->bytes[0];
    uint8_t opcode = getOpcode(insncode);

    // all instructions are 32 bit
    int len = 4;
    disasm->instruction.length = 4;
    disasm->instruction.branchType = DISASM_BRANCH_NONE;
    disasm->instruction.addressValue = 0;
    disasm->instruction.pcRegisterValue = disasm->virtualAddr + 4;
    uint8_t dest_reg = getRD(insncode);
    uint8_t src1_reg = getRS1(insncode);
    uint8_t src2_reg = getRS2(insncode);
    uint8_t funct3 = getFunct3(insncode);
    uint8_t funct7 = getFunct7(insncode);

#if NDEBUG
    if ((disasm->virtualAddr & 0xffffffff) == 0x80000400) {
        NSObject <HPHopperServices> *services = _cpu.hopperServices;
        [services logMessage:[NSString stringWithFormat:@"opcode:%d, funct3:%d, rd:%d, rs1:%d, rs2:%d, imm:%0x, funct7:%0x, shamt:%0x",
                                                        opcode, funct3, dest_reg, src1_reg, src2_reg, getItypeImmediate(insncode), funct7, getShamt(insncode)]];
    }
#endif

    switch (opcode) {

        case OPCODE_AUIPC /* AUIPC adds a 20-bit upper immediate to the PC */:
            strcpy(disasm->instruction.mnemonic, "auipc");
            disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
            disasm->operand[0].type |= getRegMask(dest_reg);
            disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE;
            disasm->operand[1].immediateValue = (insncode & IMM_MASK) >> 12;
            disasm->operand[1].accessMode = DISASM_ACCESS_READ;
            disasm->instruction.addressValue = (Address) (disasm->operand[1].immediateValue << 12);
            break;

        case OPCODE_LUI /* LUI */:
            strcpy(disasm->instruction.mnemonic, "lui");
            disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
            disasm->operand[0].type |= getRegMask(dest_reg);
            disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE;
            disasm->operand[1].immediateValue = (insncode & IMM_MASK) >> 12;
            disasm->operand[1].accessMode = DISASM_ACCESS_READ;
            disasm->instruction.addressValue = (Address) (disasm->operand[1].immediateValue << 12);
            break;

        case OPCODE_JAL /* JAL */:
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
                disasm->instruction.branchType = DISASM_BRANCH_CALL;
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
                disasm->instruction.branchType = DISASM_BRANCH_CALL;
                disasm->instruction.addressValue = disasm->virtualAddr + disasm->operand[0].immediateValue;
            }
            break;

        case OPCODE_JALR /* JALR */:
            if (getItypeImmediate(insncode) == 0) {
                if (dest_reg == 0 /* zero */) {
                    if (src1_reg == 1 /* ra */) {
                        // ret = jalr zero, ra, 0
                        strcpy(disasm->instruction.mnemonic, "ret");
                        disasm->instruction.branchType = DISASM_BRANCH_RET;
                    } else {
                        // jr rs = jalr zero, rs, 0
                        strcpy(disasm->instruction.mnemonic, "jr");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getRegMask(src1_reg);
                        disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[0].isBranchDestination = 1;
                        disasm->instruction.branchType = DISASM_BRANCH_CALL;
                    }
                } else if (dest_reg == 1 /* ra */) {
                    // jalr rs = jalr ra, rs, 0
                    strcpy(disasm->instruction.mnemonic, "jalr");
                    disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                    disasm->operand[0].type |= getRegMask(src1_reg);
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[0].isBranchDestination = 1;
                    disasm->instruction.branchType = DISASM_BRANCH_CALL;
                }
            } else if (dest_reg == 0 /* zero */) {
                // result (PC + 4) is discarded
                // jalr rs, imm
                strcpy(disasm->instruction.mnemonic, "jalr");
                disasm->operand[0].type = DISASM_OPERAND_MEMORY_TYPE;
                disasm->operand[0].type |= getRegMask(src1_reg);
                disasm->operand[0].memory.baseRegistersMask = getRegMask(src1_reg);
                disasm->operand[0].memory.displacement = getItypeImmediate(insncode);
                disasm->operand[0].memory.scale = 1;
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[0].isBranchDestination = 1;
                disasm->instruction.branchType = DISASM_BRANCH_CALL;
                disasm->instruction.addressValue = (Address) getItypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
            }
            if (disasm->instruction.mnemonic[0] == 0) {
                // jalr rd, rs, imm
                strcpy(disasm->instruction.mnemonic, "jalr");
                disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                disasm->operand[0].type |= getRegMask(dest_reg);
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].isBranchDestination = 1;
                disasm->instruction.branchType = DISASM_BRANCH_CALL;
                disasm->instruction.addressValue = (Address) getItypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
            }
            break;

        case OPCODE_OPIMM /* OP-IMM */:
            switch (funct3) {
                case 0b000 /* addi */:
                    if (dest_reg == src1_reg && dest_reg == 0 && getItypeImmediate(insncode) == 0) {
                        // addi zero, zero, 0
                        strcpy(disasm->instruction.mnemonic, "nop");
                    } else if (dest_reg != src1_reg && src1_reg == 0) {
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
                        disasm->operand[1].type |= getRegMask(src1_reg);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                    } else {
                        populateOPIMM(disasm, insncode, "addi");
                    }
                    break;
                case 0x001 /* slli */:
                    if ([_file is32Bits]) {
                        switch (funct7) {
                            case 0b0000000:
                                populateOPIMMShift(disasm, insncode, "slli");
                                break;
                        }
                    } else {
                        // 64 bits
                        switch (getFunct6(insncode)) {
                            case 0b000000:
                                populateOPIMMShift64(disasm, insncode, "slli");
                                break;
                        }
                    }
                    break;
                case 0b010 /* slti */:
                    populateOPIMM(disasm, insncode, "slti");
                    break;
                case 0b011 /* sltiu */:
                    if (getItypeImmediate(insncode) == 1) {
                        //  seqz rd, rs = sltiu rd, rs1, 1
                        strcpy(disasm->instruction.mnemonic, "seqz");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getRegMask(dest_reg);
                        disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type |= getRegMask(src1_reg);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                    } else {
                        populateOPIMM(disasm, insncode, "sltiu");
                    }
                    break;
                case 0b100 /* xori */:
                    if (getItypeImmediate(insncode) == -1) {
                        // not rd, rs = xori rd, rs, -1
                        strcpy(disasm->instruction.mnemonic, "not");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getRegMask(dest_reg);
                        disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type |= getRegMask(src1_reg);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                    } else {
                        populateOPIMM(disasm, insncode, "xori");
                    }
                    break;
                case 0b101 /* srli/srai */:
                    if ([_file is32Bits]) {
                        switch (funct7) {
                            case 0b0000000:
                                populateOPIMMShift(disasm, insncode, "srli");
                                break;
                            case 0b0100000:
                                populateOPIMMShift(disasm, insncode, "srai");
                                break;
                        }
                    } else {
                        // 64 bits
                        switch (getFunct6(insncode)) {
                            case 0b000000:
                                populateOPIMMShift64(disasm, insncode, "srli");
                                break;
                            case 0b010000:
                                populateOPIMMShift64(disasm, insncode, "srai");
                                break;
                        }
                    }
                    break;
                case 0b110 /* ori */:
                    populateOPIMM(disasm, insncode, "ori");
                    break;
                case 0b111 /* andi */:
                    populateOPIMM(disasm, insncode, "andi");
                    break;
            }
            break;

        case OPCODE_BRANCH /* BRANCH */:
            switch (funct3) {
                case 0b000 /* beq */:
                    if (src2_reg == 0 /* zero */) {
                        strcpy(disasm->instruction.mnemonic, "beqz");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getRegMask(src1_reg);
                        disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                        disasm->operand[1].immediateValue = getBtypeImmediate(insncode);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].isBranchDestination = 1;
                        disasm->instruction.addressValue = (Address) getBtypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
                        disasm->instruction.branchType = DISASM_BRANCH_JE;
                    } else {
                        strcpy(disasm->instruction.mnemonic, "beq");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getRegMask(src1_reg);
                        disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type |= getRegMask(src2_reg);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                        disasm->operand[2].immediateValue = getBtypeImmediate(insncode);
                        disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[2].isBranchDestination = 1;
                        disasm->instruction.addressValue = (Address) getBtypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
                        disasm->instruction.branchType = DISASM_BRANCH_JE;
                    }
                    break;
                case 0b001 /* bne */:
                    if (src2_reg == 0 /* zero */) {
                        strcpy(disasm->instruction.mnemonic, "bnez");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getRegMask(src1_reg);
                        disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                        disasm->operand[1].immediateValue = getBtypeImmediate(insncode);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].isBranchDestination = 1;
                        disasm->instruction.addressValue = (Address) getBtypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
                        disasm->instruction.branchType = DISASM_BRANCH_JNE;
                    } else {
                        strcpy(disasm->instruction.mnemonic, "bne");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getRegMask(src1_reg);
                        disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type |= getRegMask(src2_reg);
                        disasm->operand[1].accessMode = DISASM_ACCESS_WRITE;
                        disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                        disasm->operand[2].immediateValue = getBtypeImmediate(insncode);
                        disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[2].isBranchDestination = 1;
                        disasm->instruction.addressValue = (Address) getBtypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
                        disasm->instruction.branchType = DISASM_BRANCH_JNE;
                    }
                    break;
                case 0b100 /* blt */:
                    if (src2_reg == 0 /* zero */) {
                        strcpy(disasm->instruction.mnemonic, "bltz");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getRegMask(src1_reg);
                        disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                        disasm->operand[1].immediateValue = getBtypeImmediate(insncode);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].isBranchDestination = 1;
                        disasm->instruction.addressValue = (Address) getBtypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
                        disasm->instruction.branchType = DISASM_BRANCH_JNE;
                    } else {
                        strcpy(disasm->instruction.mnemonic, "blt");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getRegMask(src1_reg);
                        disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type |= getRegMask(src2_reg);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                        disasm->operand[2].immediateValue = getBtypeImmediate(insncode);
                        disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[2].isBranchDestination = 1;
                        disasm->instruction.addressValue = (Address) getBtypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
                        disasm->instruction.branchType = DISASM_BRANCH_JNE;
                    }
                    break;
                case 0b101 /* bge */:
                    if (src2_reg == 0 /* zero */) {
                        strcpy(disasm->instruction.mnemonic, "bgez");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getRegMask(src1_reg);
                        disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                        disasm->operand[1].immediateValue = getBtypeImmediate(insncode);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].isBranchDestination = 1;
                        disasm->instruction.addressValue = (Address) getBtypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
                        disasm->instruction.branchType = DISASM_BRANCH_JNE;
                    } else {
                        strcpy(disasm->instruction.mnemonic, "bge");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getRegMask(src1_reg);
                        disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type |= getRegMask(src2_reg);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                        disasm->operand[2].immediateValue = getBtypeImmediate(insncode);
                        disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[2].isBranchDestination = 1;
                        disasm->instruction.addressValue = (Address) getBtypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
                        disasm->instruction.branchType = DISASM_BRANCH_JNE;
                    }
                    break;
                case 0b110 /* bltu */:
                    strcpy(disasm->instruction.mnemonic, "bltu");
                    disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                    disasm->operand[0].type |= getRegMask(src1_reg);
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                    disasm->operand[1].type |= getRegMask(src2_reg);
                    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                    disasm->operand[2].immediateValue = getBtypeImmediate(insncode);
                    disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[2].isBranchDestination = 1;
                    disasm->instruction.addressValue = (Address) getBtypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
                    disasm->instruction.branchType = DISASM_BRANCH_JNE;
                    break;
                case 0b111 /* bgeu */:
                    strcpy(disasm->instruction.mnemonic, "bgeu");
                    disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                    disasm->operand[0].type |= getRegMask(src1_reg);
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                    disasm->operand[1].type |= getRegMask(src2_reg);
                    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                    disasm->operand[2].immediateValue = getBtypeImmediate(insncode);
                    disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[2].isBranchDestination = 1;
                    disasm->instruction.addressValue = (Address) getBtypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
                    disasm->instruction.branchType = DISASM_BRANCH_JNE;
                    break;
            }
            break;

        case OPCODE_OP /* OP */:
            switch (funct7) {
                case 0b0000000:
                    switch (funct3) {
                        case 0b000 /* add */:
                            populateOP(disasm, insncode, "add");
                            break;
                        case 0b001 /* sll */:
                            populateOP(disasm, insncode, "sll");
                            break;
                        case 0b010 /* slt */:
                            populateOP(disasm, insncode, "slt");
                            break;
                        case 0b011 /* sltu */:
                            populateOP(disasm, insncode, "sltu");
                            break;
                        case 0b100 /* xor */:
                            populateOP(disasm, insncode, "xor");
                            break;
                        case 0b101 /* srl */:
                            populateOP(disasm, insncode, "srl");
                            break;
                        case 0b110 /* or */:
                            populateOP(disasm, insncode, "or");
                            break;
                        case 0b111 /* and */:
                            populateOP(disasm, insncode, "and");
                            break;
                    }
                    break;
                case 0b0100000:
                    switch (funct3) {
                        case 0b000 /* sub */:
                            populateOP(disasm, insncode, "sub");
                            break;
                        case 0b101 /* sra */:
                            populateOP(disasm, insncode, "sra");
                            break;
                    }
                    break;
            }
            break;

        case OPCODE_OP32 /* OP-32 */:
            switch (funct7) {
                case 0b0000000:
                    switch (funct3) {
                        case 0b000 /* add */:
                            populateOP(disasm, insncode, "addw");
                            break;
                        case 0b001 /* sll */:
                            populateOP(disasm, insncode, "sllw");
                            break;
                        case 0b010 /* slt */:
                            populateOP(disasm, insncode, "sltw");
                            break;
                        case 0b101 /* srl */:
                            populateOP(disasm, insncode, "srlw");
                            break;
                    }
                    break;
                case 0b0100000:
                    switch (funct3) {
                        case 0b000 /* sub */:
                            populateOP(disasm, insncode, "subw");
                            break;
                        case 0b101 /* sra */:
                            populateOP(disasm, insncode, "sraw");
                            break;
                    }
                    break;
            }
            break;

        case OPCODE_LOAD:
            switch (funct3) {
                case 0b000 /* LB */:
                    populateLOAD(disasm, insncode, "lb");
                    break;
                case 0b001 /* LH */:
                    populateLOAD(disasm, insncode, "lh");
                    break;
                case 0b010 /* LW */:
                    populateLOAD(disasm, insncode, "lw");
                    break;
                case 0b011 /* LD 64 bit */:
                    populateLOAD(disasm, insncode, "ld");
                    break;
                case 0b100 /* LBU */:
                    populateLOAD(disasm, insncode, "lbu");
                    break;
                case 0b101 /* LHU */:
                    populateLOAD(disasm, insncode, "lhu");
                    break;
            }
            break;

        case OPCODE_STORE:
            switch (funct3) {
                case 0b000 /* sb */:
                    populateSTORE(disasm, insncode, "sb");
                    break;
                case 0b001 /* sh */:
                    populateSTORE(disasm, insncode, "sh");
                    break;
                case 0b010 /* sw */:
                    populateSTORE(disasm, insncode, "sw");
                    break;
                case 0b011 /* sd 64 bit */:
                    populateSTORE(disasm, insncode, "sd");
                    break;
            }
            break;

        case OPCODE_MISC_MEM:
            break;

        case OPCODE_SYSTEM:
            switch (funct3) {
                case 0b000 /* ECALL/EBREAK */:
                    switch (getItypeImmediate(insncode) /* funct12 */) {
                        case 0:
                            if (getRS1(insncode) == 0 && getRD(insncode) == 0) {
                                strcpy(disasm->instruction.mnemonic, "ecall");
                            }
                            break;
                        case 1:
                            if (getRS1(insncode) == 0 && getRD(insncode) == 0) {
                                strcpy(disasm->instruction.mnemonic, "ebreak");
                            }
                            break;
                    }
                    break;
                case 0b001 /* CSRRW */:
                    //strcpy(disasm->instruction.mnemonic, "cssrw");
                    break;
                case 0b010 /* CSRRS */:
                    //strcpy(disasm->instruction.mnemonic, "csrrs");
                    break;
                case 0b011 /* CSRRC */:
                    //strcpy(disasm->instruction.mnemonic, "csrrc");
                    break;
                case 0b101 /* CSRRWI */:
                    //strcpy(disasm->instruction.mnemonic, "csrrwi");
                    break;
                case 0b110 /* CSRRSI */:
                    //strcpy(disasm->instruction.mnemonic, "csrri");
                    break;
                case 0b111 /* CSRRCI */:
                    //strcpy(disasm->instruction.mnemonic, "csrrci");
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
            NSString *symbol = [_file nameForVirtualAddress:disasm->instruction.addressValue];
            if (symbol) {
                [line appendName:symbol atAddress:disasm->instruction.addressValue];
            } else {
                // TODO is there a better way to get the local name (?)
                NSString *labelFormat = (bitsize == 32) ? @"loc_%x" : @"loc_%llx";
                NSString *localLabel = [NSString stringWithFormat:labelFormat, disasm->instruction.addressValue];
                [line appendLocalName:localLabel
                            atAddress:(Address) disasm->instruction.addressValue];
            }
        } else {
            if (format == Format_Default) {
                // small values in decimal
                if (operand->immediateValue > -100 && operand->immediateValue < 100) {
                    format = Format_Decimal;
                }
                if (operand->immediateValue < 0) {
                    format |= Format_Signed;
                }
            }
            [line appendRawString:@"#"];
            [line append:[file formatNumber:(uint64_t) operand->immediateValue
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
