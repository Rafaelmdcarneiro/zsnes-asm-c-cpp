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

EXTSYM vidmemch2
EXTSYM resolutn,curypos
EXTSYM oamram,objhipr,objptr,objptrn,objsize1,objsize2,spritetablea,sprleftpr
EXTSYM sprlefttot,vcache4b,objadds1,objadds2,objmovs1,objmovs2,tltype4b
EXTSYM vidmemch4,vram,bgptr,bgptrc,bgptrd,curtileptr,vcache2b,vcache8b,vidmemch8
EXTSYM sprcnt,sprstart,sprtilecnt,sprend,sprendx,interlval,offsetmshl,tltype2b
EXTSYM tltype8b

; Process stuff & Cache sprites

SECTION .data
ALIGN32

NEWSYM sprprifix,    db 1
NEWSYM OMBGTestVal, dd 0
NEWSYM ngptrdat2, dd 0
NEWSYM ofshvaladd, dd 0
NEWSYM ofsmtptrs, dd 0
NEWSYM ofsmcptr2, dd 0

NEWSYM addr2add,     dd 0
section .text

;*******************************************************
; Process Sprites
;*******************************************************
; Use oamram for object table
NEWSYM processsprites
;    cmp byte[cbitmode],1
;    je .skipnewspr
;    cmp byte[newengen],1
;    je .skipnewspr
    cmp byte[sprprifix],0
    jne near processspritesb
.skipnewspr
    ; set obj pointers
    cmp byte[objsize1],1
    jne .16dot1
    mov ebx,.process8x8sprite
    mov [.size1ptr],ebx
    jmp .fin1
.16dot1
    cmp byte[objsize1],4
    jne .32dot1
    mov ebx,.process16x16sprite
    mov [.size1ptr],ebx
    jmp .fin1
.32dot1
    cmp byte[objsize1],16
    jne .64dot1
    mov ebx,.process32x32sprite
    mov [.size1ptr],ebx
    jmp .fin1
.64dot1
    mov ebx,.process64x64sprite
    mov [.size1ptr],ebx
.fin1
    cmp byte[objsize2],1
    jne .16dot2
    mov ebx,.process8x8sprite
    mov [.size2ptr],ebx
    jmp .fin2
.16dot2
    cmp byte[objsize2],4
    jne .32dot2
    mov ebx,.process16x16sprite
    mov [.size2ptr],ebx
    jmp .fin2
.32dot2
    cmp byte[objsize2],16
    jne .64dot2
    mov ebx,.process32x32sprite
    mov [.size2ptr],ebx
    jmp .fin2
.64dot2
    mov ebx,.process64x64sprite
    mov [.size2ptr],ebx
.fin2
    ; set pointer adder
    xor eax,eax
    xor ebx,ebx
    mov al,[objhipr]
    shl ax,2
    mov ebx,eax
    sub bx,4
    and bx,01FCh
    mov dword[addr2add],0
    mov byte[.prileft],4
    mov byte[.curpri],0
    ; do 1st priority
    mov ecx,[objptr]
    shl ecx,1
    mov [.objvramloc],ecx
    mov ecx,[objptrn]
    sub ecx,[objptr]
    shl ecx,1
    mov [.objvramloc2],ecx
    push ebp
    mov ebp,[spritetablea]
.startobject
    mov byte[.objleft],128
.objloop
    xor ecx,ecx
    mov cx,[oamram+ebx+2]
    mov dl,ch
    shr dl,4
    and dl,03h
    cmp dl,[.curpri]
    jne near .nextobj
    ; get object information
    push ebx
    mov dl,[oamram+ebx+1]       ; y
    inc dl
    ; set up pointer to esi
    mov dh,ch
    and ch,01h
    shr dh,1
    shl ecx,6
    add ecx,[.objvramloc]
    test byte[oamram+ebx+3],01h
    jz .noloc2
    add ecx,[.objvramloc2]
.noloc2
    and ecx,01FFFFh
    add ecx,[vcache4b]
    mov esi,ecx
    ; get x
    mov al,[oamram+ebx]         ; x
    ; get double bits
    mov cl,bl
    shr ebx,4           ; /16
    shr cl,1
    and cl,06h
    mov ah,[oamram+ebx+512]
    shr ah,cl
    and ah,03h
    mov ch,ah
    and ch,01h
    mov cl,al
    ; process object
    ; esi = pointer to 8-bit object, dh = stats (1 shifted to right)
    ; cx = x position, dl = y position
    cmp cx,384
    jb .noadder
    add cx,65535-511
.noadder
    cmp cx,256
    jge .returnfromptr
    cmp cx,-64
    jle .returnfromptr
    test ah,02h
    jz .size1
    jmp dword near [.size2ptr]
.size1
    jmp dword near [.size1ptr]
.returnfromptr
    pop ebx
    ; next object
.nextobj
    sub bx,4
    and bx,01FCh
    dec byte[.objleft]
    jnz near .objloop
    add dword[addr2add],256
    inc byte[.curpri]
    dec byte[.prileft]
    jnz near .startobject
    pop ebp
    ret

SECTION .bss
.objvramloc resd 1
.objvramloc2 resd 1
.curpri  resd 1
.trypri  resd 1
.objleft resd 1
.prileft resd 1
.size1ptr resd 1
.size2ptr resd 1
SECTION .text

.reprocesssprite
    cmp cx,-8
    jle .next
    cmp cx,256
    jge .next
    add cx,8
.reprocessspriteb
    cmp dl,[resolutn]
    ja .overflow
    xor ebx,ebx
    mov bl,dl
    xor eax,eax
    cmp bx,[curypos]
    jb .overflow
    mov al,[sprlefttot+ebx]
    cmp al,45
    ja near .overflow
    inc byte[sprlefttot+ebx]
    add ebx,[addr2add]
    inc byte[sprleftpr+ebx]
    sub ebx,[addr2add]
    shl ebx,9
    shl eax,3
    add ebx,eax
    mov [ebp+ebx],cx
    mov [ebp+ebx+2],esi
    mov al,[.statusbit]
    mov [ebp+ebx+6],dh
    mov [ebp+ebx+7],al
.overflow
    inc dl
    add esi,8
    dec byte[.numleft2do]
    jnz .reprocessspriteb
    sub cx,8
    ret
.next
    add dl,8
    add esi,64
    ret

.reprocessspriteflipy
    cmp cx,-8
    jle .nextb
    cmp cx,256
    jge .nextb
    add cx,8
.reprocessspriteflipyb
    cmp dl,[resolutn]
    ja .overflow2
    xor ebx,ebx
    xor eax,eax
    mov bl,dl
    cmp bx,[curypos]
    jb .overflow2
    mov al,[sprlefttot+ebx]
    cmp al,45
    ja near .overflow2
    inc byte[sprlefttot+ebx]
    add ebx,[addr2add]
    inc byte[sprleftpr+ebx]
    sub ebx,[addr2add]
    shl ebx,9
    shl eax,3
    add ebx,eax
    mov [ebp+ebx],cx
    mov [ebp+ebx+2],esi
    mov al,[.statusbit]
    mov [ebp+ebx+6],dh
    mov [ebp+ebx+7],al
.overflow2
    inc dl
    sub esi,8
    dec byte[.numleft2do]
    jnz .reprocessspriteflipyb
    sub cx,8
    ret
.nextb
    add dl,8
    sub esi,64
    ret

section .bss
.statusbit resb 1
section .text

.process8x8sprite:
    test dh,40h
    jnz .8x8flipy
    mov [.statusbit],dh
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    jmp .returnfromptr
.8x8flipy
    mov [.statusbit],dh
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add esi,56
    call .reprocessspriteflipy
    jmp .returnfromptr

section .bss
.numleft2do resb 1
section .text

;*******************************************************
; Sprite increment/draw macros
;*******************************************************

%macro add_x 0
    mov eax,[sprt_char]
    shr eax,2
    add al,64>>2
    shl eax,2
    mov [sprt_char],eax
    mov esi,[objloc]
    add esi,eax
%endmacro

%macro add_y 1
    mov eax,[sprt_char]
    shr eax,2
    sub al,(64>>2)*%1
    shl eax,2
    add eax,64*10h
    and eax,3FFFh
    mov [sprt_char],eax
    mov esi,[objloc]
    add esi,eax
%endmacro

%macro nextsprite2right 0
    sub dl,8
    add cx,8
    mov byte[.numleft2do],8
    call .reprocesssprite
%endmacro

%macro nextsprite2rightflipy 0
    add esi,56
    sub dl,8
    add cx,8
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
%endmacro

%macro nextsprite2rightflipx 0
    sub dl,8
    sub cx,8
    mov byte[.numleft2do],8
    call .reprocesssprite
%endmacro

%macro nextsprite2rightflipyx 0
    add esi,56
    sub dl,8
    sub cx,8
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
%endmacro

