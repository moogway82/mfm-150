;=========================================================================
; mfm-150-xtjr - BIOS main file
;	Recreation of the Zenith MFM-150 Monitor
;-------------------------------------------------------------------------
;
; Compiles with NASM 2.15.05, might work with other versions
;-------------------------------------------------------------------------
;
; Regex remove address & bytes from dissassembly:
;^[0-9a-f]{4}:[0-9a-f]{4}[ ]+[0-9a-f.]+[ ]+(.*)
;    $1
;
; Regex fix data Bytes
;^\s+[a-f0-9]{4}:[a-f0-9]{4} [0-9a-f]+[ ]+(db[ ]+[0-9A-F]+h)
;    $1

cpu	8086
%define START       0x0000      ; BIN As Option ROM
; %define START       0x6000    ; BIN As BASIC ROM
%define OPTION_SEG  0xED80      ; The Option ROM Segment Address - offset is 0000

%include "macro.inc"

; Trying this out in the Cassette BASIC segment F600h
org START

; Comment out the Option ROM lines if just loading as BASIC ROM
; Option ROM signature (2 Byte)
    db      0x55, 0xAA
; Option ROM size (1 Byte) in 512 Byte Blocks 
    db      18                  ; 16.798828125 (8601 / 512 Blocks)

; Springboard
    JMP     OptionROMInit          ; ToDo: would like to attach to Int 18 to boot MFM-150 and
                                    ; register Ctrl+Alt+Enter start the WarmStartMonitor like Z150
;    JMP     ColdStartMonitor 

; Ports
pic1_reg0           equ 0x20 
pit_ch2_reg         equ 0x42
pit_ctl_reg         equ 0x43
kbc_data_reg        equ 0x60
ppi_pb_reg          equ 0x61    ; 8255 PPI port B I/O register

; From BIOS DS 0040:
equipment_list      equ 0x10     ; word - equpment list
equip_video         equ 0000000000110000b ; 0x30

memory_size         equ 0x13    ; word - memory size in KiB
kbd_buffer_head     equ 0x1A    ; word - keyboard buffer head offset
kbd_buffer_tail     equ 0x1C    ; word - keyboard buffer tail offset
video_mode          equ 0x49    ; byte - active video mode number
video_page_size     equ 0x4C    ; word - size of video page in bytes
video_port          equ 0x63    ; word - I/O port for the display adapter
kbd_buffer_start    equ 0x80    ; word - keyboard buffer start offset
kbd_buffer_end      equ 0x82    ; word - keyboard buffer end offset

; Scratchpad Memory Variable Locations:
; Currently 623-ish Bytes (up to 0x26f)
; From PCjs Z150 Emu: <ram id="ramBIOS" addr="0xf0000" size="0x4000" comment="16Kb of scratchpad RAM"/>
scratchRAM_Seg      equ 0x9f80      ; Could be used to relocate the scratchpad RAM, ie to EBDA
DAT_f000_0004       equ 0x4         ; Uswd By TESTCommandFunction & FUN_f000_9c4e
DAT_f000_0005       equ 0x5         ; Used By FUN_f000_9d8e
;DAT_f000_000a       equ 0xa         ; Used By FUN_f000_9c4e
DAT_f000_000b       equ 0xb         ; Used By FUN_f000_9c4e
DAT_f000_001b       equ 0x1b        ; Used By FUN_f000_9c4e
DAT_f000_001d       equ 0x1d        ; Used By FUN_f000_9c4e
DAT_f000_002d       equ 0x2d        ; Used By FUN_f000_9c4e
DAT_f000_002f       equ 0x2f        ; Used By FUN_f000_9d8e
DAT_f000_0031       equ 0x31        ; Used By FUN_f000_9d8e
DAT_f000_0039       equ 0x39        ; Used By FUN_f000_a16b
DAT_f000_003c       equ 0x3c        ; Used By FUN_f000_9cc9
DAT_f000_003d       equ 0x3d        ; Used By FUN_f000_9d03
DAT_f000_003e       equ 0x3e        ; Used By FUN_f000_9cc9
DAT_f000_0046       equ 0x46        ; Used By FUN_f000_9cc9
DAT_f000_004d       equ 0x4d        ; Used By BootCommand
DAT_f000_0057       equ 0x57        ; Used By BootCommand
DAT_f000_0058       equ 0x58        ; Used By BootCommand
DAT_f000_0059       equ 0x59        ; Used By ExecuteGoCommand
DAT_f000_005b       equ 0x5b        ; Used By ExecuteGoCommand
DAT_f000_005d       equ 0x5d        ; Used By ExecuteGoCommand
; 0081 -> 009d(?) Hold the CPU state (regs) of the machine when it was intterupted for the
; debugger (Trace/Go, etc...).
CPUState_AX_0081       equ 0x81        ; AX Stored hereUsed By ColdStartMoniror and ExecuteGoCommand
CPUState_BX_0083       equ 0x83        ; BX stored here By LAB_f000_ab6f (interrupt handelr)
CPUState_CX_0085       equ 0x85        ; CX stored here By LAB_f000_ab6f (interrupt handelr)
CPUState_DX_0087       equ 0x87        ; DX stored here By LAB_f000_ab6f (interrupt handelr)
CPUState_SI_0089       equ 0x89        ; SI stored here By LAB_f000_ab6f (interrupt handelr)
CPUState_DI_008b       equ 0x8b        ; DI stored here By LAB_f000_ab6f (interrupt handelr)
CPUState_BP_008d       equ 0x8d        ; BP stored here By LAB_f000_ab6f (interrupt handelr)
CPUState_SP_008f       equ 0x8f        ; Used By LAB_f000_ab6f (interrupt handelr), SP stored here by LAB_f000_ab6f
MonitorStart_Seg_2_CallerSeg  equ 0x91        ; DS stored here By LAB_f000_ab6f (interrupt handelr)
CPUState_DS_0093       equ 0x93        ; 
CPUState_SS_0095       equ 0x95        ; Used By LAB_f000_ab6f (interrupt handelr), SS stored here by LAB_f000_ab6f
CPUState_ES_0097       equ 0x97        ; ES stored here By LAB_f000_ab6f (interrupt handelr)
MonitorStart_Off_2_CallerOff  equ 0x99
CPUState_Flags_009b       equ 0x9b        ; Used By LAB_f000_ab6f (interrupt handelr)
DAT_f000_009d       equ 0x9d
DAT_f000_009e       equ 0x9e
DAT_f000_00a0       equ 0xa0        ; Used By LAB_f000_ab6f (interrupt handelr)
DAT_f000_00a1       equ 0xa1
DAT_f000_00a3       equ 0xa3
BIOS_DataSegment2       equ 0xc8               ; Seems to be 0040, the BIOS Data segment?
DAT_f000_01a0       equ 0x1a0               ; Used by FillMemory and SearchMemory Commands
MonitorStart_Off    equ 0x1c8
MonitorStart_Seg    equ 0x1ca
DAT_f000_01cc       equ 0x1cc       ; Used By FUN_f000_b1d0
DAT_f000_01ce       equ 0x1ce       ; Used By FUN_f000_b1d0
DAT_f000_01d0       equ 0x1d0       ; Used By FUN_f000_b23f - String Pointer to the Opcode string
DAT_f000_01d2       equ 0x1d2       ; Used By FUN_f000_b23f - Word of Operand/Instruction type data
DAT_f000_01d4       equ 0x1d4       ; Used By FUN_f000_b23f
OPCODE_METADATA_01d6       equ 0x1d6       ; Used By FUN_f000_b23f
DAT_f000_01d8       equ 0x1d8       ; Used By FUN_f000_b23f - I think this is the current instruction opcode
OperandByte1_01da       equ 0x1da       ; Used By FUN_f000_b3fc
DAT_f000_01dc       equ 0x1dc       ; Used by FUN_f000_b308
DAT_f000_01de       equ 0x1de       ; Used by FUN_f000_b308
DAT_f000_01e0       equ 0x1e0       ; Used by FUN_f000_b308
InstructionString_01e1       equ 0x1e1       ; Used By FUN_f000_b23f - 20 Bytes(?) Holds the Assembly Symbol String to print...
DAT_f000_01e2       equ 0x1e2       ; Used By FUN_f000_b23f
DAT_f000_0201       equ 0x201       ; Used By FUN_f000_b520 - Operand Value at memory address Hex ie, [0201]
DAT_f000_0210       equ 0x210       ; Operand hex value 
MonitorCommandLineBuffer   equ 0x21a
CLICursorColPosition       equ 0x26b        ; This stores the current character position of the CLI Text Cursor
DAT_f000_026d       equ 0x26d               ; Used by Command X 
DAT_f000_026e       equ 0x26e               ; Used by Command X 
DAT_f000_026f       equ 0x26f               ; Used by Command X 

;f000:00c6
BIOS_DataSegment    dw     0x0040                       ; This is defined in ScratchPad RAM, wonder what sets it?
DAT_f000_000a       db     0x04                         ; PCjs has this set to 4, and it's written to during POST, so hardcoding it...

; ---------------------------------------------------------------------
; ClearMDAandCGAVideo 
; -- Store 16k of 0x720 into B000:0000 (MDA) and 16k of B800:0000 (CGA)
; -- I think this is a Clear Screen Routine
;
;f000:8552
ClearMDAandCGAVideo:
    PUSH        AX                                      
    PUSH        CX                                      
    PUSH        DI                                      
    PUSH        ES                                      
    CLD                                                  
    MOV         ES,word CS:[CGA_Video_RAM_Seg]          ;= B800h
    XOR         DI,DI                                   ; Opcode is 33ff in original
    MOV         AX,0x720                                
    MOV         CX,0x2000                               ;2000h Words = 8192 Words = 16384 Bytes = 16kb
    REP STOSW                                           ;Store AX (0x0720) at addresses B800:0000 to B8000:8000 (32k)
    MOV         ES,word CS:[MDA_VideoRAM_Seg]           ;= B000h
    XOR         DI,DI                                   ; Also 33ff in original bin
    MOV         CX,0x2000                               
    REP STOSW   
    XOR         DX,DX                                   ; 33d2 in original
    POP         ES                                      
    POP         DI                                      
    POP         CX                                      
    POP         AX                                      
    RET                                                 ; TODO: Tried to return to f000:36ff in Bochs - I think this is because the Stack P{ointer is
                                                        ; not set right, should be at EBDA but is trying to use the Scratchpad RAM, which isn't
                                                        ; available...
; ---------------------------------------------------------------------
; PrintStringAtPos 
;
;f000:85b7
PrintStringAtPos:
    PUSH        AX                                      
    PUSH        SI                                      
LAB_f000_85b9:                                    
    MOV         AL,byte CS:[SI]                     
    INC         SI                                      
    TEST        AL,AL                                   
    JZ          LAB_f000_85c6                           
    CALL        FUN_f000_85c9                           ;undefined FUN_f000_85c9()
    JMP         LAB_f000_85b9                           
LAB_f000_85c6:                                    
    POP         SI                                      
    POP         AX                                      
    RET          

; ---------------------------------------------------------------------
; FUN_f000_85c9 
;
;f000:85c9
FUN_f000_85c9:
    CMP         AL,0xd                                  
    JNZ         LAB_f000_85d1                           
    MOV         DL,0x0                                  
    JMP         LAB_f000_862f                           
LAB_f000_85d1:                                    
    CMP         AL,0xa                                  
    JZ          LAB_f000_8626                           
    CMP         AL,0x9                                  
    JNZ         FUN_f000_85f0                           
    PUSH        AX                                      
    MOV         AH,DL                                   
    AND         AH,0xf8                                 
    ADD         AH,0x8                                  
    SUB         AH,DL                                   
LAB_f000_85e4:                                    
    MOV         AL,0x20                                 
    CALL        FUN_f000_85f0                           ;undefined FUN_f000_85f0()
    DEC         AH                                      
    JNZ         LAB_f000_85e4                           
    POP         AX                                      
    JMP         LAB_f000_862f                           
FUN_f000_85f0:
    PUSH        AX                                      
    PUSH        BX                                      
    MOV         BL,DH                                   
    MOV         BH,0x0                                  
    SHL         BX,1                                    
    MOV         BX,word CS:[BX + DAT_f000_eeeb]            
    ADD         BL,DL                                   
    ADC         BH,0x0                                  
    ADD         BL,DL                                   
    ADC         BH,0x0                                  
    MOV         AH,0x7                                  
    PUSH        ES                                      
    MOV         ES,word SS:[CGA_Video_RAM_Seg]      ;= B800h
    MOV         word ES:[BX],AX                     
    MOV         ES,word SS:[MDA_VideoRAM_Seg]       ;= B000h
    MOV         word ES:[BX],AX                     
    POP         ES                                      
    POP         BX                                      
    POP         AX                                      
    INC         DL                                      
    CMP         DL,0x50                                 
    JC          LAB_f000_862f                           
    MOV         DL,0x0                                  
LAB_f000_8626:                                    
    INC         DH                                      
    CMP         DH,0x19                                 
    JC          LAB_f000_862f                           
    MOV         DH,0x0                                  
LAB_f000_862f:                                    
    RET 

; ---------------------------------------------------------------------
; FUN_f000_8630
;
;f000:8630
FUN_f000_8630:
    PUSH        AX                                      
    PUSH        word [equipment_list]                         
    OR          word [equipment_list],equip_video    ; bits 5&4                
    MOV         AX,0x7                                  
    INT         0x10                                    
    AND         word [equipment_list],0xffef   ;  reset bits 5 & 4              
    MOV         AX,0x3                                  
    INT         0x10                                    
    POP         word [equipment_list]                         
    MOV         AX,0x3                                  
    INT         0x10                                    
    POP         AX                                      
    RET           

; ---------------------------------------------------------------------
; FUN_f000_9954
;
;f000:9954
FUN_f000_9954:
    PUSH        AX                                      
    PUSH        CX                                      
    PUSH        DX                                      
    CMP         AH,0x25                                 
    JNZ         LAB_f000_9975                           
    CMP         byte [video_mode],0x1                     
    JBE         LAB_f000_9982                           
    CMP         byte [video_mode],0x4                     
    JNC         LAB_f000_9982                           
    MOV         DX,0x3da                                
    MOV         CX,0xffff                               
LAB_f000_9970:                                    
    IN          AL,DX                                   
    AND         AL,0x8                                  
    LOOPZ       LAB_f000_9970                           
LAB_f000_9975:                                    
    MOV         DX,0x3d8                                
    MOV         AL,[video_mode]                               
    CMP         AL,0x7                                  
    JZ          LAB_f000_9982                           
    MOV         AL,AH                                   
    OUT         DX,AL                                   
LAB_f000_9982:                                    
    POP         DX                                      
    POP         CX                                      
    POP         AX                                      
    RET   

; ---------------------------------------------------------------------
; FUN_f000_9c4e
;
;f000:9c4e
FUN_f000_9c4e:
    PUSH        AX                                      
    PUSH        BX                                      
    PUSH        CX                                      
    MOV         SS:[DAT_f000_0004],AL                   ;= ??
    MOV         AH,0x25                                 
    CALL        FUN_f000_9954 
    MOV         AX,0x0                                  
    MOV         BX,0x0                                  
    MOV         CL,byte CS:[DAT_f000_000a]          ;ROM or RAM / CS or SS?
    MOV         CH,0x0                                  
LAB_f000_9c67:                                    
    MOV         word SS:[BX + DAT_f000_001d],AX     ;= ??
    MOV         word SS:[BX + DAT_f000_000b],AX     ;= ??
    MOV         word [BX + 0x50],0x0                
    ADD         AX,word [video_page_size]                      
    ADD         BX,0x2                                  
    LOOP        LAB_f000_9c67                       ; CRASHES HERE...
    MOV         word SS:[DAT_f000_002d],0x0         ;= ??
    MOV         word SS:[DAT_f000_001b],0x0         ;= ??
    MOV         ES,word SS:[CGA_Video_RAM_Seg]      ;= B800h
    CALL        FUN_f000_a07a
    MOV         ES,word SS:[MDA_VideoRAM_Seg]       ;= B000h
    CALL        FUN_f000_a07a
    PUSH        word [video_port]                         
    MOV         word [video_port],0x3d4                   
    MOV         AL,[0x62]                               
    CALL        FUN_f000_9d03 
    MOV         word [video_port],0x3b4                   
    CALL        FUN_f000_9d03   
    POP         word [video_port]                         
    MOV         AH,byte [0x65]                      
    CALL        FUN_f000_9954 
    CALL        FUN_f000_9cc9 
    POP         CX                                      
    POP         BX                                      
    POP         AX                                      
    RET          

; ---------------------------------------------------------------------
; FUN_f000_9cc9
;
;f000:9cc9
FUN_f000_9cc9:
    PUSH        AX                                      
    TEST        byte SS:[DAT_f000_0046],0x1         ;= ??
    JNZ         LAB_f000_9d01                           
    CMP         byte SS:[DAT_f000_0004],0x0         ;= ??
    JZ          LAB_f000_9d01                           
    CMP         byte [video_mode],0x2                     
    JC          LAB_f000_9d01                           
    CMP         byte [video_mode],0x7                     
    JZ          LAB_f000_9cef                           
    CMP         byte [video_mode],0x4                     
    JNC         LAB_f000_9d01                           
LAB_f000_9cef:                                    
    MOV         word [video_page_size],0x8000           ;Ghidra : DAT_0000_8000
    MOV         word SS:[DAT_f000_003e],0x7FFF       ; GHIDRA: DAT_0000_7ff
    MOV         AL,0x0                                  
    CALL        FUN_f000_9d03 
LAB_f000_9d01:                                    
    POP         AX                                      
    RET           

; ---------------------------------------------------------------------
; FUN_f000_9d03
;
;f000:9d03
FUN_f000_9d03:
    PUSH        AX                                      
    PUSH        BX                                      
    PUSH        DX                                      
    PUSH        SI                                      
    PUSH        DI                                      
    MOV         BL,byte [video_mode]                      
    CMP         BL,0x7                                  
    JA          LAB_f000_9d18                           
    XOR         BH,BH                                   
    AND         AL,byte CS:[BX + DAT_f000_e7e5]            
LAB_f000_9d18:                                    
    MOV         BH,AL                                   
    CALL        FUN_f000_9d8e 
    MOV         [0x62],AL                               
    MOV         CS:[DAT_f000_003c],AL                   ;= ??
    CBW                                                  
    MOV         DI,AX                                   
    SHL         DI,1                                    
    MOV         SI,word CS:[DI + 0xb]               
    CMP         byte [video_mode],0x7                     
    JNZ         LAB_f000_9d3a                           
    MOV         SI,word SS:[DAT_f000_001b]          ;= ??
LAB_f000_9d3a:                                    
    MOV         word [0x4e],SI                      
    MOV         DX,word [DI + 0x50]                 
    MOV         BH,byte [0x62]                      
    CALL        FUN_f000_9dc4    
    CMP         byte [video_mode],0x2                     
    JC          LAB_f000_9d7a                           
    CMP         byte [video_mode],0x3                     
    JA          LAB_f000_9d7a                           
    CMP         byte SS:[DAT_f000_0004],0x0         ;= ??
    JZ          LAB_f000_9d7a                           
    CMP         byte SS:[DAT_f000_003d],0x18        ;= ??
    JNZ         LAB_f000_9d7a                           
    MOV         AX,word CS:[DI + 0x1d]              
    SHL         AX,1                                    
    SHL         AX,1                                    
    AND         AH,0xc0                                 
    OR          AH,0x21                                 
    MOV         AL,AH                                   
    JMP         LAB_f000_9d7c                           
LAB_f000_9d7a:                                    
    MOV         AL,0x1                                  
LAB_f000_9d7c:                                    
    CALL        FUN_f000_a16b  
    MOV         BX,SI                                   
    SHR         BX,1                                    
    MOV         AL,0xc                                  
    CALL        FUN_f000_a194  
    POP         DI                                      
    POP         SI                                      
    POP         DX                                      
    POP         BX                                      
    POP         AX                                      
    RET 

; ---------------------------------------------------------------------
; FUN_f000_9d8e
;
;f000:9d8e
FUN_f000_9d8e:
    PUSH        BX                                      
    CMP         byte [video_mode],0x3                     
    JBE         LAB_f000_9d98                           
    MOV         BH,0x0                                  
LAB_f000_9d98:                                    
    MOV         byte SS:[DAT_f000_0005],BH          ;= ??
    MOV         BX,0x0                                  
    CMP         byte [video_mode],0x7                     
    JZ          LAB_f000_9db3                           
    MOV         BL,byte SS:[DAT_f000_0005]          ;= ??
    SHL         BX,1                                    
    MOV         BX,word SS:[BX + DAT_f000_001d]     ;= ??
LAB_f000_9db3:                                    
    MOV         word SS:[DAT_f000_002f],BX          ;= ??
    ADD         BX,word [0x4c]                      
    DEC         BX                                      
    MOV         word SS:[DAT_f000_0031],BX          ;= ??
    POP         BX                                      
    RET             

; ---------------------------------------------------------------------
; FUN_f000_9dc4
;
;f000:9dc4
FUN_f000_9dc4:
    PUSH        AX                                      
    PUSH        BX                                      
    PUSH        DX                                      
    MOV         byte SS:[DAT_f000_0005],BH          ;= ??
    MOV         BL,BH                                   
    MOV         BH,0x0                                  
    SHL         BX,1                                    
    ADD         BX,0x50                                 
    MOV         word [BX],DX                        
    MOV         AL,SS:[DAT_f000_0005]                   ;= ??
    CMP         AL,byte [0x62]                      
    JNZ         LAB_f000_9e04                           
    MOV         AL,DH                                   
    MUL         byte [0x4a]                         
    ADD         AL,DL                                   
    ADC         AH,0x0                                  
    SHL         AX,1                                    
    ADD         AX,word [0x4e]                      
    SHR         AX,1                                    
    CMP         AX,0x2000                               
    JBE         LAB_f000_9dfd                           
    SUB         AX,0x4000                               
LAB_f000_9dfd:                                    
    MOV         BX,AX                                   
    MOV         AL,0xe                                  
    CALL        FUN_f000_a194                           ;= ??
LAB_f000_9e04:                                    
    POP         DX                                      
    POP         BX                                      
    POP         AX                                      
    RET                   


; ---------------------------------------------------------------------
; FUN_f000_9e08 - Used with the VerticalTab Function
;
;f000:9e08
FUN_f000_9e08:
    PUSH        BX                                      
    MOV         BL,BH                                   
    MOV         BH,0x0                                  
    SHL         BX,1                                    
    ADD         BX,0x50                                 
    MOV         DX,word [BX]                        
    MOV         CX,word [0x60]
    POP         BX                                      
    RET       

; ---------------------------------------------------------------------
; FUN_f000_a07a
;
;f000:a07a
FUN_f000_a07a:
    PUSH        AX                                      
    PUSH        CX                                      
    PUSH        DI                                      
    MOV         AX,ES                                   
    CMP         AX,0xb000                               
    MOV         AX,0x720                                
    JZ          LAB_f000_a090                           
    CMP         byte [video_mode],0x3                     
    JBE         LAB_f000_a090                           
    XOR         AX,AX                                   
LAB_f000_a090:                                    
    LEA         DI,[0x0]                                
    MOV         CX,0x2000                               
    rep stosw   ; ES:DI                    ;= ??
    POP         DI                                      
    POP         CX                                      
    POP         AX                                      
    RET                      

; ---------------------------------------------------------------------
; FUN_f000_a16b
;
;f000:a16b
FUN_f000_a16b:
    PUSH        AX                                      
    PUSH        DX                                      
    TEST        byte SS:[DAT_f000_0046],0x1         ;= ??
    JZ          LAB_f000_a191                           
    MOV         DX,word [video_port]                      
    CMP         DX,0x3b4                                
    JZ          LAB_f000_a191                           
    ADD         DX,0x6                                  
    MOV         AH,byte SS:[DAT_f000_0039]          ;= ??
    AND         AH,0x6                                  
    OR          AL,AH                                   
    OUT         DX,AL                                   
    MOV         SS:[DAT_f000_0039],AL                   ;= ??
LAB_f000_a191:                                    
    POP         DX                                      
    POP         AX                                      
    RET                 

; ---------------------------------------------------------------------
; FUN_f000_a194
;
;f000:a194
FUN_f000_a194:
    PUSH        AX                                      
    PUSH        DX                                      
    MOV         DX,word [video_port]                      
    MOV         AH,AL                                   
    INC         AL                                      
    OUT         DX,AL                                   
    MOV         AL,BL                                   
    INC         DX                                      
    OUT         DX,AL                                   
    MOV         AL,AH                                   
    DEC         DX                                      
    OUT         DX,AL                                   
    INC         DX                                      
    MOV         AL,BH                                   
    OUT         DX,AL                                   
    POP         DX                                      
    POP         AX                                      
    RET          

; ---------------------------------------------------------------------
; LowerToUpperCaseAZ
;
;f000:a6d9
LowerToUpperCaseAZ:
    CMP         AL,'`'                                  
    JBE         .exit                           ;Jump if below or equal / Jump if not above 
    CMP         AL,'{'                                  
    JNC         .exit                           ;Jump if above or equal / Jump if not below
    SUB         AL,0x20                                 
.exit:                                    
    RET  

; ---------------------------------------------------------------------
; OptionROMInit
;
; Set the Int 18 vector.
; ToDo: Would be to hook into the Int 15,4F vector to try and capture Ctrl+Alt+Del
;
OptionROMInit:
; Set Int 18 as MFM-150 ROM
    PUSH        ES
    xor         AX, AX
    MOV         ES, AX
    mov         di, 4*18h                   ;   Int 18h vector
    mov         ax, ColdStartMonitor          ; MFM-150 offset
    stosw                                   ;   Store AX (0000) to ES:DI - ES should be 0000, DI 60h
    mov         ax, OPTION_SEG          ;   F600h BASIC interrupt segment
    stosw                           ;   Store AX (F600) to ES:DI - ES should be 0000, DI 62h
    POP         ES
; Capture and handle Ctrl+Alt+Enter as the 
; Idea is to use INT 15h,4Fh to detect if Ctrl+Alt+Enter has been pressed - not sure how yet ;)
; Test the CtrlAltEnterEntry first by hacking the 8088_BIOS to prove this would work...
    RETF

