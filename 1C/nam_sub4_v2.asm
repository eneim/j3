  	ORG 10		/ start
	LDA N 		/ first step
	CIR
	STA Y		/ temp = N/2, test with N first
MAIN,	ADD M2		/ AC <- M[Y] - 2 (to check if Y >= 2 or not)
	SPA 		/ AC >= 0 then skip next
	HLT
	BSA GETR	/ after this step, AC = M[R]
	LDA R
	// check R: 
	// if R = 0 then check if Y = 1 -> finish, if Y > 1: N <- N - 1, goto MAIN
	// if R != 0 then Y <- Y - 1, goto MAIN
	SZA		/ if R = 0 then skip next step
	BSA RE_Y	/ R != 0 (R < Y -> Y > 1) then Y <- Y - 1, goto MAIN
	// R = 0 then N <- N - 1, check Y and goto MAIN or HALT
	BSA RE_N
	LDA Y 		/ Load AC <- Y to check if Y > 1 or not
	BUN MAIN

// compute N % Y -> R
GETR,	HEX 0
	LDA N
	STA LAST	/ store the recent N to LAST
	STA X
DV,			/ X % Y
	LDA X
	STA R		/ M[R] <- AC
	LDA Y		/ load Y
	CMA		/ AC <- ~AC
	INC		/ AC <- AC + 1 (AC = -M[Y])
	ADD X 		/ AC <- AC + M[X] (AC <- M[X] - M[Y])	
	STA X		/ X <- 
	SNA		/ if (AC < 0) then skip next step
	BUN DV		/ goto to DV
	BUN GETR I

// refresh N: N <- N - 1
RE_N,	HEX 0
	LDA R
	SZA 		/ R = 0 then skip next
	BUN RE_N I 	/ R! = 0 then back
	LDA N 		/ Y != 1 then N <- N - 1		
	ADD M1
	STA N		/ M[N] <- AC
	CLE
	CIR
	STA Y
	BUN RE_N I

/ refresh Y: re-load Y <- Y - 1, if Y return 1 then
RE_Y,	HEX 0
	LDA Y
	ADD M1
	STA Y
	BUN RE_Y I

/ init
LAST,	DEC 0		/ M[LAST] : the biggest prime number that does not exceed N
N,	DEC 768		/ M[N] = 690, MAX N = 32770
X,	DEC 1		/ M[X] = 1
Y,	DEC 1		/ M[Y] = 1
R,	DEC 0		/ M[R] = 0, (Y, R) return (1, 0) then N is prime
M1,	DEC -1
M2,	DEC -2
	END
