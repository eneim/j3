		ORG 0		/ interrupt entry point
ST0,	HEX 0		/ interrupt return address
		BUN I_HND	/ goto I_HND (interrupt handler)

		ORG 10		/ program entry point
INI, 	/ initialize data
		LDA VH8			/ AC <- 1000
		IMK				/ IMSK <- 1000 (S_IN enabled)
		SIO				/ IOT <- 1 (serial-IO selected)
		
		/ initialize
		CLA				/ AC <- 0
		STA BYE			/ M[BYE] <- 0
		STA NXT_BYE		/ M[NXT_BYE] <- 0
		LDA CH_NL		/ AC <- '\n'
		STA OPR			/ M[OPR] <- '\n'
		BSA INI_ST		/ call INI_ST (initialize state)
		ION				/ enable interrupt

/ wait until (M[BYE] = 1)
L0,		
		LDA BYE			/ AC <- M[BYE]
		SZA				/ (M[BYE] == 0) ? skip next
		HLT
		BUN L0			/ goto L0

/-----------------------------------------------------/

/------- subroutine (initialize state) --------/
INI_ST,	HEX 0
		CLA				/ AC      <- 0
		STA Y			/ M[Y]    <- 0
		STA Y_PD		/ M[Y_PD] <- 0
		STA STT			/ M[STT]  <- 0
		STA OUT_STT		/ M[OUT_STT] <- 0
		LDA VM5			/ AC      <- M[VM5] (-5)
		STA CNT			/ M[CNT]  <- -5
		BUN INI_ST I	/ return from INI_ST
/------ end subroutine (initialize state) ------/

/-------------- interrupt handler --------------/
I_HND,
/ store AC & E to memory
		STA BA			/ M[BA] <- AC	(store AC)
		CIL				/ AC[0] <- E	(AC[15:1] is not important here...)
		STA BE			/ M[BE] <- AC	(store E)

/////////// state machine ///////////
/ M[OUT_STT] != 0  : output pending
/ M[STT] = 0  : read inputs (up to 5 dec digits)
/ M[STT] = 1  : test next prime (?)
/ M[STT] >= 2 : output message
/ check state :
		LDA OUT_STT		/ AC <- M[OUT_STT]
		SZA				/ (M[OUT_STT] = 0) ? skip next
		BUN PUT_OUT		/ goto PUT_OUT (process output)

/////////// process input ///////////
/ input mode (M[TMI] <- INPR)
		SKI				/ (FGI = 0) ? skip next
		BUN IRT			/ goto IRT (return from interrupt handler) --> this should not happen...
		CLA				/ AC <- 0
		INP				/ AC[7:0] <- INPR
		STA TMI			/ M[TMI] <- INPR
		BSA READ_DEC	/ call READ_DEC (read hex value to M[HXI](3:0))
		SPA				/ (AC >= 0) ? skip next
		BUN CALC		/ goto CALC (invalid input || press Enter)
/ valid input :
/ check state 0 :
		LDA STT			/ AC <- M[STT]
		SZA				/ (AC = 0 - reading input) ? skip next
		BUN ERR			/ goto ERR (error!!!)

/////////// state 0: read Y ///////////
		LDA Y			/ AC <- M[Y]
		BSA MUL10
		ADD HXI			/ AC <- AC + M[HXI]
		STA Y			/ M[Y] <- AC
		LDA VH1			/ AC <- M[VH1] (1)
		STA Y_PD		/ M[Y_PD] <- 1 - Y is pending
		ISZ CNT			/ ((++M[CNT]) = 0) ? skip next

/ operand digit pending
		BUN IRT			/ goto IRT (return from interrupt handler)

/ goto state 1 : calculate the max prime
		ISZ STT			/ ++M[STT] (no skip)
		BUN M_PRIME

/////////// return from interrupt handler ///////////
IRT,
		LDA BE			/ AC <- M[BE]
		CIR				/ E  <- AC[0]	(restore E)
		LDA BA			/ AC <- M[BA]	(restore AC)
		ION				/ IEN <- 1		(enable interrupt)
		BUN ST0 I		/ indirect return (return address stored in ST0)

/////////// error !!!! ///////////
ERR,
		CLA				/ AC <- 0
		STA Y			/ M[Y] <- 0
		LDA A_EMG		/ AC <- M[A_EMG] (EMG)
		BSA SET_MSG		/ call SET_MSG (set message info)

