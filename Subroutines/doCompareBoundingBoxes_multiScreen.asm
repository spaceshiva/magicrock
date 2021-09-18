;;; to understand compare in 6502: http://6502.org/tutorials/compare_instructions.html

doCompareBoundingBoxes:
	LDA $00
	STA tempC
	;;; more complicated than this
	; LDA self_screen
	; CMP other_screen
	; BNE noBboxCollision
	
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Here we will check the horizontal collision.
;;; First we need to check the RIGHT SCREEN + RIGHT BBOX of self against the
;;; LEFT SCREEN + LEFT BBOX of other.  If it is less, then there is no collision.

	LDA self_screen_right
	CMP other_screen_left
	BEQ +theseAreEqual
		;;; the self screen and other screen are not equal.
		;;; But if the self screen is MORE than the other screen,
		;;; it is still possible that this could return a collision.
		JMP +checkOtherSide
	
	+theseAreEqual
		;;; we need to check the *other* side
		LDA self_screen_left
		CMP other_screen_right
		BEQ +normalBoundsCheck
			;; this means bounds are being straddled.
			LDA bounds_right
			CMP other_left
			BCC +noBboxCollision ;; less
				JMP +hCol
		+normalBoundsCheck
	
		;; the self screen and other screen are equal
		;; which means now it is a matter of checking the 
		;; self right bbox against the left bbox.
		LDA bounds_right
		CMP other_left
		BCC +noBboxCollision
	
	
	+continueCollisionCheck
	+checkOtherSide	
	LDA self_screen_left
	CMP other_screen_right
	BEQ +theseAreEqual
		JMP +noBboxCollision	
	+theseAreEqual
		;;; check the *other* side
		LDA self_screen_right
		CMP other_screen_left
		BEQ +normalBoundsCheck
			
		+normalBoundsCheck
			LDA bounds_left
			CMP other_right
			BCS +noBboxCollision
		
+hCol
	LDA other_bottom
	CMP bounds_top
	BCC +noBboxCollision ;; less
	LDA bounds_bottom
	CMP other_top
	BCC +noBboxCollision ;; less

	LDA tempC
	ORA #%00000001 ;;horizontal collision
	STA tempC

;;;;;;;;;;;;;;;;;;
;; check now vertical collision
;; TODO: figure how to identify vertical collision and avoid doing horizontal collision when we are on top

+vCol
	LDA other_top
	CLC
	ADC #$03
	CMP bounds_bottom
	BCC +returnCol
	;; happened a vertical collision
	LDA tempC
	ORA #%00000010 ;;vertical
    ;;          | |
	;;          | ---> happened a collision, no matter where
	;;          |----> vertical collision
	STA tempC

;;;;;;;;;;;;;;;;;;	

+returnCol
	LDA tempC
	RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
noBboxCollision;; there is no collision here horizontally.
	LDA #$00 ;; read that NO, there was no collision.
	RTS
	
	
getOtherColBox:
	TYA
	PHA

		; LDA Object_x_hi,x
		; CLC
		; ADC #$10
		; LDA Object_screen,x
		; ADC #$00
		; STA other_screen_right
		LDY Object_type,x
		
		LDA Object_x_hi,x
		CLC
		ADC ObjectBboxLeft,y
        STA other_left
		LDA Object_screen,x
		ADC #$00
		STA other_screen_left
		
		LDA other_left
		CLC
		ADC ObjectWidth,y
        STA other_right
		LDA Object_screen,x
		ADC #$00
		STA other_screen_right
	
		
		LDA other_right

        SEC
        SBC other_left
        LSR
        STA other_center_x
        
        LDA ObjectBboxTop,y
		CLC
		ADC Object_y_hi,x
        STA other_top
        CLC
        ADC ObjectHeight,y
        STA other_bottom
        SEC
        SBC other_top
        LSR
        STA other_center_y ;; self center in the vertical direction.
		; LDA Object_screen,x
		; STA other_screen
	
	PLA
	TAY
	RTS