; ---------------------------------------------------------------------
; CtrlAltEnterEntry
;
; This is called by the BIOS when Ctrl+Alt+Enter is pressed.
;
CtrlAltEnterEntry:       
; Problem here is we need to save all the registers and the calling Offset, Segment & Flags which is on the original stack (SS:SP)
; If we set the SS to access the variables, we lose the Caller params...     
; Idea: Use the method INT 13 usese - Push all the regs to the stack and use BP to access them to put into Memory - Turn the stack into local
; memory
    MOV         AL, 0x20
    OUT         pic1_reg0, AL
    ; PUSH 'CALLER_OFF' ; 26
    ; PUSH 'CALLER_SEG' ; 24
    ; PUSH 'CPUFLAGS'   ; 22
    PUSH        AX      ; 20
    PUSH        BX      ; 18
    PUSH        CX      ; 16
    PUSH        DX      ; 14
    PUSH        SI      ; 12
    PUSH        DI      ; 10
    PUSH        BP      ; 8
    PUSH        DS      ; 6
    PUSH        ES      ; 4
    PUSH        SP      ; 2
    PUSH        SS      ; 0
    MOV         BP,SP
    MOV         AX, scratchRAM_Seg
    MOV         ES, AX          ; Using ES to write to ScratchPad vars
    MOV         AX,[BP+20]                   ; 
    MOV         ES:[CPUState_AX_0081],AX                                    ;ENTRY POINT FOR CTRL+ALT+ENTER
    MOV         AX,[BP+26]                                                           ;I think this is the Call Offset
    MOV         ES:[MonitorStart_Off_2_CallerOff],AX                        ;= ??                                          
    MOV         AX,[BP+24]                                                           ;I think this is the call segment
    MOV         ES:[MonitorStart_Seg_2_CallerSeg],AX                        ;= ??
    MOV         AX,[BP+22]                                                           ;CPU Flags Reg
    MOV         ES:[CPUState_Flags_009b],AX                                 ;= ??
    MOV         AX,[BP+18]
    MOV         word ES:[CPUState_BX_0083],AX                           ;= ??
    MOV         AX,[BP+16]
    MOV         word ES:[CPUState_CX_0085],AX                           ;= ??
    MOV         AX,[BP+14]
    MOV         word ES:[CPUState_DX_0087],AX                           ;= ??
    MOV         AX,[BP+12]
    MOV         word ES:[CPUState_SI_0089],AX                           ;= ??
    MOV         AX,[BP+10]
    MOV         word ES:[CPUState_DI_008b],AX                           ;= ??
    MOV         AX,[BP+8]
    MOV         word ES:[CPUState_BP_008d],AX                           ;= ??
    MOV         AX,[BP+6]
    MOV         word ES:[CPUState_DS_0093],AX                           ;= ??
    MOV         AX,[BP+4]
    MOV         word ES:[CPUState_ES_0097],AX                           ;= ??
    MOV         AX,[BP+2]
    MOV         word ES:[CPUState_SP_008f],AX                           ;= ??
    MOV         AX,[BP]
    MOV         word ES:[CPUState_SS_0095],AX                           ;= ??
    MOV         DS,word CS:[BIOS_DataSegment]                           ;= ??
    MOV         AX, scratchRAM_Seg
    MOV         SS, AX                                                     
    MOV         SP,0x338                                                    
    STI                                                                      
    CLD                                                                      
    CMP         byte SS:[DAT_f000_009d],0x0                             ;= ??
    JZ          LAB_f000_b08f                                               
    MOV         SI,0x0                                                      
LAB_f000_b073:                                              
    MOV         ES,word SS:[SI + DAT_f000_0059]                         ;= ??
    MOV         DI,word SS:[SI + DAT_f000_005b]                         ;= ??
    MOV         AL,byte SS:[SI + DAT_f000_005d]                         ;= ??
    MOV         byte ES:[DI],AL                                         
    ADD         SI,0x5                                                      
    DEC         byte SS:[DAT_f000_009d]                                 ;= ??
    JNZ         LAB_f000_b073                                               
LAB_f000_b08f:                                              
    CALL        FUN_f000_bed8 
    CALL        FUN_f000_ada6
    MOV         ES,word SS:[MonitorStart_Seg_2_CallerSeg]               ;= ??
    MOV         word SS:[MonitorStart_Seg],ES                           ;= ??
    MOV         DI,word SS:[MonitorStart_Off_2_CallerOff]               ;= ??
    MOV         word SS:[MonitorStart_Off],DI                           ;= ??
    MOV         CX,0x1                                                      
    CALL        FUN_f000_b1d0 
    JMP         WarmStartMonitor                          ;This is what CTRL+ALT+ENTER enters the MFM-150 from...


; ---------------------------------------------------------------------
; On the Z150 Emu the registry values are on starting the Monitor:
;
; AX=6D60 BX=C800 CX=0014 DX=03C2 BP=3000 SI=8000 DI=4000
; SS:SP=F000:0338
; DS=0040
; ES=0040
; CS=F000
; PS=F202 (?)
;
; Flags: V0 D0 I1 T0 S0 Z0 A0 P0 C0 
;
; Uses the Scratchpad RAM for Stack
;
; Todo:
; - Figure out how much EBDA we would need:
; -- If the stack pointer starts at F000:0338 and works backwards, and the scratchpad starts at F000:0000 it can't use any more 
; -- than 824 Bytes. I think 1K would be sufficient, start with that. Use the 2nd 1K of EDBA: 0x9F800 - 0x9FBFF, cool.
; -- Also, the last byte I see any data in on PCjs is &F000:0337... 823 Bytes
;
;f000:a80c
ColdStartMonitor:
    CLI                                                 ; Clear Interrupts
    CLD                                                 
;    PUSH        CS
;    POP         SS                                      ; Set to end of 2nd 1k block of EDBA... 0x9F800 - 0x9FBFF, so 0x9FBFF?
    MOV         AX,scratchRAM_Seg                       ; Setup the Stack Segment SS to be EBDA MFM-150 ScratchPad Segment
    MOV         SS,AX                                   ; Also the SS is used to transfer the Scratchpad variables - 
                                                        ; Hmm this line Crashes the Unassembler - and not sure if this is allowed? in Opcode table it's _MOV sr,r/m16 0x8E
    MOV         DS,word CS:[BIOS_DataSegment]       
    MOV         SP,0x338                                
    CALL        ClearMDAandCGAVideo  
    MOV         AX,0x3                                  
    INT         0x10                                    
    MOV         SI,s_MFM150Monitor                      ;The MFM-150 Monitor... string
    CALL        PrintString                             
    MOV         ax,word [memory_size]                   ;f000:a826 a1 13 00        MOV        AX,[offset DAT_0000_0813]
    CALL        PrintDecimal                            
    MOV         SI,s_K_bytes_Enter_for_help             ;= "K bytes\r\nEnter \"?\" for help.\...
    CALL        PrintString                             ;undefined PrintString()
    MOV         byte  SS:[DAT_f000_009d],0x0            ; Don't know what this is being set to 0x00 - need to put in ScratchPad
;I think this is clearing/reserving Memory for the Monitor - sets a bunch of addresses in Scratchpad RAM to 0x00
    ; PUSH        CS                                      
    ; POP         ES                                      ;F000 - I think this will need chaged to start of EBDA 0x9F800
    MOV         AX,scratchRAM_Seg
    MOV         ES,AX
    MOV         DI,CPUState_AX_0081                        ;F000:0081
    MOV         CX,28                                   ;28 Bytes
    XOR         AX,AX                                   ;AL = 0
;Insert 28 bytes of 0x00 from F000:0081 - F000:009D
;reserving memory for the Monitor?
    REP STOSB                                           ;Repeat Store AL at address ES:(E)DI....
    MOV         SS:[DAT_f000_00a1],AX                   ;= ??
    MOV         SS:[DAT_f000_00a3],AX                   ;= ??
    MOV         word SS:[MonitorStart_Seg],CS       
    MOV         word SS:[MonitorStart_Off],ColdStartMonitor
    MOV         word SS:[MonitorStart_Seg_2_CallerSeg],CS     
    MOV         word SS:[MonitorStart_Off_2_CallerOff],ColdStartMonitor
WarmStartMonitor:                                 
    STI                                                  ;I think this is an initialise Monito...
    CLD                                                  
    ; PUSH        CS  
    ; POP         SS                                     ; As the ColdStart need to setup the SS to EBDA Scratchpad addr
    MOV         AX,scratchRAM_Seg
    MOV         SS,AX
    MOV         DS,word CS:[BIOS_DataSegment]    
    MOV         SP,0x338                  
    MOV         word SS:[DAT_f000_009e],0x0
MonitorCommandLoop:                               
    MOV         SI,s_commandPrompt                      ;= "->"
    CALL        PrintString                             ;Show the command prompt
    CALL        WaitForCommandToBeEntered               ;Return the next command
    MOV         SI,0x0                                  
    CALL        IgnoreLeadingSpacesInCLIBuffer          ;I think this is ignoring spaces befo...
    MOV         AL,byte SS:[SI + MonitorCommandLineBuffer]  ;Set AL to the first non-space charac...
    CMP         AL,0xd                                  ;0xd = \r "CR" If Enter, ignore and loop again...
    JZ          MonitorCommandLoop                      
    INC         SI                                      ;AL is now set to the command letter,...
    CALL        LowerToUpperCaseAZ                      ;undefined LowerToUpperCaseAZ()
    MOV         BX,0x0                                  
    MOV         CX,17                                   ;17 Commands to check for in Command ...
    NOP                                                  
.lookupNextCommand:                               
    CMP         AL,byte  CS:[BX + MonitorCommandDispatchTable]  ;Is this command in the table?
    JZ          .commandFound                           
    ADD         BX,0x3                                  
    LOOP        .lookupNextCommand                      
    JMP         CommandError                            
.commandFound:                               
    CALL        [CS:BX + CMD_Off_PrintCommandSummaryHelpText] ;Call Command Function from lookup table "call [cs:bx-0x4e84]"
    JNC         MonitorCommandLoop                      ;Error if Carry Set
CommandError:                                     
    MOV         AX,SI                                   ;SI is the current CLI input buffer position
    MOV         AH,AL                                 
    ADD         AH,byte SS:[CLICursorColPosition]          ;Add something to the Buffer Index Position (Coloumn Number)
    DEC         AH                                      ; Take away 1
    CALL        DisplaySpaces                           ;Add spaces to the new Row
    MOV         SI,s_Invalid_Command                    ;= "^ Invalid Command!\r\n"
    CALL        PrintString                             ;
    CALL        ErrorBeep                               ;Try again
    JMP         MonitorCommandLoop       

; ---------------------------------------------------------------------
; BootCommand
;
;f000:a8c8
BootCommand:
    PUSH        AX                                      
    PUSH        DI                                      
    CALL        FUN_f000_bdff
    CALL        LowerToUpperCaseAZ 
    MOV         AH,byte SS:[DAT_f000_0057]          ;= ??
    CMP         AL,0x46                                 
    JNZ         LAB_f000_a8de                           
    AND         AH,0x7f                                 
    JMP         LAB_f000_a8e5                           
LAB_f000_a8de:                                    
    CMP         AL,0x57                                 
    JNZ         LAB_f000_a8e8                           
    OR          AH,0x80                                 
LAB_f000_a8e5:                                    
    CALL        FUN_f000_bdff                           ;= ??
LAB_f000_a8e8:                                    
    CMP         AL,0x30                                 
    JC          LAB_f000_a8fa                           
    CMP         AL,0x33                                 
    JA          LAB_f000_a8fa                           
    SUB         AL,0x30                                 
    AND         AH,0xfc                                 
    OR          AH,AL                                   
    CALL        FUN_f000_bdff
LAB_f000_a8fa:                                    
    MOV         byte SS:[DAT_f000_0057],AH          ;= ??
    CMP         AL,0x3a                                 
    JNZ         LAB_f000_a91a                           
    CALL        FUN_f000_bdff
    MOV         SS:[DAT_f000_0058],AL                   ;= ??
    CMP         AL,0xd                                  
    JZ          LAB_f000_a91f                           
    CMP         AL,0x31                                 
    JC          LAB_f000_a92b                           
    CMP         AL,0x35                                 
    CMC                                                  
    JC          LAB_f000_a92b                           
    CALL        FUN_f000_bdff
LAB_f000_a91a:                                    
    CMP         AL,0xd                                  
    STC                                                  
    JNZ         LAB_f000_a92b                           
LAB_f000_a91f:                                    
    MOV         byte SS:[DAT_f000_004d],0xff        ;= ??
    MOV         AL,SS:[DAT_f000_0058]                   ;= ??
    INT         0x19                                    
LAB_f000_a92b:                                    
    POP         DI                                      
    POP         AX                                      
    RET   

; ---------------------------------------------------------------------
; PrintColourBars 
;
;f000:a92e
PrintColourBars:
    PUSH        AX                                      
    PUSH        BX                                      
    PUSH        CX                                      
    PUSH        DX                                      
    PUSH        SI                                      
    PUSH        word [video_mode]                         
    MOV         AL,0x3                                  
    MOV         AH,0x0                                  
    INT         0x10                                    
    MOV         BX,0x0                                  
    MOV         DX,0x0                                  
LAB_f000_a943:                                    
    MOV         AH,0x2                                  
    INT         0x10                                    
    MOV         CX,0x5                                  
    MOV         AL,0xdb                                 
    MOV         AH,0x9                                  
    INT         0x10                                    
    ADD         DX,CX                                   
    INC         BL                                      
    CMP         BL,0x10                                 
    JC          LAB_f000_a943                           
    MOV         BL,0x0                                  
    MOV         DL,BL                                   
    INC         DH                                      
    CMP         DH,0x16                                 
    JC          LAB_f000_a943                           
    POP         CX                                      
    CALL        FUN_f000_bed8                           ;undefined FUN_f000_bed8()
    CMP         CL,0x7                                  
    JZ          LAB_f000_a987                           
    CMP         CL,0x3                                  
    JZ          LAB_f000_a987                           
    CMP         CL,0x2                                  
    JZ          LAB_f000_a987                           
    MOV         SI,s_Press_any_key                               
    CALL        PrintString                             ;undefined PrintString()
    MOV         AH,0x0                                  
    INT         0x16                                    
    MOV         AL,CL                                   
    MOV         AH,0x0                                  
    INT         0x10                                    
LAB_f000_a987:                                    
    CLC                                                  
    POP         SI                                      
    POP         DX                                      
    POP         CX                                      
    POP         BX                                      
    POP         AX                                      
    RET  

; ---------------------------------------------------------------------
; DisplayMemoryCommandFunction 
;
;f000:a98e
DisplayMemoryCommandFunction:
    PUSH        AX                                      
    PUSH        CX                                      
    PUSH        DI                                      
    PUSH        ES                                      
    LES         DI,SS:[DAT_f000_00a1]                   ;Sets ES:DI to the SEG:OFF at CS:00A1
    MOV         CX,0x80                                 
    CALL        FUN_f000_bde3                           ;undefined FUN_f000_bde3()
    JC          LAB_f000_a9ac                           
    MOV         AH,0xff                                 
    CALL        FUN_f000_bd1c                           ;CRASHES!
    JC          LAB_f000_aa0d                           
    CALL        FUN_f000_bde3                           ;undefined FUN_f000_bde3()
    CMC                                                  
    JC          LAB_f000_aa0d                           
LAB_f000_a9ac:                                    
    MOV         AX,DI                                   
    ADD         AX,CX                                   
    MOV         SS:[DAT_f000_00a1],AX                   ;= ??
    MOV         word SS:[DAT_f000_00a3],ES              ;= ??
    PUSH        DI                                      
    PUSH        CX                                      
    CALL        FUN_f000_be9d                           ;undefined FUN_f000_be9d()
    MOV         AH,0x2                                  
    CALL        DisplaySpaces                           ;undefined DisplaySpaces()
LAB_f000_a9c3:                                    
    MOV         AL,byte ES:[DI]                     
    CALL        FUN_f000_beb6                           ;undefined FUN_f000_beb6()
    INC         DI                                      
    DEC         CX                                      
    JZ          LAB_f000_a9e2                           
    MOV         AX,DI                                   
    AND         AL,0xf                                  
    CMP         AL,0x8                                  
    MOV         AL,0x20                                 
    JNZ         LAB_f000_a9d9                           
    MOV         AL,0x2d                                 
LAB_f000_a9d9:                                    
    CALL        PrintCharacter                          ;undefined PrintCharacter(void)
    TEST        DI,0xf                                  
    JNZ         LAB_f000_a9c3                           
LAB_f000_a9e2:                                    
    MOV         AH,0x3d                                 
    CALL        FUN_f000_bf3a                           ;undefined FUN_f000_bf3a()
    POP         CX                                      
    POP         DI                                      
LAB_f000_a9e9:                                    
    MOV         AL,byte ES:[DI]                     
    AND         AL,0x7f                                 
    CMP         AL,0x20                                 
    JC          LAB_f000_a9f6                           
    CMP         AL,0x7f                                 
    JNZ         LAB_f000_a9f8                           
LAB_f000_a9f6:                                    
    MOV         AL,0x2e                                 
LAB_f000_a9f8:                                    
    CALL        PrintCharacter                          ;undefined PrintCharacter(void)
    INC         DI                                      
    DEC         CX                                      
    JZ          LAB_f000_aa05                           
    TEST        DI,0xf                                  
    JNZ         LAB_f000_a9e9                           
LAB_f000_aa05:                                    
    CALL        FUN_f000_bed8                           ;undefined FUN_f000_bed8()
    JCXZ        LAB_f000_aa0c                           
    JMP         LAB_f000_a9ac                           
LAB_f000_aa0c:                                    
    CLC                                                  
LAB_f000_aa0d:                                    
    POP         ES                                      
    POP         DI                                      
    POP         CX                                      
    POP         AX                                      
    RET                    

; ---------------------------------------------------------------------
; ExamineMemoryCommandFunction 
;
;f000:aa12
ExamineMemoryCommandFunction:
    PUSH        AX                                      
    PUSH        CX                                      
    PUSH        DI                                      
    PUSH        ES                                      
    CALL        FUN_f000_bd57
    JC          LAB_f000_aa21                           
    CALL        FUN_f000_bde3
    CMC                                                  
    JNC         LAB_f000_aa24                           
LAB_f000_aa21:                                    
    JMP         LAB_f000_aab4                           
LAB_f000_aa24:                                    
    CALL        FUN_f000_be9d
    MOV         AH,0x2                                  
    CALL        DisplaySpaces
LAB_f000_aa2c:                                    
    MOV         AL,byte ES:[DI]                     
    CALL        FUN_f000_beb6 
    MOV         AL,0x2e                                 
    CALL        PrintCharacter
    MOV         CX,0x0                                  
LAB_f000_aa3a:                                    
    CALL        ReturnLastKeyPressASCIICode 
    CMP         AL,0xd                                  
    JNZ         LAB_f000_aa4d                           
    CALL        FUN_f000_bed8 
    TEST        CL,CL                                   
    JZ          LAB_f000_aab4                           
    MOV         byte ES:[DI],CH                     
    JMP         LAB_f000_aab4                           
LAB_f000_aa4d:                                    
    CMP         AL,0x20                                 
    JNZ         LAB_f000_aa66                           
    TEST        CL,CL                                   
    JZ          LAB_f000_aa58                           
    MOV         byte ES:[DI],CH                     
LAB_f000_aa58:                                    
    INC         DI                                      
    TEST        DI,0x7                                  
    JZ          LAB_f000_aa75                           
    MOV         AL,0x9                                  
    CALL        PrintCharacter
    JMP         LAB_f000_aa2c                           
LAB_f000_aa66:                                    
    CMP         AL,0x2d                                 
    JNZ         LAB_f000_aa7a                           
    CALL        PrintCharacter 
    TEST        CL,CL                                   
    JZ          LAB_f000_aa74                           
    MOV         byte ES:[DI],CH                     
LAB_f000_aa74:                                    
    DEC         DI                                      
LAB_f000_aa75:                                    
    CALL        FUN_f000_bed8 
    JMP         LAB_f000_aa24                           
LAB_f000_aa7a:                                    
    CMP         AL,0x8                                  
    JNZ         LAB_f000_aa92                           
    CMP         CL,0x0                                  
    JZ          LAB_f000_aa3a                           
    DEC         CL                                      
    CALL        FUN_f000_becf
    SHR         CH,1                                    
    SHR         CH,1                                    
    SHR         CH,1                                    
    SHR         CH,1                                    
    JMP         LAB_f000_aa3a                           
LAB_f000_aa92:                                    
    CMP         CL,0x2                                  
    JGE         LAB_f000_aa3a                           
    MOV         AH,AL                                   
    CALL        LowerToUpperCaseAZ
    CALL        FUN_f000_be5b
    JC          LAB_f000_aa3a                           
    SHL         CH,1                                    
    SHL         CH,1                                    
    SHL         CH,1                                    
    SHL         CH,1                                    
    OR          CH,AL                                   
    INC         CL                                      
    MOV         AL,AH                                   
    CALL        PrintCharacter 
    JMP         LAB_f000_aa3a                           
LAB_f000_aab4:                                    
    POP         ES                                      
    POP         DI                                      
    POP         CX                                      
    POP         AX                                      
    RET          

; ---------------------------------------------------------------------
; FillMemoryCommandFunction 
;
;f000:aab9
FillMemoryCommandFunction:
    PUSH        AX                                      
    PUSH        BX                                      
    PUSH        CX                                      
    PUSH        DX                                      
    PUSH        DI                                      
    PUSH        ES                                      
    MOV         AH,0x0                                  
    CALL        FUN_f000_bd1c                           ;undefined FUN_f000_bd1c()

    JC          LAB_f000_aae6                           
    PUSH        DI                                      
    MOV         DI,0x1a0                                
    CALL        FUN_f000_bcde                           ;undefined FUN_f000_bcde()

    POP         DI                                      
    JC          LAB_f000_aae6                           
    MOV         DX,BX                                   
    MOV         BX,0x0                                  