/////////// prepare output ///////////
PRP_OUT,
		LDA VH1			/ AC <- M[VH1] (2)
		STA OUT_STT		/ M[OUT_STT] <- 1 (output state)
		LDA VH4			/ AC <- 0100
		IMK				/ IMSK <- 0100 (S_OUT enabled)
		BUN IRT			/ goto IRT (return from interrupt handler)

//////////////// check end-character ///////////////
CEC,	HEX 0
/ arg0 (AC) : output character
/ end-character = 0x4 (ctrl-D)
		ADD VM4		/ AC <- AC - 4
		SZA			/ (AC == 0) ? skip next
		BUN CEC I	/ return from CEC
/ output character matches (ctrl-D)
		LDA VM1		/ AC <- -1
		STA STT		/ M[STT] <- -1
		CLA			/ AC <- 0
		IMK			/ IMSK <- 0 (all interrupts disabled)
		BUN CEC I	/ return from CEC

/////////// multiple by 10 ///////////
MUL10,	HEX 0
		CLE
		STA TMP
		CIL
		CIL
		CIL
		ADD TMP
		ADD TMP
		BUN MUL10 I

/////////// SET OUTPUT ///////////////
SET_OUT,
		LDA LAST
		STA Z
		BSA WRITE_Z		/ call WRITE_Z (write Z to Z_MSG)
		LDA A_ZMG		/ AC <- M[A_ZMG] (ZMG)
		BSA SET_MSG		/ call SET_MSG (set message info)
		BUN PRP_OUT		

CHK_CH,	HEX 0			/ return address
////////// subroutine (check character) ///////////
/ arg0 (AC) : character to identify
/ return AC = 1 : character matched
/ return AC = 0 : character not matched
		CMA				/ AC <- ~AC
		INC				/ AC <- AC + 1 (AC = - arg0)
		ADD TMI			/ AC <- AC + M[TMI] (M[TMI] - arg0)
		SZA				/ (M[TMI] = arg0) ? skip next
		LDA VM1			/ AC <- M[VM1] (-1) (no match)
		INC				/ AC <- AC + 1
		BUN CHK_CH I	/ return from CHK_CH

CALC,	/ cur-operator : M[TMI]
/ (cur-operator = '\r') ?
		LDA CH_CR		/ AC <- M[CH_CR] ('\r')
		BSA CHK_CH		/ call CHK_CH (check character)
		SZA				/ (AC = 0) ? skip next (not enter)
		BUN CHK_OP		/ goto STT_OP (handle enter)

/ (cur-operator is unsupported... : prepare to terminate this program)
		LDA VH1			/ AC <- M[VH1] (1)
		STA NXT_BYE		/ M[NXT_BYE] <- 1
		LDA A_BMG		/ AC <- M[A_BMG] (BMG)
		BSA SET_MSG		/ call SET_MSG (set message info)
		BUN PRP_OUT

CHK_OP,
/ skip-output flag = 0
		CLA				/ AC     <- 0
		STA TMA			/ M[TMA] <- 0 (skip-output flag = 0)
/ (prev-operator = '\r') ?
		LDA CH_CR		/ AC <- M[CH_CR] ('\r')
		BSA CHK_CH		/ call CHK_CH
		SZA				/ (AC = 0) ? skip next
		BUN C_CR		/ goto C_CR (enter -> find the max prime)

/ (prev-operator is unsupported) ?
		BUN C_NONE		/ goto C_NONE (unsupported operator)

C_CR,	/ Goto M_PRIME
		ISZ TMA			/ ++M[TMA] (no skip) : skip-output flag = 1
		BUN M_PRIME		/ goto STA_Z

C_NONE, 
		CLA				/ AC <- 0 (just for now...)

SET_MSG,	HEX 0
////////// subroutine (set message info) //////////
/ arg0 (AC) : message address
			STA PTR_MG		/ M[PTR_MG] <- arg0 (message address)
			ADD VM1			/ AC <- arg0 - 1
			STA TMA			/ M[TMA] <- arg0 - 1
			LDA TMA I		/ AC <- M[M[TMA]] (M[arg0 - 1] = message count)
			STA CNT			/ M[CNT] <- message count
			BUN SET_MSG I	/ return from SET_MSG

