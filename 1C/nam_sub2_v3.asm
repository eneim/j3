		ORG 10		/ start
SHF,	
		CLA
		LDA Y
		CMA
		INC
		ADD X	// A <- X - Q
		SPA		// X >= Q then skip next step
		BUN P_NO
		BUN NXT

NXT,			// X >= Q then Q <- Q << 1
		CLE
		LDA CNT
		INC
		STA CNT	// counter ++
		LDA Y
		CIL
		STA Y
		BUN SHF

FIN,
		LDA CNT
		ADD VM1
		STA CNT 	// counter --
		CLE
		LDA Y
		CIR
		STA Y		// Y <- Y >> 1
		CMA
		INC
		ADD X
		STA TMP		// X <- X - Y
		SPA			// X - Y >= 0 then skip next step
		BUN P_NO
		BUN P_YES

P_NO,	
		CLE			// X - Y <= 0
		LDA R
		CIL
		STA R
		LDA CNT
		SZA		
		BUN FIN
		HLT

P_YES,				// X - Y > 0
		LDA TMP
		STA X
		CLE
		LDA R
		CIL
		INC
		STA R
		LDA CNT
		SZA		
		BUN FIN
		HLT

X,		DEC 65533	/ M[X] = 32781
Y,		DEC 32767
R,		DEC 0		/ M[R] init = 0
CNT,	DEC 0
VM1, 	DEC -1  	/ M[S1] = -1
TMP,	DEC 0
		END			/ end