		ORG 10	/ start
		LDA N 	/ first step
		STA LAST
		CIR
		STA Y		/ temp = N/2, test with N first
MAIN,		ADD M2	/ AC <- M[Y] - 2 (to check if Y >= 2 or not)
		SPA 		/ AC >= 0 then skip next
		BUN OUTP	/ OUTPUT
		BSA GETR	/ after this step, AC = M[R]
		LDA R
	// check R: 
	// if R = 0 then check if Y = 1 -> finish, if Y > 1: N <- N - 1, goto MAIN
	// if R != 0 then Y <- Y - 1, goto MAIN
		SZA			/ if R = 0 then skip next step
		BSA RE_Y		/ R != 0 (R < Y do Y > 1) then Y <- Y - 1, goto MAIN
	// R = 0 then N <- N - 1, check Y and goto MAIN or HALT
		BSA RE_N
		LDA Y 		/ Load AC <- Y to check if Y > 1 or not
		BUN MAIN

// compute N % Y -> R
GETR,	HEX 0
		LDA N
		STA LAST	/ store the recent N to LAST
		STA X
	DV,				/ X % Y
		LDA X
		STA R		/ M[R] <- AC
		LDA Y		/ load Y
		CMA			/ AC <- ~AC
		INC			/ AC <- AC + 1 (AC = -M[Y])
		ADD X 		/ AC <- AC + M[X] (AC <- M[X] - M[Y])	
		STA X		/ X <- 
		SNA			/ if (AC < 0) then skip next step
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

//////////////////// OUTPUT PROCESS /////////////////////
OUTP,		HEX 0
		LDA LAST
		STA Z
		LDA Z
		BSA WRITE_Z
		LDA VM5
		STA CNT
S_OUT,	SKO				/ if (S_OUT ready) -> skip next
		BUN S_OUT			/ S_OUT not ready: goto L1
		LDA A_ZMG I
		OUT
		ISZ A_ZMG		/ ++M[A_OUT]
		ISZ CNT			/ if (++M[CNT]) skip next
		BUN S_OUT			/ goto L1 (next output)
		HLT				/ halt
		BUN OUTP I

WRITE_Z,	HEX 0		/ return address
////////// subroutine (write Z to ZMG) //////////
		LDA A_ZMG		/ AC <- M[A_ZMG] (ZMG)
		ADD VH4			/ AC <- ZMG + 4
		STA TMA			/ M[TMA] <- ZMG + 4
		LDA VM5			/ AC <- M[VM4] (-4)
		STA CNT			/ M[CNT] <- -4
PUT_DGT,
		LDA Z			/ AC <- M[Z]
		BSA DV10
		LDA R_O
		ADD CH_0		/ AC <- (M[Z] & 000f) + '0'
STR_DGT,
		STA TMA I		/ M[M[TMA]] <- AC
		LDA P
		STA Z			/ M[Z] <- M[Z] >> 4
		CLA
		STA P
		LDA TMA			/ AC <- M[TMA]
		ADD VM1			/ AC <- M[TMA] - 1
		STA TMA			/ M[TMA] <- M[TMA] - 1
		ISZ CNT			/ ((++M[CNT]) = 0) ? skip next
		BUN PUT_DGT		/ goto PUT_DGT
		BUN WRITE_Z I	/ return from OUT_Z

// compute TMX % 10 -> P, R
DV10,	HEX 0
		STA TMX
LOP,	STA R_O		/ M[R] <- AC
		ADD VM10	
		STA TMX	/ X <- AC
		ISZ P		/ M[P]++
		SNA		/ if (AC < 0) then skip next step
		BUN LOP	/ goto to LOP
		CLA		/ AC <- 0	
		LDA P		/ AC <- M[P]
		ADD S1	/ AC <- AC - 1
		STA P		/ M[P] <- AC
		BUN DV10 I

/ init
LAST,	DEC 0		/ M[LAST] : the biggest prime number that does not exceed N
N,	DEC 999	/ M[N] = 999, MAX N = 32770
X,	DEC 1		/ M[X] = 1
Y,	DEC 1		/ M[Y] = 1
R,	DEC 0		/ M[R] = 0, (Y, R) return (1, 0) then N is prime
M1,	DEC -1
M2,	DEC -2
Z,	DEC 0
TMP,	DEC 0
TMA,	HEX 0
TMX,	DEC 0
P,		DEC 0
R_O,		DEC 0
S1,		DEC -1
CH_0,	HEX 30
A_ZMG,	SYM ZMG
ZMG,	HEX A		/ hex digit 4
		HEX B		/ hex digit 3
		HEX F		/ hex digit 2
		HEX D		/ hex digit 1
		HEX E 		/ hex digit 0
VH4,	HEX 4		/ VH4 = 4
VM1,	DEC -1		/ VM1 = -1
VM4,	DEC -4		/ VM4 = -4
VM5,	DEC -5		/ VM5 = -5
VM10,	DEC -10		/ VM10 = -10
CNT,	DEC 0		/ (init: -4) digit count
AMKN,	HEX 000F	/ AMKN = 000F (and mask negated)

	END
