.equ OS_WriteC, 0
.equ OS_WriteO, 2
.equ OS_WriteN, 0x46
.equ OS_NewLine, 3
.equ OS_Byte, 6
.equ XOS_Byte, OS_Byte | (1 << 17)
.equ OS_Word, 7
.equ XOS_Word, OS_Word | (1 << 17)
.equ OS_File, 8
.equ OS_Exit, 0x11
.equ OS_BreakPt, 0x17
.equ OS_Mouse, 0x1c
.equ OS_ChangeDynamicArea, 0x2a
.equ OS_GenerateError, 0x2b
.equ OS_ReadVduVariables, 0x31
.equ OS_ReadMonotonicTime, 0x42
.equ OS_ReadDynamicArea, 0x5c
.equ OS_ConvertHex2, 0xd1
.equ OS_ConvertHex4, 0xd2
.equ OS_ConvertHex8, 0xd4
.equ OS_ConvertCardinal1, 0xd5	
.equ OS_ConvertCardinal4, 0xd8

.equ OSByte_EventEnable, 14
.equ OSByte_EventDisable, 13
.equ OSByte_Vsync, 19
.equ OSByte_WriteVDUBank, 112
.equ OSByte_WriteDisplayBank, 113
.equ OSByte_KeyboardScan, 121
.equ OSByte_ReadKey, 129

.equ OSWord_WritePalette, 12

.equ IKey_LeftClick, 0xf6
.equ IKey_RightClick, 0xf4
.equ IKey_Space, 0x9d
.equ IKey_Escape, 0x8f
.equ IKey_ArrowUp, 198
.equ IKey_ArrowDown, 214
.equ IKey_ArrowLeft, 230
.equ IKey_ArrowRight, 134
.equ IKey_Return, 0xB6

.equ RMKey_ArrowUp, 0x59
.equ RMKey_ArrowDown, 0x63
.equ RMKey_Return, 0x47

.equ DynArea_Screen, 2

.equ VD_ScreenStart, 148 

.equ OS_Claim, 0x1f
.equ OS_Release, 0x20
.equ OS_AddToVector, 0x47

.equ ErrorV, 0x01
.equ EventV, 0x10
.equ Event_VSync, 4

.equ QTM_Load, 0x47E40
.equ QTM_Start, 0x47E41
.equ QTM_Stop, 0x47E42
.equ QTM_Pause, 0x47E43
.equ QTM_Clear, 0x47E44
.equ QTM_Pos, 0x47E46
.equ QTM_SetSampleSpeed, 0x47E49
.equ QTM_VUBarControl, 0x47E50
.equ QTM_ReadVULevels, 0x47E51
.equ QTM_SoundControl, 0x47E58

.equ RasterMan_Install, 0x47e80
.equ RasterMan_Release, 0x47e81
.equ RasterMan_Wait, 0x47e82
.equ RasterMan_SetTables, 0x47e83
.equ RasterMan_Version, 0x47e84
.equ RasterMan_ReadScanline, 0x47e85
.equ RasterMan_SetVIDCRegister, 0x47e86
.equ RasterMan_SetMEMCRegister, 0x47e87
.equ RasterMan_QTMParamAddr, 0x47e88
.equ RasterMan_ScanKeyboard, 0x47e89
.equ RasterMan_ClearKeyBuffer, 0x47e8a
.equ RasterMan_ReadScanAddr, 0x47e8b