;*******************************************************
; 16x16 sprites routines
;*******************************************************

%macro nextline16x16 0
    sub cx,8
    add_y 2
    mov byte[.numleft2do],8
    call .reprocesssprite
    nextsprite2right
%endmacro

.process16x16sprite:
    mov [.statusbit],dh
    test dh,20h
    jnz near .16x16flipx
    test dh,40h
    jnz .16x16flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    nextsprite2right
    nextline16x16
    jmp .returnfromptr

%macro nextline16x16flipy 0
    sub cx,8
    add_y 2
    add esi,56
    sub dl,16
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    nextsprite2rightflipy
%endmacro

.16x16flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add dl,8
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipy
    nextline16x16flipy
    jmp .returnfromptr

%macro nextline16x16flipx 0
    add cx,8
    add_y 2
    mov byte[.numleft2do],8
    call .reprocesssprite
    nextsprite2rightflipx
%endmacro

.16x16flipx
    test dh,40h
    jnz .16x16flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,8
    call .reprocesssprite
    nextsprite2rightflipx
    nextline16x16flipx
    jmp .returnfromptr

%macro nextline16x16flipyx 0
    add cx,8
    add_y 2
    add esi,56
    sub dl,16
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    nextsprite2rightflipyx
%endmacro

.16x16flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,8
    add dl,8
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipyx
    nextline16x16flipyx
    jmp .returnfromptr

;*******************************************************
; 32x32 sprites routines
;*******************************************************

%macro nextline32x32 0
    sub cx,24
    add_y 4
    mov byte[.numleft2do],8
    call .reprocesssprite
    nextsprite2right
    nextsprite2right
    nextsprite2right
%endmacro

.process32x32sprite:
    mov [.statusbit],dh
    test dh,20h
    jnz near .32x32flipx
    test dh,40h
    jnz near .32x32flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextline32x32
    nextline32x32
    nextline32x32
    jmp .returnfromptr

%macro nextline32x32flipy 0
    sub cx,24
    add_y 4
    add esi,56
    sub dl,16
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
%endmacro

.32x32flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add dl,24
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextline32x32flipy
    nextline32x32flipy
    nextline32x32flipy
    jmp .returnfromptr

%macro nextline32x32flipx 0
    add cx,24
    add_y 4
    mov byte[.numleft2do],8
    call .reprocesssprite
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
%endmacro

.32x32flipx
    test dh,40h
    jnz near .32x32flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,24
    call .reprocesssprite
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextline32x32flipx
    nextline32x32flipx
    nextline32x32flipx
    jmp .returnfromptr

%macro nextline32x32flipyx 0
    add cx,24
    add_y 4
    add esi,56
    sub dl,16
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
%endmacro

.32x32flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,24
    add dl,24
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextline32x32flipyx
    nextline32x32flipyx
    nextline32x32flipyx
    jmp .returnfromptr

;*******************************************************
; 64x64 sprites routines
;*******************************************************

%macro nextline64x64 0
    sub cx,56
    add_y 8
    mov byte[.numleft2do],8
    call .reprocesssprite
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
%endmacro

.process64x64sprite:
    mov [.statusbit],dh
    test dh,20h
    jnz near .64x64flipx
    test dh,40h
    jnz near .64x64flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextline64x64
    nextline64x64
    nextline64x64
    nextline64x64
    nextline64x64
    nextline64x64
    nextline64x64
    jmp .returnfromptr

%macro nextline64x64flipy 0
    sub cx,56
    add_y 8
    add esi,56
    sub dl,16
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
%endmacro

.64x64flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add dl,56
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    jmp .returnfromptr

%macro nextline64x64flipx 0
    add cx,56
    add_y 8
    mov byte[.numleft2do],8
    call .reprocesssprite
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
%endmacro

.64x64flipx
    test dh,40h
    jnz near .64x64flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,56
    call .reprocesssprite
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    jmp .returnfromptr

%macro nextline64x64flipyx 0
    add cx,56
    add_y 8
    add esi,56
    sub dl,16
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
%endmacro

.64x64flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,56
    add dl,56
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    jmp .returnfromptr

;*******************************************************
; Process Sprites B - Process
;*******************************************************
; Use oamram for object table

%macro do_RTO 2
    cmp cx,-%1
    jle .returnfromptr_rto
    xor ebx,ebx
    mov bl,dl
    mov al,%2
%%loop
    cmp bx,[resolutn]
    ja %%no
    cmp bx,[curypos]
    jb %%no
    inc byte[sprcnt+ebx]
    cmp byte[sprcnt+ebx],32
    jne %%no
    mov dl,[.objleft]
    mov [sprstart+ebx],dl
%%no
    inc bl
    dec al
    jnz %%loop
    jmp .returnfromptr_rto
%endmacro

%macro do_RTO2 2
    cmp cx,-%1
    jle .returnfromptr_rto2
    xor ebx,ebx
    mov bl,dl
    mov ax,%2
%%loopy
    mov dh,128+1
    sub dh,[.objleft]
    cmp [sprstart+ebx],dh
    ja %%noy
    cmp bx,[resolutn]
    ja %%noy
    cmp bx,[curypos]
    jb %%noy
    mov dl,%1>>3
    push ecx
%%loopx
    cmp word[.obj_x],256
    je %%doit
    cmp cx,-8
    jle %%nox
    cmp cx,256
    jge %%nox
%%doit
    inc byte[sprtilecnt+ebx]
    cmp byte[sprtilecnt+ebx],34
    jne %%nox
    mov [sprend+ebx],dh
    mov [sprendx+ebx*2],cx
    add word[sprendx+ebx*2],8
%%nox
    add cx,8
    dec dl
    jnz %%loopx
    pop ecx
%%noy
    inc bl
    dec ax
    jnz %%loopy
    jmp .returnfromptr_rto2
%endmacro

section .bss
sprt_char resd 1
objloc resd 1
section .text

NEWSYM processspritesb
    ; set obj pointers
    cmp byte[objsize1],1
    jne .16dot1
    mov ebx,.process8x8sprite
    mov [.size1ptr],ebx
    mov ebx,.process8x8sprite_rto
    mov [.size1ptr_rto],ebx
    mov ebx,.process8x8sprite_rto2
    mov [.size1ptr_rto2],ebx
    jmp .fin1
.16dot1
    cmp byte[objsize1],4
    jne .32dot1
.do16dot1
    mov ebx,.process16x16sprite
    mov [.size1ptr],ebx
    mov ebx,.process16x16sprite_rto
    mov [.size1ptr_rto],ebx
    mov ebx,.process16x16sprite_rto2
    mov [.size1ptr_rto2],ebx
    jmp .fin1
.32dot1
    cmp byte[objsize1],16
    jne .64dot1
    mov ebx,.process32x32sprite
    mov [.size1ptr],ebx
    mov ebx,.process32x32sprite_rto
    mov [.size1ptr_rto],ebx
    mov ebx,.process32x32sprite_rto2
    mov [.size1ptr_rto2],ebx
    jmp .fin1
.64dot1
    cmp byte[objsize1],64
    jne .16x32dot1
    mov ebx,.process64x64sprite
    mov [.size1ptr],ebx
    mov ebx,.process64x64sprite_rto
    mov [.size1ptr_rto],ebx
    mov ebx,.process64x64sprite_rto2
    mov [.size1ptr_rto2],ebx
    jmp .fin1
.16x32dot1
    test byte[interlval],2
    jnz .do16dot1
    mov ebx,.process16x32sprite
    mov [.size1ptr],ebx
    mov ebx,.process16x32sprite_rto
    mov [.size1ptr_rto],ebx
    mov ebx,.process16x32sprite_rto2
    mov [.size1ptr_rto2],ebx
.fin1
    cmp byte[objsize2],1
    jne .16dot2
    mov ebx,.process8x8sprite
    mov [.size2ptr],ebx
    mov ebx,.process8x8sprite_rto
    mov [.size2ptr_rto],ebx
    mov ebx,.process8x8sprite_rto2
    mov [.size2ptr_rto2],ebx
    jmp .fin2
.16dot2
    cmp byte[objsize2],4
    jne .32dot2
    mov ebx,.process16x16sprite
    mov [.size2ptr],ebx
    mov ebx,.process16x16sprite_rto
    mov [.size2ptr_rto],ebx
    mov ebx,.process16x16sprite_rto2
    mov [.size2ptr_rto2],ebx
    jmp .fin2
.32dot2
    cmp byte[objsize2],16
    jne .64dot2
    mov ebx,.process32x32sprite
    mov [.size2ptr],ebx
    mov ebx,.process32x32sprite_rto
    mov [.size2ptr_rto],ebx
    mov ebx,.process32x32sprite_rto2
    mov [.size2ptr_rto2],ebx
    jmp .fin2