LAB_f000_aad5:                                    
    MOV         AL,byte SS:[BX + DAT_f000_01a0]
    INC         BX                                      
    STOSB                                               ; ES:DI                                   
    CMP         BX,DX                                   
    JNZ         LAB_f000_aae3                           
    MOV         BX,0x0                                  
LAB_f000_aae3:                                    
    LOOP        LAB_f000_aad5                           
    CLC                                                  
LAB_f000_aae6:                                    
    POP         ES                                      
    POP         DI                                      
    POP         DX                                      
    POP         CX                                      
    POP         BX                                      
    POP         AX                                      
    RET              

; ---------------------------------------------------------------------
; ExecuteGoCommandFunction 
;
;f000:aaed
ExecuteGoCommandFunction:
    PUSH        AX                                      
    PUSH        BX                                      
    PUSH        DI                                      
    PUSH        ES                                      
    CALL        FUN_f000_bde3                           ;undefined FUN_f000_bde3()

    JC          LAB_f000_ab13                           
    MOV         ES,word SS:[MonitorStart_Off_2_CallerOff]     ;= ??
    CMP         byte SS:[SI + MonitorCommandLineBuffer],0x3d           
    JNZ         LAB_f000_ab13                           
    INC         SI                                      
    CALL        FUN_f000_bd57                           ;undefined FUN_f000_bd57()

    JC          LAB_f000_ab6a                           
    MOV         word SS:[MonitorStart_Off_2_CallerOff],ES     ;= ??
    MOV         word SS:[MonitorStart_Seg_2_CallerSeg],DI     ;= ??
LAB_f000_ab13:                                    
    MOV         BX,0x0                                  
    MOV         byte SS:[DAT_f000_009d],0x0         ;= ??
LAB_f000_ab1c:                                    
    CALL        FUN_f000_bde3                           ;undefined FUN_f000_bde3()

    JC          LAB_f000_ab4f                           
    CMP         byte SS:[DAT_f000_009d],0x8         ;= ??
    CMC                                                  
    JC          LAB_f000_ab6a                           
    CALL        FUN_f000_bd57                           ;undefined FUN_f000_bd57()

    JC          LAB_f000_ab6a                           
    MOV         word SS:[BX + DAT_f000_0059],ES     ;= ??
    MOV         word SS:[BX + DAT_f000_005b],DI     ;= ??
    MOV         AL,byte ES:[DI]                     
    MOV         byte SS:[BX + DAT_f000_005d],AL     ;= ??
    MOV         byte ES:[DI],0xcc                   
    ADD         BX,0x5                                  
    INC         byte SS:[DAT_f000_009d]             ;= ??
    JMP         LAB_f000_ab1c                           
LAB_f000_ab4f:                                    
    PUSH        DS                                      
    MOV         AX,CS                                   
    MOV         DS,AX                                   
    MOV         SI,0xb00b                               
    MOV         AL,0x3                                  
    CALL        SetIntHandler                           ;undefined SetIntHandler()

    MOV         SI,0xb0b2                               
    MOV         AL,0x1                                  
    CALL        SetIntHandler                           ;undefined SetIntHandler()

    POP         DS                                      
    MOV         AH,0x0                                  
    JMP         LAB_f000_ab6f                           

    NOP

LAB_f000_ab6a:                                    
    POP         ES                                      
    POP         DI                                      
    POP         BX                                      
    POP         AX                                      
    RET  

; ---------------------------------------------------------------------
; LAB_f000_ab6f 
;
; Some kind of interrupt handler used by ExecuteGoCommand
;
;f000:ab6f
LAB_f000_ab6f:                                    
    CLI                                                                      
    MOV         byte SS:[DAT_f000_00a0],0xff                            ;= ??
    AND         word SS:[CPUState_Flags_009b],0xfeff                          ;= ??
    TEST        AH,AH                                                       
    MOV         AX,SS:[CPUState_Flags_009b]                                       ;= ??
    JNZ         LAB_f000_ab88                                               
    JMP         LAB_f000_ac0f                                               
LAB_f000_ab88:                                    
    PUSH        AX                                                          
    MOV         ES,word SS:[MonitorStart_Seg_2_CallerSeg]                         ;= ??
    MOV         SI,word SS:[MonitorStart_Off_2_CallerOff]                         ;= ??
    MOV         AL,byte ES:[SI]
    PUSH        CS
    POP         ES                                                          
    MOV         DI,0xb177                                                   
    MOV         CX,0x4                                                      
    repne scasb                                                       
    JZ          LAB_f000_aba8                                               
    MOV         byte SS:[DAT_f000_00a0],0x0                             ;= ??
LAB_f000_aba8:                                    
    CMP         AL,0xcd                                                     
    JNZ         LAB_f000_abe3                                               
    MOV         SS,word SS:[CPUState_SS_0095]                              ;= ??
    MOV         SP,word SS:[CPUState_SP_008f]                              ;= ??
    ADD         word SS:[MonitorStart_Off_2_CallerOff],0x2                        ;= ??
    PUSH        word SS:[CPUState_Flags_009b]                                 ;= ??
    PUSH        word SS:[MonitorStart_Seg_2_CallerSeg]                            ;= ??
    PUSH        word SS:[MonitorStart_Off_2_CallerOff]                            ;= ??
    MOV         ES,word SS:[MonitorStart_Seg_2_CallerSeg]                         ;= ??
    MOV         AL,byte ES:[SI + 0x1]
    CALL        FUN_f000_e890 
    MOV         word SS:[MonitorStart_Seg_2_CallerSeg],DS                         ;= ??
    MOV         word SS:[MonitorStart_Off_2_CallerOff],SI                         ;= ??
    JMP         LAB_f000_abfb                                               
LAB_f000_abe3:                                    
    CMP         AL,0x9c                                                     
    JNZ         LAB_f000_ac08                                               
    MOV         SS,word SS:[CPUState_SS_0095]                              ;= ??
    MOV         SP,word SS:[CPUState_SP_008f]                              ;= ??
    PUSH        word SS:[CPUState_Flags_009b]                                 ;= ??
    INC         word SS:[MonitorStart_Off_2_CallerOff]                            ;= ??
LAB_f000_abfb:                                    
    MOV         word SS:[CPUState_SS_0095],SS                              ;= ??
    MOV         word SS:[CPUState_SP_008f],SP                              ;= ??
    JMP         LAB_f000_b117                                               
LAB_f000_ac08:                                    
    POP         AX                                                          
    OR          AX,0x100                                                    
    AND         AX,0xfdff                                                   
LAB_f000_ac0f:                                    
    MOV         BX,word SS:[CPUState_BX_0083]                              ;= ??
    MOV         CX,word SS:[CPUState_CX_0085]                              ;= ??
    MOV         DX,word SS:[CPUState_DX_0087]                              ;= ??
    MOV         SI,word SS:[CPUState_SI_0089]                              ;= ??
    MOV         DI,word SS:[CPUState_DI_008b]                              ;= ??
    MOV         BP,word SS:[CPUState_BP_008d]                              ;= ??
    MOV         SP,word SS:[CPUState_SP_008f]                              ;= ??
    MOV         DS,word SS:[CPUState_DS_0093]                              ;= ??
    MOV         SS,word SS:[CPUState_SS_0095]                              ;= ??
    MOV         ES,word SS:[CPUState_ES_0097]                              ;= ??
    PUSH        AX                                                          
    PUSH        word SS:[MonitorStart_Seg_2_CallerSeg]                            ;= ??
    PUSH        word SS:[MonitorStart_Off_2_CallerOff]                            ;= ??
    MOV         AX,SS:[CPUState_AX_0081]                                       ;= ??
    IRET     

; ---------------------------------------------------------------------
; FUN_f000_adcd 
;
;f000adcd
FUN_f000_adcd:
    PUSH        AX                                      
    PUSH        BX                                      
    PUSH        CX                                      
    PUSH        DX                                      
    MOV         AL,byte CS:[BX + s_cpu_regs]            
    CALL        PrintCharacter            
    MOV         AL,byte CS:[BX + s_cpu_regs + 1]            
    CALL        PrintCharacter             
    MOV         AL,AH                                   
    CALL        PrintCharacter         
    MOV         DX,word SS:[BX + CPUState_AX_0081]          ; I'm assuming this is a ScratchPad variable read...    
    CMP         BX,0x1a                                 
    JNZ         LAB_f000_ae22                           
    MOV         CX,0x10                                 
    MOV         BX,0x0                                  
LAB_f000_adf6:                                    
    PUSH        BX                                      
    SHR         DX,1                                    
    JNC         LAB_f000_adfe                           
    ADD         BX,0x2                                  
LAB_f000_adfe:                                    
    CMP         word CS:[BX + s_cpu_regs_cn],0x0     
    JZ          LAB_f000_ae1a                           
    MOV         AL,0x20                                 
    CALL        PrintCharacter 
    MOV         AX,word CS:[BX + s_cpu_regs_cn]
    XCHG        AH,AL                                   
    CALL        PrintCharacter  
    MOV         AL,AH                                   
    CALL        PrintCharacter 
LAB_f000_ae1a:                                    
    POP         BX                                      
    ADD         BX,0x4                                  
    LOOP        LAB_f000_adf6                           
    JMP         LAB_f000_ae2a                           
LAB_f000_ae22:                                    
    MOV         AX,word SS:[BX + CPUState_AX_0081]            ; I'm assuming this is a ScratchPad variable read...      
    CALL        FUN_f000_beaf  
LAB_f000_ae2a:                                    
    POP         DX                                      
    POP         CX                                      
    POP         BX                                      
    POP         AX                                      
    RET           

; ---------------------------------------------------------------------
; PrintCommandSummaryHelp 
;
;f000:ac51
PrintCommandSummaryHelp:
    PUSH        SI                                      
    MOV         SI,s_150_Command_Summary                ;Help text
    CALL        PrintString                             ;undefined PrintString()
    POP         SI                                      
    RET    

; ---------------------------------------------------------------------
; HexMathCommandFunction 
;
;f000:ac5a
HexMathCommandFunction:
    PUSH        AX                                      
    PUSH        CX                                      
    PUSH        DX                                      
    CALL        FUN_f000_bd77 
    JC          LAB_f000_ac8d                           
    MOV         CX,AX                                   
    CALL        FUN_f000_bd77 
    JC          LAB_f000_ac8d                           
    CALL        FUN_f000_bde3 
    CMC                                                  
    JC          LAB_f000_ac8d                           
    MOV         DX,AX                                   
    MOV         SI,s_Sum                               
    CALL        PrintString  
    ADD         AX,CX                                   
    CALL        FUN_f000_beaf 
    MOV         SI,s_Diff                               
    CALL        PrintString
    MOV         AX,CX                                   
    SUB         AX,DX                                   
    CALL        FUN_f000_beaf
    CALL        FUN_f000_bed8
    CLC                                                  
LAB_f000_ac8d:                                    
    POP         DX                                      
    POP         CX                                      
    POP         AX                                      
    RET                   

; ---------------------------------------------------------------------
; InputFromPortCommandFunction 
;
;f000:ac91
InputFromPortCommandFunction:
    PUSH        AX                                      
    PUSH        DX                                      
    CALL        FUN_f000_bd77
    JC          LAB_f000_aca8                           
    CALL        FUN_f000_bde3
    CMC                                                  
    JC          LAB_f000_aca8                           
    MOV         DX,AX                                   
    IN          AL,DX                                   
    CALL        FUN_f000_beb6
    CALL        FUN_f000_bed8
    CLC                                                  
LAB_f000_aca8:                                    
    POP         DX                                      
    POP         AX                                      
    RET                  

; ---------------------------------------------------------------------
; MoveMemoryBlockCommandFunction 
;
;f000:acab
MoveMemoryBlockCommandFunction:
    PUSH        AX                                      
    PUSH        BX                                      
    PUSH        CX                                      
    PUSH        SI                                      
    PUSH        DI                                      
    PUSH        DS                                      
    PUSH        ES                                      
    MOV         AH,0x0                                  
    CALL        FUN_f000_bd1c 
    JC          LAB_f000_acee                           
    PUSH        ES                                      
    PUSH        DI                                      
    CALL        FUN_f000_bd57  
    POP         AX                                      
    POP         DS                                      
    JC          LAB_f000_acee                           
    MOV         SI,AX                                   
    DEC         CX                                      
    MOV         AX,DS                                   
    MOV         BX,ES                                   
    CMP         AX,BX                                   
    JNZ         LAB_f000_acdf                           
    MOV         AX,SI                                   
    ADD         AX,CX                                   
    CMP         SI,DI                                   
    JNC         LAB_f000_acdb                           
    CMP         AX,DI                                   
    JA          LAB_f000_ace4                           
    JMP         LAB_f000_acdf                           
LAB_f000_acdb:                                    
    CMP         AX,DI                                   
    JBE         LAB_f000_ace4                           
LAB_f000_acdf:                                    
    rep movsb                                
    movsb                                
    JMP         LAB_f000_acec                           
LAB_f000_ace4:                                    
    ADD         SI,CX                                   
    ADD         DI,CX                                   
    STD                                                  
    rep movsb                                
    movsb                                
LAB_f000_acec:                                    
    CLD                                                  
    CLC                                                  
LAB_f000_acee:                                    
    POP         ES                                      
    POP         DS                                      
    POP         DI                                      
    POP         SI                                      
    POP         CX                                      
    POP         BX                                      
    POP         AX                                      
    RET                    

; ---------------------------------------------------------------------
; OutputToPortCommandFunction
;
; This is for Command X, whatever that is, it seems to crash on the emulator
; and it's not documented... 
;
;f000:acf6
OutputToPortCommandFunction:
    PUSH        AX                                      
    PUSH        DX                                      
    CALL        FUN_f000_bd77
    JC          LAB_f000_ad0b                           
    MOV         DX,AX                                   
    CALL        FUN_f000_bd77 
    JC          LAB_f000_ad0b                           
    CALL        FUN_f000_bde3 
    CMC                                                  
    JC          LAB_f000_ad0b                           
    OUT         DX,AL                                   
LAB_f000_ad0b:                                    
    POP         DX                                      
    POP         AX                                      
    RET            

; ---------------------------------------------------------------------
; ExamineRegistersCommandFunction
;
;f000:ad0e
ExamineRegistersCommandFunction:
    PUSH        AX                                      
    PUSH        BX                                      
    CALL        FUN_f000_bde3         
    JC          .LAB_f000_ad4b                           
    CALL        FUN_f000_ad6c  
    JC          .LAB_f000_ad69                           
    CALL        FUN_f000_bde3  
    CMC                                                  
    JC          .LAB_f000_ad69                           
    MOV         AH,0x3a                                 
    CALL        FUN_f000_adcd 
    MOV         AL,0x2d                                 
    CALL        PrintCharacter   
    CALL        WaitForCommandToBeEntered  
    MOV         SI,0x0                                  
    CALL        FUN_f000_bde3  
    JC          .ExitNoError                            
    CMP         BX,0x1a                                 
    JNZ         .LAB_f000_ad3f                           
    CALL        FUN_f000_ae2f 
    JMP         .LAB_f000_ad69                           
.LAB_f000_ad3f:                                    
    CALL        FUN_f000_bd77 
    JC          .LAB_f000_ad69                           
    MOV         word SS:[BX + CPUState_AX_0081],AX              
    JMP         .ExitNoError                            
.LAB_f000_ad4b:                                    
    CALL        FUN_f000_ada6                       ; This prints the contents of the registers I think
; CRASH: The data offset differs here: PCjs: MOV      ES,[0091] | Bochs:  mov es, word ptr ss:0x0099!
    MOV         ES,word SS:[MonitorStart_Seg_2_CallerSeg]     ;= ??
    MOV         DI,word SS:[MonitorStart_Off_2_CallerOff]     ;= ??
    MOV         word SS:[MonitorStart_Seg],ES       ;= ??
    MOV         word SS:[MonitorStart_Off],DI       ;= ??
    MOV         CX,0x1   
; CRASH:
; Already diffs are: PCjs: AX=0052 DI=A80C ES=F000 | Bochs: AX=9f52 DI=f000 ES=a80c                              
    CALL        FUN_f000_b1d0                       ;CRASH! This seems to print the current address and dissasembled instruction
.ExitNoError:                                     
    CLC                                                  
.LAB_f000_ad69:                                    
    POP         BX                                      
    POP         AX                                      
    RET            

; ---------------------------------------------------------------------
; FUN_f000_ad6c
;
;f000:ad6c
FUN_f000_ad6c:
    PUSH        AX                                      
    PUSH        CX                                      
    MOV         AX,word SS:[SI + MonitorCommandLineBuffer]             
    CALL        LowerToUpperCaseAZ 
    XCHG        AL,AH                                   
    CALL        LowerToUpperCaseAZ 
    MOV         CX,0xf                                  
    MOV         BX,0x0                                  
LAB_f000_ad81:                                    
    CMP         AH,byte CS:[BX + s_cpu_regs]    ;= "AXBXCXDXSIDIBPSPCSDSSSESIPFLIPCNYC"
    JNZ         LAB_f000_ad8f                           
    CMP         AL,byte CS:[BX + s_cpu_regs]    ;= "XBXCXDXSIDIBPSPCSDSSSESIPFLIPCNYC"
    JZ          LAB_f000_ad97                           
LAB_f000_ad8f:                                    
    ADD         BX,0x2                                  
    LOOP        LAB_f000_ad81                           
    STC                                                  
    JMP         LAB_f000_ada3                           
LAB_f000_ad97:                                    
    CMP         BX,0x1a                                 
    JBE         LAB_f000_ad9f                           
    MOV         BX,0x18                                 
LAB_f000_ad9f:                                    
    ADD         SI,0x2                                  
    CLC                                                  
LAB_f000_ada3:                                    
    POP         CX                                      
    POP         AX                                      
    RET                           

; ---------------------------------------------------------------------
; FUN_f000_ada6
;
; I think this prints the current Address in Memory for Examine Reg
;
;f000:ada6
FUN_f000_ada6:
    PUSH        AX                                      
    PUSH        BX                                      
    PUSH        CX                                      
    MOV         CX,0xe                                  
    MOV         BX,0x0                                  
LAB_f000_adaf:                                    
    MOV         AH,0x3d                                 
    CALL        FUN_f000_adcd   
    MOV         AL,0x20                                 
    CALL        PrintCharacter   
    CMP         CX,0x7                                  
    JNZ         LAB_f000_adc1                           
    CALL        FUN_f000_bed8  
LAB_f000_adc1:                                    
    ADD         BX,0x2                                  
    LOOP        LAB_f000_adaf                           
    CALL        FUN_f000_bed8 
    POP         CX                                      
    POP         BX                                      
    POP         AX                                      
    RET    

; ---------------------------------------------------------------------
; FUN_f000_ae2f
;
;f000:ae2f
FUN_f000_ae2f:
    PUSH        AX                                      
    PUSH        BX                                      
    PUSH        CX                                      
    PUSH        DX                                      
LAB_f000_ae33:                                    
    MOV         CX,0x1                                  
    MOV         DL,0x0                                  
    MOV         BX,0x0                                  
    MOV         AX,word SS:[SI + 0x21a]             
    CALL        LowerToUpperCaseAZ   
    XCHG        AL,AH                                   
    CALL        LowerToUpperCaseAZ  
LAB_f000_ae48:                                    
    CALL        IgnoreLeadingSpacesInCLIBuffer 
    CMP         AX,word CS:[BX + s_cpu_regs_cn]    ;= "CNYC"
    JZ          LAB_f000_ae60                           
    ADD         BX,0x2                                  
    XOR         DL,0x1                                  
    JNZ         LAB_f000_ae48                           
    SHL         CX,1                                    
    JNC         LAB_f000_ae48                           
    JMP         LAB_f000_ae7e                           
LAB_f000_ae60:                                    
    TEST        DL,DL                                   
    JNZ         LAB_f000_ae6d                           
    NOT         CX                                      
    AND         word SS:[CPUState_Flags_009b],CX          ;= ??
    JMP         LAB_f000_ae72                           
LAB_f000_ae6d:                                    
    OR          word SS:[CPUState_Flags_009b],CX          ;= ??
LAB_f000_ae72:                                    
    ADD         SI,0x2                                  
    CALL        IgnoreLeadingSpacesInCLIBuffer 
    CALL        FUN_f000_bde3  
    JNC         LAB_f000_ae33                           
    CLC                                                  
LAB_f000_ae7e:                                    
    POP         DX                                      
    POP         CX                                      
    POP         BX                                      
    POP         AX                                      
    RET   

; ---------------------------------------------------------------------
; SearchMemoryCommandFunction
;
;f000:ae83
SearchMemoryCommandFunction:
    PUSH        AX                                      
    PUSH        BX                                      
    PUSH        CX                                      
    PUSH        DX                                      
    PUSH        DI                                      
    PUSH        ES                                      
    PUSH        DS                                      
    MOV         AH,0x0                                  
    CALL        FUN_f000_bd1c 
    JC          LAB_f000_aec7                           
    PUSH        DI                                      
    MOV         DI,0x1a0                                
    CALL        FUN_f000_bcde
    POP         DI                                      
    JC          LAB_f000_aec7                           
LAB_f000_ae9b:                                    
    PUSH        CS
    POP         DS                                      
    DEC         CX                                      
    MOV         AL,CS:[DAT_f000_01a0]                   ;= ??
    repne scasb                                         ; GHIDRA: SCASB.REPNE ES:DI                                   
    JZ          LAB_f000_aeaa                           
    SCASB       ;ES:DI                                   
    CLC                                                  
    JNZ         LAB_f000_aec7                           
LAB_f000_aeaa:                                    
    MOV         SI,0x1a1                                
    PUSH        DI                                      
    PUSH        CX                                      
    MOV         CX,BX                                   
    DEC         CX                                      
    repe cmpsb                                          ; GHIDRA: CMPSB.REPE  ES:DI,SI                                
    POP         CX                                      
    POP         DI                                      
    JNZ         LAB_f000_aec1                           
    POP         DS                                      
    DEC         DI                                      
    CALL        FUN_f000_be9d 
    CALL        FUN_f000_bed8 
    PUSH        DS                                      
LAB_f000_aec1:                                    
    INC         DI                                      
    TEST        CX,CX                                   
    JNZ         LAB_f000_ae9b                           
    CLC                                                  
LAB_f000_aec7:                                    
    POP         DS                                      
    POP         ES                                      
    POP         DI                                      
    POP         DX                                      
    POP         CX                                      
    POP         BX                                      
    POP         AX                                      
    RET               
; ---------------------------------------------------------------------
; TraceProgramCommandFunction
;
;f000:aecf
TraceProgramCommandFunction:
    MOV         AL,byte SS:[SI + MonitorCommandLineBuffer]             
    CALL        LowerToUpperCaseAZ                      ;undefined LowerToUpperCaseAZ()

    CMP         AL,'E'                                  
    JNZ         .notTESTDoTraceCMD                      
    MOV         AL,byte SS:[SI + 0x21b]             
    CALL        LowerToUpperCaseAZ                      ;undefined LowerToUpperCaseAZ()

    CMP         AL,'S'                                  
    JNZ         .notTESTDoTraceCMD                      
    MOV         AL,byte SS:[SI + 0x21c]             
    CALL        LowerToUpperCaseAZ                      ;undefined LowerToUpperCaseAZ()

    CMP         AL,'T'                                  
    JNZ         .notTESTDoTraceCMD                      
    CALL        TESTCommandFunction                     ;undefined TESTCommandFunction()
    CLC                                                  
    JMP         .exit                                   
.notTESTDoTraceCMD:                               
    CALL        FUN_f000_aefd                           ;undefined FUN_f000_aefd()

.exit:                                            
    RET   

