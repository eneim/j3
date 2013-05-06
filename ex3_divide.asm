      	ORG 10		/ start
LOP,	LDA Y		/ AC <- M[Y]
		CMA		 	/ AC <- ~AC
		INC		  	/ AC <- AC + 1 (AC = -M[Y])
		ADD X 		/ AC <- AC + M[X] (AC <- M[X] - M[Y])	
		STA X		/ X <- AC
		ISZ P		/ M[P]++
		SNA		  	/ if (AC < 0) then skip next step
		STA R		/ M[R] <- AC
		SNA		 	/ if (AC < 0) then skip next step
		BUN LOP		/ goto to LOP
		CLA		  	/ AC <- 0	
		LDA P		/ AC <- M[P]
		CMA		  	/ AC <- ~AC
		INC		  	/ AC <- AC + 1
		CMA		  	/ AC <- ~AC
		STA P		/ M[P] <- AC, M[P] <- M[P] - 1
/ init data
X,	  DEC 300		/ M[X] = 300
Y,	  DEC 37		/ M[Y] = 37
P,  	DEC 0		/ M[P] = 0
R,	  DEC 0			/ M[R] = 0
	    END		  	/ end
