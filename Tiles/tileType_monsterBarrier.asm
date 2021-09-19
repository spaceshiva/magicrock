;; monster barrier

LDA Object_flags,x
;; if x equals monster (x && 01000 == true)
;; this flag represents the 4th position in "monster flags" in object details.
AND #%00001000
BEQ +continueCheck
	JMP +makeObjectSolid

+continueCheck
AND #%00000001 ;; NPC (block for us)
BEQ +skipObjectIsNotSolid

+makeObjectSolid
	LDA ObjectUpdateByte
	ORA #%00000001
	STA ObjectUpdateByte ;; makes solid

+skipObjectIsNotSolid
RTS