.64dot2
    cmp byte[objsize2],64
    jne .32x64dot2
    mov ebx,.process64x64sprite
    mov [.size2ptr],ebx
    mov ebx,.process64x64sprite_rto
    mov [.size2ptr_rto],ebx
    mov ebx,.process64x64sprite_rto2
    mov [.size2ptr_rto2],ebx
    jmp .fin2
.32x64dot2
    mov ebx,.process32x64sprite
    mov [.size2ptr],ebx
    mov ebx,.process32x64sprite_rto
    mov [.size2ptr_rto],ebx
    mov ebx,.process32x64sprite_rto2
    mov [.size2ptr_rto2],ebx
.fin2
    ; set pointer adder
    xor eax,eax
    xor ebx,ebx
    mov al,[objhipr]
    shl ax,2
    mov ebx,eax
    and bx,01FCh
    mov dword[addr2add],0
    ; do 1st priority
    mov ecx,[objptr]
    shl ecx,1
    mov [.objvramloc],ecx
    mov ecx,[objptrn]
    sub ecx,[objptr]
    shl ecx,1
    mov [.objvramloc2],ecx
    push ebp
    mov ebp,[spritetablea]
.startobject
    mov byte[.objleft],128
.objloop_rto
    ; get object information
    push ebx
    mov dl,[oamram+ebx+1]       ; y
    inc dl
    ; get x
    mov al,[oamram+ebx]         ; x
    ; get double bits
    mov cl,bl
    shr ebx,4           ; /16
    shr cl,1
    and cl,06h
    mov ah,[oamram+ebx+512]
    shr ah,cl
    and ah,03h
    mov ch,ah
    and ch,01h
    mov cl,al
    ; process object
    ; esi = pointer to 8-bit object, dh = stats (1 shifted to right)
    ; cx = x position, dl = y position
    cmp cx,384
    jb .noadder_rto
    add cx,65535-511
.noadder_rto
    cmp cx,256
    jg .returnfromptr_rto
    test ah,02h
    jz .size1_rto
    jmp dword near [.size2ptr_rto]
.size1_rto
    jmp dword near [.size1ptr_rto]
.returnfromptr_rto
    pop ebx
    add bx,4
    and bx,01FCh
    dec byte[.objleft]
    jnz near .objloop_rto
    sub bx,4
    and bx,01FCh

    mov byte[.objleft],128
.objloop_rto2
    ; get object information
    push ebx
    mov dl,[oamram+ebx+1]       ; y
    inc dl
    mov dh,[oamram+ebx+3]
    shr dh,1
    ; get x
    mov al,[oamram+ebx]         ; x
    ; get double bits
    mov cl,bl
    shr ebx,4           ; /16
    shr cl,1
    and cl,06h
    mov ah,[oamram+ebx+512]
    shr ah,cl
    and ah,03h
    mov ch,ah
    and ch,01h
    mov cl,al
    ; process object
    ; esi = pointer to 8-bit object, dh = stats (1 shifted to right)
    ; cx = x position, dl = y position
    cmp cx,384
    jb .noadder_rto2
    add cx,65535-511
.noadder_rto2
    mov [.obj_x],cx
    cmp cx,256
    jg .returnfromptr_rto2
    test ah,02h
    jz .size1_rto2
    jmp dword near [.size2ptr_rto2]
.size1_rto2
    jmp dword near [.size1ptr_rto2]
.returnfromptr_rto2
    pop ebx
    ; next object
.nextobj_rto2
    sub bx,4
    and bx,01FCh
    dec byte[.objleft]
    jnz near .objloop_rto2
    add bx,4
    and bx,01FCh

    mov byte[.objleft],128
.objloop
    xor ecx,ecx
    mov cx,[oamram+ebx+2]
    mov dl,ch
    shr dl,4
    and edx,03h
    mov [.cpri],dl
    ; get object information
    push ebx
    mov dl,[oamram+ebx+1]       ; y
    inc dl
    ; set up pointer to esi
    mov dh,ch
    and ch,01h
    shr dh,1
    shl ecx,6
    mov [sprt_char],ecx
    and dword[sprt_char],3FFFh
    add ecx,[.objvramloc]
    test byte[oamram+ebx+3],01h
    jz .noloc2
    add ecx,[.objvramloc2]
.noloc2
    and ecx,01FFFFh
    add ecx,[vcache4b]
    mov esi,ecx
    mov [objloc],ecx
    mov ecx,[sprt_char]
    sub [objloc],ecx
    ; get x
    mov al,[oamram+ebx]         ; x
    ; get double bits
    mov cl,bl
    shr ebx,4           ; /16
    shr cl,1
    and cl,06h
    mov ah,[oamram+ebx+512]
    shr ah,cl
    and ah,03h
    mov ch,ah
    and ch,01h
    mov cl,al
    ; process object
    ; esi = pointer to 8-bit object, dh = stats (1 shifted to right)
    ; cx = x position, dl = y position
    cmp cx,384
    jb .noadder
    add cx,65535-511
.noadder
    mov [.obj_x],cx
    cmp cx,256
    jg .returnfromptr
    test ah,02h
    jz .size1
    jmp dword near [.size2ptr]
.size1
    jmp dword near [.size1ptr]
.returnfromptr
    pop ebx
    ; next object
.nextobj
    add bx,4
    and bx,01FCh
    dec byte[.objleft]
    jnz near .objloop
    pop ebp
    ret

SECTION .bss
.objvramloc resd 1
.objvramloc2 resd 1
.curpri  resd 1
.trypri  resd 1
.objleft resd 1
.prileft resd 1
.size1ptr resd 1
.size2ptr resd 1
.size1ptr_rto resd 1
.size2ptr_rto resd 1
.size1ptr_rto2 resd 1
.size2ptr_rto2 resd 1
.cpri     resd 1
.obj_x    resw 1
SECTION .text

.reprocesssprite
    cmp cx,-8
    jle near .next
    cmp cx,256
    jge near .next
.spec
    add cx,8
.reprocessspriteb
    cmp dl,[resolutn]
    ja .overflow
    xor ebx,ebx
    xor eax,eax
    mov bl,dl
    cmp bx,[curypos]
    jb .overflow
    mov al,[.objleft]
    cmp [sprstart+ebx],al
    ja .overflow
    cmp byte[sprtilecnt+ebx],34
    jbe .okay
    cmp [sprend+ebx],al
    jb .overflow
    ja .okay
    cmp [sprendx+ebx*2],cx
    jb .overflow
.okay
    mov al,[sprlefttot+ebx]
    inc byte[sprlefttot+ebx]
    mov edi,[.cpri]
    mov byte[sprleftpr+ebx*4+edi],1
    shl ebx,9
    shl eax,3
    add ebx,eax
    mov [ebp+ebx],cx
    mov [ebp+ebx+2],esi
    mov al,[.statusbit]
    and al,0F8h
    or al,[.cpri]
    mov [ebp+ebx+6],dh
    mov [ebp+ebx+7],al
.overflow
    inc dl
    add esi,8
    dec byte[.numleft2do]
    jnz .reprocessspriteb
    add_x
    sub cx,8
    ret
.next
    cmp word[.obj_x],256
    je .spec
    add dl,8
    add_x
    ret

.reprocessspriteflipy
    cmp cx,-8
    jle near .nextb
    cmp cx,256
    jge near .nextb
.specb
    add cx,8
.reprocessspriteflipyb
    cmp dl,[resolutn]
    ja .overflow2
    xor ebx,ebx
    xor eax,eax
    mov bl,dl
    cmp bx,[curypos]
    jb .overflow2
    mov al,[.objleft]
    cmp [sprstart+ebx],al
    ja .overflow2
    cmp byte[sprtilecnt+ebx],34
    jbe .okayb
    cmp [sprend+ebx],al
    jb .overflow2
    ja .okayb
    cmp [sprendx+ebx*2],cx
    jb .overflow2
.okayb
    mov al,[sprlefttot+ebx]
    inc byte[sprlefttot+ebx]
    mov edi,[.cpri]
    mov byte[sprleftpr+ebx*4+edi],1
    shl ebx,9
    shl eax,3
    add ebx,eax
    mov [ebp+ebx],cx
    mov [ebp+ebx+2],esi
    mov al,[.statusbit]
    and al,0F8h
    or al,[.cpri]
    mov [ebp+ebx+6],dh
    mov [ebp+ebx+7],al
.overflow2
    inc dl
    sub esi,8
    dec byte[.numleft2do]
    jnz .reprocessspriteflipyb
    sub cx,8
    add_x
    ret
.nextb
    cmp word[.obj_x],256
    je .specb
    add dl,8
    add_x
    ret

section .bss
.statusbit resb 1
section .text

.process8x8sprite_rto:
    do_RTO 8,8

.process8x8sprite_rto2:
    do_RTO2 8,8

.process8x8sprite:
    cmp cx,-8
    jle .returnfromptr
    mov [.statusbit],dh
    test dh,40h
    jnz .8x8flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    jmp .returnfromptr
