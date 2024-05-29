;Copyright (C) 1997-2008 ZSNES Team ( zsKnight, _Demo_, pagefault, Nach )
;
;http://www.zsnes.com
;http://sourceforge.net/projects/zsnes
;https://zsnes.bountysource.com
;
;This program is free software; you can redistribute it and/or
;modify it under the terms of the GNU General Public License
;version 2 as published by the Free Software Foundation.
;
;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.
;
;You should have received a copy of the GNU General Public License
;along with this program; if not, write to the Free Software
;Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

%include "macros.mac"

EXTSYM SfxB,SfxBRAMR,SfxCBR,SfxCFGR,SfxCLSR,SfxCPB,SfxCROM
EXTSYM SfxCarry,SfxMemTable,SfxOverflow,SfxPBR,SfxPIPE,SfxR0,SfxR1,SfxR10
EXTSYM SfxR11,SfxR12,SfxR13,SfxR14,SfxR15,SfxR2,SfxR3,SfxR4,SfxR5,SfxR6
EXTSYM SfxR7,SfxR8,SfxR9,SfxRAMBR,SfxRAMMem,SfxROMBR,SfxSCBR,SfxSCMR,SfxSFR
EXTSYM SfxSignZero,SfxnRamBanks,sfxramdata,ChangeOps
EXTSYM SfxPOR,sfxclineloc,UpdatePORSCMR,UpdateCLSR,UpdateSCBRCOLR,SfxAC
EXTSYM sfx128lineloc,sfx160lineloc,sfx192lineloc,sfxobjlineloc,SFXProc

%macro AssembleSFXFlags 0
    and word[SfxSFR],8F60h
    test byte[SfxCarry],1
    jz .nosfxcarry
    or word[SfxSFR],04h
.nosfxcarry
    cmp word[SfxSignZero],0
    jne .nozero
    or word[SfxSFR],02h
.nozero
    test word[SfxSignZero],8000h
    jz .noneg
    or word[SfxSFR],08h
.noneg
    cmp byte[SfxOverflow],0
    je .noof
    or word[SfxSFR],10h
.noof
    cmp byte[SfxB],0
    je .bzero
    or word[SfxSFR],1000h
.bzero
%endmacro

SECTION .text

NEWSYM cacheregr
    or byte[cachewarning],1
    ret

NEWSYM cacheregw
    or byte[cachewarning],2
    ret

SECTION .bss
NEWSYM cachewarning, resb 1

SECTION .text

; SFX Registers

NEWSYM reg3000r
    mov al,[SfxR0]
    ret
NEWSYM reg3001r
    mov al,[SfxR0+1]
    ret
NEWSYM reg3002r
    mov al,[SfxR1]
    ret
NEWSYM reg3003r
    mov al,[SfxR1+1]
    ret
NEWSYM reg3004r
    mov al,[SfxR2]
    ret
NEWSYM reg3005r
    mov al,[SfxR2+1]
    ret
NEWSYM reg3006r
    mov al,[SfxR3]
    ret
NEWSYM reg3007r
    mov al,[SfxR3+1]
    ret
NEWSYM reg3008r
    mov al,[SfxR4]
    ret
NEWSYM reg3009r
    mov al,[SfxR4+1]
    ret
NEWSYM reg300Ar
    mov al,[SfxR5]
    ret
NEWSYM reg300Br
    mov al,[SfxR5+1]
    ret
NEWSYM reg300Cr
    mov al,[SfxR6]
    ret
NEWSYM reg300Dr
    mov al,[SfxR6+1]
    ret
NEWSYM reg300Er
    mov al,[SfxR7]
    ret
NEWSYM reg300Fr
    mov al,[SfxR7+1]
    ret
NEWSYM reg3010r
    mov al,[SfxR8]
    ret
NEWSYM reg3011r
    mov al,[SfxR8+1]
    ret
NEWSYM reg3012r
    mov al,[SfxR9]
    ret
