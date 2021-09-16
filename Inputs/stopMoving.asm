;;;; 
    ;; clear the collision flags
    LDA #$00
    STA colInfo
    
    STX temp ;; assumes the object we want to move is in x. 
   GetActionStep temp
    CMP #$07
    BNE +notHurt
        RTS
    +notHurt   
    StopMoving temp, #$FF, #$00
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    RTS