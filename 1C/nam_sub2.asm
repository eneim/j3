		ORG 10		/ start
		LDA X
LOP,	STA R		/ M[R] <- AC
		LDA Y		/ AC <- M[Y]
		CMA			/ AC <- ~AC
		INC			/ AC <- AC + 1 (AC = -M[Y])
		ADD X 		/ AC <- AC + M[X] (AC <- M[X] - M[Y])	
		STA X		/ X <- AC
		ISZ P		/ M[P]++
		SNA			/ if (AC < 0) then skip next step
		BUN LOP		/ goto to LOP
		LDA P		/ AC <- M[P]
		ADD S1		/ AC <- AC - 1
		STA P		/ M[P] <- AC
		HLT
X,		DEC 65533	/ M[X] = 32781
Y,		DEC 32767
P,		DEC 0		/ M[P] init = 0
R,		DEC 0		/ M[R] init = 0
S1, 	DEC -1  	/ M[S1] = -1
		END			/ end