; ---------------------------------------------------------------------
; TraceProgramCommandFunction
;
;f000:aefd
FUN_f000_aefd:
    PUSH        AX                                      
    CALL        FUN_f000_bde3 
    JC          LAB_f000_af20                           
    MOV         ES,word SS:[MonitorStart_Off_2_CallerOff]     ;= ??
    CMP         byte SS:[SI + 0x21a],0x3d           
    JNZ         LAB_f000_af20                           
    INC         SI                                      
    CALL        FUN_f000_bd57   
    JC          LAB_f000_af4a                           
    MOV         word SS:[MonitorStart_Off_2_CallerOff],ES     ;= ??
    MOV         word SS:[MonitorStart_Seg_2_CallerSeg],DI     ;= ??
                            LAB_f000_af20:                                    
    CALL        FUN_f000_bde3          
    MOV         AX,0x1                                  
    JC          LAB_f000_af33                           
    CALL        FUN_f000_bd77          
    JC          LAB_f000_af4a                           
    CALL        FUN_f000_bde3     
    CMC                                                  
    JC          LAB_f000_af4a                           
LAB_f000_af33:                                    
    MOV         SS:[DAT_f000_009e],AX                   ;= ??
    PUSH        DS                                      
    MOV         AX,CS                                   
    MOV         DS,AX                                   
    MOV         SI,0xb0b2                               
    MOV         AL,0x1                                  
    CALL        SetIntHandler  
    POP         DS                                      
    MOV         AH,0xff                                 
    JMP         LAB_f000_ab6f                           
LAB_f000_af4a:                                    
    POP         AX                                      
    RET           

; ---------------------------------------------------------------------
; UnassembleCommandFunction
;
;f000:af4c
UnassembleCommandFunction:
    PUSH        AX                                      
    PUSH        CX                                      
    PUSH        DI                                      
    PUSH        ES                                      
    LES         DI,SS:[MonitorStart_Off]                ;= ??
    MOV         CX,0x20                                 
    CALL        FUN_f000_bde3 
    JC          LAB_f000_af6a                           
    MOV         AH,0xff                                 
    CALL        FUN_f000_bd1c  
    JC          LAB_f000_af7c                           
    CALL        FUN_f000_bde3  
    CMC                                                  
    JC          LAB_f000_af7c                           
LAB_f000_af6a:                                    
    MOV         AX,DI                                   
    ADD         AX,CX                                   
    CALL        FUN_f000_b1d0                       ; UCRASH: This is what prints the instructions
    MOV         word SS:[MonitorStart_Off],DI       ;= ??
    MOV         word SS:[MonitorStart_Seg],ES       ;= ??
    CLC                                                  
LAB_f000_af7c:                                    
    POP         ES                                      
    POP         DI                                      
    POP         CX                                      
    POP         AX                                      
    RET               

; ---------------------------------------------------------------------
; SetVideoScrollCommandFunction
;
;f000:af81
SetVideoScrollCommandFunction:
    PUSH        AX                                      
 LAB_f000_af82:                                    
    CALL        FUN_f000_bdff
    CALL        LowerToUpperCaseAZ 
    CMP         AL,0x4d                                 
    JNZ         LAB_f000_afad                           
    CALL        FUN_f000_bd77
    JC          LAB_f000_afc6                           
    AND         word [equipment_list],0xffcf    ; Clear Bits 4 and 5                 
    OR          word [equipment_list],0x20      ; Sets Bit 4
    CMP         AL,0x7                                 
    JNZ         LAB_f000_afa7                           
    OR          word [equipment_list],0x30                    
LAB_f000_afa7:                                    
    XOR         AH,AH                                   
    INT         0x10                                    
    JMP         LAB_f000_af82                           
LAB_f000_afad:                                    
    CMP         AL,0x53                                 
    JNZ         LAB_f000_afc2                           
    CALL        FUN_f000_bd77 
    JC          LAB_f000_afc6                           
    CMP         AX,0x3                                  
    CMC                                                  
    JC          LAB_f000_afc6                           
    MOV         AH,0x64                                 
    INT         0x10                                    
    JMP         LAB_f000_af82                           
LAB_f000_afc2:                                    
    SUB         AL,0xd                                  
    ADD         AL,0xff                                 
LAB_f000_afc6:                                    
    POP         AX     
    RET     

; ---------------------------------------------------------------------
; CommandX
;
; This is for Command X, whatever that is, it seems to crash on the emulator
; and it's not documented... 
; As it redefines Int 3 and Int 1, this is defo debugging code, maybe just
; for internal development?5
;
;f000:afc8
CommandX:                                    
;     PUSH        AX                                      
;     CALL        FUN_f000_bd77
;     CMP         AX,0x100                                
;     CMC                                                  
;     JC          LAB_f000_b009                           
;     MOV         byte CS:[DAT_f000_026d],0xcd        ;= ??
;     MOV         CS:[DAT_f000_026e],AL                   ;= ??
;     MOV         byte CS:[DAT_f000_026f],0xcc        ;= ??
;     MOV         word CS:[MonitorStart_Seg_2_CallerSeg],0x26d  ;= ??
;     MOV         word CS:[MonitorStart_Off_2_CallerOff],CS     ;= ??
;     PUSH        DS                                      
;     MOV         AX,CS                       ; CS prob F000             
;     MOV         DS,AX                                   
;     MOV         SI,0xb00b                               
;     MOV         AL,0x3                                  
;     CALL        SetIntHandler               ; Set Int 3 to be F000:b00b ; INT 03 - Debugger breakpoint
;     MOV         SI,0xb0b2                               
;     MOV         AL,0x1                                  
;     CALL        SetIntHandler               ; Set Int 1 to be F000:b0b2 ; INT 01 - Single step
;     POP         DS                                      
;     MOV         AH,0x0                                  
;     JMP         LAB_f000_ab6f  
; LAB_f000_b009:
;     POP        AX
    RET

; ---------------------------------------------------------------------
; LAB_f000_b117
;
; Used by the ExecuteGoCommand Interrupt Handling Routine...
;
;f000:b117
LAB_f000_b117:                                    
    MOV         DS,word CS:[BIOS_DataSegment]       ;= ??
    PUSH        CS                       ;= ??
    POP         SS                                      
    MOV         SP,0x338                                
    STI                                                  
    CLD                                                  
    CALL        FUN_f000_ada6 
    MOV         ES,word SS:[MonitorStart_Off_2_CallerOff]     ;= ??
    MOV         DI,word SS:[MonitorStart_Seg_2_CallerSeg]     ;= ??
    MOV         CX,0x1                                  
    CALL        FUN_f000_b1d0 
    CMP         word SS:[DAT_f000_009e],0x0         ;= ??
    JZ          LAB_f000_b145                           
    DEC         word SS:[DAT_f000_009e]             ;= ??
    JNZ         LAB_f000_b148                           
LAB_f000_b145:                                    
    JMP         ColdStartMonitor:WarmStartMonitor      
LAB_f000_b148:                                    
    CALL        FUN_f000_bed8 
    MOV         AH,0xff                                 
    JMP         LAB_f000_ab6f   

; ---------------------------------------------------------------------
; WaitForCommandToBeEntered 
;
;f000:b17b

MonitorCommandDispatchTable:                      
    db        '?'                                     
CMD_Off_PrintCommandSummaryHelpText:              
    dw          PrintCommandSummaryHelp                 
MonitorCommandDispatchTable_B:                    
    db        'B'                                     
    dw          BootCommand
    db        'C'                                     
    dw          PrintColourBars                         
    db        'D'                                     
    dw          DisplayMemoryCommandFunction            
    db        'E'                                     
    dw          ExamineMemoryCommandFunction            
    db        'F'                                     
    dw          FillMemoryCommandFunction               
    db        'G'                                     
    dw          ExecuteGoCommandFunction                
    db        'H'                                     
    dw          HexMathCommandFunction                  
    db        'I'                                     
    dw          InputFromPortCommandFunction            
    db        'M'                                     
    dw          MoveMemoryBlockCommandFunction          
    db        'O'                                     
    dw          OutputToPortCommandFunction             
    db        'R'                                     
    dw          ExamineRegistersCommandFunction         ;undefined ExamineRegistersCommandFunction()
    db        'S'                                     
    dw          SearchMemoryCommandFunction             
    db        'T'                                     
    dw          TraceProgramCommandFunction             
    db        'U'                                     
    dw          UnassembleCommandFunction               
    db        'V'                                     
    dw          SetVideoScrollCommandFunction           
    db        'X'                                     
    dw          CommandX            

; ---------------------------------------------------------------------
; FUN_f000_b1d0 
;
;f000:b1d0
FUN_f000_b1d0:
    PUSH        AX                                      
    PUSH        BX                                      
    PUSH        CX                                      
    PUSH        DX                                      
    PUSH        SI                                      
LAB_f000_b1d5:                                    
    CALL        FUN_f000_be9d
    MOV         AH,0x2                                  
    CALL        DisplaySpaces
    MOV         word SS:[DAT_f000_01cc],ES          ;= ??
    MOV         word SS:[DAT_f000_01ce],DI          ;= ??
    PUSH        ES                                      
    PUSH        DI                                      
    PUSH        CX                                      
    CALL        FUN_f000_b23f                       ; This populates ScratchPad variables with the Dissassembly symbols
    POP         CX                                      
    POP         DI                                      
    POP         ES                                      
    MOV         SI,AX                                   
    MOV         AX,SS:[DAT_f000_01ce]                   ;= ??
    SUB         AX,DI                                   
    MOV         DX,AX                                   
    MOV         BX,AX                                   
    MOV         AL,byte ES:[DI]                     
    PUSH        AX                                      
LAB_f000_b200:                                    
    MOV         AL,byte ES:[DI]                     
    CALL        FUN_f000_beb6 
    INC         DI                                      
    DEC         BX                                      
    JNZ         LAB_f000_b200                           
    MOV         BX,DX                                   
LAB_f000_b20c:                                    
    CMP         BX,0x7                                  
    JGE         LAB_f000_b219                           
    MOV         AH,0x2                                  
    CALL        DisplaySpaces 
    INC         BX                                      
    JMP         LAB_f000_b20c                           
LAB_f000_b219:                                    
    CALL        PrintString_SS                 ; This prints the instruction stored in SI - 1E1h = CLI...
    CALL        FUN_f000_bed8               
    POP         AX                                      
    SUB         CX,DX                                   
    JA          LAB_f000_b1d5                  ; This loops the Dissasembly for the number of lines/opcodes?         
    PUSH        DI                                      
    PUSH        ES                                      
    MOV         DI,CS                                   
    MOV         ES,DI                                   
    MOV         DI,BYTE_f000_f7c1                     ; Hmmm, this look s like a reference...          
    MOV         CX,0x7                                  
    repne scasb
    POP         ES                                      
    POP         DI                                      
    MOV         CX,0x1                                  
    JZ          LAB_f000_b1d5                           
    POP         SI                                      
    POP         DX                                      
    POP         CX                                      
    POP         BX                                      
    POP         AX                                      
    RET     

; ---------------------------------------------------------------------
; FUN_f000_b23f 
;
; This does the dissasebly - sets up all the 01d0+ variables to show the
; various symbols and keeps track of the machine code to decode.
;
;f000:b23f
FUN_f000_b23f:
    MOV         byte SS:[InstructionString_01e1],0x0         ;= ??
    MOV         word SS:[DAT_f000_01d2],s_symbols       ; Hmmm what is this value? I think it's F000:b1bf which points to some ASCII symbol strings
    MOV         word SS:[DAT_f000_01d4],s_symbols       ;= ??
    MOV         SI,word SS:[DAT_f000_01ce]          ; CRASH: At this point ES and DI are vice-versa - PCjs: ES:F000 & DI:A80C 
    INC         word SS:[DAT_f000_01ce]             ;= ??
    MOV         AL,byte ES:[SI]                     ; Ah, if ES and DI are wrong way round, this will do wrong thing... PCjs: AL:FA, Bo:FF! SI also wrong, is F000 in Bo
    XOR         AH,AH                                   
    MOV         SS:[DAT_f000_01d8],AX                   ;= Move current opcode into DAT_f000_01d8
    SHL         AX,1                                    ; 
    SHL         AX,1                                    ; *4 
    MOV         SI,AX                                   
    ADD         SI,DisassemblyLookupTable_Opcodes               ; Hmm is this an address? I think it's a pointer to the top of a table for decoding x86 instructions, the dissasembler...
                                                        ; I think f000:f124 to f000:f7c8 would be enough to try.
;CRASH! PCjs AX=03E8 | Bochs AX=0003!                                                        
    MOV         AX,word CS:[SI]                         ; Load the entry from the table to AX - This should be the Symbol for the Opcode
    MOV         SS:[DAT_f000_01d0],AX                   ; Save that to a variable
    MOV         AX,word CS:[SI + 0x2]                   ; Get the next word from the table - This should be the operands info...
    MOV         SS:[OPCODE_METADATA_01d6],AX                   ; Save that
    CALL        FUN_f000_b308
    CALL        FUN_f000_b38d 
;CRASH!
    CALL        FUN_f000_b3fc                           ; CRASH on 8ED0 "MOV SS,AX"
    CALL        FUN_f000_b5e5 
    MOV         SI,word SS:[DAT_f000_01d0]              ; Restore entry to the lookup table
    MOV         DI,InstructionString_01e1                        ; 
LAB_f000_b293:                                    
    cs lodsb                                            ; CS:SI -> AL : For CLI, SI = F58E
    TEST        AL,0x80                                 
    JNZ         LAB_f000_b29f                           
    MOV         [ss:di],al                              ; GARB_BUG! This should write the Assembly Symbol string to 0x01E1 ie, CLI 
    INC         DI                                      ; Hmm, at this point, the data at  InstructionString_01e1
    JMP         LAB_f000_b293                           
LAB_f000_b29f:                                    
    AND         AL,0x7f                                 
    MOV         [ss:di],al
    MOV         byte [SS:di+0x1],0x9               ;NDISASM: mov byte [cs:di+0x1],0x9; Ghidra: byte CS:[DI + offset DAT_f000_01e2],0x9
    MOV         byte [ss:di+0x2],0x0                 ;= ??
    MOV         DI,InstructionString_01e1                             ; DI,0x1e1   
    MOV         SI,word SS:[DAT_f000_01d4]          ;= ??
    CMP         byte CS:[SI],0x0   ;= ""
    JZ          LAB_f000_b2d8                           
    CMP         byte SS:[DAT_f000_01e0],0x0         ;= ??
    JNZ         LAB_f000_b2d0                           
    TEST        word SS:[OPCODE_METADATA_01d6],0x8000      ;= ??
    JZ          LAB_f000_b2d0                           
    CALL        FUN_f000_b6e2                           ;undefined FUN_f000_b6e2()
LAB_f000_b2d0:                                    
    MOV         SI,word SS:[DAT_f000_01d4]          ;= ??
    CALL        FUN_f000_b768                           ;CRASH!
LAB_f000_b2d8:                                    
    MOV         SI,word SS:[DAT_f000_01d2]          ;= ??
    CMP         byte CS:[SI],0x0                ;= "" THIS Needs to be CS not SS!
    JZ          LAB_f000_b305                           
    MOV         SI,s_symbols_comma                  ; It probably shouldn't get here, opcode meta data wrong?
;CRASH!                        
    CALL        FUN_f000_b768                       ; This adds a comma to the OPcode, it shouldn't be there...
    CMP         byte SS:[DAT_f000_01e0],0x0         ; 
    JNZ         LAB_f000_b2fd                           
    TEST        word SS:[OPCODE_METADATA_01d6],0x8000      ;= ??
    JNZ         LAB_f000_b2fd                           
    CALL        FUN_f000_b6e2                       ; This is then adding the incorrect "BYTE PTR" to the instruction sting
LAB_f000_b2fd:                                    
    MOV         SI,word SS:[DAT_f000_01d2]          ; Hmm, looks bad, SI gets set to 210h which I think is wrong - I wonder if 1D2 is not set correctly? ** 210 is what PCjs is set to so OK I think...
                                                    ; After the following function runs, 1E1... looks a mess...
    CALL        FUN_f000_b768                       ; This does seem to populate the operands with the operand memory address, and on Bochs it fills it with garbage...
                                                    ; 210 and 201 seem to have copies of this address, 201 is a [] and 210 is just the address
                                                    ; AH HA - It's probably printing the string written here - so might needa PRINT_SS like before!!
LAB_f000_b305:                                    
    MOV         AX,DI                                   
    RET    

; ---------------------------------------------------------------------
; FUN_f000_b308
;
;f000:b308
FUN_f000_b308:
    MOV         byte SS:[DAT_f000_01e0],0x0         ;= ??
    MOV         word SS:[DAT_f000_01dc],0x1         ;= ??
    MOV         word SS:[DAT_f000_01de],0x0         ;= ??
    MOV         AX,SS:[OPCODE_METADATA_01d6]                   ;= ??
    AND         AX,0x1c0                                
    CMP         AX,0x1c0                                
    JZ          LAB_f000_b343                           
    CMP         AX,0x180                                
    JZ          LAB_f000_b34a                           
    CMP         AX,0x80                                 
    JZ          LAB_f000_b353                           
    CMP         AX,0xc0                                 
    JZ          LAB_f000_b35c                           
    CMP         AX,0x100                                
    JZ          LAB_f000_b365                           
    CMP         AX,0x140                                
    JZ          LAB_f000_b36e                           
    JMP         LAB_f000_b375                           
LAB_f000_b343:                                    
    MOV         word SS:[DAT_f000_01dc],0x2         ;= ??
LAB_f000_b34a:                                    
    MOV         word SS:[DAT_f000_01d2],s_symbols_1       ;= ??
    JMP         LAB_f000_b375                           
LAB_f000_b353:                                    
    MOV         word SS:[DAT_f000_01dc],0x2         ;= ??
    JMP         LAB_f000_b375                           
LAB_f000_b35c:                                    
    MOV         word SS:[DAT_f000_01dc],0x3         ;= ??
    JMP         LAB_f000_b375                           
LAB_f000_b365:                                    
    MOV         word SS:[DAT_f000_01dc],0x4         ;= ??
    JMP         LAB_f000_b375                           
LAB_f000_b36e:                                    
    MOV         word SS:[DAT_f000_01dc],0x5         ;= ??
LAB_f000_b375:                                    
    CMP         word SS:[DAT_f000_01dc],0x2         ;= ??
    JC          LAB_f000_b38c                           
    CMP         word SS:[DAT_f000_01dc],0x4         ;= ??
    JZ          LAB_f000_b38c                           
    MOV         word SS:[DAT_f000_01de],0x8         ;= ??
LAB_f000_b38c:                                    
    RET            

; ---------------------------------------------------------------------
; FUN_f000_b38d
;
;f000:b38d
FUN_f000_b38d:
    TEST        word SS:[OPCODE_METADATA_01d6],0x2000      ;= ??
    JZ          LAB_f000_b3bb                           
    MOV         byte SS:[DAT_f000_01e0],0x1         ;= ??
    MOV         SI,word SS:[DAT_f000_01de]          ;= ??
    SHL         SI,1                                    
    MOV         AX,word CS:[SI + WORD_f000_f720]            
    TEST        word SS:[OPCODE_METADATA_01d6],0x8000      ;= ??
    JZ          LAB_f000_b3b7                           
    MOV         SS:[DAT_f000_01d4],AX                   ;= ??
    JMP         LAB_f000_b3bb                           
LAB_f000_b3b7:                                    
    MOV         SS:[DAT_f000_01d2],AX                   ;= ??
LAB_f000_b3bb:                                    
    MOV         SI,word SS:[OPCODE_METADATA_01d6]          ;= ??
    AND         SI,0x1f                                 
    JZ          LAB_f000_b3fb                           
    MOV         byte SS:[DAT_f000_01e0],0x1         ;= ??
    DEC         SI                                      
    SHL         SI,1                                    
    MOV         AX,word CS:[SI + WORD_f000_f720]            
    MOV         BX,word SS:[DAT_f000_01d4]          ;= ??
    CMP         byte CS:[BX],0x0                    ; Debugging in PCjs has BX as B1Bf, so I'm going for CS here... It's s_symbols_comma
    JNZ         LAB_f000_b3f1                           
    CMP         word SS:[DAT_f000_01d8],0xd2        ;= ??
    JZ          LAB_f000_b3f1                           
    CMP         word SS:[DAT_f000_01d8],0xd3        ;= ??
    JNZ         LAB_f000_b3f7                           
LAB_f000_b3f1:                                    
    MOV         SS:[DAT_f000_01d2],AX                   ;= ??
    JMP         LAB_f000_b3fb                           
LAB_f000_b3f7:                                    
    MOV         SS:[DAT_f000_01d4],AX                   ;= ??
LAB_f000_b3fb:                                    
    RET                

; ---------------------------------------------------------------------
; FUN_f000_b3fc
;
;f000:b3fc
FUN_f000_b3fc:
    TEST        word SS:[OPCODE_METADATA_01d6],0x1800      ;MOV SS,AX = 90A0: Are Bit 12 AND Bit 11 set? 
    JZ          LAB_f000_b443                       ; No, JUMP
    MOV         SI,word SS:[DAT_f000_01ce]          ;Move current IB to SI
    INC         word SS:[DAT_f000_01ce]             ;Move current Instruction Byte to next
    MOV         AL,byte ES:[SI]                     ; Move D0 to AL
    XOR         AH,AH                               ; AH = 0
    MOV         SS:[OperandByte1_01da],AX               ; Store 00D0 into 1da
    MOV         CL,0x3                                 
    SHR         AX,CL                               ; D0 /2 /2 /2 = 0x1A
    AND         AX,0x7                              ; leave last 3 bits = 0x02
    MOV         BX,AX                               ;BX = 2
    ADD         AX,word SS:[DAT_f000_01de]          ; +[1de] = +0008 = 0xA
    MOV         DX,AX                               ;DX = 0xA    
    MOV         AX,SS:[DAT_f000_01d8]               ;   0x8e    0x00
    AND         AL,0xfe                             ; keep all but bit 0    
    CMP         AL,0xfe                             ; Is it all 1's but bit 0?    
    JNZ         LAB_f000_b443                       ; No, jump
    CMP         BX,0x3                              ; Is BX 3? (not in example...)   
    JZ          LAB_f000_b43c                       ; Yes Jump    
    CMP         BX,0x5                              ; No, is BX 5?   (must be 1,2,4?)?  
    JNZ         LAB_f000_b443                       ; No, Jump    
LAB_f000_b43c:                                    
    MOV         word SS:[DAT_f000_01dc],0x3         ; Put 3 into 1dc?
LAB_f000_b443:                                    
    MOV         BX,word SS:[OPCODE_METADATA_01d6]          ;OPCODE_METADATA_01d6 is Instuction Operand info
    AND         BX,0x1800                           ; Keep bits 12 and 11    
    MOV         CL,0xa                              ; put 10 into CL    
    SHR         BX,CL                               ; Shift Bits 11 and 12 down to 2 and 1 positions    
    JMP         [cs:bx+WORD_f000_b455]              ; What's 0xb455 now? GHIDRA: word CS:[BX + BYTE_f000_b455] 
;f000:b455
; Thi is some kind of branch lookup table, used by (above) "JMP         word CS:[BX + BYTE_f000_b455]"      
WORD_f000_b455:                                   
    dw          LAB_F000_B45D                      ; b12:0, b11:0 - eg, CLI (0), CLD (0) & MOV AX,9F80 (8489h)                                
    dw          LAB_f000_b460                      ; b12:0, b11:1                             
    dw          LAB_f000_b47b                      ; b12:1, b11:0 - MOV SS,AX = 90A0 Should jump here!                                 
    dw          LAB_f000_b4bc                      ; b12:1, b11:1
LAB_F000_B45D:                                                       
    JMP         LAB_f000_b51f   
LAB_f000_b460:                                            
    CALL        FUN_f000_b520 
    MOV         SI,word SS:[DAT_f000_01d4]                              ;= ??
    CMP         byte CS:[SI],0x0                                        ; ROM or RAM / CS or SS?
    JZ          LAB_f000_b474                                               
    MOV         SS:[DAT_f000_01d2],AX                                       ;= ??
    JMP         LAB_f000_b478                                               
LAB_f000_b474:                                    
    MOV         SS:[DAT_f000_01d4],AX                                       ;= ??