NEWSYM reg3013r
    mov al,[SfxR9+1]
    ret
NEWSYM reg3014r
    mov al,[SfxR10]
    ret
NEWSYM reg3015r
    mov al,[SfxR10+1]
    ret
NEWSYM reg3016r
    mov al,[SfxR11]
    ret
NEWSYM reg3017r
    mov al,[SfxR11+1]
    ret
NEWSYM reg3018r
    mov al,[SfxR12]
    ret
NEWSYM reg3019r
    mov al,[SfxR12+1]
    ret
NEWSYM reg301Ar
    mov al,[SfxR13]
    ret
NEWSYM reg301Br
    mov al,[SfxR13+1]
    ret
NEWSYM reg301Cr
    mov al,[SfxR14]
    ret
NEWSYM reg301Dr
    mov al,[SfxR14+1]
    ret
NEWSYM reg301Er
    mov al,[SfxR15]
    ret
NEWSYM reg301Fr
    mov al,[SfxR15+1]
    ret

; Other SFX stuff

NEWSYM reg3030r
    AssembleSFXFlags
    mov al,[SfxSFR]
    ret
NEWSYM reg3031r
    cmp byte[SfxAC],1
    je .alwaysclear
    cmp dword[ChangeOps],-350*240
    jl .noclear
.alwaysclear
    and byte[SfxSFR+1],07fh        ; clear IRQ flag
    jmp .cleared
.noclear
    cmp dword[ChangeOps],-350*240*4
    jge .clear
    mov dword[ChangeOps],-350*240*4
    jmp .cleared
.clear
    add dword[ChangeOps],350*240
.cleared
    mov al,[SfxSFR+1]
    ret
SECTION .bss
.test resb 1
SECTION .text

NEWSYM reg3032r       ; Unused
    xor al,al
    ret
NEWSYM reg3033r       ; BRAMR Backup Ram Read only on/off (bits 1-15 unused)
    mov al,[SfxBRAMR]
    ret
NEWSYM reg3034r       ; PBR (Program Bank)
    mov al,[SfxPBR]
    ret
NEWSYM reg3035r       ; Unused
    xor al,al
    ret
NEWSYM reg3036r       ; ROMBR (Gamepak Rom Bank Register)
    mov al,[SfxROMBR]
    ret
NEWSYM reg3037r       ; CFGR (Control Flags Register)
    mov al,[SfxCFGR]
    ret
NEWSYM reg3038r       ; SCBR (Screen Bank Register)
    mov al,[SfxSCBR]
    ret
NEWSYM reg3039r       ; CLSR (Clock Speed Register)
    mov al,[SfxCLSR]
    ret
NEWSYM reg303Ar       ; SCMR (Screen Mode Register)
    mov al,[SfxSCMR]
    test byte[SfxPOR],10h
    jnz .objmode
    mov al,[SfxSCMR]
    and al,00100100b     ; 4 + 32
    cmp al,4
    je .lines160
    cmp al,32
    je .lines192
    cmp al,36
    je .objmode
    mov eax,[sfx128lineloc]
    jmp .donelines
.lines160
    mov eax,[sfx160lineloc]
    jmp .donelines
.lines192
    mov eax,[sfx192lineloc]
    jmp .donelines
.objmode
    mov eax,[sfxobjlineloc]
.donelines
    mov [sfxclineloc],eax
    ret
NEWSYM reg303Br       ; VCR (Version Code Register)
    mov al,20h
    ret
NEWSYM reg303Cr       ; RAMBR (Ram bank register)
    mov al,[SfxRAMBR]
    ret
NEWSYM reg303Dr       ; Unused
    xor al,al
    ret
NEWSYM reg303Er       ; CBR (Cache Base Register), lower byte
    mov al,[SfxCBR]
    ret
NEWSYM reg303Fr       ; CBR (Cache Base Register), upper byte
    mov al,[SfxCBR+1]
    ret

; SFX Write Registers

NEWSYM reg3000w
    mov [SfxR0],al
    ret