READ_DEC,HEX 0			/ return addess
////////// subroutine (read hex value) //////////
/ return AC >= 0 : valid hex value in M[HXI](3:0)
/ return AC < 0  :  raw INPR value in M[TMI](7:0)
/ check '0' <= M[TMI] <= '9'
		LDA CH_0		/ AC <- M[CH_0] ('0')
		BSA CHK_DGT		/ call CHK_DGT (check digit character)
		DEC 0			/ 2nd argument to CHK_DGT (offset)
		DEC 9			/ 3rd argument to CHK_DGT (upper bound)
		SNA				/ (AC < 0) ? skip next
		BUN READ_DEC I	/ return from RHX (M[HXI](3:0) = {0 to 9})
/ not hex value --> convert new-line (\n) and carrage-return (\r) to equal (=)
		LDA CH_NL		/ AC <- M[CH_NL] ('\n')
		BSA CHK_CH		/ call CHK_CH
		SZA				/ (AC = 0) ? skip next
		BUN CONV_NL		/ goto CONV_EQ (convert to EQUAL)
		LDA CH_CR		/ AC <- M[CH_CR] ('\r')
		BSA CHK_CH		/ call CHK_CH
		SZA				/ (AC = 0) ? skip next
		BUN CONV_NL		/ goto CONV_EQ (convert to EQUAL)
R_READ_DEC,
		LDA VM1			/ AC <- M[VM1] (-1)
		BUN READ_DEC I	/ return from RHX (not hex value)
CONV_NL,
		LDA CH_NL		/ AC <- M[CH_EQ] ('=')
		STA TMI			/ M[TMI] <- '='
		BUN R_READ_DEC	/ goto R_READ_DEC (return : not hex value)

CHK_DGT,HEX 0			/ return address
////////// subroutine (check digit character) //////////
/ arg0 (AC) : lower bound character
/ arg1 (M[M[CHK_DGT]]) : offset
/ arg2 (M[M[CHK_DGT]+1]) : upper bound value
/ return AC >= 0 : valid digit value in M[HXI](3:0)
/ return AC < 0  : not valid digit
/ check (M[TMI] >= lower bound)
		CMA				/ AC <- ~AC
		INC				/ AC <- AC + 1 (- arg0)
		ADD	TMI			/ AC <- AC + M[TMI] (M[TMI] - arg0)
		SPA				/ (AC = M[TMI] - arg0 >= 0) ? skip next
		BUN R_CHK1		/ goto R_CHK1 (return : AC < 0)
		STA TMA			/ M[TMA] <- M[TMI] - arg0
		ADD CHK_DGT I	/ AC <- M[TMI] - arg0 + arg1
		STA HXI			/ M[HXI] <- M[TMI] - arg0 + arg1 (actual hex value)
		ISZ CHK_DGT		/ ++M[CHK_DGT]
/ check (M[TMI] <= upper bound)
		LDA TMA			/ AC <- M[TMA] (M[TMI] - arg0)
		CMA				/ AC <- ~AC
		INC				/ AC <- AC + 1 (arg0 - M[TMI])
		ADD CHK_DGT I	/ AC <- arg2 - arg0 - M[TMI] (if (AC < 0) then not within bound)
		BUN R_CHK2		/ goto R_CHK2
R_CHK1,
		ISZ CHK_DGT		/ ++M[CHK_DGT]
R_CHK2,
		ISZ CHK_DGT		/ ++M[CHK_DGT]
		BUN CHK_DGT I	/ return from CHK_DGT

////////// subroutine (write Z to ZMG) //////////
WRITE_Z,	HEX 0		/ return address
			LDA A_ZMG		/ AC <- M[A_ZMG] (ZMG)
			ADD VH4			/ AC <- ZMG + 4
			STA TMA			/ M[TMA] <- ZMG + 4
			LDA VM5			/ AC <- M[VM5] (-5)
			STA CNT_Z			/ M[CNT_Z] <- -4
			LDA LAST
			/LDA Y
			STA Z
PUT_DGT,
		LDA Z			/ AC <- M[Z]
		BSA DV10
		LDA R_0
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
		ISZ CNT_Z		/ ((++M[CNT_Z]) = 0) ? skip next
		BUN PUT_DGT		/ goto PUT_DGT
		BUN WRITE_Z I	/ return from OUT_Z

// compute TMX % 10 -> P, R
DV10,	HEX 0
		STA TMX
