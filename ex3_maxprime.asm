	ORG 10		/ start
	LDA N
	STA X		/ store N to X as a temporary variable
	CIR
	STA T		/ temp = N/2
	SNA		/ if (T < 0) skip next step
	BUN LOP1	/ goto LOP 1, compute X(N)%Y(T)
	HLT		/ T < 0 then input has error, halt
/ loop 1: compute N%Y
LOP1,	LDA X
	STA R		/ M[R] <- AC
	LDA T		/ load temp variable, AC <- M[T]
	STA Y		/ M[Y] = M[TMP]
	CMA		/ AC <- ~AC
	INC		/ AC <- AC + 1 (AC = -M[Y])
	ADD X 		/ AC <- AC + M[X] (AC <- M[X] - M[Y])	
	STA X		/ X <- AC
	SNA		/ if (AC < 0) then skip next step
	BUN LOP1	/ goto to LOP1
	LDA R		/ AC <- M[R]
	SZA		/ if R = 0 skip next step
	BUN LOP2	/ if R != 0 then test with Y = Y - 1
	BUN LOP		/ R = 0 run LOP to check if Y = 1 or not
/ loop 2: Y = Y - 1, goto LOP1 again
LOP2,	LDA Y
	BSA SH4
	STA T		/ Y = Y - 1
	LDA N
	STA X		/ X <- N
	BUN LOP1
	HLT
/ loop: R = 0 then load N - 1 to N, test again
/ R = 0 then firstly check that if Y = 1 or not
LOP,	LDA N
	STA LAST
	BSA SH4		/ N = N - 1, AC <- M[N] - 1
	STA N		/ M[N] <- AC
	STA X		/ load N to X
	CIR		/ AC <- M[X] >> 1
	STA T		/ T = X/2
	LDA Y		
	BSA SH4		/ AC <- Y - 1
	STA Y		/ Y = Y - 1
	LDA Y
	SZA		/ if AC = 0 (Y = 1) then skip next step	
	BUN LOP1	/ AC != 0 then test with N = N - 1
	HLT		/ Y = 1, R = 0 then stop
/ sub routine : X = X - 1 (special subtraction)
SH4,	HEX 0
	CMA		/ AC <- ~AC
	INC		/ AC <- AC + 1
	CMA		/ AC <- ~AC
	BUN SH4 I	/ return from SH4
/ init
LAST,	DEC 1		/ M[LAST] : the biggest prime number that does not exceed N
N,	DEC 32770	/ M[N] = 40, MAX N = 32770
X,	DEC 1		/ M[X] = 1
Y,	DEC 1		/ M[Y] = 1
T,	DEC 0		/ temp, init = 1
R,	DEC 0		/ M[R] = 0, (Y, R) return (1, 0) then N is prime
	END