NEWSYM reg3001w
    mov [SfxR0+1],al
    ret
NEWSYM reg3002w
    mov [SfxR1],al
    ret
NEWSYM reg3003w
    mov [SfxR1+1],al
    ret
NEWSYM reg3004w
    mov [SfxR2],al
    ret
NEWSYM reg3005w
    mov [SfxR2+1],al
    ret
NEWSYM reg3006w
    mov [SfxR3],al
    ret
NEWSYM reg3007w
    mov [SfxR3+1],al
    ret
NEWSYM reg3008w
    mov [SfxR4],al
    ret
NEWSYM reg3009w
    mov [SfxR4+1],al
    ret
NEWSYM reg300Aw
    mov [SfxR5],al
    ret
NEWSYM reg300Bw
    mov [SfxR5+1],al
    ret
NEWSYM reg300Cw
    mov [SfxR6],al
    ret
NEWSYM reg300Dw
    mov [SfxR6+1],al
    ret
NEWSYM reg300Ew
    mov [SfxR7],al
    ret
NEWSYM reg300Fw
    mov [SfxR7+1],al
    ret
NEWSYM reg3010w
    mov [SfxR8],al
    ret
NEWSYM reg3011w
    mov [SfxR8+1],al
    ret
NEWSYM reg3012w
    mov [SfxR9],al
    ret
NEWSYM reg3013w
    mov [SfxR9+1],al
    ret
NEWSYM reg3014w
    mov [SfxR10],al
    ret
NEWSYM reg3015w
    mov [SfxR10+1],al
    ret
NEWSYM reg3016w
    mov [SfxR11],al
    ret
NEWSYM reg3017w
    mov [SfxR11+1],al
    ret
NEWSYM reg3018w
    mov [SfxR12],al
    ret
NEWSYM reg3019w
    mov [SfxR12+1],al
    ret
NEWSYM reg301Aw
    mov [SfxR13],al
    ret
NEWSYM reg301Bw
    mov [SfxR13+1],al
    ret
NEWSYM reg301Cw
    mov [SfxR14],al
    ret
NEWSYM reg301Dw
    mov [SfxR14+1],al
    ret
NEWSYM reg301Ew
    mov [SfxR15],al
    ret
NEWSYM reg301Fw
    mov [SfxR15+1],al
    ; start execution
    push edx
    mov edx,[SfxPBR]
    mov edx,[SfxMemTable+edx*4]
    add edx,[SfxR15]
    mov dl,[edx]
    mov [SfxPIPE],dl
    pop edx
    inc word[SfxR15]
    or byte[SfxSFR],20h
    or dword[SfxSFR],08000h         ; Set IRQ Flag
    mov dword[SFXProc],1
    ret

; Other SFX stuff

NEWSYM reg3030w
    mov [SfxSFR],al
    mov byte[SfxAC],1
    mov dh,10
    ret
NEWSYM reg3031w
    mov [SfxSFR+1],al
    ret
NEWSYM reg3032w       ; Unused
    ret
NEWSYM reg3033w       ; BRAMR Backup Ram Read only on/off (bits 1-15 unused)
    and al,0FEh
    mov [SfxBRAMR],al
    ret
NEWSYM reg3034w       ; PBR (Program Bank)
    mov [SfxPBR],al
    xor ebx,ebx
    mov bl,al
    mov ebx,[SfxMemTable+ebx*4]
    mov [SfxCPB],ebx
    ret
NEWSYM reg3035w       ; Unused
    ret
NEWSYM reg3036w       ; ROMBR (Gamepak Rom Bank Register)
    mov [SfxROMBR],al
    xor ebx,ebx
    mov bl,al
    mov ebx,[SfxMemTable+ebx*4]
    mov [SfxCROM],ebx
    ret
NEWSYM reg3037w       ; CFGR (Control Flags Register)
    mov [SfxCFGR],al
    ret
