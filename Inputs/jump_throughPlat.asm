;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Only can jump if the place below feet is free.
    SwitchBank #$1C

    ;; we check if the colisions flag are defined -> #$01 means e are above a block, so we can jump
    LDA colInfo
    CMP #$01
    BNE +checkMore
        JMP +doJump
    +checkMore

    LDY Object_type,x
    LDA ObjectBboxTop,y
    CLC
    ADC ObjectHeight,y
    STA temp2
    
    LDA Object_x_hi,x
    CLC
    ADC ObjectBboxLeft,y
    STA temp
    JSR getPointColTable
    
    LDA Object_y_hi,x
    CLC
    ADC #$02
    CLC
    ADC temp2
    STA temp1

    CheckCollisionPoint temp, temp1, #$01, tempA ;; check below feet to see if it is solid.
                                        ;;; if it is (equal), can jump.
                                        ;;; if not, skips jumping.
    BNE +checkMore 
        JMP +doJump
    +checkMore
    
    CheckCollisionPoint temp, temp1, #$07, tempA ;; check below feet to see if it is jumpthrough platform.
                                        ;;; if it is (equal), can jump.
                                        ;;; if not, skips jumping.
    BNE +checkMore 
        JMP +doJump
    +checkMore
     CheckCollisionPoint temp, temp1, #$09, tempA ;; check below feet to see if it is prize block .
                                        ;;; if it is (equal), can jump.
                                        ;;; if not, skips jumping.
    BNE +checkMore 
        JMP +doJump
    +checkMore
    CheckCollisionPoint temp, temp1, #$0A, tempA ;; check below feet to see if it is ladder.
                                        ;;; if it is (equal), can jump.
                                        ;;; if not, skips jumping.

     BNE +dontDoJump
        JMP  +doJump
        +dontDoJump
            ;; check second point.
        LDY Object_type,x
        LDA ObjectWidth,y
        CLC
        ADC temp
        STA temp
        JSR getPointColTable
        CheckCollisionPoint temp, temp1, #$01, tempA ;; check below feet to see if it is solid.
                                            ;;; if it is (equal), can jump.
                                            ;;; if not, skips jumping.          
        BEQ +doJump
        
        CheckCollisionPoint temp, temp1, #$07, tempA ;; check below feet to see if it is jumpthrough platform.
                                        ;;; if it is (equal), can jump.
                                        ;;; if not, skips jumping.
        BEQ +doJump
        CheckCollisionPoint temp, temp1, #$09, tempA ;; check below feet to see if it is jumpthrough platform.
                                        ;;; if it is (equal), can jump.
                                        ;;; if not, skips jumping.
        BEQ +doJump
        CheckCollisionPoint temp, temp1, #$0A, tempA ;; check below feet to see if it is ladder.
                                        ;;; if it is (equal), can jump.
                                        ;;; if not, skips jumping.
        BEQ +doJump
            JMP +skipJumping
+doJump:
    STX temp ;; assumes the object we want to move is in x.
    ;PlaySound #sfx_thump

    LDY Object_type,x
    LDA ObjectJumpSpeedLo,y
    EOR #$FF
    STA Object_v_speed_lo,x
    LDA ObjectJumpSpeedHi,y
    EOR #$FF
    STA Object_v_speed_hi,x

    ;; clear the block colision flag
    LDA #$00
    STA colInfo
        
    ;STX temp ;; assumes the object we want to move is in x.

 ;  change the object's action so that he is in jump mode.

+skipJumping:
    ReturnBank
    RTS