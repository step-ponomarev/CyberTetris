.model small, stdcall
.stack 256h
.data
    squareFigure  db 1, 1, 0, 0
                  db 1, 1, 0, 0
                  db 0, 0, 0, 0
                  db 0, 0, 0, 0

    longFigure    db 2, 0, 0, 0
                  db 2, 0, 0, 0
                  db 2, 0, 0, 0
                  db 2, 0, 0, 0

    tFigure       db 0, 3, 0, 0
                  db 3, 3, 3, 0
                  db 0, 0, 0, 0
                  db 0, 0, 0, 0

    lFigure       db 4, 0, 0, 0
                  db 4, 0, 0, 0
                  db 4, 0, 0, 0
                  db 4, 4, 4, 0

    curFigure dw offset longFigure

    xCoord db 0
    yCoord db 0
.code
;colored symbols
FIELD_SYMBOL = 10DBh
BLACK_SYMBOL = 00DBh
WHITE_SYMBOL = 0FFDBh

ORANGE_SYMBOL = 44DBh
PURPLE_SYMBOL = 55DBh
BLUE_SYMBOL = 33DBh
GREEN_SYMBOL = 22DBh

;playing filed sizes
MAX_COLUMN_COUNT = 80
ROW_COUNT = 21
PLAYING_FIELD_SIZE = 12

VIDEO_RAM = 0b800h

pickColor proc
    cmp al, 1
    je @@pickSquareColor

    cmp al, 2
    je @@pickLColor

    cmp al, 3
    je @@pickTColor

    cmp al, 4
    je @@pickLColor

    @@pickSquareColor:
        mov ax, ORANGE_SYMBOL
        jmp @@ret

    @@pickLongColor:
        mov ax, PURPLE_SYMBOL
        jmp @@ret

    @@pickTColor:
        mov ax, GREEN_SYMBOL
        jmp @@ret
        
    @@pickLColor:
        mov ax, BLUE_SYMBOL
        jmp @@ret

@@ret:
    ret
pickColor endp

; prepare BX Before call
fillEmptyRow proc
    mov ax, BLACK_SYMBOL ; 20 space 10 color

    @@empty:
        stosw ; ax -> es[di]
        dec bx
        jnz @@empty
ret
fillEmptyRow endp

drawField proc 
jmp @@startDrawField

@@printFrame:
    mov ax, WHITE_SYMBOL ; 20 space 10 color
    jmp @@print

@@startDrawField: 
    ;init data segments
    mov ax, VIDEO_RAM ;vdieo ram
    mov es, ax ; es -> 0b800h
    mov di, 0   ;es[di]
    
    mov cx, ROW_COUNT  ;rows
    @@row:
        mov bx, PLAYING_FIELD_SIZE ;columns
        @@col:
            ;bottom frame
            cmp cx, 1
            je @@printFrame

            ;left frame
            cmp bx, PLAYING_FIELD_SIZE
            je @@printFrame

            ;right frame
            cmp bx, 1
            je @@printFrame
        
            mov ax, FIELD_SYMBOL ; 20 space 10 color
            @@print:
                stosw ; ax -> es[di]
        
            dec bx
            jnz @@col

        mov bx, MAX_COLUMN_COUNT - PLAYING_FIELD_SIZE
        call fillEmptyRow
    loop @@row
    
ret
drawField endp


drawFigure proc
jmp @@startDrawFigure

@@printPlayngField:
    mov ax, FIELD_SYMBOL
    jmp @@print

@@startDrawFigure:
    mov ax, VIDEO_RAM
    mov es, ax ; 

    mov si, [curFigure]

    ;prepare position
    xor ax, ax
    mov al, [yCoord]
    mov dl, MAX_COLUMN_COUNT
    mul dl

    xor dx, dx
    mov dl, [xCoord]
    add ax, dx
    inc ax

    ;each pipxel is 2 bytes [attr, symbol]
    shl ax, 1 
    
    mov di, ax

    mov bx, 0 ;figure rows [1, 4]
    @@row:
        mov cx, 4
        @@col:
            xor ax, ax
            lodsb ; ds[si] -> al
            cmp al, 0
            je @@printPlayngField

            call pickColor
            @@print:
                stosw ; ax -> es[di]
        loop @@col

        xor ax, ax
        mov ax, di
        sub ax, 8
        add ax, MAX_COLUMN_COUNT * 2

        mov di, ax
    inc bx
    cmp bx, 4
    jl @@row
ret
drawFigure endp

exit proc
    mov ah, 4ch
    int 21h
    ret
exit endp

Sleep proc
    mov cx, 0FFFFh
    @@sleep:
        mov dx, 0FFFFh
        mov ah, 86h
        int 15h
        int 15h
        int 15h
        int 15h
        int 15h

    loop @@sleep

    ret
Sleep endp

main: 
    mov ax, @data
    mov ds, ax

    call drawField
        call drawFigure


    @@cycle:
        call drawField
        call drawFigure

        call Sleep

        mov al, [yCoord]
        cmp al, 16
        je @@exit

        inc al
        mov bx, offset yCoord
        mov [bx], al
    jmp @@cycle


    @@exit: 
        call exit
end main