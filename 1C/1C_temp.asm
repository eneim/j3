  ORG 10
	LDA N
	BSA MUL10
	STA N
	HLT
MUL10,	HEX 0
		STA TMP
		CIL
		CIL
		CIL
		ADD TMP
		ADD TMP
		BUN MUL10 I

/// init ///
N,	DEC 	24
TMP,	DEC	0
	END