.8x8flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add esi,56
    call .reprocessspriteflipy
    jmp .returnfromptr

section .bss
.numleft2do resb 1
section .text

.process16x16sprite_rto:
    do_RTO 16,16

.process16x16sprite_rto2:
    do_RTO2 16,16

.process16x16sprite:
    cmp cx,-16
    jle .returnfromptr
    mov [.statusbit],dh
    test dh,20h
    jnz near .16x16flipx
    test dh,40h
    jnz .16x16flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    nextsprite2right
    nextline16x16
    jmp .returnfromptr
.16x16flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add dl,8
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipy
    nextline16x16flipy
    jmp .returnfromptr
.16x16flipx
    test dh,40h
    jnz .16x16flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,8
    call .reprocesssprite
    nextsprite2rightflipx
    nextline16x16flipx
    jmp .returnfromptr
.16x16flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,8
    add dl,8
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipyx
    nextline16x16flipyx
    jmp .returnfromptr

;*******************************************************
; 32x32 sprites routines
;*******************************************************

.process32x32sprite_rto:
    do_RTO 32,32

.process32x32sprite_rto2:
    do_RTO2 32,32

.process32x32sprite:
    cmp cx,-32
    jle .returnfromptr
    mov [.statusbit],dh
    test dh,20h
    jnz near .32x32flipx
    test dh,40h
    jnz near .32x32flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextline32x32
    nextline32x32
    nextline32x32
    jmp .returnfromptr

.32x32flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add dl,24
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextline32x32flipy
    nextline32x32flipy
    nextline32x32flipy
    jmp .returnfromptr

.32x32flipx
    test dh,40h
    jnz near .32x32flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,24
    call .reprocesssprite
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextline32x32flipx
    nextline32x32flipx
    nextline32x32flipx
    jmp .returnfromptr

.32x32flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,24
    add dl,24
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextline32x32flipyx
    nextline32x32flipyx
    nextline32x32flipyx
    jmp .returnfromptr

;*******************************************************
; 64x64 sprites routines
;*******************************************************

.process64x64sprite_rto:
    do_RTO 64,64

.process64x64sprite_rto2:
    do_RTO2 64,64

.process64x64sprite:
    cmp cx,-64
    jle .returnfromptr
    mov [.statusbit],dh
    test dh,20h
    jnz near .64x64flipx
    test dh,40h
    jnz near .64x64flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextline64x64
    nextline64x64
    nextline64x64
    nextline64x64
    nextline64x64
    nextline64x64
    nextline64x64
    jmp .returnfromptr

.64x64flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add dl,56
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    jmp .returnfromptr

.64x64flipx
    test dh,40h
    jnz near .64x64flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,56
    call .reprocesssprite
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    jmp .returnfromptr

.64x64flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,56
    add dl,56
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    jmp .returnfromptr

;*******************************************************
; 16x32 sprites routines
;*******************************************************

.process16x32sprite_rto:
    do_RTO 16,32

.process16x32sprite_rto2:
    do_RTO2 16,32

.process16x32sprite:
    cmp cx,-16
    jle .returnfromptr
    mov [.statusbit],dh
    test dh,20h
    jnz near .16x32flipx
    test dh,40h
    jnz near .16x32flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    nextsprite2right
    nextline16x16
    nextline16x16
    nextline16x16
    jmp .returnfromptr
.16x32flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add dl,8
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipy
    nextline16x16flipy
    add dl,32
    nextline16x16flipy
    nextline16x16flipy
    jmp .returnfromptr
.16x32flipx
    test dh,40h
    jnz near .16x32flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,8
    call .reprocesssprite
    nextsprite2rightflipx
    nextline16x16flipx
    nextline16x16flipx
    nextline16x16flipx
    jmp .returnfromptr
.16x32flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,8
    add dl,8
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipyx
    nextline16x16flipyx
    add dl,32
    nextline16x16flipyx
    nextline16x16flipyx
    jmp .returnfromptr

;*******************************************************
; 32x64 sprites routines
;*******************************************************

.process32x64sprite_rto:
    do_RTO 32,64

.process32x64sprite_rto2:
    do_RTO2 32,64

.process32x64sprite:
    cmp cx,-32
    jle .returnfromptr
    mov [.statusbit],dh
    test dh,20h
    jnz near .32x64flipx
    test dh,40h
    jnz near .32x64flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextline32x32
    nextline32x32
    nextline32x32
    nextline32x32
    nextline32x32
    nextline32x32
    nextline32x32
    jmp .returnfromptr

.32x64flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add dl,24
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextline32x32flipy
    nextline32x32flipy
    nextline32x32flipy
    add dl,64
    nextline32x32flipy
    nextline32x32flipy
    nextline32x32flipy
    nextline32x32flipy
    jmp .returnfromptr

.32x64flipx
    test dh,40h
    jnz near .32x64flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,24
    call .reprocesssprite
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextline32x32flipx
    nextline32x32flipx
    nextline32x32flipx
    nextline32x32flipx
    nextline32x32flipx
    nextline32x32flipx
    nextline32x32flipx
    jmp .returnfromptr

.32x64flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,24
    add dl,24
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextline32x32flipyx
    nextline32x32flipyx
    nextline32x32flipyx
    add dl,64
    nextline32x32flipyx
    nextline32x32flipyx
    nextline32x32flipyx
    nextline32x32flipyx
    jmp .returnfromptr

;*******************************************************
; Cache Process Macros, info from Nerlaska!
;*******************************************************

%macro processcache2b 1
    xor al,al
    add ch,ch
    adc al,al
    add cl,cl
    adc al,al
    mov [edi+%1],al
%endmacro

%macro processcache4b 1
    xor al,al
    add dh,dh
    adc al,al
    add dl,dl
    adc al,al
    add ch,ch
    adc al,al
    add cl,cl
    adc al,al
    mov [edi+%1],al
%endmacro

;*******************************************************
; Cache Sprites
;*******************************************************
; Use oamram for object table, copy from vram -> vcache4b
; 16x16 sprite, to move = 2, to add = 14, 32x32 = 4,12, 64x64 = 8,8

%macro processcache4bs 1
    xor al,al
    add dh,dh
    adc al,al
    add dl,dl
    adc al,al
    add ch,ch
    adc al,al
    add cl,cl
    adc al,al
    mov [edi+%1],al
    or al,al
    jz %%zeroed
    and byte[tiletypec],1
    jmp %%nozeroed
%%zeroed
    and byte[tiletypec],2
%%nozeroed
%endmacro

NEWSYM cachesprites
    ; initialize obj size cache
    mov dword[.objptr],oamram
    add dword[.objptr],512
    mov esi,[.objptr]
    mov al,[esi]
    mov [.curobjtype],al
    mov byte[.objleftinbyte],4
    ; Initialize oamram pointer
    mov esi,oamram
    add esi,2

    ; process pointers (.objptra = source, .objptrb = dest)
.trynextgroup
    xor ebx,ebx
    mov bx,[objptr]
    mov ecx,ebx
    shr ecx,4
    mov [.nbg],cx
    mov edi,[vram]
    add edi,ebx
    mov [.objptra],edi
    shl ebx,1
    add ebx,[vcache4b]
    mov [.objptrb],ebx

    xor ebx,ebx
    mov bx,[objptrn]
    mov ecx,ebx
    shr ecx,4
    mov [.nbg2],cx
    mov edi,[vram]
    add edi,ebx
    mov [.objptra2],edi
    shl ebx,1
    add ebx,[vcache4b]
    mov [.objptrb2],ebx

    xor ebx,ebx

    ; process objects
    mov dword[.sprnum],3
    mov byte[.objleft],128
.nextobj
    ; process sprite sizes
    test byte[.curobjtype],02h
    jz .dosprsize1
    mov al,[objsize2]
    mov [.num2do],al
    mov [.num2do+1],al
    mov ax,[objadds2]
    mov [.byte2add],ax
    mov al,[objmovs2]
    mov [.byte2move],al
    mov [.byteb4add],al
    jmp .exitsprsize
.dosprsize1
    mov al,[objsize1]
    mov [.num2do],al
    mov [.num2do+1],al
    mov ax,[objadds1]
    mov [.byte2add],ax
    mov al,[objmovs1]
    mov [.byte2move],al
    mov [.byteb4add],al
.exitsprsize
    shr byte[.curobjtype],2
    dec byte[.objleftinbyte]
    jnz .skipobjproc
    mov byte[.objleftinbyte],4
    inc dword[.objptr]
    mov ebx,[.objptr]
    mov al,[ebx]
    mov [.curobjtype],al
.skipobjproc
    mov bx,[esi]
    and bh,1h
    mov [.curobj],bx
