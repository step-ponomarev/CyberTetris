.model small
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
    mov di, 0

    mov si, [curFigure]
    mov cx, 4 ;figure rows
    @@row:
        add di, 2 ; + left board: 1 byte color 1 byte symbol 
        mov bx, 1;
        @@col:
            ;if figure print
            cmp bx, 4
            ja @@printPlayngField
            
            lodsb ; ds[si] -> al
            cmp al, 0
            je @@printPlayngField

            call pickColor
            @@print:
                stosw ; ax -> es[di]

            inc bx
            cmp bx, PLAYING_FIELD_SIZE - 1
            jne @@col
        
        add di, 2
        mov bx, MAX_COLUMN_COUNT - PLAYING_FIELD_SIZE
        call fillEmptyRow
    loop @@row
ret
drawFigure endp

exit proc
    mov ah, 4ch
    int 21h
    ret
exit endp

main: 
    mov ax, @data
    mov ds, ax

    call drawField
    call drawFigure

    call exit
end main