LAB_f000_b478:                                    
    JMP         LAB_f000_b51f    
LAB_f000_b47b:                                           
    MOV         byte SS:[DAT_f000_01e0],0x1                             ;This is just before the Instruction String, maybe a flag more to do?
    TEST        word SS:[OPCODE_METADATA_01d6],0x20                            ;Eg, 90A0 test Bit 5 - Yes it's set
    JZ          LAB_f000_b491                                           ; Not 0    
    AND         DX,0x3                                                  ; DX = A, last 2 bits kept = 10    
    ADD         DX,0x10                                                 ; = 12 b10010    
LAB_f000_b491:                                    
    CALL        FUN_f000_b520                                           ; This is where it crashes...
    MOV         SI,DX                                                       
    SHL         SI,1                                                        
    MOV         SI,word CS:[SI + WORD_f000_f720]                            ; Ah, what's this? Ah it's my old dissasembler data init?
    TEST        word SS:[OPCODE_METADATA_01d6],0x8000                          ;= ??
    JZ          LAB_f000_b4b1                                               
    MOV         SS:[DAT_f000_01d2],AX                                       ;= ??
    MOV         word SS:[DAT_f000_01d4],SI                              ;= ??
    JMP         LAB_f000_b4ba                                               
LAB_f000_b4b1:                                    
    MOV         word SS:[DAT_f000_01d2],SI                              ;= ??
    MOV         SS:[DAT_f000_01d4],AX                                       ;= ??
LAB_f000_b4ba:                                    
    JMP         LAB_f000_b51f  
LAB_f000_b4bc:                                             
    MOV         AX,SS:[DAT_f000_01d8]                                       ;= ??
    AND         AX,0xf8                                                     
    CMP         AX,0xd8                                                     
    JNZ         LAB_f000_b4d1                                               
    CALL        FUN_f000_b520 
    MOV         SS:[DAT_f000_01d2],AX                                       ;= ??
    JMP         LAB_f000_b51f                                               
LAB_f000_b4d1:                                    
    MOV         SI,DX                                                       
    AND         SI,0x7                                                      
    MOV         CL,0x3                                                      
    MOV         AX,SS:[DAT_f000_01d0]                                       ;= ??
    SHL         AX,CL                                                       
    ADD         SI,AX                                                       
    SHL         SI,1                                                        
    MOV         SI,word CS:[SI + WORD_f000_f524]                            ; Hmmm this is new, what's 0xf524? Assuming it's f000:f524 in the disassemler data...
    MOV         word SS:[DAT_f000_01d0],SI                              ;= ??
;CRASH!
    CALL        FUN_f000_b520   
    MOV         SI,word SS:[DAT_f000_01d4]                              ;= ??
    CMP         byte CS:[SI],0x0                                        ; ROM or RAM / CS or SS?
    JZ          LAB_f000_b501                                               
    MOV         SS:[DAT_f000_01d2],AX                                       ;= ??
    JMP         LAB_f000_b505                                               
LAB_f000_b501:                                    
    MOV         SS:[DAT_f000_01d4],AX                                       ;= ??
LAB_f000_b505:                                    
    MOV         AX,SS:[DAT_f000_01d8]                                       ;= ??
    AND         AX,0xfe                                                     
    CMP         AX,0xf6                                                     
    JNZ         LAB_f000_b51f                                               
    MOV         AX,DX                                                       
    AND         AX,0x7                                                      
    JNZ         LAB_f000_b51f                                               
    OR          word SS:[OPCODE_METADATA_01d6],0x400                           ;= ??
LAB_f000_b51f:                                    
    RET       

; ---------------------------------------------------------------------
; FUN_f000_b520
;
;f000:b520
FUN_f000_b520:
    PUSH        DX                                                          
    MOV         DI,0x201                                                    
    MOV         DL,0x1                                                      
    MOV         DH,0x1                                                      
    XOR         CH,CH                                                       
    MOV         byte SS:[DAT_f000_0201],0x0                             ; 201 is memoryData
    MOV         BX,word SS:[OperandByte1_01da]                              ; D0 in MOV SS,AX
    AND         BX,0xc0                                                     ; Keep bits 6 & 7 - b7:1 b6:1 = C0
    MOV         CL,0x5                                                      ; Move them down to bits 2 & 1 (ie *2 WORD size)
    SHR         BX,CL                                                       ; D0 = 6
;switchD:                                                    
    JMP         [cs:bx+switchdataD_f000_b542]       ; THIS IS WRONG!!!!!! It jumps to 0f01da word [CS:BX + switchdataD_f000_b542]                                   
switchdataD_f000_b542:                                      
    dw          caseD_0                             ; b7:0 b6:0                          
    dw          caseD_40                            ; b7:0 b6:1  B563h                                                       
    dw          caseD_80                            ; b7:1 b6:0  B56Ch                                                       
    dw          caseD_c0                            ; b7:1 b6:1  Eg, D0 in MOV SS,AX   ;B573h                                                       
caseD_0:                                                    
    MOV         AX,SS:[OperandByte1_01da]                                       ;= ??
    AND         AX,0x7                                                      
    CMP         AX,0x6                                                      
    JNZ         LAB_f000_b55f                                               
    CALL        FUN_f000_b717
    MOV         BX,AX                                                       
    XOR         DL,DL                                                       
    JMP         LAB_f000_b590                                               
LAB_f000_b55f:                                              
    XOR         DH,DH                                                       
    JMP         LAB_f000_b590                                               
caseD_40:                                                   
    MOV         CH,0x1                                                      
    CALL        FUN_f000_b6f5                                               ;undefined FUN_f000_b6f5()
                    
    MOV         BX,AX                                                       
    JMP         LAB_f000_b590                                               
caseD_80:                                                   
    CALL        FUN_f000_b717                                               ;undefined FUN_f000_b717()
                    
    MOV         BX,AX                                                       
    JMP         LAB_f000_b590                                               
caseD_c0:                                                   
    MOV         byte SS:[DAT_f000_01e0],0x1                             ; Keep a 1 in Byte before InsString...
    MOV         SI,word SS:[OperandByte1_01da]                              ; D0 in MOV SS,AX
    AND         SI,0x7                                                  ; Bits 3,2,1 = 0 so this is 0   
    ADD         SI,word SS:[DAT_f000_01de]                              ;= +0008 in MOV SS,AX
    SHL         SI,1                                                    ; 0x8 * 2 = 0x10
    MOV         AX,word CS:[SI + WORD_f000_f720]                        ; = s_AX_f000_f6fc "AX"        
    JMP         LAB_f000_b5e3                                               
LAB_f000_b590:                                              
    TEST        DL,DL                                                       
    JZ          LAB_f000_b5a6                                               
    MOV         SI,word SS:[OperandByte1_01da]                              ;= ??
    AND         SI,0x7                                                      
    SHL         SI,1                                                        
    MOV         SI,word CS:[SI + WORD_f000_f7b1]                                
    JMP         LAB_f000_b5a9                                               
LAB_f000_b5a6:                                              
    MOV         SI,s_symbols_lsqbr                                                   
LAB_f000_b5a9:                                              
    CALL        FUN_f000_b768
    TEST        DH,DH                                                       
    JZ          LAB_f000_b5db                                               
    TEST        CH,CH                                                       
    JZ          LAB_f000_b5cc                                               
    TEST        BX,BX                                                       
    JGE         LAB_f000_b5bf                                               
    MOV         SI,s_symbols_minus                                                   
    NEG         BX                                                          
    JMP         LAB_f000_b5c2                                               
LAB_f000_b5bf:                                              
    MOV         SI,s_symbols_plus                                                   
LAB_f000_b5c2:                                              
    CALL        FUN_f000_b768  
    MOV         AX,BX                                                       
    CALL        ByteToHexString 
    JMP         LAB_f000_b5db                                               
LAB_f000_b5cc:                                              
    TEST        DL,DL                                                       
    JZ          LAB_f000_b5d6                                               
    MOV         SI,s_symbols_plus                                                   
    CALL        FUN_f000_b768                                               ;undefined FUN_f000_b768()
LAB_f000_b5d6:                                              
    MOV         AX,BX                                                       
    CALL        WordToHexString                                               ;undefined WordToHexString()
LAB_f000_b5db:                                              
    MOV         SI,s_symbols_rsqbr                                                   
    CALL        FUN_f000_b768  
    MOV         AX,DI                                                       
LAB_f000_b5e3:                                              
    POP         DX                                                          
    RET                                                                      


; ---------------------------------------------------------------------
; FUN_f000_b5e5
;
;f000:b5e5
FUN_f000_b5e5:
    MOV         DI,0x210                                                    
    MOV         AX,0x2                                                      
    TEST        word SS:[OPCODE_METADATA_01d6],0x200                           ;= ??
    JNZ         LAB_f000_b5f8                                               
    MOV         AX,SS:[DAT_f000_01dc]                                       ;= ??
LAB_f000_b5f8:                                              
    MOV         DX,AX                                                       
    MOV         byte SS:[DAT_f000_0210],0x0                             ;
    MOV         AX,SS:[DAT_f000_01d8]                                       ;=
    AND         AX,0xf8                                                     
    CMP         AX,0xd8                                                     
    JNZ         LAB_f000_b632                                               
    MOV         AX,SS:[DAT_f000_01d8]                                       ;= ??
    AND         AX,0x7                                                      
    MOV         CL,0x3                                                      
    SHL         AX,CL                                                       
    MOV         BX,word SS:[OperandByte1_01da]                              ;= ??
    AND         BX,0x38                                                     
    SHR         BX,CL                                                       
    ADD         AX,BX                                                       
    CALL        ByteToHexString 
    MOV         SI,s_symbols_H                                                 ; 0xb1cc ROM/RAM? REF!
    CALL        FUN_f000_b768 
    MOV         word SS:[DAT_f000_01d4],DI                              ;= ??
LAB_f000_b632:                                              
    TEST        word SS:[OPCODE_METADATA_01d6],0x600                           ;= ??
    JNZ         LAB_f000_b63e                                               
    JMP         LAB_f000_b6e1                                               
LAB_f000_b63e:                                              
    MOV         SI,DX                                                       
    CMP         SI,0x5                                                      
    JG          LAB_f000_b64c                                               
    SHL         SI,1                                                        
    JMP         [cs:si + WORD_f000_b64f]                             ; I think this is the code below... 0xb64f, GHIDRA word CS:[SI + WORD_f000_b64f]      
LAB_f000_b64c:                                              
    JMP         LAB_f000_b6ca                                               
    NOP                                                                      
WORD_f000_b64f:                                             
    dw          LAB_f000_b6ca                                               
    dw          LAB_f000_b65b                                               
    dw          LAB_f000_b664                                               
    dw          LAB_f000_b68a                                               
    dw          LAB_f000_b6ca                                               
    dw          LAB_f000_b6a2                                               
LAB_f000_b65b:                                              
    CALL        FUN_f000_b6f5 
    CALL        ByteToHexString 
    JMP         LAB_f000_b6ca                                               
    NOP                                                                      
LAB_f000_b664:                                              
    TEST        word SS:[OPCODE_METADATA_01d6],0x200                           ;= ??
    JZ          LAB_f000_b673                                               
    MOV         SI,s_symbols_lsqbr                                                   
    CALL        FUN_f000_b768                                               ;undefined FUN_f000_b768()
LAB_f000_b673:                                              
    CALL        FUN_f000_b717                                           ; This should set AX with the Hex Value Operand in AX, but it doesn't set to 0000...
    CALL        WordToHexString                                         ; This is called with AX=0000 which is wrong...
    TEST        word SS:[OPCODE_METADATA_01d6],0x200                           ;= ??
    JZ          LAB_f000_b688                                               
    MOV         SI,s_symbols_rsqbr                                               ;0xb1ca WHAT's this again? 
    CALL        FUN_f000_b768                                               ;undefined FUN_f000_b768()
LAB_f000_b688:                                              
    JMP         LAB_f000_b6ca                                               
LAB_f000_b68a:                                              
    CALL        FUN_f000_b717 
    MOV         BX,AX                                                       
    CALL        FUN_f000_b717
    CALL        WordToHexString
    MOV         SI,s_symbols_colon                                                   
    CALL        FUN_f000_b768
    MOV         AX,BX                                                       
    CALL        WordToHexString
    JMP         LAB_f000_b6ca                                               
LAB_f000_b6a2:                                              
    TEST        word SS:[OPCODE_METADATA_01d6],0x4000                          ;= ??
    JZ          LAB_f000_b6b3                                               
    CALL        FUN_f000_b6f5
    CALL        WordToHexString 
    JMP         LAB_f000_b6ca                                               
LAB_f000_b6b3:                                              
    CALL        FUN_f000_b6f5
    TEST        AX,AX                                                       
    MOV         SI,s_symbols_plus                                                   
    JGE         LAB_f000_b6c2                                               
    MOV         SI,s_symbols_minus                                                   
    NEG         AX                                                          
LAB_f000_b6c2:                                              
    PUSH        AX                                                          
    CALL        FUN_f000_b768 
    POP         AX                                                          
    CALL        ByteToHexString                                               ;undefined FUN_f000_b742()
LAB_f000_b6ca:                                              
    MOV         SI,word SS:[DAT_f000_01d4]                              ;= ??
    CMP         byte [cs:si],0x0                                        ; ROM or RAM / CS or SS?
    JZ          LAB_f000_b6dc                                               
    MOV         word SS:[DAT_f000_01d2],DI                              ;= ??
    JMP         LAB_f000_b6e1                                               
LAB_f000_b6dc:                                              
    MOV         word SS:[DAT_f000_01d4],DI                              ;= ??
LAB_f000_b6e1:                                              
    RET                                                                      

; ---------------------------------------------------------------------
; FUN_f000_b6e2
;
;f000:b6e2
FUN_f000_b6e2:
    MOV         SI,word SS:[DAT_f000_01dc]          ;= ??
    SHL         SI,1                                    
    MOV         SI,word CS:[SI + WORD_f000_f779]            
    MOV         DI,InstructionString_01e1                                
    CALL        FUN_f000_b768 
    RET    

; ---------------------------------------------------------------------
; FUN_f000_b6f5
;
;f000:b6f5
FUN_f000_b6f5:
    MOV        SI,word SS:[DAT_f000_01ce]
    MOV        ES,word SS:[DAT_f000_01cc] 
    MOV        AL,byte ES:[SI]                              ; ROM or RAM / CS or SS?
    INC        word SS:[DAT_f000_01ce]
    CBW
    TEST       word SS:[OPCODE_METADATA_01d6],0x4000 
    JZ         LAB_f000_b716
    ADD        AX,word SS:[DAT_f000_01ce]
LAB_f000_b716:
    RET

; ---------------------------------------------------------------------
; FUN_f000_b717
;
; This sets up AX to have the Operand Hex Number in it. It might check other things too, don't know...
;
;f000:b717
FUN_f000_b717:
    MOV        SI,word SS:[DAT_f000_01ce]
    MOV        ES,word SS:[DAT_f000_01cc]
    ES LODSW                                           ; ES! THIS should set AX to 809F but it doesn't... Didn't fix it...
    MOV        word SS:[DAT_f000_01ce],SI
    TEST       word SS:[OPCODE_METADATA_01d6],0x4000
    JZ         LAB_f000_b736                        ; Hmmm, this seems to be wrong
    ADD        AX,word SS:[DAT_f000_01ce]           ; This should be set to 6336
LAB_f000_b736:
    RET

; ---------------------------------------------------------------------
; WordToHexString (formerly FUN_f000_b737)
;
;f000:b737
WordToHexString:
    PUSH       AX
    MOV        AL,AH
    CALL       ByteToHexString
    POP        AX
    CALL       ByteToHexString
    RET


; ---------------------------------------------------------------------
; ByteToHexString (GHIDRA: FUN_f000_b742)
;
; This is a convert AL to a Hex number and stores in in memory location
; SI : This is the location of the Hex Characters string
; DI : The memory address of the string to add the hex characters to
; AX : The character to print /16 SHR by 4 - Upper Nibble = Lower Nibble
;
;f000:b742
ByteToHexString:
    PUSH        SI                                      
    PUSH        DI                                      
    CALL        FUN_f000_b778
    XOR         AH,AH                                   
    MOV         SI,AX                                   
    MOV         CL,0x4                                  
    SHR         SI,CL                                   
    MOV         CL,byte CS:[SI + s_HexCharacters]            ;
    MOV         byte SS:[DI],CL                              ; Hmm I think this shoudl be SS as it's moving the Hext Operand to 210...
    INC         DI                                      
    AND         AX,0xf                                  
    MOV         SI,AX                                   
    MOV         AL,byte CS:[SI + s_HexCharacters]            
    MOV         word SS:[DI],AX                     ; ROM or RAM / CS or SS?
    POP         DI                                      
    POP         SI                                      
    RET     

; ---------------------------------------------------------------------
; FUN_f000_b768
;
;
;
;f000:b768
FUN_f000_b768:
    PUSH        DI   
    PUSH        ES                                  
    CALL        FUN_f000_b778 
    CMP         SI, 0x210           ; Is this an immediate value?
    JA          .set_ES_to_CS       ; No, skip
    PUSH        SS
    POP         ES
    JMP         LAB_f000_b76c
.set_ES_to_CS:
    PUSH        CS
    POP         ES
LAB_f000_b76c:                                    
    ES lodsb                                   ; IS THIS A PROBLEM? - Sometimes this routine loads a ROM String, and someimtes a Scratchpad address
                                               ; So it needs to sometimes be SS and sometimes CS... Just need a simple Check and Jump I guess, lets try setting this to SS and see if it changes things...
                                               ; ROM or RAM, CS or SS? - Load byte at address DS:(E)SI into AL.
                                               ; In Bochs, 210h seems to be empty, but it should have the Hex operand value... WHere is it set?
                                               ; Yes defo a problem, need to be able to switch this if 201 or 210...
    MOV         byte SS:[DI],AL                 ; ROM or RAM, CS or SS?    
    INC         DI                                      
    TEST        AL,AL                                   
    JNZ         LAB_f000_b76c    
    POP         ES                       
    POP         DI                                      
    RET           

; ---------------------------------------------------------------------
; FUN_f000_b778
;
;f000:b778
FUN_f000_b778:
    CMP         byte SS:[DI],0x0                    ; ROM or RAM / CS or DS?
    JZ          LAB_f000_b781                           
    INC         DI                                      
    JMP         FUN_f000_b778                           ;undefined FUN_f000_b778()
LAB_f000_b781:                                    
    RET     

; ---------------------------------------------------------------------
; TESTCommandFunction
;
;f000:b782
TESTCommandFunction:
    PUSH        AX                                      
    PUSH        BX                                      
    PUSH        CX                                      
    PUSH        DX                                      
    PUSH        SI                                      
    PUSH        BP                                      
    PUSH        ES                                      
    MOV         CL,byte [video_mode]                      
    MOV         CH,byte SS:[DAT_f000_0004]          ;= ??
    CALL        FUN_f000_8630  
    MOV         AL,0x0                                  
    CALL        FUN_f000_9c4e  
    MOV         BX,0xb800                               
    MOV         AL,[0x10]                               
    AND         AL,0x30                                 
    CMP         AL,0x30                                 
    JNZ         LAB_f000_b7a9                           
    MOV         BX,0xb000                               
LAB_f000_b7a9:                                    
    MOV         ES,BX                                   
LAB_f000_b7ab:                                    
    CALL        ClearMDAandCGAVideo
    MOV         DX,0x0                                  
    MOV         BP,DX                                   
    MOV         SI,s_Choose_TESTMenu                               
    CALL        PrintStringAtPos 
LAB_f000_b7b9:                                    
    CALL        ReturnLastKeyPressASCIICode    
    CMP         AL,'1'                                  
    JNC         LAB_f000_b7c5                           
    CALL        ErrorBeep                              ;undefined ErrorBeep()
    JMP         LAB_f000_b7b9                           
LAB_f000_b7c5:                                    
    CMP         AL,'6'                                  
    JC          LAB_f000_b7ce                           
    CALL        ErrorBeep                              ;undefined ErrorBeep()
    JMP         LAB_f000_b7b9                           
LAB_f000_b7ce:                                    
    CALL        FUN_f000_85c9                           ;undefined FUN_f000_85c9()
    CMP         AL,'5'                                  
    JZ          .exitTESTMenu                           
    SUB         AL,0x31                                 
    MOV         BH,0x0                                  
    MOV         BL,AL                                   
    SHL         BX,1                                    
    CALL        word [CS:BX + TEST_MenuCommandLoopupTable]  ;I think it converts the ASCII number to Decimal and then does another comman...
    JMP         LAB_f000_b7ab                           
.exitTESTMenu:                                    
    MOV         AL,CL                                   
    XOR         AH,AH                                   
    INT         0x10                                    
    MOV         AL,CH                                   
    CALL        FUN_f000_9c4e                           ;undefined FUN_f000_9c4e()
    POP         ES                                      
    POP         BP                                      
    POP         SI                                      
    POP         DX                                      
    POP         CX                                      
    POP         BX                                      
    POP         AX                                      
    RET        

TEST_MenuCommandLoopupTable:
    dw          TESTDiskCommandFunction                 
    dw          TESTKeyboardCommandFunction             
    dw          TESTMemoryCommandFunction               
    dw          TESTPowerUpCommandFunction ; Maybe leave this out as might need to implement half the z150 BIOS just for the tests?

; ---------------------------------------------------------------------
; TESTDiskCommandFunction
;
;f000:b7f7
TESTKeyboardCommandFunction:
    RET                  

; ---------------------------------------------------------------------
; TESTMemoryCommandFunction
;
;f000:b8c8
TESTMemoryCommandFunction:
    RET

; ---------------------------------------------------------------------
; TESTDiskCommandFunction
;
;f000:bbe3
TESTDiskCommandFunction:
;     PUSH        AX                                      
;     PUSH        BX                                      
;     PUSH        SI                                      
;     MOV         BP,0x0                                  
;     CALL        ClearMDAandCGAVideo  
;     MOV         BX,0x0                                  
;     CALL        SetupScreenTESTMemory                   ;undefined SetupScreenTESTMemory()
; LAB_f000_bbf2:                                    
;     CALL        FUN_f000_b8ad                           ;undefined FUN_f000_b8ad()
; LAB_f000_bbf5:                                    
;     MOV         DL,byte ptr CS:[DAT_f000_0057]          ;= ??
;     CALL        FUN_f000_8f2a 
;     JNC         LAB_f000_bbf2                           
;     TEST        AH,AH                                   
;     JZ          LAB_f000_bc0e                           
;     MOV         DX,0x100                                
;     MOV         SI,0xffc1                               
;     CALL        PrintStringAtPos 
;     JMP         LAB_f000_bbf5                           
; LAB_f000_bc0e:                                    
;     CALL        FUN_f000_b850 
;     CALL        FUN_f000_bc18 
;     POP         SI                                      
;     POP         BX                                      
;     POP         AX                                      
    RET         

; ---------------------------------------------------------------------
; TESTPowerUpCommandFunction
;
;f000:bc28
TESTPowerUpCommandFunction:
    RET



; ---------------------------------------------------------------------
; FUN_f000_bcde
;
;f000:bcde
FUN_f000_bcde:
    PUSH        AX                                      
    MOV         BX,0x0                                  
    CALL        FUN_f000_bde3 
    JC          LAB_f000_bd1a                           
LAB_f000_bce7:                                    
    CMP         byte SS:[SI + MonitorCommandLineBuffer],0x22           
    JNZ         LAB_f000_bd05                           
    INC         SI                                      
LAB_f000_bcf0:                                    
    MOV         AL,byte SS:[SI + MonitorCommandLineBuffer]             
    INC         SI                                      
    CMP         AL,0xd                                  
    STC                                                  
    JZ          LAB_f000_bd1a                           
    CMP         AL,0x22                                 
    JZ          LAB_f000_bd0e                           
    MOV         byte SS:[BX + DI],AL                
    INC         BX                                      
    JMP         LAB_f000_bcf0                           