.nextobject
    mov ebx,[.sprnum]
    mov cl,[oamram+ebx-2]
    mov ch,[curypos]
    dec ch
    cmp cl,ch
    jb near .nocache
    mov ch,[resolutn]
    dec ch
    cmp cl,ch
    jbe .okayres
    cmp byte[.num2do+1],8
    jae .okayres
    cmp byte[.num2do+1],1
    jne .not8x8
    add cl,8
    jnc near .nocache
    jmp .okayres
.not8x8
    add cl,16
    jnc near .nocache
.okayres

    test byte[oamram+ebx],01h
    jnz .namebase
    xor ebx,ebx
    mov bx,[.curobj]
    mov cx,bx
    add bx,bx
    add bx,[.nbg]
    and bx,4095
    test word[vidmemch4+ebx],0101h
    jz near .nocache
    mov word[vidmemch4+ebx],0000h
    mov [.sprfillpl],ebx
    push esi
    shl bx,4
    mov esi,[vram]
    add esi,ebx
    add ebx,ebx
    mov edi,[vcache4b]
    add edi,ebx
    jmp .nonamebase
.namebase
    xor ebx,ebx
    mov bx,[.curobj]
    mov cx,bx
    shl bx,1
    add bx,[.nbg2]
    and bx,4095
    test word[vidmemch4+ebx],0101h
    jz near .nocache
    mov word[vidmemch4+ebx],0000h
    mov [.sprfillpl],ebx
    push esi
    shl bx,4
    mov esi,[vram]
    add esi,ebx
    add ebx,ebx
    mov edi,[vcache4b]
    add edi,ebx
.nonamebase
    ; convert from [esi] to [edi]
    mov byte[.rowleft],8
    mov byte[tiletypec],3
.donext

    mov cx,[esi]
    mov dx,[esi+16]

    processcache4bs 0
    processcache4bs 1
    processcache4bs 2
    processcache4bs 3
    processcache4bs 4
    processcache4bs 5
    processcache4bs 6
    processcache4bs 7

    add edi,8
    add esi,2
    dec byte[.rowleft]
    jnz near .donext
    mov ebx,[.sprfillpl]
    mov al,[tiletypec]
    shr ebx,1
    pop esi
    mov [tltype4b+ebx],al
.nocache
    mov bx,[.curobj]
    shl bx,4
    add bl,10h
    shr bx,4
    mov [.curobj],bx
    dec byte[.byteb4add]
    jnz .skipbyteadd
    mov ax,[.byte2add]
    mov bx,[.curobj]
    shl bx,4
    shl al,4
    add bl,al
    shr bx,4
    add bl,10h
    mov [.curobj],bx
    mov al,[.byte2move]
    mov [.byteb4add],al
.skipbyteadd
    dec byte[.num2do]
    jnz near .nextobject
    add esi,4
    add dword[.sprnum],4
    dec byte[.objleft]
    jnz near .nextobj
    ret

SECTION .data
.num2do dd 1
.byteb4add dd 2

SECTION .bss
.objptra resd 1
.objptrb resd 1
.nbg     resd 1
.objptra2 resd 1
.objptrb2 resd 1
.nbg2     resd 1
.objleft resb 1
.rowleft resb 1
.a       resd 1
.objptr resd 1
.objleftinbyte resd 1
.curobjtype resd 1
.curobj resd 1
.byte2move resd 1
.byte2add  resd 1
.sprnum    resd 1
.sprcheck  resd 1
.sprfillpl resd 1

section .text

;*******************************************************
; Cache 2-Bit
;*******************************************************
NEWSYM cachetile2b
    ; Keep high word ecx 0
    push eax
    xor ecx,ecx
    push edx
    mov byte[.nextar],1
    push ebx
    ; get tile info location
    test al,20h
    jnz .highptr
    shl eax,6   ; x 64 for each line
    add ax,[bgptr]
    jmp .loptr
.highptr
    and al,1Fh
    shl eax,6   ; x 64 for each line
    add ax,[bgptrc]
.loptr
    add eax,[vram]
    mov bx,[curtileptr]
    shr bx,4
    mov byte[.count],32
    mov [.nbg],bx
    ; do loop
.cacheloop
    mov si,[eax]
    and esi,03FFh
    add si,[.nbg]
    and esi,4095
    test byte[vidmemch2+esi],01h
    jz near .nocache
    mov byte[vidmemch2+esi],00h
    mov edi,esi
    shl esi,4
    shl edi,6
    add esi,[vram]
    add edi,[vcache2b]
    push eax
    mov byte[.rowleft],8
.donext
    mov cx,[esi]
    processcache2b 0
    processcache2b 1
    processcache2b 2
    processcache2b 3
    processcache2b 4
    processcache2b 5
    processcache2b 6
    processcache2b 7
    add edi,8
    add esi,2
    dec byte[.rowleft]
    jnz near .donext
    pop eax
.nocache
    add eax,2
    dec byte[.count]
    jnz near .cacheloop

    cmp byte[.nextar],0
    je .skipall
    mov bx,[bgptrc]
    cmp [bgptrd],bx
    je .skipall
    add eax,2048-64
    mov byte[.count],32
    mov byte[.nextar],0
    jmp .cacheloop
.skipall
    pop ebx
    pop edx
    pop eax
    ret

section .bss

.nbg     resw 1
.count   resb 1
.a       resb 1
.rowleft resb 1
.nextar  resb 1

section .text

NEWSYM cache2bit
    ret

;*******************************************************
; Cache 4-Bit
;*******************************************************

; esi = pointer to tile location vram
; edi = pointer to graphics data (cache & non-cache)
; ebx = external pointer
; tile value : bit 15 = flipy, bit 14 = flipx, bit 10-12 = palette, 0-9=tile#

NEWSYM cachetile4b
    ; Keep high word ecx 0
    push eax
    xor ecx,ecx
    push edx
    mov byte[.nextar],1
    push ebx
    ; get tile info location
    test al,20h
    jnz .highptr
    shl eax,6   ; x 64 for each line
    add ax,[bgptr]
    jmp .loptr
.highptr
    and al,1Fh
    shl eax,6   ; x 64 for each line
    add ax,[bgptrc]
.loptr
    add eax,[vram]
    mov bx,[curtileptr]
    shr bx,5
    mov byte[.count],32
    mov [.nbg],bx

    ; do loop
.cacheloop
    mov si,[eax]
    and esi,03FFh
    add si,[.nbg]
    shl esi,1
    and esi,4095
    test word[vidmemch4+esi],0101h
    jz near .nocache
    mov word[vidmemch4+esi],0000h
    mov edi,esi
    shl esi,4
    shl edi,5
    add esi,[vram]
    add edi,[vcache4b]
    push eax
    mov byte[.rowleft],8
.donext

    mov cx,[esi]
    mov dx,[esi+16]
    processcache4b 0
    processcache4b 1
    processcache4b 2
    processcache4b 3
    processcache4b 4
    processcache4b 5
    processcache4b 6
    processcache4b 7

    add edi,8
    add esi,2
    dec byte[.rowleft]
    jnz near .donext
    pop eax
.nocache
    add eax,2
    dec byte[.count]
    jnz near .cacheloop

    cmp byte[.nextar],0
    je .skipall
    mov bx,[bgptrc]
    cmp [bgptrd],bx
    je .skipall
    add eax,2048-64
    mov byte[.count],32
    mov byte[.nextar],0
    jmp .cacheloop
.skipall
    pop ebx
    pop edx
    pop eax
    ret

section .bss

.nbg     resw 1
.count   resb 1
.rowleft resb 1
.nextar  resb 1

section .text

NEWSYM cache4bit
    ret
;*******************************************************
; Cache 8-Bit
;*******************************************************
; tile value : bit 15 = flipy, bit 14 = flipx, bit 10-12 = palette, 0-9=tile#
NEWSYM cachetile8b
    ; Keep high word ecx 0
    push eax
    xor ecx,ecx
    push edx
    mov byte[.nextar],1
    push ebx
    ; get tile info location
    test al,20h
    jnz .highptr
    shl eax,6   ; x 64 for each line
    add ax,[bgptr]
    jmp .loptr
.highptr
    and al,1Fh
    shl eax,6   ; x 64 for each line
    add ax,[bgptrc]
.loptr
    add eax,[vram]
    mov bx,[curtileptr]
    shr bx,6
    mov byte[.count],32
    mov [.nbg],bx

    ; do loop
.cacheloop
    mov si,[eax]
    and esi,03FFh
    add si,[.nbg]
    shl esi,2
    and esi,4095
    test dword[vidmemch8+esi],01010101h
    jz near .nocache
    mov dword[vidmemch8+esi],00000000h
    mov edi,esi
    shl esi,4
    shl edi,4
    add esi,[vram]
    add edi,[vcache8b]
    push eax
    mov byte[.rowleft],8
