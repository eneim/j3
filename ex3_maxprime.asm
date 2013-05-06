  	ORG 10		/ start
	LDA N
	STA X
	CIR
	STA T		/ temp = N >> 1, test with N first
/ loop 1: run the division
LOP1,	CLA
	LDA T		/ load temp variable
	STA Y		/ M[Y] = M[TMP]
	CLA		/ AC <- 0
	LDA Y		/ AC <- M[Y]
	CMA		/ AC <- ~AC
	INC		/ AC <- AC + 1 (AC = -M[Y])
	ADD X 		/ AC <- AC + M[X] (AC <- M[X] - M[Y])	
	STA X		/ X <- AC
	SNA		/ if (AC < 0) then skip next step
	STA R		/ M[R] <- AC
	SNA		/ if (AC < 0) then skip next step
	BUN LOP1	/ goto to LOP
	LDA R
	SZA		/ if R = 0 then X is not a prime, skip next step
	BUN LOP2	/ if R != 0 then test with Y = Y - 1
	BUN LOP		/ R = 0 run LOP to check if Y = 1 or not
/ loop 2: Y --, load N to X, test N/(Y-1)
LOP2,	LDA Y
	BSA SH4
	STA T		/ Y = Y - 1
	CLA
	LDA N
	STA X		/ X <- N
	BUN LOP1
	HLT
/ loop: R = 0 then load N - 1 to N, test again
/ R = 0 then firstly check that if Y = 1 or not
LOP,	LDA N
	STA LAST
	BSA SH4		/ N = N - 1, AC = M[N] - 1
	STA N		/ M[N] <- AC
	STA X
	CIR
	STA T
	LDA Y
	BSA SH4
	STA Y
	LDA Y
	SZA		/ if Y = 0 then skip next step	
	BUN LOP1	/ Y != 0 then test with N = N - 1
	HLT
/ sub routine : X = X - 1
SH4,	HEX 0
	CMA		/ AC <- ~AC
	INC		/ AC <- AC + 1
	CMA		/ AC <- ~AC
	BUN SH4 I	/ return from SH4
/ end if sub routine
LAST,	DEC 1		/ M[LAST] : the biggest prime number that is not exceed N
N,	DEC 40000	/ M[N] = 40000
X,	DEC 1		/ M[X] = 1
Y,	DEC 1		/ M[Y] = 1
T,	DEC 0		/ temp
R,	DEC 0		/ M[R] = 0, (Y, R) return (1, 0) then N is prime
	END
