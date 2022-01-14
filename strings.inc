

s_MFM150Monitor				db	`MFM-150 Monitor, Version 3.1E\r\nMemory Size: `, 0x00
s_K_bytes_Enter_for_help	db	`K bytes\r\nEnter ? for help.\r\n`, 0x00
s_commandPrompt 			db 	"->", 0x00
s_Sum 						db 	"Sum: ", 0x00
s_Diff 						db 	"  Diff: ", 0x00
s_Invalid_Command 			db	`^ Invalid Command!\r\n`, 0x00
s_150_Command_Summary 		db 	`\t\t- MFM-150 Command Summary -\r\n\r\nCMD:\tExplanation\t\tSyntax\r\n----\t-----------\t\t------\r\n?:\t`
							db 	`Help\t\t\t?\r\nB:\tBoot from disk\t\tB [{F|W}][{0|1|2|3}][:<partition>]\r\nC:\tColor Bar\t\tC\r\nD:\t`
							db	`Display memory\t\tD [<range>]\r\nE:\tExamine memory\t\tE <addr>\r\nF:\t`
							db	`Fill memory\t\tF <range>,{<byte>|",'"<string>"',"}...\r\nG:\t`
							db	`Execute (Go)\t\tG [=<addr>][,<breakpoint>]...\r\nH:\tHex math\t\tH <number1>,<number2>\r\nI:\t`
							db	`Input from port\t\tI <port>\r\nM:\t`
							db	`Move memory block\tM <range>,<dest>\r\nO:\tOutput to port\t\tO <port>,<value>\r\nR:\t`
							db	`Examine Registers\tR [<register>]\r\nS:\t`
							db	`Search memory\t\tS <range>,{<byte>|",'"<string>"',"}...\r\nT:\t`
							db	`Trace program\t\tT [<count>]\r\nU:\tUnassemble program\tU [<range>]\r\nV:\t`
							db	`Set Video/Scroll\tV [M<mode>][S<scroll>]\r\nTEST:\t`
							db	`Extended diagnostics\tTEST\r\nWhere\t<range> is:\t\t<addr>{,<addr>|L<length>}\r\n\r\n\t `
							db	`Copyright (C) 1987, by Zenith Data Systems\r\n`, 0x00
s_Press_any_key             db  `\t\t\t    - Press any key to continue -\r\n`
s_Choose_TESTMenu           db  `\r\n\n\n\n\n\n\t\t\tCHOOSE ONE OF THE FOLLOWING:\r\n\n\t\t\t1. DISK READ TEST\r\n\t\t\t2. KEYBOARD TEST\r\n\t\t\t3. MEMORY TEST\r\n\t\t\t4. POWER-UP TEST\r\n\t\t\t5. EXIT\r\n\n\n\t\t\tENTER YOUR CHOICE: `

;f000:e9e8
s_cpu_regs:
s_cpu_regs_ax: 				db 	'AX'
s_cpu_regs_bx: 				db 	'BX'
s_cpu_regs_cx: 				db 	'CX'
s_cpu_regs_dx: 				db 	'DX'
s_cpu_regs_si: 				db 	'SI'
s_cpu_regs_di: 				db 	'DI'
s_cpu_regs_bp: 				db 	'BP'
s_cpu_regs_sp: 				db 	'SP'
s_cpu_regs_cs: 				db 	'CS'
s_cpu_regs_ds: 				db 	'DS'
s_cpu_regs_ss: 				db 	'SS'
s_cpu_regs_es: 				db 	'ES'
s_cpu_regs_ip: 				db 	'IP'
s_cpu_regs_fl: 				db 	'FL'
s_cpu_regs_ip2: 			db 	'IP'
;f000:ea06
; s_cpu_regs_cn: 				db 	'CN'
; s_cpu_regs_yc: 				db 	'YC', 0x00
s_cpu_regs_cn:                                             
    db          43h                                                         
    db          4Eh                                                         
s_cpu_regs_yc:                                             
    db          59h                                                         
    db          43h                                                         
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          4Fh                                                         
    db          50h                                                         
    db          45h                                                         
    db          50h                                                         
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          41h                                                         
    db          4Eh                                                         
    db          43h                                                         
    db          41h                                                         
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          5Ah                                                         
    db          4Eh                                                         
    db          52h                                                         
    db          5Ah                                                         
    db          4Ch                                                         
    db          50h                                                         
    db          47h                                                         
    db          4Eh                                                         
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          49h                                                         
    db          44h                                                         
    db          49h                                                         
    db          45h                                                         
    db          50h                                                         
    db          55h                                                         
    db          4Eh                                                         
    db          44h                                                         
    db          56h                                                         
    db          4Eh                                                         
    db          56h                                                         
    db          4Fh                                                         
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          
    db          0h                                                          

;f000:b1ae
s_HexCharacters 			db 	'0123456789ABCDEF',0x00
s_symbols: 					db 	0x00
s_symbols_comma:          	db  ",",0x00
s_symbols_1:          		db  "1",0x00
s_symbols_lsqbr:          	db  "[",0x00
s_symbols_minus:          	db  "-",0x00
s_symbols_plus:          	db  "+",0x00
s_symbols_rsqbr:          	db   "]",0x00
s_symbols_H:          		db   "H",0x00
s_symbols_colon:          	db   ":",0x00