.donext
    xor ah,ah
    xor ebx,ebx
    xor ecx,ecx
    xor edx,edx
    mov byte[.a],0

    mov al,[esi]                ; bitplane 0
    cmp al,0
    je .skipconva
    test al,01h
    jz .skipa0
    or ah,01h
.skipa0
    test al,02h
    jz .skipa1
    or bl,01h
.skipa1
    test al,04h
    jz .skipa2
    or bh,01h
.skipa2
    test al,08h
    jz .skipa3
    or cl,01h
.skipa3
    test al,10h
    jz .skipa4
    or ch,01h
.skipa4
    test al,20h
    jz .skipa5
    or dl,01h
.skipa5
    test al,40h
    jz .skipa6
    or dh,01h
.skipa6
    test al,80h
    jz .skipa7
    or byte[.a],01h
.skipa7
.skipconva

    mov al,[esi+1]                ; bitplane 1
    cmp al,0
    je .skipconvb
    test al,01h
    jz .skipb0
    or ah,02h
.skipb0
    test al,02h
    jz .skipb1
    or bl,02h
.skipb1
    test al,04h
    jz .skipb2
    or bh,02h
.skipb2
    test al,08h
    jz .skipb3
    or cl,02h
.skipb3
    test al,10h
    jz .skipb4
    or ch,02h
.skipb4
    test al,20h
    jz .skipb5
    or dl,02h
.skipb5
    test al,40h
    jz .skipb6
    or dh,02h
.skipb6
    test al,80h
    jz .skipb7
    or byte[.a],02h
.skipb7
.skipconvb

    mov al,[esi+16]                ; bitplane 2
    cmp al,0
    je .skipconvc
    test al,01h
    jz .skipc0
    or ah,04h
.skipc0
    test al,02h
    jz .skipc1
    or bl,04h
.skipc1
    test al,04h
    jz .skipc2
    or bh,04h
.skipc2
    test al,08h
    jz .skipc3
    or cl,04h
.skipc3
    test al,10h
    jz .skipc4
    or ch,04h
.skipc4
    test al,20h
    jz .skipc5
    or dl,04h
.skipc5
    test al,40h
    jz .skipc6
    or dh,04h
.skipc6
    test al,80h
    jz .skipc7
    or byte[.a],04h
.skipc7
.skipconvc

    mov al,[esi+17]                ; bitplane 3
    cmp al,0
    je .skipconvd
    test al,01h
    jz .skipd0
    or ah,08h
.skipd0
    test al,02h
    jz .skipd1
    or bl,08h
.skipd1
    test al,04h
    jz .skipd2
    or bh,08h
.skipd2
    test al,08h
    jz .skipd3
    or cl,08h
.skipd3
    test al,10h
    jz .skipd4
    or ch,08h
.skipd4
    test al,20h
    jz .skipd5
    or dl,08h
.skipd5
    test al,40h
    jz .skipd6
    or dh,08h
.skipd6
    test al,80h
    jz .skipd7
    or byte[.a],08h
.skipd7
.skipconvd

    mov al,[esi+32]                ; bitplane 4
    cmp al,0
    je .skipconve
    test al,01h
    jz .skipe0
    or ah,10h
.skipe0
    test al,02h
    jz .skipe1
    or bl,10h
.skipe1
    test al,04h
    jz .skipe2
    or bh,10h
.skipe2
    test al,08h
    jz .skipe3
    or cl,10h
.skipe3
    test al,10h
    jz .skipe4
    or ch,10h
.skipe4
    test al,20h
    jz .skipe5
    or dl,10h
.skipe5
    test al,40h
    jz .skipe6
    or dh,10h
.skipe6
    test al,80h
    jz .skipe7
    or byte[.a],10h
.skipe7
.skipconve

    mov al,[esi+33]                ; bitplane 5
    cmp al,0
    je .skipconvf
    test al,01h
    jz .skipf0
    or ah,20h
.skipf0
    test al,02h
    jz .skipf1
    or bl,20h
.skipf1
    test al,04h
    jz .skipf2
    or bh,20h
.skipf2
    test al,08h
    jz .skipf3
    or cl,20h
.skipf3
    test al,10h
    jz .skipf4
    or ch,20h
.skipf4
    test al,20h
    jz .skipf5
    or dl,20h
.skipf5
    test al,40h
    jz .skipf6
    or dh,20h
.skipf6
    test al,80h
    jz .skipf7
    or byte[.a],20h
.skipf7
.skipconvf

    mov al,[esi+48]                ; bitplane 6
    cmp al,0
    je .skipconvg
    test al,01h
    jz .skipg0
    or ah,40h
.skipg0
    test al,02h
    jz .skipg1
    or bl,40h
.skipg1
    test al,04h
    jz .skipg2
    or bh,40h
.skipg2
    test al,08h
    jz .skipg3
    or cl,40h
.skipg3
    test al,10h
    jz .skipg4
    or ch,40h
.skipg4
    test al,20h
    jz .skipg5
    or dl,40h
.skipg5
    test al,40h
    jz .skipg6
    or dh,40h
.skipg6
    test al,80h
    jz .skipg7
    or byte[.a],40h
.skipg7
.skipconvg

    mov al,[esi+49]                ; bitplane 7
    cmp al,0
    je .skipconvh
    test al,01h
    jz .skiph0
    or ah,80h
.skiph0
    test al,02h
    jz .skiph1
    or bl,80h
.skiph1
    test al,04h
    jz .skiph2
    or bh,80h
.skiph2
    test al,08h
    jz .skiph3
    or cl,80h
.skiph3
    test al,10h
    jz .skiph4
    or ch,80h
.skiph4
    test al,20h
    jz .skiph5
    or dl,80h
.skiph5
    test al,40h
    jz .skiph6
    or dh,80h
.skiph6
    test al,80h
    jz .skiph7
    or byte[.a],80h
.skiph7
.skipconvh

    ; move all bytes into [edi]
    mov [edi+7],ah
    mov [edi+6],bl
    mov [edi+5],bh
    mov [edi+4],cl
    mov [edi+3],ch
    mov [edi+2],dl
    mov [edi+1],dh
    mov al,[.a]
    mov [edi],al
    add edi,8
    add esi,2
    dec byte[.rowleft]
    jnz near .donext
    pop eax
.nocache
    add eax,2
    dec byte[.count]
    jnz near .cacheloop

    cmp byte[.nextar],0
    je .skipall
    mov bx,[bgptrc]
    cmp [bgptrd],bx
    je .skipall
    add eax,2048-64
    mov byte[.count],32
    mov byte[.nextar],0
    jmp .cacheloop
.skipall
    pop ebx
    pop edx
    pop eax
    ret

section .bss

.nbg     resw 1
.count   resb 1
.a       resb 1
.rowleft resb 1
.nextar  resb 1

section .text

NEWSYM cache8bit
    ret

;*******************************************************
; Cache 2-Bit 16x16 tiles
;*******************************************************

NEWSYM cachetile2b16x16
    ; Keep high word ecx 0
    push eax
    xor ecx,ecx
    push edx
    mov byte[.nextar],1
    push ebx
    ; get tile info location
    test al,20h
    jnz .highptr
    shl eax,6   ; x 64 for each line
    add ax,[bgptr]
    jmp .loptr
.highptr
    and al,1Fh
    shl eax,6   ; x 64 for each line
    add ax,[bgptrc]
.loptr
    add eax,[vram]
    mov bx,[curtileptr]
    shr bx,4
    mov byte[.count],32
    mov [.nbg],bx
    ; do loop
.cacheloop
    mov si,[eax]
    and esi,03FFh
    add si,[.nbg]
    mov byte[.tileleft],4
.nextof4
    and esi,4095
    test byte[vidmemch2+esi],01h
    jz near .nocache
    mov byte[vidmemch2+esi],00h
    push esi
    mov edi,esi
    shl esi,4
    shl edi,6
    add esi,[vram]
    add edi,[vcache2b]
    push eax
    mov byte[.rowleft],8
.donext
    mov cx,[esi]
    processcache2b 0
    processcache2b 1
    processcache2b 2
    processcache2b 3
    processcache2b 4
    processcache2b 5
    processcache2b 6
    processcache2b 7
    add edi,8
    add esi,2
    dec byte[.rowleft]
    jnz near .donext
    pop eax
    pop esi
.nocache
    inc esi
    cmp byte[.tileleft],3
    jne .noadd
    add esi,14
.noadd
    dec byte[.tileleft]
    jnz near .nextof4
    add eax,2
    dec byte[.count]
    jnz near .cacheloop

    cmp byte[.nextar],0
    je .skipall
    mov bx,[bgptrc]
    cmp [bgptrd],bx
    je .skipall
    add eax,2048-64
    mov byte[.count],32
    mov byte[.nextar],0
    jmp .cacheloop
.skipall
    pop ebx
    pop edx
    pop eax
    ret

section .bss

