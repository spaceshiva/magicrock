;;;; Choose out of 4 directions, UDLR.
	STX tempA
	LDA #%00000010  ;; "right"
	TAY
	LDA DirectionTableOrdered,y
	STA tempB
	LDA FacingTableOrdered,y
	STA tempC
	StartMoving tempA, tempB, #$00
	ChangeFacingDirection tempA, tempC
	
	