LOP,	STA R_0		/ M[R] <- AC
		ADD VM10	
		STA TMX	/ X <- AC
		ISZ P		/ M[P]++
		SNA		/ if (AC < 0) then skip next step
		BUN LOP	/ goto to LOP
		CLA		/ AC <- 0	
		LDA P		/ AC <- M[P]
		ADD VM1	/ AC <- AC - 1
		STA P		/ M[P] <- AC
		BUN DV10 I

////////// process output //////////

PUT_OUT,
		SKO				/ (FGO = 0) ? skip next
		BUN IRT			/ goto IRT (return from interrupt handler) --> this should not happen...
/ here, AC = M[OUT_STT] : 
		ADD VM1			/ AC <- M[OUT_STT] - 1
		SZA				/ (M[OUT_STT] = 1) ? skip next
		BUN PUT_OUT_2	/ goto PUT_O2
/ M[OUT_STT] = 1 : put 1st newline 
		LDA CH_NL		/ AC <- M[CH_NL] ('\n')
		OUT				/ OUTR <- AC(7:0)
		BSA CEC
		ISZ OUT_STT		/ ++M[OUT_STT] (no skip)
		BUN IRT			/ goto IRT (return from interrupt handler)
/ check (M[OUT_STT] = 2) ?
PUT_OUT_2,
		ADD VM1			/ AC <- M[OUT_STT] - 1 - 1
		SZA				/ (M[OUT_STT] = 2) ? skip next
		BUN PUT_NL2		/ goto PUT_NL2
/ M[OUT_STT] = 2 : put message
		LDA PTR_MG I	/ AC <- M[M[PTR_MG]]
		OUT				/ OUTR <- AC(7:0)
		BSA CEC
		ISZ PTR_MG		/ ++M[PTR_MG] (no skip)
		ISZ CNT			/ (++M[CNT])= 0) ? skip next
		BUN IRT			/ goto IRT (return from interrupt handler)
		ISZ OUT_STT		/ ++M[OUT_STT] (no skip)
		BUN IRT			/ goto IRT (return from interrupt handler)
/ M[OUT_STT] = 3 : put 2nd newline (process output ends here...)
PUT_NL2,	
		LDA CH_NL		/ AC <- M[CH_NL] ('\n')
		OUT				/ OUTR <- AC(7:0)
		BSA CEC
		BSA INI_ST		/ call INI_ST (initialize state)
		LDA NXT_BYE		/ AC <- M[NXT_BYE]
		STA BYE			/ M[BYE] <- M[NXT_BYE]
		SZA				/ (M[NXT_BYE] == 0) ? skip next
		BUN EXT			/ goto EXT (disable all interrupts)
		LDA VH8			/ AC <- 1000
		IMK				/ IMK <- 1000 (S_IN enabled)
		BUN IRT			/ goto IRT (return from interrupt handler)
EXT,
		CLA				/ AC <- 0
		IMK				/ IMK <- 0000 (all interrupts disabled)
		BUN IRT			/ goto IRT (return from interrupt handler)

/------------------ process main part: process the primes -------------------/

// CNT == 0 -> jump to M_PRIME
// ENTER == TRUE --> jump to M_PRIME
// M_PRIME: (1) check N, output LAST[N] --> (2) SET_OUT (no halt) --> (3) N = Z[N] - 1, if N == 1 then halt else back to (1)

M_PRIME,
		CLA
		CLE		
		LDA Y
		STA _N 		/ first step
		/STA LAST
		CIR
		STA _Y		/ temp = N/2, test with N first
		BUN CHK_Y

CHK_Y,
		LDA _Y
		ADD VM2
		SPA			/ Y - 2 >=0 then skip next step
		BUN SET_OUT
		BUN TEST

TEST,	
		BSA GETR	/ after this step, AC = M[R]
		LDA _R
		// check R: 
		// if R = 0 then check if Y = 1 -> finish, if Y > 1: N <- N - 1, goto MAIN
		// if R != 0 then Y <- Y - 1, goto MAIN
		SZA			/ if R = 0 then skip next step
		BUN RE_Y	/ R != 0 (R < Y -> Y > 1) then Y <- Y - 1, goto MAIN
		// R = 0 then N <- N - 1, check Y and goto MAIN or HALT
		BUN RE_N
		
// refresh N: N <- N - 1
RE_N,	
		LDA _N 		/ Y != 1 then N <- N - 1
		ADD VM1
		STA _N		/ M[N] <- AC
		CLE
		CIR
		STA _Y
		BUN CHK_Y