.nbg      resw 1
.count    resb 1
.a        resb 1
.rowleft  resb 1
.nextar   resb 1
.tileleft resb 1

section .text

NEWSYM cache2bit16x16
    ret

;*******************************************************
; Cache 4-Bit 16x16 tiles
;*******************************************************

NEWSYM cachetile4b16x16
    ; Keep high word ecx 0
    push eax
    xor ecx,ecx
    push edx
    mov byte[.nextar],1
    push ebx
    ; get tile info location
    test al,20h
    jnz .highptr
    shl eax,6   ; x 64 for each line
    add ax,[bgptr]
    jmp .loptr
.highptr
    and al,1Fh
    shl eax,6   ; x 64 for each line
    add ax,[bgptrc]
.loptr
    add eax,[vram]
    mov bx,[curtileptr]
    shr bx,5
    mov byte[.count],32
    mov [.nbg],bx

    ; do loop
.cacheloop
    mov si,[eax]
    and esi,03FFh
    add si,[.nbg]
    shl esi,1
    mov byte[.tileleft],4
.nextof4
    and esi,4095
    test word[vidmemch4+esi],0101h
    jz near .nocache
    mov word[vidmemch4+esi],0000h
    push esi
    mov edi,esi
    shl esi,4
    shl edi,5
    add esi,[vram]
    add edi,[vcache4b]
    push eax
    mov byte[.rowleft],8
.donext
    mov cx,[esi]
    mov dx,[esi+16]

    processcache4b 0
    processcache4b 1
    processcache4b 2
    processcache4b 3
    processcache4b 4
    processcache4b 5
    processcache4b 6
    processcache4b 7

    add edi,8
    add esi,2
    dec byte[.rowleft]
    jnz near .donext
    pop eax
    pop esi
.nocache
    add esi,2
    cmp byte[.tileleft],3
    jne .noadd
    add esi,28
.noadd
    dec byte[.tileleft]
    jnz near .nextof4
    add eax,2
    dec byte[.count]
    jnz near .cacheloop

    cmp byte[.nextar],0
    je .skipall
    mov bx,[bgptrc]
    cmp [bgptrd],bx
    je .skipall
    add eax,2048-64
    mov byte[.count],32
    mov byte[.nextar],0
    jmp .cacheloop
.skipall
    pop ebx
    pop edx
    pop eax
    ret

section .bss

.nbg     resw 1
.count   resb 1
.rowleft resb 1
.nextar  resb 1
.tileleft resb 1

section .text

NEWSYM cache4bit16x16
    ret

;*******************************************************
; Cache 8-Bit 16x16 tiles
;*******************************************************

NEWSYM cachetile8b16x16
    ; Keep high word ecx 0
    push eax
    xor ecx,ecx
    push edx
    mov byte[.nextar],1
    push ebx
    ; get tile info location
    test al,20h
    jnz .highptr
    shl eax,6   ; x 64 for each line
    add ax,[bgptr]
    jmp .loptr
.highptr
    and al,1Fh
    shl eax,6   ; x 64 for each line
    add ax,[bgptrc]
.loptr
    add eax,[vram]
    mov bx,[curtileptr]
    shr bx,6
    mov byte[.count],32
    mov [.nbg],bx

    ; do loop
.cacheloop
    mov si,[eax]
    and esi,03FFh
    add si,[.nbg]
    shl esi,2
    mov byte[.tileleft],4
.nextof4
    and esi,4095
    test dword[vidmemch8+esi],01010101h
    jz near .nocache
    mov dword[vidmemch8+esi],00000000h
    push esi
    mov edi,esi
    shl esi,4
    shl edi,4
    add esi,[vram]
    add edi,[vcache8b]
    push eax
    mov byte[.rowleft],8
.donext
    xor ah,ah
    xor ebx,ebx
    xor ecx,ecx
    xor edx,edx
    mov byte[.a],0

    mov al,[esi]                ; bitplane 0
    cmp al,0
    je .skipconva
    test al,01h
    jz .skipa0
    or ah,01h
.skipa0
    test al,02h
    jz .skipa1
    or bl,01h
.skipa1
    test al,04h
    jz .skipa2
    or bh,01h
.skipa2
    test al,08h
    jz .skipa3
    or cl,01h
.skipa3
    test al,10h
    jz .skipa4
    or ch,01h
.skipa4
    test al,20h
    jz .skipa5
    or dl,01h
.skipa5
    test al,40h
    jz .skipa6
    or dh,01h
.skipa6
    test al,80h
    jz .skipa7
    or byte[.a],01h
.skipa7
.skipconva

    mov al,[esi+1]                ; bitplane 1
    cmp al,0
    je .skipconvb
    test al,01h
    jz .skipb0
    or ah,02h
.skipb0
    test al,02h
    jz .skipb1
    or bl,02h
.skipb1
    test al,04h
    jz .skipb2
    or bh,02h
.skipb2
    test al,08h
    jz .skipb3
    or cl,02h
.skipb3
    test al,10h
    jz .skipb4
    or ch,02h
.skipb4
    test al,20h
    jz .skipb5
    or dl,02h
.skipb5
    test al,40h
    jz .skipb6
    or dh,02h
.skipb6
    test al,80h
    jz .skipb7
    or byte[.a],02h
.skipb7
.skipconvb

    mov al,[esi+16]                ; bitplane 2
    cmp al,0
    je .skipconvc
    test al,01h
    jz .skipc0
    or ah,04h
.skipc0
    test al,02h
    jz .skipc1
    or bl,04h
.skipc1
    test al,04h
    jz .skipc2
    or bh,04h
.skipc2
    test al,08h
    jz .skipc3
    or cl,04h
.skipc3
    test al,10h
    jz .skipc4
    or ch,04h
.skipc4
    test al,20h
    jz .skipc5
    or dl,04h
.skipc5
    test al,40h
    jz .skipc6
    or dh,04h
.skipc6
    test al,80h
    jz .skipc7
    or byte[.a],04h
.skipc7
.skipconvc

    mov al,[esi+17]                ; bitplane 3
    cmp al,0
    je .skipconvd
    test al,01h
    jz .skipd0
    or ah,08h
.skipd0
    test al,02h
    jz .skipd1
    or bl,08h
.skipd1
    test al,04h
    jz .skipd2
    or bh,08h
.skipd2
    test al,08h
    jz .skipd3
    or cl,08h
.skipd3
    test al,10h
    jz .skipd4
    or ch,08h
.skipd4
    test al,20h
    jz .skipd5
    or dl,08h
.skipd5
    test al,40h
    jz .skipd6
    or dh,08h
.skipd6
    test al,80h
    jz .skipd7
    or byte[.a],08h
.skipd7
.skipconvd

    mov al,[esi+32]                ; bitplane 4
    cmp al,0
    je .skipconve
    test al,01h
    jz .skipe0
    or ah,10h
.skipe0
    test al,02h
    jz .skipe1
    or bl,10h
.skipe1
    test al,04h
    jz .skipe2
    or bh,10h
.skipe2
    test al,08h
    jz .skipe3
    or cl,10h
.skipe3
    test al,10h
    jz .skipe4
    or ch,10h
.skipe4
    test al,20h
    jz .skipe5
    or dl,10h
.skipe5
    test al,40h
    jz .skipe6
    or dh,10h
.skipe6
    test al,80h
    jz .skipe7
    or byte[.a],10h
.skipe7
.skipconve

    mov al,[esi+33]                ; bitplane 5
    cmp al,0
    je .skipconvf
    test al,01h
    jz .skipf0
    or ah,20h
.skipf0
    test al,02h
    jz .skipf1
    or bl,20h
.skipf1
    test al,04h
    jz .skipf2
    or bh,20h
.skipf2
    test al,08h
    jz .skipf3
    or cl,20h
.skipf3
    test al,10h
    jz .skipf4
    or ch,20h
.skipf4
    test al,20h
    jz .skipf5
    or dl,20h
.skipf5
    test al,40h
    jz .skipf6
    or dh,20h
.skipf6
    test al,80h
    jz .skipf7
    or byte[.a],20h
.skipf7
.skipconvf

    mov al,[esi+48]                ; bitplane 6
    cmp al,0
    je .skipconvg
    test al,01h
    jz .skipg0
    or ah,40h
.skipg0
    test al,02h
    jz .skipg1
    or bl,40h
.skipg1
    test al,04h
    jz .skipg2
    or bh,40h
.skipg2
    test al,08h
    jz .skipg3
    or cl,40h
.skipg3
    test al,10h
    jz .skipg4
    or ch,40h
.skipg4
    test al,20h
    jz .skipg5
    or dl,40h
.skipg5
    test al,40h
    jz .skipg6
    or dh,40h
.skipg6
    test al,80h
    jz .skipg7
    or byte[.a],40h
.skipg7
.skipconvg

    mov al,[esi+49]                ; bitplane 7
    cmp al,0
    je .skipconvh
    test al,01h
    jz .skiph0
    or ah,80h