LAB_f000_bd05:                                    
    CALL        FUN_f000_bd77 
    JC          LAB_f000_bd1a                           
    MOV         byte SS:[BX + DI],AL                
    INC         BX                                      
LAB_f000_bd0e:                                    
    CALL        FUN_f000_bdca 
    CMP         byte SS:[SI + MonitorCommandLineBuffer],0xd            
    JNZ         LAB_f000_bce7                           
    CLC                                                  
LAB_f000_bd1a:                                    
    POP         AX                                      
    RET        

; ---------------------------------------------------------------------
; FUN_f000_bd1c
;
;f000:bd1c
FUN_f000_bd1c:
    PUSH        AX                                      
    PUSH        AX                                      
    CALL        FUN_f000_bd57               ; CRASH!
    POP         AX                                      
    JC          LAB_f000_bd55                           
    MOV         AL,byte SS:[SI + MonitorCommandLineBuffer]             
    CMP         AL,0xd                                  
    JNZ         LAB_f000_bd34                           
    TEST        AH,AH                                   
    JNZ         LAB_f000_bd51                           
    STC                                                  
    JMP         LAB_f000_bd55                           
LAB_f000_bd34:                                    
    CALL        LowerToUpperCaseAZ
    CMP         AL,0x4c                                 
    JNZ         LAB_f000_bd45                           
    INC         SI                                      
    CALL        FUN_f000_bd77 
    JC          LAB_f000_bd55                           
    MOV         CX,AX                                   
    JMP         LAB_f000_bd51                           
LAB_f000_bd45:                                    
    CALL        FUN_f000_bd77
    CMP         AX,DI                                   
    JC          LAB_f000_bd55                           
    MOV         CX,AX                                   
    SUB         CX,DI                                   
    INC         CX                                      
LAB_f000_bd51:                                    
    CLC                                                  
    CALL        FUN_f000_bdca
LAB_f000_bd55:                                    
    POP         AX                                      
    RET              

; ---------------------------------------------------------------------
; FUN_f000_bd57
;
;f000:bd57
FUN_f000_bd57:
    PUSH        AX                                      
    CALL        FUN_f000_bd77                   ;CRASH!       
    JC          LAB_f000_bd72                           
    MOV         DI,AX                                   
    CMP         byte SS:[SI + MonitorCommandLineBuffer],0x3a           
    CLC                                                  
    JNZ         LAB_f000_bd72                           
    INC         SI                                      
    MOV         ES,DI                                   
    CALL        FUN_f000_bd77                      
    JC          LAB_f000_bd75                           
    MOV         DI,AX                                   
LAB_f000_bd72:                                    
    CALL        FUN_f000_bdca                 
LAB_f000_bd75:                                    
    POP         AX                                      
    RET                  

; ---------------------------------------------------------------------
; FUN_f000_bd77
;
;f000:bd77
FUN_f000_bd77:
    PUSH        BX                                      
    PUSH        DX                                      
    CALL        FUN_f000_bde3                           
    JC          LAB_f000_bdc7                           
    CALL        FUN_f000_ad6c                         
    JC          LAB_f000_bd8a                           
    MOV         DX,word CS:[BX + 0x81]              
    JMP         LAB_f000_bdc1                           
LAB_f000_bd8a:                                    
    MOV         DX,0x0                                  
    CALL        FUN_f000_bdff               ; CRASH!
LAB_f000_bd90:                                    
    CALL        LowerToUpperCaseAZ           
    CALL        FUN_f000_be5b                   
    JC          LAB_f000_bdc7                           
    SHL         DX,1                                    
    SHL         DX,1                                    
    SHL         DX,1                                    
    SHL         DX,1                                    
    OR          DL,AL                                   
    MOV         AL,byte SS:[SI + MonitorCommandLineBuffer]             
    CALL        LowerToUpperCaseAZ                 
    CMP         AL,0x20                                 
    JZ          LAB_f000_bdc1                           
    CMP         AL,0x2c                                 
    JZ          LAB_f000_bdc1                           
    CMP         AL,0x3a                                 
    JZ          LAB_f000_bdc1                           
    CMP         AL,0x4c                                 
    JZ          LAB_f000_bdc1                           
    CMP         AL,0xd                                  
    JZ          LAB_f000_bdc1                           
    INC         SI                                      
    JMP         LAB_f000_bd90                           
LAB_f000_bdc1:                                    
    MOV         AX,DX                                   
    CLC                                                  
    CALL        FUN_f000_bdca                      
LAB_f000_bdc7:                                    
    POP         DX                                      
    POP         BX                                      
    RET                    

; ---------------------------------------------------------------------
; FUN_f000_bdca 
;
;f000:bdca
FUN_f000_bdca:
    PUSHF                                                
    PUSH        AX                                      
    CALL        IgnoreLeadingSpacesInCLIBuffer
    MOV         AL,byte SS:[SI + MonitorCommandLineBuffer]             
    CMP         AL,0x2c                                 
    JZ          LAB_f000_bddc                           
    CMP         AL,0x2d                                 
    JNZ         LAB_f000_bddd                           
LAB_f000_bddc:                                    
    INC         SI                                      
LAB_f000_bddd:                                    
    CALL        IgnoreLeadingSpacesInCLIBuffer 
    POP         AX                                      
    POPF                                                 
    RET      

; ---------------------------------------------------------------------
; FUN_f000_bde3 
;
; Used By:
; - DisplayMemoryCommandFunction
; - ExamineMemoryCommandFunction
; - ExecuteGoCommandFunction
; - HexMathCommandFunction
; - InputFromPortCommandFunction
; - OutputToPortCommandFunctio
; - ExamineRegistersCommandFunction
; - UnassembleCommandFunction
;
;f000:bde3
FUN_f000_bde3:
    PUSH        AX                                      
    CALL        IgnoreLeadingSpacesInCLIBuffer 
    MOV         AL,byte SS:[SI + MonitorCommandLineBuffer]             
    SUB         AL,0xd                                  
    ADD         AL,0xff                                 
    CMC                                                  
    POP         AX                                      
    RET           

; ---------------------------------------------------------------------
; IgnoreLeadingSpacesInCLIBuffer 
;
; I think it moves SI to the first non-space character in the command line buffer
;
;f000:bdf3
IgnoreLeadingSpacesInCLIBuffer:
    CMP         byte SS:[SI + MonitorCommandLineBuffer],0x20               ;F000:021A = 0x20
    JNZ         .return                                 
    INC         SI                                      
    JMP         IgnoreLeadingSpacesInCLIBuffer 
.return:                                          
    RET         

; ---------------------------------------------------------------------
; FUN_f000_bdff 
;
;f000:bdff
FUN_f000_bdff:
    CALL        IgnoreLeadingSpacesInCLIBuffer
    MOV         AL,byte SS:[SI + MonitorCommandLineBuffer]             
    INC         SI                                      
    RET                    

; ---------------------------------------------------------------------
; WaitForCommandToBeEntered 
;
;f000:be09
WaitForCommandToBeEntered:
    PUSH        AX                                      
    PUSH        CX                                      
    PUSH        DX                                      
    PUSH        DI                                      
    CALL        PrintVerticalTab                        ;undefined PrintVerticalTab() 
    MOV         byte SS:[CLICursorColPosition],DL       ;1stboot:DL=9D (0x81 + 28)                                                     ;F026B is read into AL later in Monitor CLI...
    MOV         DI,0                                    
WaitForNextKeyPress:                              
    CALL        ReturnLastKeyPressASCIICode             ;Hopping over this in PCjr, only Reg that changed was: AL:00 -> AL:FF
;Handle Backspace (delete character from Monitor CLI)
    CMP         AL,0x8                                  ;backspace \b
    JNZ         LAB_f000_be2f                           
    CALL        PrintVerticalTab                        ;undefined PrintVerticalTab()
    CMP         DL,byte  SS:[CLICursorColPosition]   ;Checking that the character is at the start of the line maybe?
    JBE         WaitForNextKeyPress                     
    CALL        FUN_f000_becf                           ;undefined FUN_f000_becf()
    DEC         DI                                      ;Move it back a space?
    JMP         WaitForNextKeyPress                     
LAB_f000_be2f:                                    
    CMP         AL,0xd                                  ;0xd = \r Why CR? Is this the enter key - ie go to the next line?
    JNZ         LAB_f000_be3d                           
    MOV         byte  SS:[DI + MonitorCommandLineBuffer],AL
    CALL        FUN_f000_bed8                           ;undefined FUN_f000_bed8()
    JMP         LAB_f000_be56                           
LAB_f000_be3d:                                    
    CMP         AL,0x20                                 ;Space - make a space in the editor
    JNC         LAB_f000_be46                           
LAB_f000_be41:                                    
    CALL        ErrorBeep                               ;undefined ErrorBeep()
    JMP         WaitForNextKeyPress                     
LAB_f000_be46:                                    
    CMP         DI,0x50                                 ;Command Line buffer is full - only 80 characters.
    JNC         LAB_f000_be41                           
    MOV         byte SS:[DI + MonitorCommandLineBuffer],AL                 ;= ??
    INC         DI                                      
    CALL        PrintCharacter                          ;Show the character typed if it's visible (ie, not a CR/BS).
    JMP         WaitForNextKeyPress                     
LAB_f000_be56:                                    
    POP         DI                                      
    POP         DX                                      
    POP         CX                                      
    POP         AX                                      
    RET    

; ---------------------------------------------------------------------
; FUN_f000_be5b 
;
;f000:be5b
FUN_f000_be5b:
    PUSH        BX                                      
    MOV         BL,AL                                   
    SUB         AL,0x30                                 
    JC          LAB_f000_be72                           
    CMP         AL,0xa                                  
    CMC                                                  
    JNC         LAB_f000_be74                           
    CMP         AL,0x11                                 
    JC          LAB_f000_be72                           
    SUB         AL,0x7                                  
    CMP         AL,0x10                                 
    CMC                                                  
    JNC         LAB_f000_be74                           
LAB_f000_be72:                                    
    MOV         AL,BL                                   
LAB_f000_be74:                                    
    POP         BX                                      
    RET                         

; ---------------------------------------------------------------------
; PrintVerticalTab 
;
;f000:be80
PrintVerticalTab:
    PUSH        BX                                      
    MOV         BH,byte  [0x62]                      
    CALL        FUN_f000_9e08                           
    POP         BX                                      
    RET   

; ---------------------------------------------------------------------
; PrintDecimal 
; Pretty sure this is a Print Dec function.
;
;f000:be80
PrintDecimal:
    PUSH        AX                                      
    PUSH        CX                                      
    PUSH        DX                                      
    MOV         DX,0x0                                  
    MOV         CX,0xa                                  
    DIV         CX                                      ;Unsigned divide DX:AX by r/m16, with result stored in AX = Quotient, DX = Re...
    TEST        AX,AX                                   
    JZ          .localJump                           
    CALL        PrintDecimal                            
.localJump:                                    
    MOV         AX,DX                                   
    ADD         AL,0x30                                 
    CALL        PrintCharacter                          
    POP         DX                                      
    POP         CX                                      
    POP         AX                                      
    RET                          

; ---------------------------------------------------------------------
; FUN_f000_be9d 
;
;f000:be9d
FUN_f000_be9d:
    PUSH        AX                                      
    MOV         AX,ES                                   
    CALL        FUN_f000_beaf
    MOV         AL,0x3a                                 
    CALL        PrintCharacter                          ;undefined PrintCharacter(void)
    MOV         AX,DI                                   
    CALL        FUN_f000_beaf
    POP         AX                                      
    RET          

; ---------------------------------------------------------------------
; FUN_f000_beb6 
;
;  Falls through to FUN_f000_beb6
;
;f000:beaf
FUN_f000_beaf:
    PUSH        AX                                      
    MOV         AL,AH                                   
    CALL        FUN_f000_beb6
    POP         AX   

; ---------------------------------------------------------------------
; FUN_f000_beb6 
;
;f000:beb6
FUN_f000_beb6:
    PUSH        AX                                      
    PUSH        CX                                      
    MOV         CL,0x4                                  
    SHR         AL,CL                                   
    POP         CX                                      
    CALL        FUN_f000_bec1
    POP         AX                                      
FUN_f000_bec1:
    AND         AL,0xf                                  
    ADD         AL,0x30                                 
    CMP         AL,0x39                                 
    JBE         LAB_f000_becb                           
    ADD         AL,0x7                                  
LAB_f000_becb:                                    
    CALL        PrintCharacter  
    RET   

; ---------------------------------------------------------------------
; FUN_f000_bed8 
; Used by PrintColourBars & WaitForCommandToBeEntered
;
;f000:bed8
FUN_f000_bed8:
    PUSH        AX                                      
    PUSH        SI                                      
    CALL        FUN_f000_bfdd                           ;undefined FUN_f000_bfdd()
    JZ          LAB_f000_bef6                           
    CMP         AL,0x13                                 
    JNZ         LAB_f000_bef6                           
    CALL        ReturnLastKeyPressASCIICode             ;undefined ReturnLastKeyPressASCIICode()
    CALL        ReturnLastKeyPressASCIICode             ;undefined ReturnLastKeyPressASCIICode()
    CMP         AX,0x0                                  
    JZ          LAB_f000_bf17                           
    CMP         AL,0x1b                                 
    JZ          LAB_f000_bf17                           
    CMP         AL,0x3                                  
    JZ          LAB_f000_bf17                           
LAB_f000_bef6:                                    
    TEST        byte [0x17],0x10                    
    JNZ         LAB_f000_bef6                           
    MOV         SI,s_CRLF                               
    CALL        PrintString                             ;undefined PrintString()
    CALL        FUN_f000_bfdd                           ;undefined FUN_f000_bfdd()
    JZ          LAB_f000_bf25                           
    CMP         AX,0x0                                  
    JZ          LAB_f000_bf1f                           
    CMP         AL,0x1b                                 
    JZ          LAB_f000_bf1f                           
    CMP         AL,0x3                                  
    JNZ         LAB_f000_bf25                           
    JMP         LAB_f000_bf1f                           
LAB_f000_bf17:                                    
    MOV         SI,s_CRLF                               
    CALL        PrintString                             ;undefined PrintString()
    JMP         LAB_f000_bf22                           
LAB_f000_bf1f:                                    
    CALL        ReturnLastKeyPressASCIICode             ;undefined ReturnLastKeyPressASCIICode()
LAB_f000_bf22:                                    
    JMP         ColdStartMonitor:WarmStartMonitor      
LAB_f000_bf25:                                    
    POP         SI                                      
    POP         AX                                      
    RET     

; ---------------------------------------------------------------------
; FUN_f000_becf 
;
;f000:becf
FUN_f000_becf:
    PUSH        SI                                      
    MOV         SI,s_bs_space_bs                               
    CALL        PrintString
    POP         SI                                      
    RET        

; ---------------------------------------------------------------------
; PrintString_SS 
;
;new
PrintString_SS:
    PUSH        AX                                      
    PUSH        SI                                      
.nextCharacter:                                   
    MOV         AL,byte  SS:[SI]                     
    INC         SI                                      
    TEST        AL,AL                                   
    JZ          .exit                           
    CALL        PrintCharacter
    JMP         .nextCharacter                          
.exit:                                    
    POP         SI                                      
    POP         AX                                      
    RET     

; ---------------------------------------------------------------------
; PrintString 
;
;f000:bf28
PrintString:
    PUSH        AX                                      
    PUSH        SI                                      
.nextCharacter:                                   
    MOV         AL,byte  CS:[SI]                     
    INC         SI                                      
    TEST        AL,AL                                   
    JZ          .exit                           
    CALL        PrintCharacter
    JMP         .nextCharacter                          
.exit:                                    
    POP         SI                                      
    POP         AX                                      
    RET     

; ---------------------------------------------------------------------
; FUN_f000_bf3a 
;
;f000:bf3a
FUN_f000_bf3a:
    PUSH        AX                                      
    PUSH        CX                                      
    PUSH        DX                                      
    CALL        PrintVerticalTab
    SUB         AH,DL                                   
    CALL        DisplaySpaces 
    POP         DX                                      
    POP         CX                                      
    POP         AX                                      
    RET                           

; ---------------------------------------------------------------------
; DisplaySpaces 
;
;f000:bf49
DisplaySpaces:
    PUSH        AX                                      
.NextSpace:                                       
    MOV         AL,0x20                                 
    CALL        PrintCharacter                          
    DEC         AH                                      
    JNZ         .NextSpace                              
    POP         AX                                      
    RET                                

; ---------------------------------------------------------------------
; PrintCharacter 
;
;f000:bf28
PrintCharacter:
    PUSH        AX                                      
    PUSH        BX                                      
    PUSH        CX                                      
    PUSH        DX                                      
    TEST        AL,AL                                   
    JZ          .exit                                   
    CMP         AL,0x9                                  
    JNZ         .callInt10                           
    CALL        PrintVerticalTab                        
    MOV         AH,DL                                   
    AND         AH,0xf8                                 
    ADD         AH,0x8                                  
    SUB         AH,DL                                   
    CALL        DisplaySpaces                          
    JMP         .exit                                   
.callInt10:                                    
    MOV         AH,0xe                                  
    MOV         BL,0x7                                  
    INT         0x10                                    
 .exit:                                            
    POP         DX                                      
    POP         CX                                      
    POP         BX                                      
    POP         AX                                      
    RET                
;f000:bf7e
s_bs_space_bs:
    db          0x8, ' ', 0x8, 0x00     ; "\b \b"
s_CRLF:                                           
    db          0xd, 0xa, 0x00          ; "\r\n"

; ---------------------------------------------------------------------
; ReturnLastKeyPressASCIICode 
;
;f000:bfd3
ReturnLastKeyPressASCIICode:
    CALL        GetNewKeystroke                        ;Check For Keystroke?
    CALL        FUN_f000_c0b1                           ;undefined FUN_f000_c0b1()
    JC          ReturnLastKeyPressASCIICode             
    STC                                                 ;Set Carry Flag
    RET        

; ---------------------------------------------------------------------
; FUN_f000_bfdd 
;
;f000:bfdd
FUN_f000_bfdd:
    CALL        ReturnLastKeystoke                      ;undefined ReturnLastKeystoke()
    JZ          LAB_f000_bfef                           
    PUSHF                                                
    CALL        FUN_f000_c0b1                           ;undefined FUN_f000_c0b1()
    JNC         LAB_f000_bfee                           
    POPF                                                 
    CALL        GetNewKeystroke                        ;undefined GetNewKeystroke?()
    JMP         FUN_f000_bfdd                           ;undefined FUN_f000_bfdd()
LAB_f000_bfee:                                    
    POPF                                                 
LAB_f000_bfef:                                    
    RET     



; ---------------------------------------------------------------------
; GetNewKeystroke 
;
;f000:c047
GetNewKeystroke:
    PUSH        SI                                      
    CALL        ReturnLastKeystoke                      ;Zero flag set if no new keystroke
    JNZ         .newKeyStroke                           
;This the where the CLI waits for a key to be pressed...
.waitForKeystroke:                                
    CLI                                                  ;Interrupts: OFF
    CALL        ReturnLastKeystoke                       ; Zero Flag set if no new keystroke in buffer
    JNZ         .newKeyStroke                            ;
    STI                                                  ;Interrupts: ON
    NOP                                                  
    JMP         .waitForKeystroke                       
.newKeyStroke:                                    
    CLI                                                  ;Key scancode seems to be in AH?
    MOV         SI,word [kbd_buffer_head]           
    PUSHF                                                
    INC         SI                                     
    INC         SI                                      
    POPF                                                 
    CALL        WrapKeyboardBuffer                      ;If SI is beyond the buffer, wrap it back to the start
    MOV         word [kbd_buffer_head],SI           
    STI                                                  
    POP         SI                                      
    RET  

; ---------------------------------------------------------------------
; ReturnLastKeystoke 
;
; Zero Flag is set if no new key press in buffer
; Added BP to push/POP and used that to 
;
;f000:c06a 
ReturnLastKeystoke:
    PUSH        BX                                      
    PUSH        SI                                      
    PUSH        ES                                       
    CLI                                                  
    MOV         ES,word CS:[BIOS_DataSegment]       ;ES this should get set to the start of the keyboard buffer?
    MOV         SI,word [kbd_buffer_head]           ;SI = keyboard buffer head offset
    CMP         SI,word [kbd_buffer_tail]           ;Set Zero Flag if head = tail (as there is nothing in the buffer?)
    MOV         AX,word ES:[SI]                     ;Return the 'head' character from the keyboard buffer
    STI                                                  
    CLC                                               
    POP         ES                                      
    POP         SI                                      
    POP         BX                                      
    RET                                       

; ---------------------------------------------------------------------
; FUN_f000_c0b1
; Haven't figured out what this is yet - Scancode to ASCII Conversion? 
; Decode Extended keys or Modifiers, like Ctrl?
;
;f000:c0b1 
FUN_f000_c0b1:
    PUSH        BX                                      
    MOV         BX,AX                                   ;2 Byte scan code into BX
    CMP         BH,0xe0                                 ;If High is E0 then it's an extended key?
    JNZ         LAB_f000_c0c9                           ; Not Extended, try the next thing
    MOV         BH,0x1C                                 ; Set High Byte to 1C
    CMP         BL,0xa                                  
    JZ          LAB_f000_c0e7                           
    CMP         BL,0xd                                  
    JZ          LAB_f000_c0e7                           
    MOV         BH,0x35                                 ; High Bytes to 35?                   
    JMP         LAB_f000_c0e7                           
LAB_f000_c0c9:                                    
    CMP         BH,0x84                                 ; JA jumps if CF = 0 and ZF = 0 (unsigned Above: no carry and not equal)
    JA          LAB_f000_c0d8                           ; Is the high byte > 0x84?
    CMP         BL,0xf0                                 ; No, is Low Byte F0?
    JNZ         LAB_f000_c0db                           ; No, 
    CMP         BH,0x0                                  ; Is the High Bytes 0?
    JZ          LAB_f000_c0e7                           ; Yes, quit
LAB_f000_c0d8:                                    
    STC                                                  
    JMP         LAB_f000_c0e8                           
LAB_f000_c0db:                                    
    CMP         BL,0xe0                                 
    JNZ         LAB_f000_c0e7                           
    CMP         BH,0x0                                  
    JZ          LAB_f000_c0e7                           
    MOV         BL,0x0                                  ; Set Low Byte to 0x0?
LAB_f000_c0e7:                                    
    CLC                                                  
LAB_f000_c0e8:                                    
    MOV         AX,BX                                   ; Put BX back into AX
    POP         BX                                      
    RET                        

; ---------------------------------------------------------------------
; WrapKeyboardBuffer 
;
;f000:c5e8 
WrapKeyboardBuffer:
    CMP         SI,word [kbd_buffer_end]            
    JC          .exit                                   
    MOV         SI,word [kbd_buffer_start]          
.exit:                                            
    RET        

; ---------------------------------------------------------------------
; Used By FUN_f000_9d03 
;
;f000:e7e5 
DAT_f000_e7e5:
    db      07h
    db      07h
    db      03h
    db      03h
    db      00h
    db      00h
    db      00h
    db      00h


; ---------------------------------------------------------------------
; ErrorBeep 
;
;f000:e845 
ErrorBeep:
    PUSH        CX                                      
    MOV         CX,0xa6                                 
    CALL        FUN_f000_e857                           ;undefined FUN_f000_e857()
    POP         CX                                      
    RET   

; ---------------------------------------------------------------------
; FUN_f000_e857 
;
; Make a beep probably...
;
;f000:e857 
FUN_f000_e857:
    PUSH        AX                                      
    PUSH        CX                                      
    MOV         AL,0xb6                                 
    OUT         pit_ctl_reg,AL                          
    MOV         AL,0x80                                 
    OUT         pit_ch2_reg,AL                          
    MOV         AL,0x6                                  
    OUT         pit_ch2_reg,AL                          
    IN          AL,ppi_pb_reg                           
    PUSH        AX                                      
    OR          AL,0x3                                  
    OUT         ppi_pb_reg,AL                           
    CALL        FUN_f000_e875                           ;Bet this is a delay function...
    POP         AX                                      
    OUT         ppi_pb_reg,AL                           
    POP         CX                                      
    POP         AX                                      
    RET                

