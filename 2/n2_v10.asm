		ORG 0		/ interrupt entry point
ST0,	HEX 0		/ interrupt return address
		BUN I_HND	/ goto I_HND (interrupt handler)

		ORG 10		/ program entry point
INI, / initialize data
		CLA				/ AC         <- 0
		STA BYE			/ M[BYE]     <- 0
		STA NXT_BYE		/ M[NXT_BYE] <- 0
		STA STT			/ M[STT]     <- 0
		STA NXT_STT		/ M[NXT_STT] <- 0
		LDA VH1			/ AC         <- 1
		STA NXT_INP		/ M[NXT_INP] <- 1 (change to input state after output process)
		STA OUT_STT		/ M[OUT_STT] <- 1 (output state)

	/ set start message
		LDA VH2			/ AC <- 2
		BSA SET_ML		/ call SET_ML (set message list)
		SYM MG_WELC		/ "WELCOME TO MAZE'N MATH!"		
		/SYM BRD1		/ show the first board
		SYM MG_SEL		/ "\nselect level(0[easy], 1[normal], 2[hard]):"

	/ setup IO registers
		LDA VH4			/ AC <- 4
		IMK				/ IMSK <- 0100 (S_OUT enabled)
		SIO				/ IOT <- 1 (serial-IO selected)
		ION				/ enable interrupt

	/ wait until (M[BYE] = 1)
L0,		
		LDA BYE			/ AC <- M[BYE]
		SZA				/ (M[BYE] == 0) ? skip next
		HLT
		BUN L0			/ goto L0

/////////// interrupt handler ///////////
I_HND,	
/ store AC & E to memory
		STA BA			/ M[BA] <- AC	(store AC)
		CIL				/ AC[0] <- E	(AC[15:1] is not important here...)
		STA BE			/ M[BE] <- AC	(store E)

/////////// state machine ///////////
/ M[OUT_PD] = 0 (process input), 1 (process output)
/ check state :
		LDA OUT_STT		/ AC <- M[OUT_STT]
		SZA				/ (M[OUT_STT] == 0) skip next
		BUN PUT_OUT		/ goto PUT_OUT (process output)

/////////// process input ///////////
/ M[OUT_STT] = 0 : input mode (M[TMI] <- INPR)
		SKI				/ (FGI = 0) ? skip next
_B_,	BUN IRT			/ goto IRT (return from interrupt handler) --> this should not happen...
		CLA				/ AC      <- 0
		INP				/ AC[7:0] <- INPR
_M_,	STA TMI			/ M[TMI]  <- INPR

/////////// state switch : M[STT] = 0, 1, 2, 3, 4, 5, 6 ///////////
STT_SW,/////////// sub: line feed, reset collum counter ///////////

		LDA STT			/ AC <- M[STT]
		ADD VM1			/ AC <- M[STT] - 1
		SPA				/ (M[STT] >= 1) ? skip next
		BUN STT_0		/ goto STT_0 (M[STT] = 0: setup new game) --> M[NXT_STT] = 1 (get your move)

		ADD VM1			/ AC <- M[STT] - 1 - 1
		SPA				/ (M[STT] >= 2) ? skip next
		BUN STT_1		/ goto STT_1 (M[STT] = 1: get your move)  --> M[NXT_STT] = 1 (get my move), 2(end game)
		BUN STT_2		/ goto STT_2 (M[STT] = 2: end game)   --> M[NXT_STT] = 0 (setup new game)

/////////// end maze'n math ///////////
END_MM,
		LDA VH1			/ AC         <- 1
		BSA SET_ML		/ call SET_ML (set message list)
		SYM MG_BYE		/ (arg1) "bye-bye!"
		STA NXT_BYE		/ M[NXT_BYE] <- 1
		BUN PRP_OUT		/ goto PRP_OUT (prepare output)

/////////// return from interrupt handler ///////////
IRT,	
		LDA BE			/ AC  <- M[BE]
		CIR				/ E   <- AC[0]	(restore E)
		LDA BA			/ AC  <- M[BA]	(restore AC)
		ION				/ IEN <- 1		(enable interrupt)
		BUN ST0 I		/ return from ST0 (interrupt handler)

/////////// prepare output ///////////
PRP_OUT,
		LDA VH1			/ AC         <- 1
		STA OUT_STT		/ M[OUT_STT] <- 1 (output state)
