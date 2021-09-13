;; transform the monsters into stone
;; loaded by SCR_HANDLE_MONSTER_HURT
;; called by label doHandleHurtMonster

    ;; destroys the current monster and put a block in its place
    LDX otherObject
    LDA Object_screen,x
	STA tempD
	
	LDA Object_x_hi,x
	STA tempA
	
	LDA Object_y_hi,x
	STA tempB

    ;; before destroying, maybe changing the action to hurt?
    ;; in this case we need to change to "destroy object" after the animation ends, not here
    ;ChangeActionStep otherObject, #$07

    LDA otherObject
    DestroyObject

	TXA
    PHA
    CreateObjectOnScreen tempA, tempB, #$08, #$00, tempD
    		;;; x, y, object, starting action, screen.
    PLA
    TAX