NEWSYM reg3038w       ; SCBR (Screen Bank Register)
    mov [SfxSCBR],al
    ccallv UpdateSCBRCOLR
    ret
NEWSYM reg3039w       ; CLSR (Clock Speed Register)
    and al,0FEh
    mov [SfxCLSR],al
    ccallv UpdateCLSR
    ret
NEWSYM reg303Aw       ; SCMR (Screen Mode Register)
    mov [SfxSCMR],al
    ccallv UpdatePORSCMR
    ret
NEWSYM reg303Bw       ; VCR (Version Code Register)
    ret
NEWSYM reg303Cw       ; RAMBR (Ram bank register)
    mov bl,[SfxnRamBanks]
    dec bl
    and al,bl
    mov ebx,[SfxnRamBanks]
    dec ebx
    and eax,ebx
    mov [SfxRAMBR],eax
    xor ebx,ebx
    mov bl,al
    shl ebx,16
    add ebx,[sfxramdata]
    mov [SfxRAMMem],ebx
    ret
NEWSYM reg303Dw       ; Unused
    ret
NEWSYM reg303Ew       ; CBR (Cache Base Register), lower byte
    mov [SfxCBR],al
    ret
NEWSYM reg303Fw       ; CBR (Cache Base Register), upper byte
    mov [SfxCBR+1],al
    ret

NEWSYM sfxaccessbankr8
    mov ebx,[sfxramdata]
    mov al,[ebx+ecx]
    xor ebx,ebx
    ret

NEWSYM sfxaccessbankw8
    mov ebx,[sfxramdata]
    mov [ebx+ecx],al
    xor ebx,ebx
    ret

NEWSYM sfxaccessbankr16
    mov ebx,[sfxramdata]
    mov ax,[ebx+ecx]
    xor ebx,ebx
    ret

NEWSYM sfxaccessbankw16
    mov ebx,[sfxramdata]
    mov [ebx+ecx],ax
    xor ebx,ebx
    ret

NEWSYM sfxaccessbankr8b
    mov ebx,[sfxramdata]
    mov al,[ebx+ecx+65536]
    xor ebx,ebx
    ret

NEWSYM sfxaccessbankw8b
    mov ebx,[sfxramdata]
    mov [ebx+ecx+65536],al
    xor ebx,ebx
    ret

NEWSYM sfxaccessbankr16b
    mov ebx,[sfxramdata]
    mov ax,[ebx+ecx+65536]
    xor ebx,ebx
    ret

NEWSYM sfxaccessbankw16b
    mov ebx,[sfxramdata]
    mov [ebx+ecx+65536],ax
    xor ebx,ebx
    ret

NEWSYM sfxaccessbankr8c
    mov ebx,[sfxramdata]
    mov al,[ebx+ecx+65536*2]
    xor ebx,ebx
    ret

NEWSYM sfxaccessbankw8c
    mov ebx,[sfxramdata]
    mov [ebx+ecx+65536*2],al
    xor ebx,ebx
    ret

NEWSYM sfxaccessbankr16c
    mov ebx,[sfxramdata]
    mov ax,[ebx+ecx+65536*2]
    xor ebx,ebx
    ret

NEWSYM sfxaccessbankw16c
    mov ebx,[sfxramdata]
    mov [ebx+ecx+65536*2],ax
    xor ebx,ebx
    ret

NEWSYM sfxaccessbankr8d
    mov ebx,[sfxramdata]
    mov al,[ebx+ecx+65536*3]
    xor ebx,ebx
    ret

NEWSYM sfxaccessbankw8d
    mov ebx,[sfxramdata]
    mov [ebx+ecx+65536*3],al
    xor ebx,ebx
    ret

NEWSYM sfxaccessbankr16d
    mov ebx,[sfxramdata]
    mov ax,[ebx+ecx+65536*3]
    xor ebx,ebx
    ret

NEWSYM sfxaccessbankw16d
    mov ebx,[sfxramdata]
    mov [ebx+ecx+65536*3],ax
    xor ebx,ebx
    ret


