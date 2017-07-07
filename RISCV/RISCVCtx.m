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

- (instancetype)initWithCPU:(RISCVCPU *)cpu andFile:(NSObject <HPDisassembledFile> *)file {
    if (self = [super init]) {
        _cpu = cpu;
        _file = file;
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

    // all standard instructions are 32 bit
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

    switch (opcode) {

        case OPCODE_AUIPC /* AUIPC adds a 20-bit upper immediate to the PC */:
            strcpy(disasm->instruction.mnemonic, "auipc");
            populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
            disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE;
            disasm->operand[1].immediateValue = (insncode & IMM_MASK) >> 12;
            disasm->operand[1].accessMode = DISASM_ACCESS_READ;
            disasm->instruction.addressValue = (Address) (disasm->operand[1].immediateValue << 12);
            break;

        case OPCODE_LUI /* LUI */:
            strcpy(disasm->instruction.mnemonic, "lui");
            populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
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
                populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
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
                        populateOperandReg(&disasm->operand[0], src1_reg, DISASM_ACCESS_READ);
                        disasm->operand[0].isBranchDestination = 1;
                        disasm->instruction.branchType = DISASM_BRANCH_CALL;
                    }
                } else if (dest_reg == 1 /* ra */) {
                    // jalr rs = jalr ra, rs, 0
                    strcpy(disasm->instruction.mnemonic, "jalr");
                    populateOperandReg(&disasm->operand[0], src1_reg, DISASM_ACCESS_READ);
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
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[0].isBranchDestination = 1;
                disasm->instruction.branchType = DISASM_BRANCH_CALL;
                disasm->instruction.addressValue = (Address) getItypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
            }
            if (disasm->instruction.mnemonic[0] == 0) {
                // jalr rd, rs, imm
                strcpy(disasm->instruction.mnemonic, "jalr");
                populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                disasm->operand[1].type = DISASM_OPERAND_MEMORY_TYPE;
                disasm->operand[1].type |= getRegMask(src1_reg);
                disasm->operand[1].memory.displacement = getItypeImmediate(insncode);
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
                        populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                        disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE;
                        disasm->operand[1].immediateValue = getItypeImmediate(insncode);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                    } else if (getItypeImmediate(insncode) == 0) {
                        // addi rd, rs, 0
                        strcpy(disasm->instruction.mnemonic, "mv");
                        populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                        populateOperandReg(&disasm->operand[1], src1_reg, DISASM_ACCESS_READ);
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
                    } else if ([_file is64Bits]) {
                        // 64 bits
                        switch (getFunct6(insncode)) {
                            case 0b000000:
                                populateOPIMMShift64(disasm, insncode, "slli");
                                break;
                        }
                    } else {
                        // 128 bits
                        switch (getFunct5(insncode)) {
                            case 0b00000:
                                populateOPIMMShift128(disasm, insncode, "slli");
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
                        populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                        populateOperandReg(&disasm->operand[1], src1_reg, DISASM_ACCESS_READ);
                    } else {
                        populateOPIMM(disasm, insncode, "sltiu");
                    }
                    break;
                case 0b100 /* xori */:
                    if (getItypeImmediate(insncode) == -1) {
                        // not rd, rs = xori rd, rs, -1
                        strcpy(disasm->instruction.mnemonic, "not");
                        populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                        populateOperandReg(&disasm->operand[1], src1_reg, DISASM_ACCESS_READ);
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
                    } else if ([_file is64Bits]) {
                        // 64 bits
                        switch (getFunct6(insncode)) {
                            case 0b000000:
                                populateOPIMMShift64(disasm, insncode, "srli");
                                break;
                            case 0b010000:
                                populateOPIMMShift64(disasm, insncode, "srai");
                                break;
                        }
                    } else {
                        // 128 bits
                        switch (getFunct5(insncode)) {
                            case 0b00000:
                                populateOPIMMShift128(disasm, insncode, "srli");
                                break;
                            case 0b01000:
                                populateOPIMMShift128(disasm, insncode, "srai");
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

        case OPCODE_OPIMM64:
            switch (funct3) {
                case 0b000 /* addiw */:
                    if (getItypeImmediate(insncode) == 0) {
                        strcpy(disasm->instruction.mnemonic, "sext.w");
                        populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                        populateOperandReg(&disasm->operand[1], src1_reg, DISASM_ACCESS_READ);
                    } else {
                        populateOPIMM(disasm, insncode, "addiw");
                    }
                    break;
                case 0b001 /* slliw */:
                    switch (funct7) {
                        case 0b0000000:
                            populateOPIMMShift64(disasm, insncode, "slliw");
                            break;
                    }
                    break;
                case 0b101 /* slliw/srliw */:
                    switch (funct7) {
                        case 0b0000000:
                            populateOPIMMShift64(disasm, insncode, "srliw");
                            break;
                        case 0b0100000:
                            populateOPIMMShift64(disasm, insncode, "sraiw");
                            break;
                    }
                    break;
            }
            break;

        case OPCODE_OPIMM128:
            switch (funct3) {
                case 0b000 /* addid */:
                    if (getItypeImmediate(insncode) == 0) {
                        strcpy(disasm->instruction.mnemonic, "sext.d");
                        populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                        populateOperandReg(&disasm->operand[1], src1_reg, DISASM_ACCESS_READ);
                    } else {
                        populateOPIMM(disasm, insncode, "addid");
                    }
                    break;
                case 0b001 /* slliw */:
                    switch (funct7) {
                        case 0b0000000:
                            populateOPIMMShift128(disasm, insncode, "sllid");
                            break;
                    }
                    break;
                case 0b101 /* slliw/srliw */:
                    switch (funct7) {
                        case 0b0000000:
                            populateOPIMMShift128(disasm, insncode, "srlid");
                            break;
                        case 0b0100000:
                            populateOPIMMShift128(disasm, insncode, "sraid");
                            break;
                    }
                    break;
            }

            break;

        case OPCODE_BRANCH /* BRANCH */:
            switch (funct3) {
                case 0b000 /* beq */:
                    if (src2_reg == 0 /* zero */) {
                        strcpy(disasm->instruction.mnemonic, "beqz");
                        populateOperandReg(&disasm->operand[0], src1_reg, DISASM_ACCESS_READ);
                        disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                        disasm->operand[1].immediateValue = getBtypeImmediate(insncode);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].isBranchDestination = 1;
                        disasm->instruction.addressValue = (Address) getBtypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
                        disasm->instruction.branchType = DISASM_BRANCH_JE;
                    } else {
                        strcpy(disasm->instruction.mnemonic, "beq");
                        populateOperandReg(&disasm->operand[0], src1_reg, DISASM_ACCESS_READ);
                        populateOperandReg(&disasm->operand[1], src2_reg, DISASM_ACCESS_READ);
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
                        populateOperandReg(&disasm->operand[0], src1_reg, DISASM_ACCESS_READ);
                        disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                        disasm->operand[1].immediateValue = getBtypeImmediate(insncode);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].isBranchDestination = 1;
                        disasm->instruction.addressValue = (Address) getBtypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
                        disasm->instruction.branchType = DISASM_BRANCH_JNE;
                    } else {
                        strcpy(disasm->instruction.mnemonic, "bne");
                        populateOperandReg(&disasm->operand[0], src1_reg, DISASM_ACCESS_READ);
                        populateOperandReg(&disasm->operand[1], src2_reg, DISASM_ACCESS_READ);
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
                        populateOperandReg(&disasm->operand[0], src1_reg, DISASM_ACCESS_READ);
                        disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                        disasm->operand[1].immediateValue = getBtypeImmediate(insncode);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].isBranchDestination = 1;
                        disasm->instruction.addressValue = (Address) getBtypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
                        disasm->instruction.branchType = DISASM_BRANCH_JNE;
                    } else {
                        strcpy(disasm->instruction.mnemonic, "blt");
                        populateOperandReg(&disasm->operand[0], src1_reg, DISASM_ACCESS_READ);
                        populateOperandReg(&disasm->operand[1], src2_reg, DISASM_ACCESS_READ);
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
                        populateOperandReg(&disasm->operand[0], src1_reg, DISASM_ACCESS_READ);
                        disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                        disasm->operand[1].immediateValue = getBtypeImmediate(insncode);
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].isBranchDestination = 1;
                        disasm->instruction.addressValue = (Address) getBtypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
                        disasm->instruction.branchType = DISASM_BRANCH_JNE;
                    } else {
                        strcpy(disasm->instruction.mnemonic, "bge");
                        populateOperandReg(&disasm->operand[0], src1_reg, DISASM_ACCESS_READ);
                        populateOperandReg(&disasm->operand[1], src2_reg, DISASM_ACCESS_READ);
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
                    populateOperandReg(&disasm->operand[0], src1_reg, DISASM_ACCESS_READ);
                    populateOperandReg(&disasm->operand[1], src2_reg, DISASM_ACCESS_READ);
                    disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                    disasm->operand[2].immediateValue = getBtypeImmediate(insncode);
                    disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[2].isBranchDestination = 1;
                    disasm->instruction.addressValue = (Address) getBtypeImmediate(insncode) + disasm->virtualAddr /* + src1_reg */;
                    disasm->instruction.branchType = DISASM_BRANCH_JNE;
                    break;
                case 0b111 /* bgeu */:
                    strcpy(disasm->instruction.mnemonic, "bgeu");
                    populateOperandReg(&disasm->operand[0], src1_reg, DISASM_ACCESS_READ);
                    populateOperandReg(&disasm->operand[1], src2_reg, DISASM_ACCESS_READ);
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
                case 0b0000001 /* MULDIV */:
                    switch (funct3) {
                        case 0b000 /* MUL */:
                            populateOP(disasm, insncode, "mul");
                            break;
                        case 0b001 /* MULH */:
                            populateOP(disasm, insncode, "mulh");
                            break;
                        case 0b010 /* MULHSU */:
                            populateOP(disasm, insncode, "mulhsu");
                            break;
                        case 0b011 /* MULHU */:
                            populateOP(disasm, insncode, "mulhu");
                            break;
                        case 0b100 /* DIV */:
                            populateOP(disasm, insncode, "div");
                            break;
                        case 0b101 /* DIVU */:
                            populateOP(disasm, insncode, "divu");
                            break;
                        case 0b110 /* REM */:
                            populateOP(disasm, insncode, "rem");
                            break;
                        case 0b111 /* REMU */:
                            populateOP(disasm, insncode, "remu");
                            break;
                    }
                    break;
                case 0b0100000:
                    switch (funct3) {
                        case 0b000 /* sub */:
                            if (src2_reg == 0 /* zero */) {
                                strcpy(disasm->instruction.mnemonic, "neg");
                                populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                                populateOperandReg(&disasm->operand[1], src1_reg, DISASM_ACCESS_READ);
                            } else {
                                populateOP(disasm, insncode, "sub");
                            }
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
                case 0b0000001 /* MULDIV */:
                    switch (funct3) {
                        case 0b000 /* MULW */:
                            populateOP(disasm, insncode, "mulw");
                            break;
                        case 0b100 /* DIVW */:
                            populateOP(disasm, insncode, "divw");
                            break;
                        case 0b101 /* DIVUW */:
                            populateOP(disasm, insncode, "divuw");
                            break;
                        case 0b110 /* REMW */:
                            populateOP(disasm, insncode, "remw");
                            break;
                        case 0b111 /* REMUW */:
                            populateOP(disasm, insncode, "remuw");
                            break;
                    }
                    break;
                case 0b0100000:
                    switch (funct3) {
                        case 0b000 /* sub */:
                            if (src2_reg == 0 /* zero */) {
                                strcpy(disasm->instruction.mnemonic, "negw");
                                populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                                populateOperandReg(&disasm->operand[1], src1_reg, DISASM_ACCESS_READ);
                            } else {
                                populateOP(disasm, insncode, "subw");
                            }
                            break;
                        case 0b101 /* sra */:
                            populateOP(disasm, insncode, "sraw");
                            break;
                    }
                    break;
            }
            break;

        case OPCODE_OP128:
            switch (funct7) {
                case 0b0000000:
                    switch (funct3) {
                        case 0b000 /* addd */:
                            populateOP(disasm, insncode, "addd");
                            break;
                        case 0b001 /* slld */:
                            populateOP(disasm, insncode, "slld");
                            break;
                        case 0b101 /* srld */:
                            populateOP(disasm, insncode, "srld");
                            break;
                    }
                    break;
                case 0b0000001 /* MULDIV */:
                    switch (funct3) {
                        case 0b000 /* MULD */:
                            populateOP(disasm, insncode, "muld");
                            break;
                        case 0b100 /* DIVD */:
                            populateOP(disasm, insncode, "divd");
                            break;
                        case 0b101 /* DIVUD */:
                            populateOP(disasm, insncode, "divud");
                            break;
                        case 0b110 /* REMD */:
                            populateOP(disasm, insncode, "remd");
                            break;
                        case 0b111 /* REMUD */:
                            populateOP(disasm, insncode, "remud");
                            break;
                    }
                    break;
                case 0b0100000:
                    switch (funct3) {
                        case 0b000 /* subd */:
                            if (src2_reg == 0 /* zero */) {
                                strcpy(disasm->instruction.mnemonic, "negd");
                                populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                                populateOperandReg(&disasm->operand[1], src1_reg, DISASM_ACCESS_READ);
                            } else {
                                populateOP(disasm, insncode, "subd");
                            }
                            break;
                        case 0b101 /* srad */:
                            populateOP(disasm, insncode, "srad");
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
                case 0b110 /* LWU */:
                    populateLOAD(disasm, insncode, "lwu");
                    break;
                case 0b111 /* LDU 128 bit */:
                    populateLOAD(disasm, insncode, "ldu");
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
                case 0b100 /* aq 128 bit */:
                    populateSTORE(disasm, insncode, "sq");
                    break;
            }
            break;

        case OPCODE_MISC_MEM:
            switch (funct3) {
                case 0b000 /* FENCE */:
                    strcpy(disasm->instruction.mnemonic, "fence");
                    if (getPredecessor(insncode) != 0xf || getSuccessor(insncode) != 0xf) {
                        disasm->operand[0].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_FENCE;
                        disasm->operand[0].immediateValue = getPredecessor(insncode);
                        disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_FENCE;
                        disasm->operand[1].immediateValue = getSuccessor(insncode);
                    }
                    break;
                case 0b001 /* FENCE.I */:
                    strcpy(disasm->instruction.mnemonic, "fence.i");
                    break;
                case 0b010 /* LQ *128 bit */:
                    populateLOAD(disasm, insncode, "lq");
                    break;
            }
            break;


        case OPCODE_SYSTEM:
            switch (funct3) {
                case 0b000 /* PRIV : ECALL/EBREAK */:
                    switch (getItypeImmediate(insncode) /* funct12 */) {
                        case 0b000000000000:
                            if (getRS1(insncode) == 0 && getRD(insncode) == 0) {
                                strcpy(disasm->instruction.mnemonic, "ecall");
                            }
                            break;
                        case 0b000000000001:
                            if (getRS1(insncode) == 0 && getRD(insncode) == 0) {
                                strcpy(disasm->instruction.mnemonic, "ebreak");
                            }
                            break;

                            /* trap-return instructions */
                        case 0b000000000010:
                            if (getRS1(insncode) == 0 && getRD(insncode) == 0) {
                                strcpy(disasm->instruction.mnemonic, "uret");
                            }
                            break;
                        case 0b000100000010:
                            if (getRS1(insncode) == 0 && getRD(insncode) == 0) {
                                strcpy(disasm->instruction.mnemonic, "sret");
                            }
                            break;
                        case 0b001000000010:
                            if (getRS1(insncode) == 0 && getRD(insncode) == 0) {
                                strcpy(disasm->instruction.mnemonic, "hret");
                            }
                            break;
                        case 0b001100000010:
                            if (getRS1(insncode) == 0 && getRD(insncode) == 0) {
                                strcpy(disasm->instruction.mnemonic, "mret");
                            }
                            break;

                            /* interrupt-management instructions */
                        case 0b000100000101:
                            if (getRS1(insncode) == 0 && getRD(insncode) == 0) {
                                strcpy(disasm->instruction.mnemonic, "wfi");
                            }
                            break;

                            /* memory-management instructions */
                        case 0b000100000100:
                            if (getRD(insncode) == 0) {
                                strcpy(disasm->instruction.mnemonic, "sfence.vm");
                                if (getRS1(insncode) != 0) {
                                    disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                                    disasm->operand[0].type |= getRegMask(src1_reg);
                                    disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                                }
                            }
                            break;
                    }
                    break;
                case 0b001 /* CSRRW */:
                    // Atomic Read/Write CSR
                    if (dest_reg == 0 /* zero */) {
                        // CSRW csr, rs1 = CSRRW zero, csr, rs1
                        switch (getCsr(insncode)) {
                            case 0x001 /* FLAGS */:
                                strcpy(disasm->instruction.mnemonic, "fsflags");
                                populateOperandReg(&disasm->operand[0], src1_reg, DISASM_ACCESS_READ);
                                break;
                            case 0x002 /* FRM */:
                                strcpy(disasm->instruction.mnemonic, "fsrm");
                                populateOperandReg(&disasm->operand[0], src1_reg, DISASM_ACCESS_READ);
                                break;
                            case 0x003 /* FCSR */:
                                strcpy(disasm->instruction.mnemonic, "fssr");
                                populateOperandReg(&disasm->operand[0], src1_reg, DISASM_ACCESS_READ);
                                break;
                            default:
                                strcpy(disasm->instruction.mnemonic, "csrw");
                                disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                                disasm->operand[0].type |= getCsrMask();
                                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                                disasm->operand[0].userData[0] = getCsr(insncode);
                                populateOperandReg(&disasm->operand[1], src1_reg, DISASM_ACCESS_READ);
                        }
                    } else {
                        strcpy(disasm->instruction.mnemonic, "cssrw");
                        populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type |= getCsrMask();
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].userData[0] = getCsr(insncode);
                        populateOperandReg(&disasm->operand[2], src1_reg, DISASM_ACCESS_READ);
                    }
                    break;
                case 0b010 /* CSRRS */:
                    // Atomic Read and Set Bits in CSR
                    if (src1_reg == 0 /* zero */) {
                        // CSRR rd, csr = CSRRS rd, csr, zero
                        switch (getCsr(insncode)) {
                            case 0x001 /* FLAGS */:
                                strcpy(disasm->instruction.mnemonic, "frflags");
                                populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                                break;
                            case 0x002 /* FRM */:
                                strcpy(disasm->instruction.mnemonic, "frrm");
                                populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                                break;
                            case 0x003 /* FCSR */:
                                strcpy(disasm->instruction.mnemonic, "frsr");
                                populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                                break;
                            case 0xc00 /* RDCYCLE */:
                                strcpy(disasm->instruction.mnemonic, "rdcycle");
                                populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                                break;
                            case 0xc01 /* RDTIME */:
                                strcpy(disasm->instruction.mnemonic, "rdtime");
                                populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                                break;
                            case 0xc02 /* RDINSTRET */:
                                strcpy(disasm->instruction.mnemonic, "rdinstret");
                                populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                                break;
                            case 0xc80 /* RDCYCLEH */:
                                strcpy(disasm->instruction.mnemonic, "rdcycleh");
                                populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                                break;
                            case 0xc81 /* RDTIMEH */:
                                strcpy(disasm->instruction.mnemonic, "rdtimeh");
                                populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                                break;
                            case 0xc82 /* RDINSTRETH */:
                                strcpy(disasm->instruction.mnemonic, "rdinstreth");
                                populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                                break;
                            default:
                                strcpy(disasm->instruction.mnemonic, "csrr");
                                populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                                disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                                disasm->operand[1].type |= getCsrMask();
                                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                                disasm->operand[1].userData[0] = getCsr(insncode);
                        }
                    } else if (dest_reg == 0 /* zero */) {
                        // CSRS csr, rs1 = CSRRS zero, csr, rs1
                        strcpy(disasm->instruction.mnemonic, "csrs");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getCsrMask();
                        disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                        disasm->operand[0].userData[0] = getCsr(insncode);
                        populateOperandReg(&disasm->operand[1], src1_reg, DISASM_ACCESS_READ);
                    } else {
                        strcpy(disasm->instruction.mnemonic, "csrrs");
                        populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type |= getCsrMask();
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].userData[0] = getCsr(insncode);
                        populateOperandReg(&disasm->operand[2], src1_reg, DISASM_ACCESS_READ);
                    }
                    break;
                case 0b011 /* CSRRC */:
                    // Atomic Read and Clear Bits in CSR
                    if (dest_reg == 0 /* zero */) {
                        // CSRC csr, rs1 = CSRRC zero, csr, rs1
                        strcpy(disasm->instruction.mnemonic, "csrc");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getCsrMask();
                        disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                        disasm->operand[0].userData[0] = getCsr(insncode);
                        populateOperandReg(&disasm->operand[1], src1_reg, DISASM_ACCESS_READ);
                    } else {
                        strcpy(disasm->instruction.mnemonic, "csrrc");
                        populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type |= getCsrMask();
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].userData[0] = getCsr(insncode);
                        populateOperandReg(&disasm->operand[2], src1_reg, DISASM_ACCESS_READ);
                    }
                    break;
                case 0b101 /* CSRRWI */:
                    if (dest_reg == 0 /* zero */) {
                        // CSRWI csr, zimm = CSRRWI zero, csr, zimm
                        strcpy(disasm->instruction.mnemonic, "csrwi");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getCsrMask();
                        disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[0].userData[0] = getCsr(insncode);
                        populateOperandReg(&disasm->operand[1], src1_reg, DISASM_ACCESS_READ);
                    } else {
                        strcpy(disasm->instruction.mnemonic, "csrrwi");
                        populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type |= getCsrMask();
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].userData[0] = getCsr(insncode);
                        populateOperandReg(&disasm->operand[2], src1_reg, DISASM_ACCESS_READ);
                    }
                    break;
                case 0b110 /* CSRRSI */:
                    if (dest_reg == 0 /* zero */) {
                        // CSRSI csr, zimm = CSRRSI zero, csr, zimm
                        strcpy(disasm->instruction.mnemonic, "csrsi");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getCsrMask();
                        disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[0].userData[0] = getCsr(insncode);
                        populateOperandReg(&disasm->operand[1], src1_reg, DISASM_ACCESS_READ);
                    } else {
                        strcpy(disasm->instruction.mnemonic, "csrrsi");
                        populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type |= getCsrMask();
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].userData[0] = getCsr(insncode);
                        populateOperandReg(&disasm->operand[2], src1_reg, DISASM_ACCESS_READ);
                    }
                    break;
                case 0b111 /* CSRRCI */:
                    if (dest_reg == 0 /* zero */) {
                        // CSRCI csr, zimm = CSRRCI zero, csr, zimm
                        strcpy(disasm->instruction.mnemonic, "csrci");
                        disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[0].type |= getCsrMask();
                        disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[0].userData[0] = getCsr(insncode);
                        populateOperandReg(&disasm->operand[1], src1_reg, DISASM_ACCESS_READ);
                    } else {
                        strcpy(disasm->instruction.mnemonic, "csrrci");
                        populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
                        disasm->operand[1].type |= getCsrMask();
                        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                        disasm->operand[1].userData[0] = getCsr(insncode);
                        populateOperandReg(&disasm->operand[2], src1_reg, DISASM_ACCESS_READ);
                    }
                    break;
            }
            break;

        case OPCODE_AMO:
            switch (funct3) {
                case 0b010 /* RV32A */:
                    switch (getFunct5(insncode)) {
                        // RV32A Standard Extension
                        case 0b00010 /* LR */:
                            populateLR(disasm, insncode, "lr.w");
                            break;
                        case 0b00011 /* SC */:
                            populateAMO(disasm, insncode, "sc.w");
                            break;
                        case 0b00001 /* AMOSWAP.W */:
                            populateAMO(disasm, insncode, "amoswap.w");
                            break;
                        case 0b00000 /* AMOADD.W */:
                            populateAMO(disasm, insncode, "amoadd.w");
                            break;
                        case 0b00100 /* AMOXOR.W */:
                            populateAMO(disasm, insncode, "amoxor.w");
                            break;
                        case 0b01100 /* AMOAND.W */:
                            populateAMO(disasm, insncode, "amoand.w");
                            break;
                        case 0b01000 /* AMOOR.W */:
                            populateAMO(disasm, insncode, "amoor.w");
                            break;
                        case 0b10000 /* AMOMIN.W */:
                            populateAMO(disasm, insncode, "amomin.w");
                            break;
                        case 0b10100 /* AMOMAX.W */:
                            populateAMO(disasm, insncode, "amomax.w");
                            break;
                        case 0b11000 /* AMOMINU.W */:
                            populateAMO(disasm, insncode, "amominu.w");
                            break;
                        case 0b11100 /* AMOMAXU.W */:
                            populateAMO(disasm, insncode, "amomaxu.w");
                            break;
                    }
                    break;

                case 0b011 /* RV64A */:
                    switch (getFunct5(insncode)) {
                        // RV32A Standard Extension
                        case 0b00010 /* LR.D */:
                            populateLR(disasm, insncode, "lr.d");
                            break;
                        case 0b00011 /* SC.D */:
                            populateAMO(disasm, insncode, "sc.d");
                            break;
                        case 0b00001 /* AMOSWAP.D */:
                            populateAMO(disasm, insncode, "amoswap.d");
                            break;
                        case 0b00000 /* AMOADD.D */:
                            populateAMO(disasm, insncode, "amoadd.d");
                            break;
                        case 0b00100 /* AMOXOR.D */:
                            populateAMO(disasm, insncode, "amoxor.d");
                            break;
                        case 0b01100 /* AMOAND.D */:
                            populateAMO(disasm, insncode, "amoand.d");
                            break;
                        case 0b01000 /* AMOOR.D */:
                            populateAMO(disasm, insncode, "amoor.d");
                            break;
                        case 0b10000 /* AMOMIN.D */:
                            populateAMO(disasm, insncode, "amomin.d");
                            break;
                        case 0b10100 /* AMOMAX.D */:
                            populateAMO(disasm, insncode, "amomax.d");
                            break;
                        case 0b11000 /* AMOMINU.D */:
                            populateAMO(disasm, insncode, "amominu.d");
                            break;
                        case 0b11100 /* AMOMAXU.D */:
                            populateAMO(disasm, insncode, "amomaxu.d");
                            break;
                    }
                    break;

                case 0b100 /* RV128A */:
                    switch (getFunct5(insncode)) {
                        // RV32A Standard Extension
                        case 0b00010 /* LR.Q */:
                            populateLR(disasm, insncode, "lr.q");
                            break;
                        case 0b00011 /* SC.Q */:
                            populateAMO(disasm, insncode, "sc.q");
                            break;
                        case 0b00001 /* AMOSWAP.Q */:
                            populateAMO(disasm, insncode, "amoswap.q");
                            break;
                        case 0b00000 /* AMOADD.Q */:
                            populateAMO(disasm, insncode, "amoadd.q");
                            break;
                        case 0b00100 /* AMOXOR.Q */:
                            populateAMO(disasm, insncode, "amoxor.q");
                            break;
                        case 0b01100 /* AMOAND.Q */:
                            populateAMO(disasm, insncode, "amoand.q");
                            break;
                        case 0b01000 /* AMOOR.Q */:
                            populateAMO(disasm, insncode, "amoor.q");
                            break;
                        case 0b10000 /* AMOMIN.Q */:
                            populateAMO(disasm, insncode, "amomin.q");
                            break;
                        case 0b10100 /* AMOMAX.Q */:
                            populateAMO(disasm, insncode, "amomax.q");
                            break;
                        case 0b11000 /* AMOMINU.Q */:
                            populateAMO(disasm, insncode, "amominu.q");
                            break;
                        case 0b11100 /* AMOMAXU.Q */:
                            populateAMO(disasm, insncode, "amomaxu.q");
                            break;
                    }
                    break;
            }
            break;

        case OPCODE_LOADFP:
            // ccc1a087 -> flw ft1, -820(gp)
            switch (funct3)  /* width */ {
                case 0b010:
                    strcpy(disasm->instruction.mnemonic, "flw");
                    break;
                case 0b011:
                    strcpy(disasm->instruction.mnemonic, "fld");
                    break;
                case 0b100:
                    strcpy(disasm->instruction.mnemonic, "flq");
                    break;
            }
            populateOperandReg(&disasm->operand[0], dest_reg, DISASM_ACCESS_WRITE);
            disasm->operand[1].type = DISASM_OPERAND_REGISTER_TYPE;
            disasm->operand[1].type = DISASM_OPERAND_MEMORY_TYPE;
            disasm->operand[1].type |= getRegMask(src1_reg);
            disasm->operand[1].memory.baseRegistersMask = getRegMask(src1_reg);
            disasm->operand[1].memory.displacement = getItypeImmediate(insncode);
            disasm->operand[1].accessMode = DISASM_ACCESS_READ;
            break;

        case OPCODE_STOREFP:
            // 00b12627 -> fsw fa1, 12(sp)
            switch (funct3) /* width */ {
                case 0b010:
                    strcpy(disasm->instruction.mnemonic, "fsw");
                    break;
                case 0b011:
                    strcpy(disasm->instruction.mnemonic, "fsd");
                    break;
                case 0b100:
                    strcpy(disasm->instruction.mnemonic, "fsq");
                    break;
            }
            disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
            disasm->operand[0].type |= getFpuRegMask(src2_reg);
            disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[1].type = DISASM_OPERAND_MEMORY_TYPE;
            disasm->operand[1].type |= getRegMask(src1_reg);
            disasm->operand[1].memory.baseRegistersMask = getRegMask(src1_reg);
            disasm->operand[1].memory.displacement = getStypeImmediate(insncode);
            disasm->operand[1].accessMode = DISASM_ACCESS_READ;
            break;

        case OPCODE_FP:
            switch (funct7) {
                case 0b0000000 /* FADD.S */:
                    populateFp_3reg_with_rm(disasm, insncode, "fadd.s");
                    break;
                case 0b0000001 /* FADD.D */:
                    populateFp_3reg_with_rm(disasm, insncode, "fadd.d");
                    break;
                case 0b0000011 /* FADD.Q */:
                    populateFp_3reg_with_rm(disasm, insncode, "fadd.q");
                    break;
                case 0b0000100 /* FSUB.S */:
                    populateFp_3reg_with_rm(disasm, insncode, "fsub.s");
                    break;
                case 0b0000101 /* FSUB.D */:
                    populateFp_3reg_with_rm(disasm, insncode, "fsub.d");
                    break;
                case 0b0000111 /* FSUB.Q */:
                    populateFp_3reg_with_rm(disasm, insncode, "fsub.q");
                    break;
                case 0b0001000 /* FMUL.S */:
                    populateFp_3reg_with_rm(disasm, insncode, "fmul.s");
                    break;
                case 0b0001001 /* FMUL.D */:
                    populateFp_3reg_with_rm(disasm, insncode, "fmul.d");
                    break;
                case 0b0001011 /* FMUL.Q */:
                    populateFp_3reg_with_rm(disasm, insncode, "fmul.q");
                    break;
                case 0b0001100 /* FDIV.S */:
                    populateFp_3reg_with_rm(disasm, insncode, "fdiv.s");
                    break;
                case 0b0001101 /* FDIV.D */:
                    populateFp_3reg_with_rm(disasm, insncode, "fdiv.d");
                    break;
                case 0b0001111 /* FDIV.Q */:
                    populateFp_3reg_with_rm(disasm, insncode, "fdiv.q");
                    break;
                case 0b0101100 /* FSQRT.S */:
                    populateFP_2reg(disasm, insncode, "fsqrt.s");
                    populateFpRoundingMode(&disasm->operand[2], insncode);
                    break;
                case 0b0101101 /* FSQRT.D */:
                    populateFP_2reg(disasm, insncode, "fsqrt.d");
                    populateFpRoundingMode(&disasm->operand[2], insncode);
                    break;
                case 0b0101111 /* FSQRT.Q */:
                    populateFP_2reg(disasm, insncode, "fsqrt.q");
                    populateFpRoundingMode(&disasm->operand[2], insncode);
                    break;
                case 0b0010000 /* FSGN.S */:
                    switch (funct3) /* rm */ {
                        case 0b000 /* FSGNJ.S */:
                            if (src2_reg == src1_reg) {
                                //  FSGNJ.S rx, ry, ry = FMV.S rx, ry
                                populateFP_2reg(disasm, insncode, "fmv.s");
                            } else {
                                populateFp_3reg(disasm, insncode, "fsgnj.s");
                            }
                            break;
                        case 0b001 /* FSGNJN.S */:
                            if (src2_reg == src1_reg) {
                                // FSGNJN.S rx, ry, ry =  FNEG.S rx, ry
                                populateFP_2reg(disasm, insncode, "fneg.s");
                            } else {
                                populateFp_3reg(disasm, insncode, "fsgnjn.s");
                            }
                            break;
                        case 0b010 /* FSGNJX.S */:
                            if (src2_reg == src1_reg) {
                                // FSGNJX.S rx, ry, ry = FABS.S rx, ry
                                populateFP_2reg(disasm, insncode, "fabs.s");
                            } else {
                                populateFp_3reg(disasm, insncode, "fsgnjx.s");
                            }
                            break;
                    }
                    break;
                case 0b0010001 /* FSGN.D */:
                    switch (funct3) /* rm */ {
                        case 0b000 /* FSGNJ.D */:
                            if (src2_reg == src1_reg) {
                                //  FSGNJ.D rx, ry, ry = FMV.D rx, ry
                                populateFP_2reg(disasm, insncode, "fmv.d");
                            } else {
                                populateFp_3reg(disasm, insncode, "fsgnj.d");
                            }
                            break;
                        case 0b001 /* FSGNJN.D */:
                            if (src2_reg == src1_reg) {
                                // FSGNJN.D rx, ry, ry =  FNEG.D rx, ry
                                populateFP_2reg(disasm, insncode, "fneg.d");
                            } else {
                                populateFp_3reg(disasm, insncode, "fsgnjn.d");
                            }
                            break;
                        case 0b010 /* FSGNJX.D */:
                            if (src2_reg == src1_reg) {
                                // FSGNJX.D rx, ry, ry = FABS.D rx, ry
                                populateFP_2reg(disasm, insncode, "fabs.d");
                            } else {
                                populateFp_3reg(disasm, insncode, "fsgnjx.d");
                            }
                            break;
                    }
                    break;
                case 0b0010011 /* FSGN.Q */:
                    switch (funct3) /* rm */ {
                        case 0b000 /* FSGNJ.Q */:
                            if (src2_reg == src1_reg) {
                                //  FSGNJ.Q rx, ry, ry = FMV.Q rx, ry
                                populateFP_2reg(disasm, insncode, "fmv.q");
                            } else {
                                populateFp_3reg(disasm, insncode, "fsgnj.q");
                            }
                            break;
                        case 0b001 /* FSGNJN.Q */:
                            if (src2_reg == src1_reg) {
                                // FSGNJN.Q rx, ry, ry =  FNEG.Q rx, ry
                                populateFP_2reg(disasm, insncode, "fneg.q");
                            } else {
                                populateFp_3reg(disasm, insncode, "fsgnjn.q");
                            }
                            break;
                        case 0b010 /* FSGNJX.Q */:
                            if (src2_reg == src1_reg) {
                                // FSGNJX.Q rx, ry, ry = FABS.Q rx, ry
                                populateFP_2reg(disasm, insncode, "fabs.q");
                            } else {
                                populateFp_3reg(disasm, insncode, "fsgnjx.q");
                            }
                            break;
                    }
                    break;
                case 0b0010100 /* FMIN/FMAX.S */:
                    switch (funct3) /* rm */ {
                        case 0b000 /* FMIN.S */:
                            populateFp_3reg(disasm, insncode, "fmin.s");
                            break;
                        case 0b001 /* FMAX.S */:
                            populateFp_3reg(disasm, insncode, "fmax.s");
                            break;
                    }
                    break;
                case 0b0010101 /* FMIN/FMAX.D */:
                    switch (funct3) /* rm */ {
                        case 0b000 /* FMIN.D */:
                            populateFp_3reg(disasm, insncode, "fmin.d");
                            break;
                        case 0b001 /* FMAX.D */:
                            populateFp_3reg(disasm, insncode, "fmax.d");
                            break;
                    }
                    break;
                case 0b0010111 /* FMIN/FMAX.Q */:
                    switch (funct3) /* rm */ {
                        case 0b000 /* FMIN.Q */:
                            populateFp_3reg(disasm, insncode, "fmin.q");
                            break;
                        case 0b001 /* FMAX.Q */:
                            populateFp_3reg(disasm, insncode, "fmax.q");
                            break;
                    }
                    break;
                case 0b0100000 /* FCVT.S.D */:
                    switch (src2_reg) {
                        case 0b00001:
                            populateFP_2reg(disasm, insncode, "fcvt.s.d");
                            populateFpRoundingMode(&disasm->operand[2], insncode);
                            break;
                    }
                    break;
                case 0b0100001 /* FCVT.D.S */:
                    switch (src2_reg) {
                        case 0b00000:
                            populateFP_2reg(disasm, insncode, "fcvt.d.s");
                            populateFpRoundingMode(&disasm->operand[2], insncode);
                            break;
                    }
                    break;
                case 0b1100000 /* FCVT.S */:
                    switch (src2_reg) /*  */ {
                        case 0b00000 /* FCVT.W.S */:
                            populateFp_gp_fp_with_rm(disasm, insncode, "fcvt.w.s");
                            break;
                        case 0b00001 /* FCVT.WU.S */:
                            populateFp_gp_fp_with_rm(disasm, insncode, "fcvt.wu.s");
                            break;
                        case 0b00010 /* FCVT.L.S */:
                            populateFp_gp_fp_with_rm(disasm, insncode, "fcvt.l.s");
                            break;
                        case 0b00011 /* FCVT.L.S */:
                            populateFp_gp_fp_with_rm(disasm, insncode, "fcvt.lu.s");
                            break;
                    }
                    break;
                case 0b1100001 /* FCVT.D */:
                    switch (src2_reg) /*  */ {
                        case 0b00000 /* FCVT.W.D */:
                            populateFp_gp_fp_with_rm(disasm, insncode, "fcvt.w.d");
                            break;
                        case 0b00001 /* FCVT.WU.D */:
                            populateFp_gp_fp_with_rm(disasm, insncode, "fcvt.wu.d");
                            break;
                        case 0b00010 /* FCVT.L.D */:
                            populateFp_gp_fp_with_rm(disasm, insncode, "fcvt.l.d");
                            break;
                        case 0b00011 /* FCVT.L.D */:
                            populateFp_gp_fp_with_rm(disasm, insncode, "fcvt.lu.d");
                            break;
                    }
                    break;
                case 0b1100011 /* FCVT.Q */:
                    switch (src2_reg) /*  */ {
                        case 0b00000 /* FCVT.W.Q */:
                            populateFp_gp_fp_with_rm(disasm, insncode, "fcvt.w.q");
                            break;
                        case 0b00001 /* FCVT.WU.Q */:
                            populateFp_gp_fp_with_rm(disasm, insncode, "fcvt.wu.q");
                            break;
                        case 0b00010 /* FCVT.L.Q */:
                            populateFp_gp_fp_with_rm(disasm, insncode, "fcvt.l.q");
                            break;
                        case 0b00011 /* FCVT.L.Q */:
                            populateFp_gp_fp_with_rm(disasm, insncode, "fcvt.lu.q");
                            break;
                    }
                    break;
                case 0b1110000:
                    switch (funct3) {
                        case 0b000 /* FMV.X.S */:
                            populateFp_gp_fp(disasm, insncode, "fmv.x.s");
                            break;
                        case 0b001 /* FCLASS.S */:
                            populateFp_gp_fp(disasm, insncode, "fclass.s");
                            break;
                    }
                    break;
                case 0b1110001:
                    switch (funct3) {
                        case 0b000 /* FMV.X.D */:
                            populateFp_gp_fp(disasm, insncode, "fmv.x.d");
                            break;
                        case 0b001 /* FCLASS.D */:
                            populateFp_gp_fp(disasm, insncode, "fclass.d");
                            break;
                    }
                    break;
                case 0b1110011:
                    switch (funct3) {
                        case 0b000 /* FMV.X.Q */:
                            populateFp_gp_fp(disasm, insncode, "fmv.x.q");
                            break;
                        case 0b001 /* FCLASS.Q */:
                            populateFp_gp_fp(disasm, insncode, "fclass.q");
                            break;
                    }
                    break;
                case 0b1010000:
                    switch (funct3) {
                        case 0b010 /* FEQ.S */:
                            populateFp_3reg(disasm, insncode, "feq.s");
                            break;
                        case 0b001 /* FLT.S */:
                            populateFp_3reg(disasm, insncode, "flt.s");
                            break;
                        case 0b000 /* FLE.S */:
                            populateFp_3reg(disasm, insncode, "fle.s");
                            break;
                    }
                    break;
                case 0b1010001:
                    switch (funct3) {
                        case 0b010 /* FEQ.D */:
                            populateFp_3reg(disasm, insncode, "feq.d");
                            break;
                        case 0b001 /* FLT.D */:
                            populateFp_3reg(disasm, insncode, "flt.d");
                            break;
                        case 0b000 /* FLE.D */:
                            populateFp_3reg(disasm, insncode, "fle.d");
                            break;
                    }
                    break;
                case 0b1101000:
                    switch (src2_reg) {
                        case 0b00000 /* FCVT.S.W */:
                            populateFp_fp_gp_with_rm(disasm, insncode, "fcvt.s.w");
                            break;
                        case 0b00001 /* FCVT.S.WU */:
                            populateFp_fp_gp_with_rm(disasm, insncode, "fcvt.s.wu");
                            break;
                        case 0b00010 /* FCVT.S.L */:
                            populateFp_fp_gp_with_rm(disasm, insncode, "fcvt.s.l");
                            break;
                        case 0b00011 /* FCVT.S.LU */:
                            populateFp_fp_gp_with_rm(disasm, insncode, "fcvt.s.lu");
                            break;
                    }
                    break;
                case 0b1101001:
                    switch (src2_reg) {
                        case 0b00000 /* FCVT.D.W */:
                            populateFp_fp_gp_with_rm(disasm, insncode, "fcvt.d.w");
                            break;
                        case 0b00001 /* FCVT.D.WU */:
                            populateFp_fp_gp_with_rm(disasm, insncode, "fcvt.d.wu");
                            break;
                        case 0b00010 /* FCVT.D.L */:
                            populateFp_fp_gp_with_rm(disasm, insncode, "fcvt.d.l");
                            break;
                        case 0b00011 /* FCVT.D.LU */:
                            populateFp_fp_gp_with_rm(disasm, insncode, "fcvt.d.lu");
                            break;
                    }
                case 0b11010011:
                    switch (src2_reg) {
                        case 0b00000 /* FCVT.Q.W */:
                            populateFp_fp_gp_with_rm(disasm, insncode, "fcvt.q.w");
                            break;
                        case 0b00001 /* FCVT.Q.WU */:
                            populateFp_fp_gp_with_rm(disasm, insncode, "fcvt.q.wu");
                            break;
                        case 0b00010 /* FCVT.Q.L */:
                            populateFp_fp_gp_with_rm(disasm, insncode, "fcvt.q.l");
                            break;
                        case 0b00011 /* FCVT.Q.LU */:
                            populateFp_fp_gp_with_rm(disasm, insncode, "fcvt.q.lu");
                            break;
                    }
                    break;
                case 0b1111000 /* FMV.S.X */:
                    populateFp_fp_gp(disasm, insncode, "fmv.x.s");
                    break;
                case 0b1111001 /* FMV.D.X */:
                    populateFp_fp_gp(disasm, insncode, "fmv.d.x");
                    break;
                case 0b1111011 /* FMV.Q.X */:
                    populateFp_fp_gp(disasm, insncode, "fmv.q.x");
                    break;
            }
            break;

        case OPCODE_FMADD:
            switch (getFmt(insncode)) {
                case FPU_FMT_SINGLE:
                    populateFp_R4(disasm, insncode, "fmadd.s");
                    break;
                case FPU_FMT_DOUBLE:
                    populateFp_R4(disasm, insncode, "fmadd.d");
                    break;
                case FPU_FMT_QUAD:
                    populateFp_R4(disasm, insncode, "fmadd.q");
                    break;
            }
            break;

        case OPCODE_FMSUB:
            switch (getFmt(insncode)) {
                case FPU_FMT_SINGLE:
                    populateFp_R4(disasm, insncode, "fmsub.s");
                    break;
                case FPU_FMT_DOUBLE:
                    populateFp_R4(disasm, insncode, "fmsub.d");
                    break;
                case FPU_FMT_QUAD:
                    populateFp_R4(disasm, insncode, "fmsub.q");
                    break;
            }
            break;

        case OPCODE_FNMADD:
            switch (getFmt(insncode)) {
                case FPU_FMT_SINGLE:
                    populateFp_R4(disasm, insncode, "fnmadd.s");
                    break;
                case FPU_FMT_DOUBLE:
                    populateFp_R4(disasm, insncode, "fnmadd.d");
                    break;
                case FPU_FMT_QUAD:
                    populateFp_R4(disasm, insncode, "fnmadd.q");
                    break;
            }
            break;

        case OPCODE_FNMSUB:
            switch (getFmt(insncode)) {
                case FPU_FMT_SINGLE:
                    populateFp_R4(disasm, insncode, "fnmsub.s");
                    break;
                case FPU_FMT_DOUBLE:
                    populateFp_R4(disasm, insncode, "fnmsub.d");
                    break;
                case FPU_FMT_QUAD:
                    populateFp_R4(disasm, insncode, "fnmsub.q");
                    break;
            }
            break;

        default:
            break;
    }

    if (disasm->instruction.mnemonic[0] == 0) {
        return DISASM_UNKNOWN_OPCODE;
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
    const BOOL isJump = (disasm->instruction.branchType != DISASM_BRANCH_NONE);
    [line appendMnemonic:@(disasm->instruction.mnemonic) isJump:isJump];
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
        if (operand->type & DISASM_OPERAND_ROUNDING_MODE) {
            NSString *name = getRoundingModeName((enum FpuRoundingMode) operand->immediateValue);
            if (name) {
                [line appendFormattedNumber:name
                                  withValue:@(operand->immediateValue)];
            }
        } else if (operand->type & DISASM_OPERAND_FENCE && operand->immediateValue != 0) {
            [line appendFormattedNumber:getIorw((uint8_t) operand->immediateValue)
                              withValue:@(operand->immediateValue)];
        } else if (operand->isBranchDestination) {
            if (format == Format_Default) {
                format = Format_Address;
            }
            [line append:[file formatNumber:disasm->instruction.addressValue
                                         at:disasm->virtualAddr
                                usingFormat:format
                                 andBitSize:bitsize]];
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
                                                position:DISASM_LOWPOSITION
                                          andSyntaxIndex:disasm->syntaxIndex];
        if ([reg_name isEqualToString:@"csr"]) {
            reg_name = getCsrName(operand->userData[0]);
        }
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
                                                    position:DISASM_LOWPOSITION
                                              andSyntaxIndex:disasm->syntaxIndex];

            if ((format & Format_Default) == Format_Default) {
                // clear default Format types
                if ([reg_name isEqualToString:@"sp"]) {
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

/**
 * Build an address from auipc, addi instructions
 *
 * @param disasm current DisasmStruct
 * @param in current instruction
 */
- (void)buildAddress:(DisasmStruct *)disasm
            withInsn:(const struct insn *)in {
    // fetch previous instruction
    uint32_t prev = [_file readUInt32AtVirtualAddress:disasm->virtualAddr - 4];
    struct insn *prevIn = 0;//getInsn(prev);
    if (prevIn && prevIn->opcode == 0b001111 /* LUI */ &&
            prevIn->itype.reg_dest == in->itype.reg_src1) {

        disasm->instruction.addressValue = (uint32_t) ((prevIn->itype.imm << 16) + ((int16_t) in->itype.imm));
        NSObject <HPSegment> *segment = [_file segmentForVirtualAddress:disasm->virtualAddr];
        [segment addReferencesToAddress:(uint32_t) disasm->instruction.addressValue
                            fromAddress:disasm->virtualAddr];
    }
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

- (BOOL)instructionOnlyLoadsAddress:(DisasmStruct *)disasmStruct {
    return NO;
}

- (BOOL)instructionMayBeASwitchStatement:(DisasmStruct *)disasmStruct {
    return NO;
}

@end