; ---------------------------------------------------------------------
; FUN_f000_e875 
;
; Probably a delay function...
;
;f000:e875 
FUN_f000_e875:
    PUSH        AX                                      
    PUSH        CX                                      
    PUSH        DX                                      
    MOV         DX,0xf8                                 
    IN          AL,0x62                                 
    AND         AL,10000000b                            
    JZ          LAB_f000_e884                           
    MOV         DX,0x19d                                
LAB_f000_e884:                                    
    PUSH        CX                                      
    MOV         CX,DX                                   
LAB_f000_e887:                                    
    LOOP        LAB_f000_e887                           
    POP         CX                                      
    LOOP        LAB_f000_e884                           
    POP         DX                                      
    POP         CX                                      
    POP         AX                                      
    RET                     

; ---------------------------------------------------------------------
; FUN_f000_e890 
;
;f000:e890 
FUN_f000_e890:
    PUSH        AX                                      
    MOV         AH,0x0                                  
    SHL         AX,1                                    
    SHL         AX,1                                    
    MOV         SI,0x0                                  
    MOV         DS,SI                                   
    MOV         SI,AX                                   
    LDS         SI,[SI]                                 
    POP         AX                                      
    RET     

; ---------------------------------------------------------------------
; SetIntHandler 
;
; This appears to be code to set Interrupt Vectors
; DS: Int Handler segment
; SI: Int Handler offset
; AL: Interupt
; Nothing returned, all regs restored
;
;f000:e8a2 
SetIntHandler:
    PUSH        AX                                      
    PUSH        DI                                      
    PUSH        ES                                      
    MOV         AH,0x0                           ; Top nibble to 0       
    SHL         AX,1                             ; Shift left twice (*4)
    SHL         AX,1                                    
    MOV         DI,0x0                           ; DI:0       
    MOV         ES,DI                            ; ES:0       
    MOV         DI,AX                            ; Set DI to AL *4       
    MOV         word ES:[DI],SI                  ; Put SI into 0000:AL*4   
    MOV         word ES:[DI + 0x2],DS            ; Put DS into 0000:AL*2 + 2   
    POP         ES                                      
    POP         DI                                      
    POP         AX                                      
    RET          

;f000:ef53
CGA_Video_RAM_Seg       dw  0xB800  

;f000:ef55
MDA_VideoRAM_Seg        dw  0xB000

;f000:e99c
%include "strings.inc"

; Used By FUN_f000_85f0:f000:85f8(*) 
;f000:eeeb 
DAT_f000_eeeb:
    db        0x00
    db        0x00
    db        0xA0
    db        0x00
    db        0x40
    db        0x01
    db        0xE0
    db        0x01
    db        0x80
    db        0x02
    db        0x20
    db        0x03
    db        0xC0
    db        0x03
    db        0x60
    db        0x04
    db        0x00
    db        0x05
    db        0xA0
    db        0x05
    db        0x40
    db        0x06
    db        0xE0
    db        0x06
    db        0x80
    db        0x07
    db        0x20
    db        0x08
    db        0xC0
    db        0x08
    db        0x60
    db        0x09
    db        0x00
    db        0x0A
    db        0xA0
    db        0x0A
    db        0x40
    db        0x0B
    db        0xE0
    db        0x0B
    db        0x80
    db        0x0C
    db        0x20
    db        0x0D
    db        0xC0
    db        0x0D
    db        0x60
    db        0x0E
    db        0x00
    db        0x0F
    db        0xA0
    db        0x0F
    db        0x40
    db        0x10
    db        0xE0
    db        0x10
    db        0x80
    db        0x11
    db        0x20
    db        0x12
    db        0xC0
    db        0x12
    db        0x60
    db        0x13
    db        0x00
    db        0x14
    db        0xA0
    db        0x14
    db        0x40
    db        0x15
    db        0xE0
    db        0x15
    db        0x80
    db        0x16
    db        0x20
    db        0x17
    db        0xC0
    db        0x17
    db        0x60
    db        0x18
    db        0x00
    db        0x19
    db        0xA0
    db        0x19
    db        0x40
    db        0x1A
    db        0xE0
    db        0x1A
    db        0x80
    db        0x1B
    db        0x20
    db        0x1C
    db        0xC0
    db        0x1C
    db        0x60
    db        0x1D
    db        0x00
    db        0x1E
    db        0xA0
    db        0x1E
    db        0x40
    db        0x1F
    db        0xE0
    db        0x1F

; This is the look up table for all x86 opcodes.
;  It also includes the details of the Operands to expect also,
;  ie '11h' is 'ES', but I don't know how this is coded yet,
;  not sure I care...

; This is a good Opcode Map:
; https://pastraiser.com/cpu/i8088/i8088_opcodes.html
; The table follows that order.

;f000:f124
DisassemblyLookupTable_Opcodes:                             
    dw          CHAR_A_f000_f576                                            ;= 'A'
    dw          1040h                                                       
    dw          CHAR_A_f000_f576                                            ;= 'A'
    dw          1080h                                                       
    dw          CHAR_A_f000_f576                                            ;= 'A'
    dw          9040h                                                       
    dw          CHAR_A_f000_f576                                            ;= 'A'
    dw          9080h                                                       
    dw          CHAR_A_f000_f576                                            ;= 'A'
    dw           0A440h                                                       
    dw          CHAR_A_f000_f576                                            ;= 'A'
    dw           0A480h                                                       
    dw          CHAR_P_f000_f660                                            ;= 'P'
    dw          11h                                                         ;I bet this is the code for ES as opcode 6h is PUSH ES
    dw          CHAR_P_f000_f659                                            ;= 'P'
    dw          11h                                                         
    dw          CHAR_O_f000_f654                                            ;= 'O'
    dw          1040h                                                       
    dw          CHAR_O_f000_f654                                            ;= 'O'
    dw          1080h                                                       
    dw          CHAR_O_f000_f654                                            ;= 'O'
    dw          9040h                                                       
    dw          CHAR_O_f000_f654                                            ;= 'O'
    dw          9080h                                                       
    dw          CHAR_O_f000_f654                                            ;= 'O'
    dw           0A440h                                                       
    dw          CHAR_O_f000_f654                                            ;= 'O'
    dw           0A480h                                                       
    dw          CHAR_P_f000_f660                                            ;= 'P'
    dw          12h                                                         
    dw          CHAR_?_f000_f564                                            ;This is undocumented 8086 instruction 0x0F POP CS, reuse...
    dw          0h                                                          
    dw          CHAR_A_f000_f573                                            ;= 'A'
    dw          1040h                                                       
    dw          CHAR_A_f000_f573                                            ;= 'A'
    dw          1080h                                                       
    dw          CHAR_A_f000_f573                                            ;= 'A'
    dw          9040h                                                       
    dw          CHAR_A_f000_f573                                            ;= 'A'
    dw          9080h                                                       
    dw          CHAR_A_f000_f573                                            ;= 'A'
    dw           0A440h                                                       
    dw          CHAR_A_f000_f573                                            ;= 'A'
    dw           0A480h                                                       
    dw          CHAR_P_f000_f660                                            ;= 'P'
    dw          13h                                                         
    dw          CHAR_P_f000_f659                                            ;= 'P'
    dw          13h                                                         
    dw          CHAR_S_f000_f68c                                            ;= 'S'
    dw          1040h                                                       
    dw          CHAR_S_f000_f68c                                            ;= 'S'
    dw          1080h                                                       
    dw          CHAR_S_f000_f68c                                            ;= 'S'
    dw          9040h                                                       
    dw          CHAR_S_f000_f68c                                            ;= 'S'
    dw          9080h                                                       
    dw          CHAR_S_f000_f68c                                            ;= 'S'
    dw           0A440h                                                       
    dw          CHAR_S_f000_f68c                                            ;= 'S'
    dw           0A480h                                                       
    dw          CHAR_P_f000_f660                                            ;= 'P'
    dw          14h                                                         
    dw          CHAR_P_f000_f659                                            ;= 'P'
    dw          14h                                                         
    dw          CHAR_A_f000_f579                                            ;= 'A'
    dw          1040h                                                       
    dw          CHAR_A_f000_f579                                            ;= 'A'
    dw          1080h                                                       
    dw          CHAR_A_f000_f579                                            ;= 'A'
    dw          9040h                                                       
    dw          CHAR_A_f000_f579                                            ;= 'A'
    dw          9080h                                                       
    dw          CHAR_A_f000_f579                                            ;= 'A'
    dw           0A440h                                                       
    dw          CHAR_A_f000_f579                                            ;= 'A'
    dw           0A480h                                                       
    dw          CHAR_E_f000_f699                                            ;= 'E'
    dw          0h                                                          
    dw          CHAR_D_f000_f5a4                                            ;= 'D'
    dw          0h                                                          
    dw          CHAR_S_f000_f6be                                            ;= 'S'
    dw          1040h                                                       
    dw          CHAR_S_f000_f6be                                            ;= 'S'
    dw          1080h                                                       
    dw          CHAR_S_f000_f6be                                            ;= 'S'
    dw          9040h                                                       
    dw          CHAR_S_f000_f6be                                            ;= 'S'
    dw          9080h                                                       
    dw          CHAR_S_f000_f6be                                            ;= 'S'
    dw           0A440h                                                       
    dw          CHAR_S_f000_f6be                                            ;= 'S'
    dw           0A480h                                                       
    dw          CHAR_C_f000_f69c                                            ;= 'C'
    dw          0h                                                          
    dw          CHAR_D_f000_f5a7                                            ;= 'D'
    dw          0h                                                          
    dw          CHAR_X_f000_f6e1                                            ;= 'X'
    dw          1040h                                                       
    dw          CHAR_X_f000_f6e1                                            ;= 'X'
    dw          1080h                                                       
    dw          CHAR_X_f000_f6e1                                            ;= 'X'
    dw          9040h                                                       
    dw          CHAR_X_f000_f6e1                                            ;= 'X'
    dw          9080h                                                       
    dw          CHAR_X_f000_f6e1                                            ;= 'X'
    dw           0A440h                                                       
    dw          CHAR_X_f000_f6e1                                            ;= 'X'
    dw           0A480h                                                       
    dw          CHAR_S_f000_f69f                                            ;= 'S'
    dw          0h                                                          
    dw          CHAR_A_f000_f567                                            ;= 'A'
    dw          0h                                                          
    dw          CHAR_C_f000_f594                                            ;= 'C'
    dw          1040h                                                       
    dw          CHAR_C_f000_f594                                            ;= 'C'
    dw          1080h                                                       
    dw          CHAR_C_f000_f594                                            ;= 'C'
    dw          9040h                                                       
    dw          CHAR_C_f000_f594                                            ;= 'C'
    dw          9080h                                                       
    dw          CHAR_C_f000_f594                                            ;= 'C'
    dw           0A440h                                                       
    dw          CHAR_C_f000_f594                                            ;= 'C'
    dw           0A480h                                                       
    dw          CHAR_D_f000_f6a2                                            ;= 'D'
    dw          0h                                                          
    dw          CHAR_A_f000_f570                                            ;= 'A'
    dw          0h                                                          
    dw          CHAR_I_f000_f5c0                                            ;= 'I'
    dw          9h                                                          
    dw          CHAR_I_f000_f5c0                                            ;= 'I'
    dw           0Ah                                                          
    dw          CHAR_I_f000_f5c0                                            ;= 'I'
    dw           0Bh                                                          
    dw          CHAR_I_f000_f5c0                                            ;= 'I'
    dw           0Ch                                                          
    dw          CHAR_I_f000_f5c0                                            ;= 'I'
    dw           0Dh                                                          
    dw          CHAR_I_f000_f5c0                                            ;= 'I'
    dw           0Eh                                                          
    dw          CHAR_I_f000_f5c0                                            ;= 'I'
    dw           0Fh                                                          
    dw          CHAR_I_f000_f5c0                                            ;= 'I'
    dw          10h                                                         
    dw          CHAR_D_f000_f5aa                                            ;= 'D'
    dw          9h                                                          
    dw          CHAR_D_f000_f5aa                                            ;= 'D'
    dw           0Ah                                                          
    dw          CHAR_D_f000_f5aa                                            ;= 'D'
    dw           0Bh                                                          
    dw          CHAR_D_f000_f5aa                                            ;= 'D'
    dw           0Ch                                                          
    dw          CHAR_D_f000_f5aa                                            ;= 'D'
    dw           0Dh                                                          
    dw          CHAR_D_f000_f5aa                                            ;= 'D'
    dw           0Eh                                                          
    dw          CHAR_D_f000_f5aa                                            ;= 'D'
    dw           0Fh                                                          
    dw          CHAR_D_f000_f5aa                                            ;= 'D'
    dw          10h                                                         
    dw          CHAR_P_f000_f660                                            ;= 'P'
    dw          9h                                                          
    dw          CHAR_P_f000_f660                                            ;= 'P'
    dw           0Ah                                                          
    dw          CHAR_P_f000_f660                                            ;= 'P'
    dw           0Bh                                                          
    dw          CHAR_P_f000_f660                                            ;= 'P'
    dw           0Ch                                                          
    dw          CHAR_P_f000_f660                                            ;= 'P'
    dw           0Dh                                                          
    dw          CHAR_P_f000_f660                                            ;= 'P'
    dw           0Eh                                                          
    dw          CHAR_P_f000_f660                                            ;= 'P'
    dw           0Fh                                                          
    dw          CHAR_P_f000_f660                                            ;= 'P'
    dw          10h                                                         
    dw          CHAR_P_f000_f659                                            ;= 'P'
    dw          9h                                                          
    dw          CHAR_P_f000_f659                                            ;= 'P'
    dw           0Ah                                                          
    dw          CHAR_P_f000_f659                                            ;= 'P'
    dw           0Bh                                                          
    dw          CHAR_P_f000_f659                                            ;= 'P'
    dw           0Ch                                                          
    dw          CHAR_P_f000_f659                                            ;= 'P'
    dw           0Dh                                                          
    dw          CHAR_P_f000_f659                                            ;= 'P'
    dw           0Eh                                                          
    dw          CHAR_P_f000_f659                                            ;= 'P'
    dw           0Fh                                                          
    dw          CHAR_P_f000_f659                                            ;= 'P'
    dw          10h                                                         
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_J_f000_f608                                            ;= 'J'
    dw          4540h                                                       
    dw          CHAR_J_f000_f5ff                                            ;= 'J'
    dw          4540h                                                       
    dw          CHAR_J_f000_f5dd                                            ;= 'J'
    dw          4540h                                                       
    dw          CHAR_J_f000_f5da                                            ;= 'J'
    dw          4540h                                                       
    dw          CHAR_J_f000_f60f                                            ;= 'J'
    dw          4540h                                                       
    dw          CHAR_J_f000_f5fc                                            ;= 'J'
    dw          4540h                                                       
    dw          CHAR_J_f000_f5df                                            ;= 'J'
    dw          4540h                                                       
    dw          CHAR_J_f000_f5d8                                            ;= 'J'
    dw          4540h                                                       
    dw          CHAR_J_f000_f60d                                            ;= 'J'
    dw          4540h                                                       
    dw          CHAR_J_f000_f602                                            ;= 'J'
    dw          4540h                                                       
    dw          CHAR_J_f000_f60a                                            ;= 'J'
    dw          4540h                                                       
    dw          CHAR_J_f000_f605                                            ;= 'J'
    dw          4540h                                                       
    dw          CHAR_J_f000_f5ed                                            ;= 'J'
    dw          4540h                                                       
    dw          CHAR_J_f000_f5ea                                            ;= 'J'
    dw          4540h                                                       
    dw          CHAR_J_f000_f5ef                                            ;= 'J'
    dw          4540h                                                       
    dw          CHAR_J_f000_f5e8                                            ;= 'J'
    dw          4540h                                                       
    dw          0h                                                          
    dw          9C40h                                                       
    dw          0h                                                          
    dw          9C80h                                                       
    dw          0h                                                          
    dw          9C40h                                                       
    dw          0h                                                          
    dw          9D40h                                                       
    dw          CHAR_T_f000_f6c1                                            ;= 'T'
    dw          1040h                                                       
    dw          CHAR_T_f000_f6c1                                            ;= 'T'
    dw          1080h                                                       
    dw          CHAR_X_f000_f6c9                                            ;= 'X'
    dw          1040h                                                       
    dw          CHAR_X_f000_f6c9                                            ;= 'X'
    dw          1080h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          1040h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          1080h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          9040h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          9080h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          10A0h                                                       
    dw          CHAR_L_f000_f618                                            ;= 'L'
    dw          1080h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          90A0h                                                       
    dw          CHAR_P_f000_f659                                            ;= 'P'
    dw          880h                                                        
    dw          CHAR_N_f000_f64e                                            ;= 'N'
    dw          0h                                                          
    dw          CHAR_X_f000_f6c9                                            ;= 'X'
    dw           0A08Ah                                                       
    dw          CHAR_X_f000_f6c9                                            ;= 'X'
    dw           0A08Bh                                                       
    dw          CHAR_X_f000_f6c9                                            ;= 'X'
    dw           0A08Ch                                                       
    dw          CHAR_X_f000_f6c9                                            ;= 'X'
    dw           0A08Dh                                                       
    dw          CHAR_X_f000_f6c9                                            ;= 'X'
    dw           0A08Eh                                                       
    dw          CHAR_X_f000_f6c9                                            ;= 'X'
    dw           0A08Fh                                                       
    dw          CHAR_X_f000_f6c9                                            ;= 'X'
    dw           0A090h                                                       
    dw          CHAR_C_f000_f585                                            ;= 'C'
    dw          0h                                                          
    dw          CHAR_C_f000_f5a1                                            ;= 'C'
    dw          0h                                                          
    dw          CHAR_C_f000_f580                                            ;= 'C'
    dw          4C0h                                                        
    dw          CHAR_W_f000_f6c5                                            ;= 'W'
    dw          0h                                                          
    dw          CHAR_P_f000_f664                                            ;= 'P'
    dw          0h                                                          
    dw          CHAR_P_f000_f65c                                            ;= 'P'
    dw          0h                                                          
    dw          CHAR_S_f000_f685                                            ;= 'S'
    dw          0h                                                          
    dw          CHAR_L_f000_f611                                            ;= 'L'
    dw          0h                                                          
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw           0A240h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw           0A280h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          2240h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          2280h                                                       
    dw          CHAR_M_f000_f63e                                            ;= 'M'
    dw          0h                                                          
    dw          CHAR_M_f000_f643                                            ;= 'M'
    dw          0h                                                          
    dw          CHAR_C_f000_f597                                            ;= 'C'
    dw          0h                                                          
    dw          CHAR_C_f000_f59c                                            ;= 'C'
    dw          0h                                                          
    dw          CHAR_T_f000_f6c1                                            ;= 'T'
    dw           0A440h                                                       
    dw          CHAR_T_f000_f6c1                                            ;= 'T'
    dw           0A480h                                                       
    dw          CHAR_S_f000_f6b4                                            ;= 'S'
    dw          0h                                                          
    dw          CHAR_S_f000_f6b9                                            ;= 'S'
    dw          0h                                                          
    dw          CHAR_L_f000_f622                                            ;= 'L'
    dw          0h                                                          
    dw          CHAR_L_f000_f627                                            ;= 'L'
    dw          0h                                                          
    dw          CHAR_S_f000_f68f                                            ;= 'S'
    dw          0h                                                          
    dw          CHAR_S_f000_f694                                            ;= 'S'
    dw          0h                                                          
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          8441h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          8442h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          8443h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          8444h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          8445h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          8446h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          8447h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          8448h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          8489h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          848Ah                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          848Bh                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          848Ch                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          848Dh                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          848Eh                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          848Fh                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          8490h                                                       
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_R_f000_f678                                            ;= 'R'
    dw          480h                                                        
    dw          CHAR_R_f000_f678                                            ;= 'R'
    dw          0h                                                          
    dw          CHAR_L_f000_f61b                                            ;= 'L'
    dw          90C0h                                                       
    dw          CHAR_L_f000_f615                                            ;= 'L'
    dw          90C0h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          8C40h                                                       
    dw          CHAR_M_f000_f63b                                            ;= 'M'
    dw          8C80h                                                       
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_R_f000_f67b                                            ;= 'R'
    dw          480h                                                        
    dw          CHAR_R_f000_f67b                                            ;= 'R'
    dw          0h                                                          
    dw          CHAR_I_f000_f5c6                                            ;= 'I'
    dw          0h                                                          
    dw          CHAR_I_f000_f5c3                                            ;= 'I'
    dw          440h                                                        
    dw          CHAR_I_f000_f5d0                                            ;= 'I'
    dw          0h                                                          
    dw          CHAR_I_f000_f5d4                                            ;= 'I'
    dw          0h                                                          
    dw          1h                                                          
    dw          1980h                                                       
    dw          1h                                                          
    dw          19C0h                                                       
    dw          1h                                                          
    dw          9842h                                                       
    dw          1h                                                          
    dw          9882h                                                       
    dw          CHAR_A_f000_f56d                                            ;= 'A'
    dw          440h                                                        
    dw          CHAR_A_f000_f56a                                            ;= 'A'
    dw          440h                                                        
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_X_f000_f6cd                                            ;= 'X'
    dw          0h                                                          
    dw          CHAR_E_f000_f5b0                                            ;= 'E'
    dw          1900h                                                       
    dw          CHAR_E_f000_f5b0                                            ;= 'E'
    dw          1900h                                                       
    dw          CHAR_E_f000_f5b0                                            ;= 'E'
    dw          1900h                                                       
    dw          CHAR_E_f000_f5b0                                            ;= 'E'
    dw          1900h                                                       
    dw          CHAR_E_f000_f5b0                                            ;= 'E'
    dw          1900h                                                       
    dw          CHAR_E_f000_f5b0                                            ;= 'E'
    dw          1900h                                                       
    dw          CHAR_E_f000_f5b0                                            ;= 'E'
    dw          1900h                                                       
    dw          CHAR_E_f000_f5b0                                            ;= 'E'
    dw          1900h                                                       
    dw          CHAR_L_f000_f635                                            ;= 'L'
    dw          4540h                                                       
    dw          CHAR_L_f000_f630                                            ;= 'L'
    dw          4540h                                                       
    dw          CHAR_L_f000_f62c                                            ;= 'L'
    dw          4540h                                                       
    dw          CHAR_J_f000_f5e4                                            ;= 'J'
    dw          4540h                                                       
    dw          CHAR_I_f000_f5be                                            ;= 'I'
    dw           0A440h                                                       
    dw          CHAR_I_f000_f5be                                            ;= 'I'
    dw           0A480h                                                       
    dw          CHAR_O_f000_f656                                            ;= 'O'
    dw          2440h                                                       
    dw          CHAR_O_f000_f656                                            ;= 'O'
    dw          2480h                                                       
    dw          CHAR_C_f000_f57c                                            ;= 'C'
    dw          4480h                                                       
    dw          CHAR_J_f000_f5f2                                            ;= 'J'
    dw          4480h                                                       
    dw          CHAR_J_f000_f5f5                                            ;= 'J'
    dw          4C0h                                                        
    dw          CHAR_J_f000_f5f2                                            ;= 'J'
    dw          4540h                                                       
    dw          CHAR_I_f000_f5be                                            ;= 'I'
    dw           0A04Bh                                                       
    dw          CHAR_I_f000_f5be                                            ;= 'I'
    dw           0A08Bh                                                       
    dw          CHAR_O_f000_f656                                            ;= 'O'
    dw          204Bh                                                       
    dw          CHAR_O_f000_f656                                            ;= 'O'
    dw          208Bh                                                       
    dw          CHAR_L_f000_f61e                                            ;= 'L'
    dw          0h                                                          
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          0h                                                          
    dw          CHAR_R_f000_f673                                            ;= 'R'
    dw          0h                                                          
    dw          CHAR_R_f000_f66f                                            ;= 'R'
    dw          0h                                                          
    dw          CHAR_H_f000_f5b3                                            ;= 'H'
    dw          0h                                                          
    dw          CHAR_C_f000_f591                                            ;= 'C'
    dw          0h                                                          
    dw          2h                                                          
    dw          9840h                                                       
    dw          2h                                                          
    dw          9880h                                                       
    dw          CHAR_C_f000_f588                                            ;= 'C'
    dw          0h                                                          
    dw          CHAR_S_f000_f6ab                                            ;= 'S'
    dw          0h                                                          
    dw          CHAR_C_f000_f58e                                            ;This is the address for the start of the sting "CLI"
    dw          0h                                                          
    dw          CHAR_S_f000_f6b1                                            ;= 'S'
    dw          0h                                                          
    dw          CHAR_C_f000_f58b                                            ;= 'C'
    dw          0h                                                          
    dw          CHAR_S_f000_f6ae                                            ;= 'S'
    dw          0h                                                          
    dw          3h                                                          
    dw          9840h                                                       
    dw          3h                                                          
    dw          9880h                                                       