/		LDA VH4			/ AC         <- 4
/		IMK				/ IMASK      <- 0100 (S_OUT enabled)
		BUN IRT			/ goto IRT (return from interrupt handler)

/////////// M[STT] = 0 : setup new game  ///////////
STT_0,
/ check input number(1<=M[TMI]<=3)
		LDA CH_1			/ AC <- '1'
		CMA
		INC				/ AC <- -'1'
		ADD TMI			/ AC <- M[TMI] - '1'
		SPA				/ (M[TMI] >= '1') ? skip next
		BUN END_MM			/ goto END_MM (end maze'n math : M[TMI] < '1')
		ADD VM3			/ AC <- M[TMI] - 3
		SNA				/ (M[TMI] < 4) ? skip next
		BUN END_MM			/ goto END_MM (end maze'math : M[TMI] >= '4')
		ADD VH1
		SNA				/ (M[TMI] < 3) ? skip next
		BUN SELECT_BRD3		/ goto SELECT_BRD3(level 3 : M[TMI] = 3)
		ADD VH1
		SNA				/ (M[TMI] < 2) ? skip next
		BUN SELECT_BRD2		/ goto SELECT_BRD2(level 2 : M[TMI] = 2)
		BUN SELECT_BRD1		/ goto SELECT_BRD1(level 1 : M[TMI] = 1)

SELECT_BRD3,	
		/set board
		BSA S_CPY_BRD
		SYM BRD1		/ copy problem board to process board 
		BUN INIT_CLR
		/clear board
SELECT_BRD2,
		/set board
		BSA S_CPY_BRD
		SYM BRD1		/ copy problem board to process board 
		BUN INIT_CLR
		/clear board
SELECT_BRD1,	
		/set board
		BSA S_CPY_BRD
		SYM BRD1		/ copy problem board to process board 
		BUN INIT_CLR
		/clear board
		
INIT_CLR,
/initialize clear
		CLA				/AC <- 0
		STA CLEAR			/M[CLEAR] <- 0
		LDA VH1			/AC <- 1
		STA NXT_STT			/M[NXT_STT] <- 1 (next state : get your move)
		STA NXT_INP			/M[INP]     <- 1 (change to input state after output process)
		/BUN STT_MNG			/go to STT_MNG
		
		BSA SHOW_GAME
		BUN PRP_OUT

///////// M[STT] = 1 : get move (must satisfy: M[TMI] = 'w'|'a'|'s'|'d'|'q')  /////////
STT_1,
/ check input data
/ (prev-operator = 'w') ?
		LDA CH_W		/ AC <- M[CH_W] ('w')
		BSA CHK_CH		/ call CHK_CH
		SZA				/ (AC = 0) ? skip next(not 'w')
		BUN Z_UP		/ goto Z_UP

/ (prev-operator = 's') ?
		LDA CH_S		/ AC <- M[CH_S] ('s')
		BSA CHK_CH		/ call CHK_CH
		SZA				/ (AC = 0) ? skip next(not 's')
		BUN Z_DOWN		/ goto Z_DOWN

/ (prev-operator = 'a') ?
		LDA CH_A		/ AC <- M[CH_A] ('a')
		BSA CHK_CH		/ call CHK_CH
		SZA				/ (AC = 0) ? skip next(not 'a')
		BUN Z_LEFT		/ goto Z_LEFT

/ (prev-operator = 'd') ?
		LDA CH_D		/ AC <- M[CH_D] ('d')
		BSA CHK_CH		/ call CHK_CH
		SZA				/ (AC = 0) ? skip next(not 'd')
		BUN Z_RIGHT		/ goto Z_RIGHT

/ (prev-operator is unsupported) ?
/		BUN NG_YM		/ goto NG_YM (your move is invalid : invalid position)

NG_YM, / your move is invalid
		LDA VH1			/ AC     <- 1
		BSA SET_ML		/ call SET_ML (set message list)
		SYM MG_IVMV		/ (arg1) "invalid move!"
		LDA VH1			/ AC     <- 1
		STA NXT_INP		/ M[INP] <- 1
		BUN PRP_OUT		/ goto PRP_OUT (prepare output)

Z_LEFT,
		LDA X_COL
		ADD VM2
		STA TMX
		SPA		// X_COL - 2 >= 0 then skip next step
		BUN NG_YM
		LDA TMX
		STA X_COL
		BSA POS_X		// goto POS_X (possition - X) to calculate P_X_NXT from X_COL and X_ROW
		STA P_X_NXT
		BUN MAIN

Z_RIGHT,
		LDA X_COL
		ADD VP2
		STA TMX
		CMA
		INC
		ADD COL	
		SPA		// X_COL + 2 <= COL then skip next step
		BUN NG_YM
		LDA TMX
		STA X_COL
		BSA POS_X		// goto POS_X (possition - X) to calculate P_X_NXT from X_COL and X_ROW
		STA P_X_NXT
		BUN MAIN

Z_UP,
		LDA X_ROW
		ADD VM2
		STA TMX	
		SPA		// X_ROW - 2 >= 0 then skip next step
		BUN NG_YM
		LDA TMX
		STA X_ROW
		BSA POS_X
		STA P_X_NXT
		BUN MAIN

Z_DOWN,
		LDA X_ROW
		ADD VP2
		STA TMX
		CMA
		INC
		ADD ROW	
		SPA		// X_ROW + 2 <= ROW then skip next step
		BUN NG_YM
		LDA TMX
		STA X_ROW
		BSA POS_X
		STA P_X_NXT
		BUN MAIN

///////// ------------ MAIN ------------ //////////
//// MAIN: renew X, update BOARD

MAIN,
		BSA RENEW_X
		BSA RESET			
		BUN PRP_OUT

///////// RESET : reset counter ////////
RESET,	HEX 0
		CLA
		LDA CNT_COL_B
		STA CNT_COL		/ reset CNT_COL
		LDA CNT_BRD
		STA CNT_NUM
		LDA A_BRD
		STA P_BRD
	
		LDA X_LEN
		CMA
		INC
		STA CNT_X
		LDA A_X_OUT
		STA P_X_OUT
		/STA P_TMP 
	
		LDA P_X_NXT
		ADD VM1
		STA P_X
		CLA
		STA P
		
		LDA VH1
		STA NXT_INP
		BUN RESET I
/////////////////////////////////////////////////////////////

///////////// sub : SHOW_GAME ////////////////
SHOW_GAME, HEX 0		/ return address
/ update board : change P_X and chang P_X_NXT		
		/BSA UPD_BRD
SET_MG_BRD, / set MG_BRD
		LDA VH5			/ AC <- 4
		BSA SET_ML		/ call SET_ML (set message list)
		SYM MG_SEPR		/ (arg1) MG_SEPR
		SYM BRD			/ (arg2) MB_BRD
		SYM MG_SEPR		/ (arg3) MG_SEPR
		SYM X_OUT
		SYM MG_SEPR		/ (arg3) MG_SEPR
/NXT_MV,	HEX 0			/ (arg4) "your move!" or "my move!" or "game over!"
		BUN SHOW_GAME I	/ return from SHOW_GAME

///////////// end : SHOW_GAME ////////////////
		
////////////////////////////////////////////////////////

CHK_CLR, HEX 0
		/ check CNT_N and X
		LDA CNT_N		/AC <- M[CNT_N]
		SZA			/(M[CNT_N] = 0) ? skip next
		BUN NXT_TURN		/go to NXT_TURN
		BUN END_TURN		/go to END_TURN

NXT_TURN,
		LDA VH1		/AC <- 1
		STA NXT_STT		/M[NXT_STT] <- 1
		BSA SHOW_GAME
		BUN CHK_CLR I

END_TURN,		
		LDA VH2
		STA NXT_STT
		BSA SHOW_GAME
		BUN CHK_CLR I		

///subroutine/// your move is something wrong
		/ putout message("input order again")
		/ LDA VH1			/ AC     <- 1
		/ STA NXT_INP		/ M[INP] <- 1
		/ output puzzle

/////////// M[STT] = 2 : end game  ///////////
STT_2,
/you clear the game
		LDA X
		SZA					/ X = 0 then skip next step
		BUN YOU_LOSE		/go to YOU_LOSE (game over)
		
		LDA A_MG_CLR		/AC <- M[A_MG_CLR]("clear the game"!)
		STA RESULT		/M[RESULT] <- "clear the game!"
		BUN STT_2_1		/go to STT_2_1

YOU_LOSE,	
		LDA A_MG_GMO	/AC <- M[A_MG_GMO]("game over!")
		STA RESULT		/M[RESULT] <- "game over!"
STT_2_1,
		LDA VH2			/AC <- 2
		BSA SET_ML		/call SET_ML (set message list)
RESULT,	HEX 0			/(arg1) "game over!" or "clear the game!"
		SYM MG_SEL		/(arg2) "select level ..."
		LDA VH1			/AC <- 1
		STA NXT_INP		/M[INP] <- 1
		CLA				/AC <- 0
		STA NXT_STT		/M[NXT_STT] <- 0
		BUN PRP_OUT

/////////////////////////////////////////////////////////////

//////////// S_CPY_BRD : copy problem board to state board ///////////

S_CPY_BRD,	HEX 0
		LDA S_CPY_BRD I
		STA TMP_CPY
		
		LDA TMP_CPY I
		STA CPY_BRD I
		CMA
		INC			/ AC <- - BRD1[0] (length of board)
		STA CNT_BRD
		STA TMP_CNT
		ISZ TMP_CPY
		ISZ CPY_BRD
	L_CPY,	/ loop of copying
		LDA TMP_CPY I
		STA CPY_BRD I
		ISZ TMP_CPY
		ISZ CPY_BRD
		ISZ TMP_CNT
		BUN L_CPY
		BUN S_CPY_BRD I

////////////////////////// end : S_CPY_BRD //////////////////////////

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
		BUN CHK_CH I			/ return from CHK_CH

/////////// sub: line feed, reset collum counter ///////////
OUT_NL, HEX 0
	LDA CNT_COL
	SZA				/ CNT_COL = 0 then skip next step
	BUN OUT_NL I	
	LDA CH_NL
	OUT
	ISZ CNT_ROW
	LDA VM6
	STA CNT_COL
	BUN OUT_NL I

/////////// sub: POS_X - calculate P_X_NXT from X_COL and X_ROW ////////////
POS_X,	HEX 0
	BSA MULTI		/ COL * X_ROW
	LDA P
	ADD X_COL
	ADD VP1
	BUN POS_X I
	
/////////// sub: MULTI ///////////
MULTI,	HEX 0
		LDA COL
		STA B
		LDA X_ROW
		STA A
	L,
		CLE
		LDA B
		SZA
		BUN LY
		BUN MULTI I
	LY,
		CIR
		STA B
		SZE
		BUN LP
	LX,
		LDA A
		CIL
		STA A
		BUN L
	LP,
		LDA A
		ADD P
		STA P
		CLE
		BUN LX
		
//////////// sub: change X <- arg0 /////////////
///// P_X: pointer of now X
///// P_X_NXT: pointer of next X
///// AC: arg0
RENEW_X, HEX 0
		LDA P_X
		ADD VP1
		CMA
		INC
		ADD P_X_NXT
		STA TMP		/ TMP = P_X_NXT - P_X

		LDA P_BRD
		STA P_TMP
		ADD P_X
		ADD VP1
		STA P_TMP		/ P_TMP = P_BRD[P_X]
		LDA CH_0 
		STA P_TMP I

		LDA P_TMP
		ADD TMP
		STA P_TMP

		LDA P_X_OUT
		ADD VP4
		STA TMX
	
		LDA P_TMP I
		STA TMP
		/ calculate TMP - CH_0
		LDA CH_0
		CMA
		INC
		ADD TMP		/ AC = TMP - CH_0
		STA TMP		
		SZA
		BUN UP_CNT_N	/ up CNT_N
		/ compare TMP with X
TO_CMPR,		
		BSA CMPR
		/ CMPR return AC = |X - TMP|
		STA X
		ADD CH_0
		STA TMX I
		LDA CH_X
		STA P_TMP I
		
		BSA CHK_CLR				
		/BSA SHOW_GAME
		BUN RENEW_X I

UP_CNT_N,
		LDA CNT_N
		INC
		STA CNT_N
		BUN TO_CMPR

///////////////////// end : RENEW_X ///////////////////

/////////// sub: CMPR - compare X with next pointer ///////////
//// return AC = |X - TMP|

CMPR,	HEX 0
	/ AC = X - TMP
	LDA TMP
	CMA
	INC
	ADD X
	STA C_TMP
	SNA		/ X - TMP < 0 then skip next step, AC < 0
	BUN CMPR_1
	CMA
	INC
	BUN CMPR I
CMPR_1,		/ X - TMP >= 0
	SZA		/ X -TMP = 0 then skip next step
	BUN CMPR_2	
	BUN CMPR I	/ return AC = 0
CMPR_2,
	BUN CMPR I	/ return AC = X - TMP ( > 0 )

///////////////// end : CMPR ///////////////////

SET_ML,	HEX 0
////////// subroutine (set message list for S_OUT) //////////
/ arg0 (AC) : msg_count
/ arg(1), arg(2), ... : message addresses (# of arguments = msg_count)
		INC				/ AC             <- (msg_count + 1)
		CMA				/ AC             <- - (msg_count + 2)
		STA CNT_MG		/ M[CNT_MG]      <- - (msg_count + 2) (2 newlines)
		INC
		INC
		STA TMA			/ M[TMA]         <- - msg_count
		LDA A_MG_LST	/ AC             <- M[A_MG_LST] (MG_LIST)
		STA P_MG_LST	/ M[P_MG_LST]    <- MG_LIST
		STA TMB			/ M[TMB]         <- MG_LIST
/ put 1st newline at head
		LDA A_MG_NL		/ AC             <- M[A_MG_NL] (MG_NL)
		STA TMB I		/ M[M[TMB]]      <- MG_NL
		ISZ TMB			/ ++M[TMB]
L_SET_ML,	/ loop set message : i = 1, 2, ..., msg_count
		LDA SET_ML I	/ AC             <- M[M[SET_ML]] (arg(i))
		STA TMB I		/ M[MG_LIST + i] <- arg(i)
		ISZ SET_ML		/ ++M[SET_ML]
		ISZ TMB			/ ++M[TMB]
		ISZ TMA			/ ((++M[TMA]) == 0) ? skip next
		BUN L_SET_ML	/ goto L_SET_ML (loop set message)
/ put 2nd newline at head
		LDA A_MG_NL		/ AC             <- M[A_MG_NL] (MG_NL)
		STA TMB I		/ M[MG_LIST + msg_count + 1] <- MG_NL
/ load 1st message
		BSA LD_MSG		/ call LD_MSG (load message info)
/ output to S_OUT
		LDA VH4			/ AC <- 4
		IMK				/ IMSK <- 0100 (S_OUT enabled)
		BUN SET_ML I	/ return from SET_ML

LD_MSG,	HEX 0
////////// subroutine (load message info) //////////
		LDA P_MG_LST I	/ AC        <- M[M[P_MG_LST]] (message address)
		STA PTR_MG		/ M[PTR_MG] <- M[M[P_MG_LST]] (message address)
		LDA PTR_MG I	/ AC        <- M[M[PTR_MG]] (message length)
		CMA
		INC				/ AC        <- - (message length)
		STA CNT_CH		/ M[CNT_CH] <- message count
		ISZ PTR_MG		/ ++M[PTR_MG] (message starts from the next address)
		ISZ P_MG_LST	/ ++M[P_MG_LST]
		BUN LD_MSG I	/ return from SET_MSG

////////// process output //////////
PUT_OUT,
		SKO				/ (FGO = 0) ? skip next
_M_,	BUN IRT			/ goto IRT (return from interrupt handler) --> this should not happen...
/ output 1 message character at address M[PTR_MG]
		LDA PTR_MG I	/ AC   <- M[M[PTR_MG]]
		OUT				/ OUTR <- AC(7:0)
		ISZ PTR_MG		/ ++M[PTR_MG]
		ISZ CNT_CH		/ ((++M[CNT_CH]) == 0) ? skip next
/ message string pending ...
		BUN IRT			/ goto IRT (return from interrupt handler)
/ message string terminated
		ISZ CNT_MG		/ ((++M[CNT_MG]) = 0) ? skip next
		BUN NXT_MSG		/ goto NXT_MSG (load next message)
STT_MNG, / all message processed
		CLA				/ AC         <- 0
		STA OUT_STT		/ M[OUT_STT] <- 0
		LDA NXT_STT		/ AC         <- M[NXT_STT]
		STA STT			/ M[STT]     <- M[NXT_STT]
		SIO				/ IOT <- 1 (serial-IO selected)
		LDA NXT_BYE		/ AC         <- M[NXT_BYE]
		STA BYE			/ M[BYE]     <- M[NXT_BYE]
		SZA				/ (AC = 0) ? skip next
		BUN CHG_INP		/ goto CHG_INP (M[BYE] = 1 : prepare to terminate program...)
		LDA NXT_INP		/ AC <- M[NXT_INP]
		SZA				/ (AC = 0) ? skip next
		BUN CHG_INP		/ goto CHG_INP (M[NXT_INP] = 1 : change to input mode)
		BUN STT_SW		/ goto STT_SW (state switch)
NXT_MSG, / load next message
		BSA LD_MSG		/ call LD_MSG (load message info)
		BUN IRT			/ goto IRT (return from interrupt handler)
CHG_INP, / change to input mode
		CLA				/ AC         <- 0
		STA NXT_INP		/ M[NXT_INP] <- 0
		LDA VH8			/ AC         <- 8
		IMK				/ IMSK       <- 1000 (S_IN enabled)
		BUN IRT			/ goto IRT (return from interrupt handler)

/ data (no initialization)
A,		DEC 0
B,		DEC 0
P,		DEC 0

/ temporary variable
TMA,	DEC 0		/temporal
TMB,	DEC 0		/temporal
TMI,	DEC 0		/ char (raw) input
TMP,  DEC 0
TMX,  DEC 0
TMP_CPY,	DEC 0
TMP_CNT,	DEC 0
P_TMP, DEC 0
C_TMP, DEC 0
BA,		HEX 0		/ backup storage for AC during interrupt handling
BE,		HEX 0		/ backup storage for  E during interrupt handling
PTR_MG,	HEX 0		/message pointer
CNT_CH,	DEC 0		/char counter
MOVE,		DEC 0		/input order(W,A,S,D,Q)
CLEAR,	DEC 0		/Clear flag

/ data (need initialization code : one-time)
BYE,	DEC 0		/ (init: 0) bye
NXT_BYE,DEC 0		/ (init: 0) next bye
_M_,
STT,	DEC 0		/ (init: 0) current state
NXT_STT,DEC 0		/ (init: 0) next state
OUT_STT,DEC 0		/ set start message
NXT_INP,DEC 0		/ (init: 0) next process input

CNT_MG,	DEC 0		/message count
P_MG_LST,	HEX 0		/message list pointer
A_MG_LST,	SYM MG_LST
MG_LST,	HEX 0		/message pointer list (up to 8+2 message)
		HEX 0
		HEX 0
		HEX 0
		HEX 0
		HEX 0
		HEX 0
		HEX 0
		HEX 0
		HEX 0

/ data (read-only)
AMK,	HEX FFF0	/ AMK = FFF0 (and mask)
AMKN,	HEX 000F	/ AMKN = 000F (and mask negated)
VH0,  HEX 0		/ VH0 = 0
VH1,	HEX 1		/ VH1 = 1
VH2,	HEX 2		/ VH2 = 2
VH3,	HEX 3		/ VH3 = 3
VH4,	HEX 4		/ VH4 = 4
VH5,	HEX 5		/ VH5 = 5
VH8,	HEX 8		/ VH5 = 8
VM1,	DEC -1		/ VM1 = -1
VM2,	DEC -2		/ VM2 = -2
VM3,	DEC -3		/ VM2 = -3
VM4,	DEC -4		/ VM2 = -4
VM5,	DEC -5		/ VM5 = -5 
VM6,	DEC -6 
VM8,	DEC -8		/ VM2 = -8
VM9,	DEC -9		/ VM2 = -9
VM10,	DEC -10		/ VM10 = -10
VP1, DEC 1
VP2, DEC 2
VP4, DEC 4
VP5, DEC 5
CH_0,	CHR 0
CH_1,	CHR 1
CH_W,	CHR w
CH_S,	CHR s
CH_A,	CHR a
CH_D,	CHR d
CH_Q,	CHR q
CH_X,	CHR X
CH_NL, HEX A

MG_WELC,DEC 25	/ MG_W/ set start message
		CHR W
		CHR E
		CHR L
		CHR C
		CHR O
		CHR M0
		CHR E
		HEX 20	/ ' '
		CHR T
		CHR O
		HEX 20	/ ' '
		CHR M
		CHR A
		CHR Z
		CHR E
		CHR '
		CHR N
		CHR -
		CHR M
		CHR A
		CHR T
		CHR H
		CHR !
		HEX 0A	/ '\n'
		HEX 0A	/ '\n'

A_MG_NL,	SYM MG_NL
MG_NL,	DEC 1	/MG_NL length
		HEX 0A	/ '\n'

MG_BYE,	DEC 8	/ MG_BYE length
		CHR b
		CHR y
		CHR e
		CHR -
		CHR b
		CHR y
		CHR e
		CHR !

A_MG_GMO, SYM MG_GMO
MG_GMO,	DEC 10	/ MG_GMO length
		CHR g
		CHR a
		CHR m
		CHR e
		HEX 20	/ ' '
		CHR o
		CHR v
		CHR e
		CHR r
		CHR !
A_MG_CLR, SYM MG_CLR
MG_CLR,	DEC 15	/ MG_CLR length
		CHR c
		CHR l
		CHR e
		CHR a
		CHR r
		HEX 20	/' '
		CHR t
		CHR h
		CHR e
		HEX 20	/' '
		CHR g
		CHR a
		CHR m
		CHR e
		CHR !

MG_IVMV,DEC 13	/ MG_IVMV length
		CHR i
		CHR n
		CHR v
		CHR a
		CHR l
		CHR i
		CHR d
		HEX 20	/ ' '
		CHR m
		CHR o
		CHR v
		CHR e
		CHR !
		
MG_SEL,DEC 44	/ MG_SEL length
		HEX 0A	/ '\n'
		CHR s
		CHR e
		CHR l
		CHR e
		CHR c
		CHR t
		HEX 20       / ' '
		CHR l
		CHR e
		CHR v
		CHR e
		CHR l
		HEX 20       / ' '
		CHR (
		CHR 1
		CHR [
		CHR e
		CHR a
		CHR s
		CHR y
		CHR ]
		CHR ,
		HEX 20
		CHR 2
		CHR [
		CHR n
		CHR o
		CHR r
		CHR m
		CHR a
		CHR l
		CHR ]
		CHR ,
		HEX 20
		CHR 3
		CHR [
		CHR h
		CHR a
		CHR r
		CHR d
		CHR ]
		CHR )
		HEX 0A	/ '\n'
/MAZE'N MATH

//// flag var ////
IS_RENEW,	DEC -1

MG_SEPR,DEC 4	/ MG_SEPR length
		CHR -
		CHR -
		CHR -
		HEX 0A	/ '\n'
		
//// X data ////
P_X,		DEC 12
P_X_NXT,	DEC 0
X,		DEC 0

X_LEN,	DEC 0
CNT_X,	DEC -5
P_X_OUT,	SYM	X_OUT
A_X_OUT,	SYM X_OUT
X_OUT,	DEC 5
		CHR X
		CHR :
		HEX 20
		CHR 0
		HEX 0A	/ '\n'

X_COL,	DEC 0
X_ROW,	DEC 2

/// BRD1 setup data///
COL,		DEC 6
ROW,		DEC 5
CNT_ROW,	DEC 0
CNT_COL_B,	DEC -6
CNT_COL,	DEC -6
CNT_NUM_B,	DEC -30
CNT_NUM,	DEC -30
CNT_N,      	DEC -3

CPY_BRD1,	SYM BRD1	/ pointer used to copy the board
CNT_CPY1,	DEC -30	/ counter used to copy the board
P_BRD1,	SYM BRD1	/ MAZ

BRD1,	DEC 30

		CHR 0			/ 0
		HEX 20	/ ' '	/ 1
		CHR 0			/ 2
		HEX 20			/ 2
		CHR 1			/ 4
		HEX 0A	/ '\n'	/ 5
		
		HEX 20			/ 6
		HEX 20			/ 7
		HEX 20			/ 8
		HEX 20			/ 9
		HEX 20			/ 10
		HEX 0A	/ '\n'	/ 11
		
		CHR X			/ 12
		HEX 20			/ 13
		CHR 0			/ 14
		HEX 20			/ 15
		CHR 2			/ 16
		HEX 0A	/ '\n'  / 17
		
		HEX 20			/ 18
		HEX 20			/ 19
		HEX 20			/ 20
		HEX 20			/ 21
		HEX 20			/ 22
		HEX 0A	/ '\n'	/ 23
		
		CHR 0			/ 24
		HEX 20			/ 25
		CHR 0			/ 26
		HEX 20			/ 27
		CHR 3			/ 28
		HEX 0A	/ '\n'	/ 29

CNT_BRD,	DEC 0
CPY_BRD,	SYM BRD	/ pointer used to copy
P_BRD,	SYM BRD
A_BRD,	SYM BRD
BRD,	DEC 1
		CHR A
END