/ refresh Y: re-load Y <- Y - 1, if Y return 1 then
RE_Y,	
		LDA _Y
		ADD VM1
		STA _Y
		BUN CHK_Y

// compute N % Y -> R
GETR,	HEX 0
		LDA _N
		STA LAST	/ store the recent N to LAST
		STA _X
	DV,				/ X % Y
		LDA _X
		STA _R		/ M[R] <- AC
		LDA _Y		/ load Y
		CMA			/ AC <- ~AC
		INC			/ AC <- AC + 1 (AC = -M[Y])
		ADD _X 		/ AC <- AC + M[X] (AC <- M[X] - M[Y])	
		STA _X		/ X <- 
		SNA			/ if (AC < 0) then skip next step
		BUN DV		/ goto to DV
		BUN GETR I

/--------- init data ---------/
/ data (no initialization)
LAST,	DEC 0		/ M[LAST] : the biggest prime number that does not exceed N
_N,	DEC 12000	/ M[N] = 999, MAX N = 32770
_X,	DEC 1		/ M[X] = 1
_Y,	DEC 1		/ M[Y] = 1
_R,	DEC 0		/ M[R] = 0, (Y, R) return (1, 0) then N is prime
_P,	DEC 0
Z,		DEC 0       / result
TMA,	DEC 0		/ temporal
TMB,	DEC 0		/ temporal
TMI,	DEC 0		/ char (raw) input
TMP,	DEC 0
HXI,	DEC 0		/ hex input
BA,		DEC 000		/ backup storage for AC during interrupt handling
BE,		DEC 000		/ backup storage for  E during interrupt handling
PTR_MG, HEX 0		/ message pointer

/ data (need initialization code : one-time)
BYE,	DEC 0		/ (init: 0) bye
NXT_BYE,DEC 0		/ (init: 0) next bye
OPR,	DEC 0		/ (init: 0) operator
X,		DEC 0       / (init: 0) X operand

/ data (need initialization code : after every output -> INI_ST)
Y,		DEC 0       / (init: 0) Y operand
Y_PD,	DEC 0		/ (init: 0) Y pending
CNT,	DEC 0		/ (init: -4) digit count
CNT_Z,	DEC 0
STT,	DEC 0		/ (init: 0) 0: read operand, 1: read operator
OUT_STT,DEC 0		/ (init: 0) 0: output 1st newline, 1: output ans, 2: output 2nd newline
R_0,	DEC 0
P,		DEC 0
TMX,	DEC 0

/ data (read-only)
AMK,	HEX FFF0	/ AMK = FFF0 (and mask)
AMKN,	HEX 000F	/ AMKN = 000F (and mask negated)
VH1,	HEX 1		/ VH1 = 1
VH2,	HEX 2		/ VH2 = 2
VH3,	HEX 3		/ VH3 = 3
VH4,	HEX 4		/ VH4 = 4
VH8,	HEX 8		/ VH8 = 8
VHA,	HEX A		/ VHA = A
VM1,	DEC -1		/ VM1 = -1
VM2,	DEC -2		/ VM2 = -2
VM4,	DEC -4		/ VM2 = -4
VM5,	DEC -5		/ VM5 = -5
VM10,	DEC -10		/ VM10 = -10
CH_0,	HEX 30		/ '0'
CH_NL,	HEX 0A		/ '\n' (newline : line feed)
CH_CR,	HEX 0D		/ '\r' (carrage return : appears on DOS)
A_ZMG,	SYM ZMG
CNT_ZMG,DEC -5		/ CNT_ZMG = -5
ZMG,	HEX 0		/ hex digit 4
		HEX 0		/ hex digit 3
		HEX 0		/ hex digit 2
		HEX 0		/ hex digit 1
		HEX 0 		/ hex digit 0
A_EMG,	SYM EMG
CNT_EMG,DEC -6		/ CNT_EMG = -6
EMG,	HEX 65		/ 'e'
		HEX 72		/ 'r'
		HEX 72		/ 'r'
		HEX 6F		/ 'o'
		HEX 72		/ 'r'
		HEX 21		/ '!'
A_BMG,	SYM BMG
CNT_BMG,DEC -4		/ CNT_BMG = -4
BMG,	HEX 62		/ 'b'
		HEX 79		/ 'y'
		HEX 65		/ 'e'
		HEX 21		/ '!'
END