.skiph0
    test al,02h
    jz .skiph1
    or bl,80h
.skiph1
    test al,04h
    jz .skiph2
    or bh,80h
.skiph2
    test al,08h
    jz .skiph3
    or cl,80h
.skiph3
    test al,10h
    jz .skiph4
    or ch,80h
.skiph4
    test al,20h
    jz .skiph5
    or dl,80h
.skiph5
    test al,40h
    jz .skiph6
    or dh,80h
.skiph6
    test al,80h
    jz .skiph7
    or byte[.a],80h
.skiph7
.skipconvh

    ; move all bytes into [edi]
    mov [edi+7],ah
    mov [edi+6],bl
    mov [edi+5],bh
    mov [edi+4],cl
    mov [edi+3],ch
    mov [edi+2],dl
    mov [edi+1],dh
    mov al,[.a]
    mov [edi],al
    add edi,8
    add esi,2
    dec byte[.rowleft]
    jnz near .donext
    pop eax
    pop esi
.nocache
    add esi,4
    cmp byte[.tileleft],3
    jne .noadd
    add esi,56
.noadd
    dec byte[.tileleft]
    jnz near .nextof4
    add eax,2
    dec byte[.count]
    jnz near .cacheloop

    cmp byte[.nextar],0
    je .skipall
    mov bx,[bgptrc]
    cmp [bgptrd],bx
    je .skipall
    add eax,2048-64
    mov byte[.count],32
    mov byte[.nextar],0
    jmp .cacheloop
.skipall
    pop ebx
    pop edx
    pop eax
    ret

section .bss

.nbg      resw 1
.count    resb 1
.a        resb 1
.rowleft  resb 1
.nextar   resb 1
.tileleft resb 1

section .text

NEWSYM cache8bit16x16
    ret

NEWSYM cachesingle
;    cmp byte[offsetmshl],1
;    je near cachesingle4b
;    cmp byte[offsetmshl],2
;    je near cachesingle2b
    ret

%macro processcache4b2 1
    xor al,al
    add dh,dh
    adc al,al
    add dl,dl
    adc al,al
    add ch,ch
    adc al,al
    add cl,cl
    adc al,al
    mov [edi+%1],al
%endmacro

NEWSYM cachesingle4b
    mov word[ebx],0
    sub ebx,vidmemch4
    push edi
    mov edi,ebx
    shl edi,5           ; cached ram
    shl ebx,4           ; vram
    add edi,[vcache4b]
    add ebx,[vram]
    push eax
    push edx
    mov byte[scacheloop],8
.nextline
    mov cx,[ebx]
    mov dx,[ebx+16]
    processcache4b2 0
    processcache4b2 1
    processcache4b2 2
    processcache4b2 3
    processcache4b2 4
    processcache4b2 5
    processcache4b2 6
    processcache4b2 7
    add ebx,2
    add edi,8
    dec byte[scacheloop]
    jnz near .nextline
    pop edx
    pop eax
    pop edi
    ret

NEWSYM cachesingle2b
    ret

section .bss

NEWSYM scacheloop, resb 1
NEWSYM tiletypec, resb 1

section .text

%macro processcache4b3 1
    xor al,al
    add dh,dh
    adc al,al
    add dl,dl
    adc al,al
    add bh,bh
    adc al,al
    add bl,bl
    adc al,al
    mov [edi+%1],al
    or al,al
    jz %%zeroed
    and byte[tiletypec],1
    jmp %%nozeroed
%%zeroed
    and byte[tiletypec],2
%%nozeroed
%endmacro

NEWSYM cachesingle4bng
    mov word[vidmemch4+ecx*2],0
    mov byte[tiletypec],3
    push edi
    push eax
    push ecx
    push ebx
    push edx
    mov edi,ecx
    shl edi,6           ; cached ram
    shl ecx,5           ; vram
    add edi,[vcache4b]
    add ecx,[vram]
    mov byte[scacheloop],8
.nextline
    mov bx,[ecx]
    mov dx,[ecx+16]
    processcache4b3 0
    processcache4b3 1
    processcache4b3 2
    processcache4b3 3
    processcache4b3 4
    processcache4b3 5
    processcache4b3 6
    processcache4b3 7
    add ecx,2
    add edi,8
    dec byte[scacheloop]
    jnz near .nextline
    pop edx
    pop ebx
    pop ecx
    mov al,[tiletypec]
    mov [tltype4b+ecx],al
    pop eax
    pop edi
    ret

%macro processcache2b3 1
    xor al,al
    add bh,bh
    adc al,al
    add bl,bl
    adc al,al
    mov [edi+%1],al
    or al,al
    jz %%zeroed
    and byte[tiletypec],1
    jmp %%nozeroed
%%zeroed
    and byte[tiletypec],2
%%nozeroed
%endmacro

NEWSYM cachesingle2bng
    mov byte[vidmemch2+ecx],0
    mov byte[tiletypec],3
    push edi
    push eax
    push ecx
    push ebx
    push edx
    mov edi,ecx
    shl edi,6           ; cached ram
    shl ecx,4           ; vram
    add edi,[vcache2b]
    add ecx,[vram]
    mov byte[scacheloop],8
.nextline
    mov bx,[ecx]
    processcache2b3 0
    processcache2b3 1
    processcache2b3 2
    processcache2b3 3
    processcache2b3 4
    processcache2b3 5
    processcache2b3 6
    processcache2b3 7
    add ecx,2
    add edi,8
    dec byte[scacheloop]
    jnz near .nextline
    pop edx
    pop ebx
    pop ecx
    mov al,[tiletypec]
    mov [tltype2b+ecx],al
    pop eax
    pop edi
    ret

%macro processcache8b3 1
    xor esi,esi
    add ch,ch
    adc esi,esi
    add cl,cl
    adc esi,esi
    add dh,dh
    adc esi,esi
    add dl,dl
    adc esi,esi
    add ah,ah
    adc esi,esi
    add al,al
    adc esi,esi
    add bh,bh
    adc esi,esi
    add bl,bl
    adc esi,esi
    push eax
    mov eax,esi
    mov [edi+%1],al
    or al,al
    jz %%zeroed
    and byte[tiletypec],1
    jmp %%nozeroed
%%zeroed
    and byte[tiletypec],2
%%nozeroed
    pop eax
%endmacro

NEWSYM cachesingle8bng
    mov dword[vidmemch8+ecx*4],0
    mov byte[tiletypec],3
    push esi
    push edi
    push eax
    push ecx
    push ebx
    push edx
    mov edi,ecx
    shl edi,6           ; cached ram
    shl ecx,6           ; vram
    add edi,[vcache8b]
    add ecx,[vram]
    mov byte[scacheloop],8
.nextline
    mov bx,[ecx]
    mov ax,[ecx+16]
    mov dx,[ecx+32]
    push ecx
    mov cx,[ecx+48]
    processcache8b3 0
    processcache8b3 1
    processcache8b3 2
    processcache8b3 3
    processcache8b3 4
    processcache8b3 5
    processcache8b3 6
    processcache8b3 7
    pop ecx
    add ecx,2
    add edi,8
    dec byte[scacheloop]
    jnz near .nextline
    pop edx
    pop ebx
    pop ecx
    mov al,[tiletypec]
    mov [tltype8b+ecx],al
    pop eax
    pop edi
    pop esi
    ret

SECTION .bss
NEWSYM dcolortab, resd 256
NEWSYM res640, resb 1
NEWSYM res480, resb 1
NEWSYM lineleft, resd 1

SECTION .data
NEWSYM videotroub,      dd 0
NEWSYM vesa2_clbit,     dd 0
NEWSYM vesa2_rpos,      dd 0
NEWSYM vesa2_gpos,      dd 0
NEWSYM vesa2_bpos,      dd 0
NEWSYM vesa2_clbitng,   dd 0
NEWSYM vesa2_clbitng2,  dd 0,0
NEWSYM vesa2_clbitng3,  dd 0
NEWSYM vesa2red10,      dd 0
NEWSYM vesa2_rtrcl,     dd 0
NEWSYM vesa2_rtrcla,    dd 0
NEWSYM vesa2_rfull,     dd 0
NEWSYM vesa2_gtrcl,     dd 0
NEWSYM vesa2_gtrcla,    dd 0
NEWSYM vesa2_gfull,     dd 0
NEWSYM vesa2_btrcl,     dd 0
NEWSYM vesa2_btrcla,    dd 0
NEWSYM vesa2_bfull,     dd 0
NEWSYM vesa2_x,         dd 320
NEWSYM vesa2_y,         dd 240
NEWSYM vesa2_bits,      dd 8
NEWSYM vesa2_rposng,    dd 0
NEWSYM vesa2_gposng,    dd 0
NEWSYM vesa2_bposng,    dd 0
NEWSYM vesa2_usbit,     dd 0