WORD_f000_f524:                                             
    dw          CHAR_A_f000_f576                                            ;= 'A'
    dw          CHAR_O_f000_f654                                            ;= 'O'
    dw          CHAR_A_f000_f573                                            ;= 'A'
    dw          CHAR_S_f000_f68c                                            ;= 'S'
    dw          CHAR_A_f000_f579                                            ;= 'A'
    dw          CHAR_S_f000_f6be                                            ;= 'S'
    dw          CHAR_X_f000_f6e1                                            ;= 'X'
    dw          CHAR_C_f000_f594                                            ;= 'C'
    dw          CHAR_R_f000_f67f                                            ;= 'R'
    dw          CHAR_R_f000_f682                                            ;= 'R'
    dw          CHAR_R_f000_f669                                            ;= 'R'
    dw          CHAR_R_f000_f66c                                            ;= 'R'
    dw          CHAR_S_f000_f6a5                                            ;= 'S'
    dw          CHAR_S_f000_f6a8                                            ;= 'S'
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          CHAR_S_f000_f689                                            ;= 'S'
    dw          CHAR_T_f000_f6c1                                            ;= 'T'
    dw          CHAR_?_f000_f564                                            ;= '?'
    dw          CHAR_N_f000_f651                                            ;= 'N'
    dw          CHAR_N_f000_f64b                                            ;= 'N'
    dw          CHAR_M_f000_f648                                            ;= 'M'
    dw          CHAR_I_f000_f5ba                                            ;= 'I'
    dw          CHAR_D_f000_f5ad                                            ;= 'D'
    dw          CHAR_I_f000_f5b6                                            ;= 'I'
    dw          CHAR_I_f000_f5c0                                            ;= 'I'
    dw          CHAR_D_f000_f5aa                                            ;= 'D'
    dw          CHAR_C_f000_f57c                                            ;= 'C'
    dw          CHAR_C_f000_f580                                            ;= 'C'
    dw          CHAR_J_f000_f5f2                                            ;= 'J'
    dw          CHAR_J_f000_f5f5                                            ;= 'J'
    dw          CHAR_P_f000_f660                                            ;= 'P'
    dw          CHAR_?_f000_f564                                            ;= '?'
CHAR_?_f000_f564:                                           
    db        '?'                                                         
    db        '?'                                                         
    db          0BFh                                                         
CHAR_A_f000_f567:                                           
    db        'A'                                                         
    db        'A'                                                         
    db          0C1h                                                         
CHAR_A_f000_f56a:                                           
    db        'A'                                                         
    db        'A'                                                         
    db          0C4h                                                         
CHAR_A_f000_f56d:                                           
    db        'A'                                                         
    db        'A'                                                         
    db          0CDh                                                         
CHAR_A_f000_f570:                                           
    db        'A'                                                         
    db        'A'                                                         
    db          0D3h                                                         
CHAR_A_f000_f573:                                           
    db        'A'                                                         
    db        'D'                                                         
    db          0C3h                                                         
CHAR_A_f000_f576:                                           
    db        'A'                                                         
    db        'D'                                                         
    db          0C4h                                                         
CHAR_A_f000_f579:                                           
    db        'A'                                                         
    db        'N'                                                         
    db          0C4h                                                         
CHAR_C_f000_f57c:                                           
    db        'C'                                                         
    db        'A'                                                         
    db        'L'                                                         
    db          0CCh                                                         
CHAR_C_f000_f580:                                           
    db        'C'                                                         
    db        'A'                                                         
    db        'L'                                                         
    db        'L'                                                         
    db          0C6h                                                         
CHAR_C_f000_f585:                                           
    db        'C'                                                         
    db        'B'                                                         
    db          0D7h                                                         
CHAR_C_f000_f588:                                           
    db        'C'                                                         
    db        'L'                                                         
    db          0C3h                                                         
CHAR_C_f000_f58b:                                           
    db        'C'                                                         
    db        'L'                                                         
    db          0C4h                                                         
CHAR_C_f000_f58e:                                           
    db        'C'                                                         
    db        'L'                                                         
    db          0C9h                                                         ;Ahh, that's why I couldn't find "CLI" string, the last c...
CHAR_C_f000_f591:                                           
    db        'C'                                                         
    db        'M'                                                         
    db          0C3h                                                         
CHAR_C_f000_f594:                                           
    db        'C'                                                         
    db        'M'                                                         
    db          0D0h                                                         
CHAR_C_f000_f597:                                           
    db        'C'                                                         
    db        'M'                                                         
    db        'P'                                                         
    db        'S'                                                         
    db          0C2h                                                         
CHAR_C_f000_f59c:                                           
    db        'C'                                                         
    db        'M'                                                         
    db        'P'                                                         
    db        'S'                                                         
    db          0D7h                                                         
CHAR_C_f000_f5a1:                                           
    db        'C'                                                         
    db        'W'                                                         
    db          0C4h                                                         
CHAR_D_f000_f5a4:                                           
    db        'D'                                                         
    db        'A'                                                         
    db          0C1h                                                         
CHAR_D_f000_f5a7:                                           
    db        'D'                                                         
    db        'A'                                                         
    db          0D3h                                                         
CHAR_D_f000_f5aa:                                           
    db        'D'                                                         
    db        'E'                                                         
    db          0C3h                                                         
CHAR_D_f000_f5ad:                                           
    db        'D'                                                         
    db        'I'                                                         
    db          0D6h                                                         
CHAR_E_f000_f5b0:                                           
    db        'E'                                                         
    db        'S'                                                         
    db          0C3h                                                         
CHAR_H_f000_f5b3:                                           
    db        'H'                                                         
    db        'L'                                                         
    db          0D4h                                                         
CHAR_I_f000_f5b6:                                           
    db        'I'                                                         
    db        'D'                                                         
    db        'I'                                                         
    db          0D6h                                                         
CHAR_I_f000_f5ba:                                           
    db        'I'                                                         
    db        'M'                                                         
    db        'U'                                                         
    db          0CCh                                                         
CHAR_I_f000_f5be:                                           
    db        'I'                                                         
    db          0CEh                                                         
CHAR_I_f000_f5c0:                                           
    db        'I'                                                         
    db        'N'                                                         
    db          0C3h                                                         
CHAR_I_f000_f5c3:                                           
    db        'I'                                                         
    db        'N'                                                         
    db          0D4h                                                         
CHAR_I_f000_f5c6:                                           
    db        'I'                                                         
    db        'N'                                                         
    db        'T'                                                         
    db        ' '                                                         
    db        ' '                                                         
    db        ' '                                                         
    db        ' '                                                         
    db        '0'                                                         
    db        '3'                                                         
    db          0C8h                                                         
CHAR_I_f000_f5d0:                                           
    db        'I'                                                         
    db        'N'                                                         
    db        'T'                                                         
    db          0CFh                                                         
CHAR_I_f000_f5d4:                                           
    db        'I'                                                         
    db        'R'                                                         
    db        'E'                                                         
    db          0D4h                                                         
CHAR_J_f000_f5d8:                                           
    db        'J'                                                         
    db          0C1h                                                         
CHAR_J_f000_f5da:                                           
    db        'J'                                                         
    db        'A'                                                         
    db          0C5h                                                         
CHAR_J_f000_f5dd:                                           
    db        'J'                                                         
    db          0C2h                                                         
CHAR_J_f000_f5df:                                           
    db        'J'                                                         
    db        'B'                                                         
    db          0C5h                                                         
    db        'J'                                                         
    db          0C3h                                                         
CHAR_J_f000_f5e4:                                           
    db        'J'                                                         
    db        'C'                                                         
    db        'X'                                                         
    db          0DAh                                                         
CHAR_J_f000_f5e8:                                           
    db        'J'                                                         
    db          0C7h                                                         
CHAR_J_f000_f5ea:                                           
    db        'J'                                                         
    db        'G'                                                         
    db          0C5h                                                         
CHAR_J_f000_f5ed:                                           
    db        'J'                                                         
    db          0CCh                                                         
CHAR_J_f000_f5ef:                                           
    db        'J'                                                         
    db        'L'                                                         
    db          0C5h                                                         
CHAR_J_f000_f5f2:                                           
    db        'J'                                                         
    db        'M'                                                         
    db          0D0h                                                         
CHAR_J_f000_f5f5:                                           
    db        'J'                                                         
    db        'M'                                                         
    db        'P'                                                         
    db          0C6h                                                         
    db        'J'                                                         
    db        'N'                                                         
    db          0C3h                                                         
CHAR_J_f000_f5fc:                                           
    db        'J'                                                         
    db        'N'                                                         
    db          0DAh                                                         
CHAR_J_f000_f5ff:                                           
    db        'J'                                                         
    db        'N'                                                         
    db          0CFh                                                         
CHAR_J_f000_f602:                                           
    db        'J'                                                         
    db        'N'                                                         
    db          0D3h                                                         
CHAR_J_f000_f605:                                           
    db        'J'                                                         
    db        'P'                                                         
    db          0CFh                                                         
CHAR_J_f000_f608:                                           
    db        'J'                                                         
    db          0CFh                                                         
CHAR_J_f000_f60a:                                           
    db        'J'                                                         
    db        'P'                                                         
    db          0C5h                                                         
CHAR_J_f000_f60d:                                           
    db        'J'                                                         
    db          0D3h                                                         
CHAR_J_f000_f60f:                                           
    db        'J'                                                         
    db          0DAh                                                         
CHAR_L_f000_f611:                                           
    db        'L'                                                         
    db        'A'                                                         
    db        'H'                                                         
    db          0C6h                                                         
CHAR_L_f000_f615:                                           
    db        'L'                                                         
    db        'D'                                                         
    db          0D3h                                                         
CHAR_L_f000_f618:                                           
    db        'L'                                                         
    db        'E'                                                         
    db          0C1h                                                         
CHAR_L_f000_f61b:                                           
    db        'L'                                                         
    db        'E'                                                         
    db          0D3h                                                         
CHAR_L_f000_f61e:                                           
    db        'L'                                                         
    db        'O'                                                         
    db        'C'                                                         
    db          0CBh                                                         
CHAR_L_f000_f622:                                           
    db        'L'                                                         
    db        'O'                                                         
    db        'D'                                                         
    db        'S'                                                         
    db          0C2h                                                         
CHAR_L_f000_f627:                                           
    db        'L'                                                         
    db        'O'                                                         
    db        'D'                                                         
    db        'S'                                                         
    db          0D7h                                                         
CHAR_L_f000_f62c:                                           
    db        'L'                                                         
    db        'O'                                                         
    db        'O'                                                         
    db          0D0h                                                         
CHAR_L_f000_f630:                                           
    db        'L'                                                         
    db        'O'                                                         
    db        'O'                                                         
    db        'P'                                                         
    db          0C5h                                                         
CHAR_L_f000_f635:                                           
    db        'L'                                                         
    db        'O'                                                         
    db        'O'                                                         
    db        'P'                                                         
    db        'N'                                                         
    db          0C5h                                                         
CHAR_M_f000_f63b:                                           
    db        'M'                                                         
    db        'O'                                                         
    db          0D6h                                                         
CHAR_M_f000_f63e:                                           
    db        'M'                                                         
    db        'O'                                                         
    db        'V'                                                         
    db        'S'                                                         
    db          0C2h                                                         
CHAR_M_f000_f643:                                           
    db        'M'                                                         
    db        'O'                                                         
    db        'V'                                                         
    db        'S'                                                         
    db          0D7h                                                         
CHAR_M_f000_f648:                                           
    db        'M'                                                         
    db        'U'                                                         
    db          0CCh                                                         
CHAR_N_f000_f64b:                                           
    db        'N'                                                         
    db        'E'                                                         
    db          0C7h                                                         
CHAR_N_f000_f64e:                                           
    db        'N'                                                         
    db        'O'                                                         
    db          0D0h                                                         
CHAR_N_f000_f651:                                           
    db        'N'                                                         
    db        'O'                                                         
    db          0D4h                                                         
CHAR_O_f000_f654:                                           
    db        'O'                                                         
    db          0D2h                                                         
CHAR_O_f000_f656:                                           
    db        'O'                                                         
    db        'U'                                                         
    db          0D4h                                                         
CHAR_P_f000_f659:                                           
    db        'P'                                                         
    db        'O'                                                         
    db          0D0h                                                         
CHAR_P_f000_f65c:                                           
    db        'P'                                                         
    db        'O'                                                         
    db        'P'                                                         
    db          0C6h                                                         
CHAR_P_f000_f660:                                           
    db        'P'                                                         
    db        'U'                                                         
    db        'S'                                                         
    db          0C8h                                                         
CHAR_P_f000_f664:                                           
    db        'P'                                                         
    db        'U'                                                         
    db        'S'                                                         
    db        'H'                                                         
    db          0C6h                                                         
CHAR_R_f000_f669:                                           
    db        'R'                                                         
    db        'C'                                                         
    db          0CCh                                                         
CHAR_R_f000_f66c:                                           
    db        'R'                                                         
    db        'C'                                                         
    db          0D2h                                                         
CHAR_R_f000_f66f:                                           
    db        'R'                                                         
    db        'E'                                                         
    db        'P'                                                         
    db          0C5h                                                         
CHAR_R_f000_f673:                                           
    db        'R'                                                         
    db        'E'                                                         
    db        'P'                                                         
    db        'N'                                                         
    db          0C5h                                                         
CHAR_R_f000_f678:                                           
    db        'R'                                                         
    db        'E'                                                         
    db          0D4h                                                         
CHAR_R_f000_f67b:                                           
    db        'R'                                                         
    db        'E'                                                         
    db        'T'                                                         
    db          0C6h                                                         
CHAR_R_f000_f67f:                                           
    db        'R'                                                         
    db        'O'                                                         
    db          0CCh                                                         
CHAR_R_f000_f682:                                           
    db        'R'                                                         
    db        'O'                                                         
    db          0D2h                                                         
CHAR_S_f000_f685:                                           
    db        'S'                                                         
    db        'A'                                                         
    db        'H'                                                         
    db          0C6h                                                         
CHAR_S_f000_f689:                                           
    db        'S'                                                         
    db        'A'                                                         
    db          0D2h                                                         
CHAR_S_f000_f68c:                                           
    db        'S'                                                         
    db        'B'                                                         
    db          0C2h                                                         
CHAR_S_f000_f68f:                                           
    db        'S'                                                         
    db        'C'                                                         
    db        'A'                                                         
    db        'S'                                                         
    db          0C2h                                                         
CHAR_S_f000_f694:                                           
    db        'S'                                                         
    db        'C'                                                         
    db        'A'                                                         
    db        'S'                                                         
    db          0D7h                                                         
CHAR_E_f000_f699:                                           
    db        'E'                                                         
    db        'S'                                                         
    db          0BAh                                                         
CHAR_C_f000_f69c:                                           
    db        'C'                                                         
    db        'S'                                                         
    db          0BAh                                                         
CHAR_S_f000_f69f:                                           
    db        'S'                                                         
    db        'S'                                                         
    db          0BAh                                                         
CHAR_D_f000_f6a2:                                           
    db        'D'                                                         
    db        'S'                                                         
    db          0BAh                                                         
CHAR_S_f000_f6a5:                                           
    db        'S'                                                         
    db        'H'                                                         
    db          0CCh                                                         
CHAR_S_f000_f6a8:                                           
    db        'S'                                                         
    db        'H'                                                         
    db          0D2h                                                         
CHAR_S_f000_f6ab:                                           
    db        'S'                                                         
    db        'T'                                                         
    db          0C3h                                                         
CHAR_S_f000_f6ae:                                           
    db        'S'                                                         
    db        'T'                                                         
    db          0C4h                                                         
CHAR_S_f000_f6b1:                                           
    db        'S'                                                         
    db        'T'                                                         
    db          0C9h                                                         
CHAR_S_f000_f6b4:                                           
    db        'S'                                                         
    db        'T'                                                         
    db        'O'                                                         
    db        'S'                                                         
    db          0C2h                                                         
CHAR_S_f000_f6b9:                                           
    db        'S'                                                         
    db        'T'                                                         
    db        'O'                                                         
    db        'S'                                                         
    db          0D7h                                                         
CHAR_S_f000_f6be:                                           
    db        'S'                                                         
    db        'U'                                                         
    db          0C2h                                                         
CHAR_T_f000_f6c1:                                           
    db        'T'                                                         
    db        'E'                                                         
    db        'S'                                                         
    db          0D4h                                                         
CHAR_W_f000_f6c5:                                           
    db        'W'                                                         
    db        'A'                                                         
    db        'I'                                                         
    db          0D4h                                                         
CHAR_X_f000_f6c9:                                           
    db        'X'                                                         
    db        'C'                                                         
    db        'H'                                                         
    db          0C7h                                                         
CHAR_X_f000_f6cd:                                           
    db        'X'                                                         
    db        'L'                                                         
    db        'A'                                                         
    db        'T'                                                         
    db        ' '                                                         
    db        ' '                                                         
    db        ' '                                                         
    db        'B'                                                         
    db        'Y'                                                         
    db        'T'                                                         
    db        'E'                                                         
    db        ' '                                                         
    db        'P'                                                         
    db        'T'                                                         
    db        'R'                                                         
    db        ' '                                                         
    db        '['                                                         
    db        'B'                                                         
    db        'X'                                                         
    db          0DDh                                                         
CHAR_X_f000_f6e1:                                           
    db        'X'                                                         
    db        'O'                                                         
    db          0D2h                                                         
s_AL_f000_f6e4:                                             
    db          "AL",0x00                                                        
s_CL_f000_f6e7:                                             
    db          "CL",0x00                                                        
s_DL_f000_f6ea:                                             
    db          "DL",0x00                                                        
s_BL_f000_f6ed:                                             
    db          "BL",0x00                                                        
s_AH_f000_f6f0:                                             
    db          "AH",0x00                                                        
s_CH_f000_f6f3:                                             
    db          "CH",0x00                                                        
s_DH_f000_f6f6:                                             
    db          "DH",0x00                                                        
s_BH_f000_f6f9:                                             
    db          "BH",0x00                                                        
s_AX_f000_f6fc:                                             
    db          "AX",0x00                                                        
s_CX_f000_f6ff:                                             
    db          "CX",0x00                                                        
s_DX_f000_f702:                                             
    db          "DX",0x00                                                        
s_BX_f000_f705:                                             
    db          "BX",0x00                                                        
s_SP_f000_f708:                                             
    db          "SP",0x00                                                        
s_BP_f000_f70b:                                             
    db          "BP",0x00                                                        
s_SI_f000_f70e:                                             
    db          "SI",0x00                                                        
s_DI_f000_f711:                                             
    db          "DI",0x00                                                        
s_ES_f000_f714:                                             
    db          "ES",0x00                                                        
s_CS_f000_f717:                                             
    db          "CS",0x00                                                        
s_SS_f000_f71a:                                             
    db          "SS",0x00                                                        
s_DS_f000_f71d:                                             
    db          "DS",0x00                                                        
WORD_f000_f720:                                             
    dw          s_AL_f000_f6e4                                              ;= "AL"
    dw          s_CL_f000_f6e7                                              ;= "CL"
    dw          s_DL_f000_f6ea                                              ;= "DL"
    dw          s_BL_f000_f6ed                                              ;= "BL"
    dw          s_AH_f000_f6f0                                              ;= "AH"
    dw          s_CH_f000_f6f3                                              ;= "CH"
    dw          s_DH_f000_f6f6                                              ;= "DH"
    dw          s_BH_f000_f6f9                                              ;= "BH"
    dw          s_AX_f000_f6fc                                              ;= "AX"
    dw          s_CX_f000_f6ff                                              ;= "CX"
    dw          s_DX_f000_f702                                              ;= "DX"
    dw          s_BX_f000_f705                                              ;= "BX"
    dw          s_SP_f000_f708                                              ;= "SP"
    dw          s_BP_f000_f70b                                              ;= "BP"
    dw          s_SI_f000_f70e                                              ;= "SI"
    dw          s_DI_f000_f711                                              ;= "DI"
    dw          s_ES_f000_f714                                              ;= "ES"
    dw          s_CS_f000_f717                                              ;= "CS"
    dw          s_SS_f000_f71a                                              ;= "SS"
    dw          s_DS_f000_f71d                                              ;= "DS"
BYTE_f000_f748:                                             
    db          0h                                                          
s_BYTE_PTR_f000_f749:                                       
    db          "BYTE PTR ",0x00                                                 
s_WORD_PTR_f000_f753:                                       
    db          "WORD PTR ",0x00                                                 
s_DWORD_PTR_f000_f75d:                                      
    db          "DWORD PTR ",0x00                                                
                            s_?_PTR_f000_f768:                                          
    db          "? PTR ",0x00                                                    
s_BYTE_PTR_f000_f76f:                                       
    db          "BYTE PTR ",0x00                                                 
WORD_f000_f779:                                             
    dw          BYTE_f000_f748                                              ;Is this a Opcode lookup table - list of words that point...
    dw          s_BYTE_PTR_f000_f749                                        ;= "BYTE PTR "
    dw          s_WORD_PTR_f000_f753                                        ;= "WORD PTR "
    dw          s_DWORD_PTR_f000_f75d                                       ;= "DWORD PTR "
    dw          s_?_PTR_f000_f768                                           ;= "? PTR "
    dw          s_BYTE_PTR_f000_f76f                                        ;= "BYTE PTR "
s_BX_SI_f000_f785:                                         
    db          "[BX+SI",0x00                                                    
s_BX_DI_f000_f78c:                                         
    db          "[BX+DI",0x00                                                    
s_BP_SI_f000_f793:                                         
    db          "[BP+SI",0x00                                                    
s_BP_DI_f000_f79a:                                         
    db          "[BP+DI",0x00                                                    
s_SI_f000_f7a1:                                            
    db          "[SI",0x00                                                       
s_DI_f000_f7a5:                                            
    db          "[DI",0x00                                                       
s_BP_f000_f7a9:                                            
    db          "[BP",0x00                                                       
s_BX_f000_f7ad:                                            
    db          "[BX",0x00                                                       
WORD_f000_f7b1:                                             
    dw          s_BX_SI_f000_f785                                          ;= "[BX+SI"
    dw          s_BX_DI_f000_f78c                                          ;= "[BX+DI"
    dw          s_BP_SI_f000_f793                                          ;= "[BP+SI"
    dw          s_BP_DI_f000_f79a                                          ;= "[BP+DI"
    dw          s_SI_f000_f7a1                                             ;= "[SI"
    dw          s_DI_f000_f7a5                                             ;= "[DI"
    dw          s_BP_f000_f7a9                                             ;= "[BP"
    dw          s_BX_f000_f7ad                                             ;= "[BX"


BYTE_f000_f7c1:
    db         26h
    db         2Eh
    db         36h
    db         3Eh
    db        0F0h
    db        0F2h
    db        0F3h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h
    db         0h

setloc START + ((18 * 0x200) - 1)           ; size is X 512B Blocks Minus 1 to add the checksum byte
; xxd -p -c 1 mfm-150.bin = Google Sheets -> SUM() HEX2DEC(X) = 902632 = 0xDC5E8 = E8 0x100 - E8 = 0x18
    db         0x21     ; Whatever needs to be added so that the lowest byte of the sum of all bytes in AL = 00

