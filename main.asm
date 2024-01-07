.model small,stdcall

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

    longRotated   db 2, 2, 2, 2
                  db 0, 0, 0, 0
                  db 0, 0, 0, 0
                  db 0, 0, 0, 0

    lFigure       db 4, 0, 0, 0
                  db 4, 0, 0, 0
                  db 4, 0, 0, 0
                  db 4, 4, 4, 0

    lFigureRotation1    db 4, 4, 4, 4
                        db 0, 0, 0, 4
                        db 0, 0, 0, 4
                        db 0, 0, 0, 4

    lFigureRotation2    db 0, 0, 0, 4
                        db 0, 0, 0, 4
                        db 0, 0, 0, 4
                        db 4, 4, 4, 4

    tFigure       db 0, 3, 0, 0
                  db 3, 3, 3, 0
                  db 0, 0, 0, 0
                  db 0, 0, 0, 0

    tFigureRotation1    db 3, 0, 0, 0
                        db 3, 3, 0, 0
                        db 3, 0, 0, 0
                        db 0, 0, 0, 0

    tFigureRotation2    db 3, 3, 3, 0
                        db 0, 3, 0, 0
                        db 0, 0, 0, 0
                        db 0, 0, 0, 0

    tFigureRotation3    db 0, 3, 0, 0
                        db 3, 3, 0, 0
                        db 0, 3, 0, 0
                        db 0, 0, 0, 0

    ; each figure has this attrs
    curFigureMaxX db 0
    curFigureMaxY db 0
    curFigure dw offset tFigureRotation2
    curFigureRotationAmount db 0
    curFigureRotationId db 0

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

;keys
RIGHT_KEY = 4dh
LEFT_KEY = 4bh

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

@@updateMaxX:
    mov [curFigureMaxX], cl
    jmp @@maxXUpdated

@@updateMaxY:
    mov [curFigureMaxY], bl
    jmp @@maxYUpdated

@@startDrawFigure:
    mov ax, VIDEO_RAM
    mov es, ax

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

    mov bx, 4 ;figure rows [1, 4]
    @@row:
        xor cx, cx
        mov cl, 04h
        @@col:
            xor ax, ax
            lodsb ; ds[si] -> al
            cmp al, 0
            je @@skip

            mov bh, [curFigureMaxX]
            cmp bh, cl
            jl @@updateMaxX

            @@maxXUpdated:
            mov bh, [curFigureMaxY]
            cmp bh, bl
            jl @@updateMaxY

            @@maxYUpdated:
            call pickColor
            @@print:
                stosw ; ax -> es[di]
                jmp @@loop
            @@skip:
                add di, 2
            @@loop:
        loop @@col

        xor ax, ax
        mov ax, di
        sub ax, 8
        add ax, MAX_COLUMN_COUNT * 2

        mov di, ax
    dec bl
    cmp bl, 0
    ja @@row
ret
drawFigure endp

exit proc
    mov ah, 4ch
    int 21h
    ret
exit endp

sleep proc
    push cx
    mov cx, 0Fh
    mov dx, 4240h
    mov ah, 86h
    int 15h
    ret
sleep endp

handleKey proc
jmp @@startHandleKey

@@handleRight:
    mov al, [xCoord]
    mov ah, PLAYING_FIELD_SIZE + 1
    sub ah, [curFigureMaxX]

    cmp al, ah
    jae @@clearBuffer

    inc al
    mov [xCoord], al
    jmp @@clearBuffer

@@handleLeft:
    mov al, [xCoord]
    cmp al, 0
    je @@clearBuffer

    dec al
    mov [xCoord], al
    jmp @@clearBuffer

@@clearBuffer:
    mov ah, 0h ; read from buffer
    int 16h

    mov ah, 1h ; mov ah -> scan code, al -> asci
    int 16h
    jnz @@clearBuffer ; check zero flag

    jmp @@ret

@@startHandleKey:
    mov ah, 1h ; mov ah -> scan code, al -> asci
    int 16h
    jz @@ret ; check zero flag

    cmp ah, RIGHT_KEY
    je @@handleRight

    cmp ah, LEFT_KEY
    je @@handleLeft

    @@ret:
        ret
handleKey endp

main: 
    mov ax, @data
    mov ds, ax

    mov cx, ROW_COUNT - 1
    ;;init field array
    ;;on finish cycle we will save figure position in memory
    ;; afterwards we will redraw all figures on draw field
    ;;need rewrite logic: init playing field and save on each figure move instead redrawing
    @@cycle:
        push cx
        call drawField
        call drawFigure

        call sleep
        call handleKey

        pop cx

        mov al, [yCoord]
        inc al

        mov [yCoord], al
    loop @@cycle

    @@exit: 
        call exit
end main