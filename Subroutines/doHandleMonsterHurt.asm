;; transform the monsters into stone
;; loaded by SCR_HANDLE_MONSTER_HURT
;; called by label doHandleHurtMonster

    ;;;;;;;;;;;; prepare object creation
    LDA Object_screen,x
	STA tempD
	
	LDA Object_x_hi,x
	STA tempA
	
	LDA Object_y_hi,x
	STA tempB
   
    LDA #$08 ; ground block
    STA tempC

    LDA Object_vulnerability,x
    AND #%0000010 ;; flag1
    BEQ +continueCheck
        LDA #$0A ;HLeftElevatorBlock
        STA tempC
        JMP +replaceObject 
    
    +continueCheck
    LDA Object_vulnerability,x
    AND #%0000001 ;; gravity
    BEQ +replaceObject
        LDA #$09 ; floating block
        STA tempC

    ;; TODO: maybe having a vertical / horizontal blocks as well?

    ;; destroys the current monster and put a block in its place
    +replaceObject          
        ;; before destroying, maybe changing the action to hurt?
        ;; in this case we need to change to "destroy object" after the animation ends, not here
        ;ChangeActionStep otherObject, #$07
        ;LDA otherObject
        DestroyObject

        TXA
        PHA
        CreateObjectOnScreen tempA, tempB, tempC, #$00, tempD
                ;;; x, y, object, starting action, screen.
        PLA
        TAX