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
		SYM MG_SEL		/ "\nselect level (1[easy], 2[normal], 3[hard], 4[tsubame], )\n"

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
/ M[OUT_STT] = 0 (process input), 1 (process output)
/ check state :

		LDA OUT_STT		/ AC <- M[OUT_STT]
		SZA				/ (M[OUT_STT] == 0) skip next
		BUN PUT_OUT		/ goto PUT_OUT (process output)

/////////// process input ///////////
/ M[OUT_STT] = 0 : input mode (M[TMP_IN] <- INPR)

		SKI				/ (FGI = 0) ? skip next
		BUN IRT
		CLA				/ AC      <- 0
		INP				/ AC[7:0] <- INPR
		STA TMP_IN

/////////// state switch : M[STT] = 0, 1, 2 ///////////

STT_SW,
		LDA STT			/ AC <- M[STT]
		ADD VM1			/ AC <- M[STT] - 1
		SPA				/ (M[STT] >= 1) ? skip next
		BUN STT_0		/ goto STT_0 (M[STT] = 0: setup new game, M[NXT_STT] -> 1 (get your move))

		ADD VM1			/ AC <- M[STT] - 1 - 1
		SPA				/ (M[STT] >= 2) ? skip next
		BUN STT_1		/ goto STT_1 (M[STT] = 1: get your move, M[NXT_STT] -> 1 (get my move) or 2(end game))
		BUN STT_2		/ goto STT_2 (M[STT] = 2: end game, M[NXT_STT] -> 0 (setup new game))

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
/ check input number (1 <= M[TMP_IN] <= 3)
		LDA CH_Q
		BSA CHK_CH
		SZA				/ IS_QUIT return AC != 0 if "q" is pressed
		BUN END_MM
		LDA CH_1		/ AC <- '1'
		CMA
		INC				/ AC <- -'1'
		ADD TMP_IN		/ AC <- M[TMP_IN] - '1'
		SPA				/ (M[TMP_IN] >= '1') ? skip next
		BUN END_MM		/ goto END_MM (end maze'n math : M[TMP_IN] < '1')
		ADD VM5			/ AC <- M[TMP_IN] - 5
		SNA				/ (M[TMP_IN] < 6) ? skip next
		BUN END_MM		/ goto END_MM (end maze'math : M[TMP_IN] >= '5')
		ADD VH1
		SNA				/ (M[TMP_IN] < 5) ? skip next
		BUN SELECT_BRD5		/ goto SELECT_BRD5 (level 5 : M[TMP_IN] = 5)
		ADD VH1			
		SNA				/ (M[TMP_IN] < 4) ? skip next
		BUN SELECT_BRD4		/ goto SELECT_BRD4 (level 4 : M[TMP_IN] = 4)
		ADD VH1
		SNA					/ (M[TMP_IN] < 3) ? skip next
		BUN SELECT_BRD3		/ goto SELECT_BRD3 (level 3 : M[TMP_IN] = 3)
		ADD VH1
		SNA					/ (M[TMP_IN] < 2) ? skip next
		BUN SELECT_BRD2		/ goto SELECT_BRD2 (level 2 : M[TMP_IN] = 2)
		BUN SELECT_BRD1		/ goto SELECT_BRD1 (level 1 : M[TMP_IN] = 1)
	
SELECT_BRD5,	
		/set board
		BSA S_CPY_BRD
		SYM BRD5		/ copy problem board BRD1 to process board BRD
		
		BSA SET_PROB	/ set problem (X value and X position)
		SYM PROB5		/ set PROB1
		
		/init
		BUN INIT_CLR
		
SELECT_BRD4,	
		/set board
		BSA S_CPY_BRD
		SYM BRD4		/ copy problem board BRD1 to process board BRD
		
		BSA SET_PROB	/ set problem (X value and X position)
		SYM PROB4		/ set PROB1
		
		/init
		BUN INIT_CLR
SELECT_BRD3,	
		/set board
		BSA S_CPY_BRD
		SYM BRD3		/ copy problem board BRD1 to process board BRD
		
		BSA SET_PROB	/ set problem (X value and X position)
		SYM PROB3		/ set PROB1
		
		/init
		BUN INIT_CLR
		
SELECT_BRD2,
		/set board
		BSA S_CPY_BRD
		SYM BRD2		/ copy problem board BRD1 to process board BRD
		
		BSA SET_PROB	/ set problem (X value and X position)
		SYM PROB2		/ set PROB1
		
		/init
		BUN INIT_CLR
		
SELECT_BRD1,	
		/set board
		BSA S_CPY_BRD
		SYM BRD1		/ copy problem board BRD1 to process board BRD
		
		BSA SET_PROB	/ set problem (X value and X position)
		SYM PROB1		/ set PROB1
		
		/init
		BUN INIT_CLR
				
INIT_CLR,
/initialize clear
		CLA				/AC <- 0
		STA CLEAR		/M[CLEAR] <- 0
		LDA VH1			/AC <- 1
		STA NXT_STT		/M[NXT_STT] <- 1 (next state : get your move)
		STA NXT_INP		/M[INP]     <- 1 (change to input state after output process)
		BSA SHOW_GAME
		BUN PRP_OUT

///////// M[STT] = 1 : get move (must satisfy: M[TMP_IN] = 'w'|'a'|'s'|'d')  /////////

STT_1,
		LDA P_X
		ADD VP1
		STA TMP_X
		
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

NG_YM, 	/ your move is invalid
		LDA VH8			/ AC     <- 1
		BSA SET_ML		/ call SET_ML (set message list)
		SYM MG_SEPR		/ (arg1) MG_SEPR
		SYM BRD			/ (arg2) MB_BRD
		SYM MG_SEPR		/ (arg3) MG_SEPR
		SYM X_OUT		/ (arg4) X_OUT
		SYM X_MG
		SYM MG_NL
		SYM MG_SEPR		/ (arg5) MG_SEPR
		SYM MG_IVMV		/ (arg1) "invalid move!"		
		LDA VH1			/ AC     <- 1
		STA NXT_INP		/ M[INP] <- 1
		BUN PRP_OUT		/ goto PRP_OUT (prepare output)

/ applying changes to player's move

Z_LEFT,
		LDA X_ROW
		STA OLD_ROW
		LDA X_COL
		STA OLD_COL

		ADD VM2			/ AC <- X_COL - 2
		STA TMX			/ TMX <- X_COL - 2
		SPA				/ X_COL - 2 >= 0 then skip next step
		BUN NG_YM		/ invalid move (over left)
		LDA TMX
		STA X_COL		/ valid move : X_COL <- X_COL (old) - 2
		/BSA POS_X		/ goto POS_X to calculate P_X_NXT (next position of X), POS_X return AC -> P_X_NXT
		LDA TMP_X
		ADD VM2
		STA P_X_NXT		/ P_X_NXT <- AC
		BUN MAIN		/ goto MAIN

Z_RIGHT,
		LDA X_ROW
		STA OLD_ROW
		LDA X_COL
		STA OLD_COL

		ADD VP2			/ AC <- X_COL + 2
		STA TMX			/ TMX <- X_COL + 2
		CMA				
		INC
		ADD COL			/ AC <- COL - (X_COL + 2)
		SPA				/ COL >= X_COL + 2 then skip next step
		BUN NG_YM		/ invalid move : over right
		LDA TMX
		STA X_COL		/ valid move : X_COL <- X_COL (old) + 2
		/BSA POS_X		/ goto POS_X to calculate P_X_NXT (next position of X), POS_X return AC -> P_X_NXT
		LDA TMP_X
		ADD VH2
		STA P_X_NXT		/ P_X_NXT <- AC
		BUN MAIN		/ goto MAIN

Z_UP,
		LDA X_COL
		STA OLD_COL
		LDA X_ROW
		STA OLD_ROW

		ADD VM2			/ AC <- X_ROW - 2
		STA TMX			/ TMX <- X_ROW - 2
		SPA				/ X_ROW - 2 >= 0 then skip next step
		BUN NG_YM		/ invalid move : over up
		LDA TMX
		STA X_ROW		/ valid move : X_ROW <- X_ROW (old) - 2
		/BSA POS_X		/ goto POS_X to calculate P_X_NXT (next position of X), POS_X return AC -> P_X_NXT
		LDA COL
		ADD COL
		CMA
		INC
		ADD TMP_X			/ P_X - ROW
		STA P_X_NXT		/ P_X_NXT <- AC
		BUN MAIN		/ goto MAIN

Z_DOWN,
		LDA X_COL
		STA OLD_COL
		LDA X_ROW
		STA OLD_ROW

		ADD VP2			/ AC <- X_ROW + 2
		STA TMX			/ TMX <- X_ROW + 2
		CMA
		INC
		ADD ROW			/ AC <- ROW - (X_ROW + 2)
		SPA				/ ROW >= X_ROW + 2 then skip next step
		BUN NG_YM		/ invalid move : over down
		LDA TMX			
		STA X_ROW		/ valid move : X_ROW <- X_ROW (old) + 2
		/BSA POS_X		/ goto POS_X to calculate P_X_NXT (next position of X), POS_X return AC -> P_X_NXT
		LDA TMP_X
		ADD COL
		ADD COL
		STA P_X_NXT		/ P_X_NXT <- AC
		BUN MAIN		/ goto MAIN

///////// ------------ MAIN ------------ //////////
//// MAIN: renew X, update BOARD

MAIN,
		BSA RENEW_X		/ renew X based on recent value of X, value of the square that P_X_NXT points to
		BSA RESET		/ reset something
		BUN PRP_OUT		/ output the result board

///////// RESET : reset counter ////////

RESET,	HEX 0
		CLA
		
		LDA A_BRD
		STA P_BRD
	
		LDA A_X_OUT
		STA P_X_OUT
		
		LDA A_X_MG
		STA P_X_MG

		LDA P_X_NXT
		ADD VM1
		STA P_X
		CLA
		STA P
		
		BUN RESET I
		
/////////////// end : RESET ///////////////

///////////// sub : SHOW_GAME ////////////////

SHOW_GAME, HEX 0		/ return address
		LDA VH7			/ AC <- 4
		BSA SET_ML		/ call SET_ML (set message list)
		SYM MG_SEPR		/ (arg1) MG_SEPR
		SYM BRD			/ (arg2) MB_BRD
		SYM MG_SEPR		/ (arg3) MG_SEPR
		SYM X_OUT		/ (arg4) X_OUT
		SYM X_MG
		SYM MG_NL
		SYM MG_SEPR		/ (arg5) MG_SEPR
		BUN SHOW_GAME I	/ return from SHOW_GAME

///////////// end : SHOW_GAME ////////////////
		
///////// CHK_CLR : check if game is cleared /////////

CHK_CLR, HEX 0
		/ check CNT_N and X
		LDA CNT_N		/AC <- M[CNT_N]
		SZA			/(M[CNT_N] = 0) ? skip next
		BUN NXT_TURN		/go to NXT_TURN
		BUN END_TURN		/go to END_TURN

NXT_TURN,
		LDA VH1		/AC <- 1
		STA NXT_STT		/M[NXT_STT] <- 1
		STA NXT_INP
		BSA SHOW_GAME
		BUN CHK_CLR I

END_TURN,
		CLA
		STA NXT_INP
		LDA VH2
		STA NXT_STT
		BSA SHOW_GAME
		BUN CHK_CLR I		

////////////////// end : CHK_CLR //////////////////

/////////// M[STT] = 2 : end game  ///////////
// jump here after CNT_N turns 0

STT_2,
/you clear the game
		LDA X			/ CNT_N = 0 then check if X = 0 or not
		SZA				/ X = 0 then skip next step
		BUN YOU_LOSE	/ go to YOU_LOSE (game over)

YOU_WIN, / label, comparing with "YOU_LOSE"
		LDA A_MG_CLR	/AC <- M[A_MG_CLR]("clear the game"!)
		STA RESULT		/M[RESULT] <- "clear the game!"
		BUN STT_2_1		/go to STT_2_1

YOU_LOSE,	
		LDA A_MG_GMO	/AC <- M[A_MG_GMO]("game over!")
		STA RESULT		/M[RESULT] <- "game over!"
		/ BUN STT_2_1 (just to remind)
		
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

////////////////////------------------------//////////////////////

//////////// S_CPY_BRD : copy problem board to BRD ///////////

S_CPY_BRD,	HEX 0
			LDA S_CPY_BRD I		/ load arg1 : pointer to the problem board
			STA TMP_CPY			/ TMP_CPY <- M[BRD?]
		
			LDA A_BRD
			STA CPY_BRD
		
			LDA TMP_CPY I		/ BRD?[0] : lenght of the board
			STA CPY_BRD I		/ store to BRD[0]
			CMA
			INC					/ AC <- - BRD?[0] (length of board)
			STA TMP_CNT			/ TMP_CNT <- - (length of BRD?)
			ISZ TMP_CPY
			ISZ CPY_BRD
	L_CPY,	/ loop for copy process
			LDA TMP_CPY I
			STA CPY_BRD I
			ISZ TMP_CPY
			ISZ CPY_BRD
			ISZ TMP_CNT			/ temporary counter
			BUN L_CPY			/ goto L_CPY
			BUN S_CPY_BRD I		/ return from S_CPY_BRD

////////////////////////// end : S_CPY_BRD //////////////////////////

//////////////////// SET_PROB : set X value /////////////////

SET_PROB,	HEX 0
		LDA SET_PROB I		/ arg1 : problem setting (X)
		STA TMP_PROB
		
		LDA TMP_PROB I		
		STA X				/ line 1: X
		
		ISZ TMP_PROB
		LDA TMP_PROB I
		STA P_X				/ line 2: P_X
		
		ISZ TMP_PROB
		LDA TMP_PROB I
		STA X_COL			/ line 3: X_RCOL
		
		ISZ TMP_PROB
		LDA TMP_PROB I
		STA X_ROW			/ line 4: X_ROW
		
		ISZ TMP_PROB
		LDA TMP_PROB I
		STA CNT_N			/ line 5: CNT_N
		
		ISZ TMP_PROB
		LDA TMP_PROB I
		STA COL			/ line 6 : COL

		ISZ TMP_PROB
		LDA TMP_PROB I
		STA ROW			/ line 7 : ROW
		
		BUN SET_PROB I

//////////////////// end : SET_PROB /////////////////

///////////// CHK_CH : check character //////////////

CHK_CH,	HEX 0			/ return address
/ arg0 (AC) : character to identify
/ return AC = 1 : character matched
/ return AC = 0 : character not matched
		CMA				/ AC <- ~AC
		INC				/ AC <- AC + 1 (AC = - arg0)
		ADD TMP_IN			/ AC <- AC + M[TMP_IN] (M[TMP_IN] - arg0)
		SZA				/ (M[TMP_IN] = arg0) ? skip next
		LDA VM1			/ AC <- M[VM1] (-1) (no match)
		INC				/ AC <- AC + 1
		BUN CHK_CH I			/ return from CHK_CH

/////////// sub: POS_X - calculate P_X_NXT from X_COL and X_ROW ////////////
POS_X,	HEX 0
	BSA MULTI		/ COL * X_ROW
	LDA P			/ P = COL * X_ROW
	ADD X_COL
	ADD VP1			/ AC <- COL * X_ROW + X_COL + 1
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
		
//////////// RENEW_X : renew X /////////////
///// P_X: recent pointer of X
///// P_X_NXT: next pointer of X
RENEW_X, HEX 0
		LDA P_X_NXT
		CMA
		INC
		ADD A_BRD I
		SNA			/ A_BRD[0] < P_X_NXT then skip next
		BUN KEEPGOIN0
		BUN ROLLBCK
		
	KEEPGOIN0,
		LDA P_X
		ADD VP1
		CMA
		INC
		ADD P_X_NXT
		STA TMP			/ TMP = P_X_NXT - P_X

		LDA P_BRD
		STA P_TMP		
		ADD P_X
		ADD VP1
		STA P_TMP		/ P_TMP = M[M[P_BRD] + P_X]
		
		ADD TMP
		STA P_TMP_NXT
		
		LDA P_TMP_NXT I
		STA TMP
		CMA
		INC
		ADD CH_SP
		SZA		
		BUN KEEPGOIN1		/ TMP != CH_SP then keep going
		BUN ROLLBCK		

	KEEPGOIN1,
		LDA CH_0 
		STA P_TMP I

		LDA P_TMP_NXT
		STA P_TMP

		LDA P_TMP I
		STA TMP			/ TMP : number at P_X_NXT
		/ calculate TMP - CH_0
	
		LDA CH_0
		CMA
		INC
		ADD TMP			/ AC = TMP - CH_0
		STA TMP		
		SZA
		BSA UP_CNT_N	/ up CNT_N
		/ compare TMP with X
		BSA CMPR
		/ CMPR return AC = next X
		STA X
		BSA WRITE_X
		LDA CH_X
		STA P_TMP I		/ add character 'X' to recent place of P_X_NXT		
		BSA CHK_CLR
		BUN RENEW_X I

	ROLLBCK,
		LDA P_X
		ADD VP1
		STA P_X_NXT
		LDA OLD_ROW
		STA X_ROW
		LDA OLD_COL
		STA X_COL
		
		LDA VH8			/ AC     <- 1
		BSA SET_ML		/ call SET_ML (set message list)
		SYM MG_SEPR		/ (arg1) MG_SEPR
		SYM BRD			/ (arg2) MB_BRD
		SYM MG_SEPR		/ (arg3) MG_SEPR
		SYM X_OUT		/ (arg4) X_OUT
		SYM X_MG
		SYM MG_NL
		SYM MG_SEPR		/ (arg5) MG_SEPR
		SYM MG_IVMV		/ (arg1) "invalid move!"		
		
		LDA VH1			/ AC     <- 1
		STA NXT_INP		/ M[INP] <- 1
		BUN RENEW_X I

UP_CNT_N, HEX 0
		LDA CNT_N
		INC
		STA CNT_N
		BUN UP_CNT_N I

///////////////////// end : RENEW_X ///////////////////

/////////// sub: CMPR - compare X with next pointer ///////////
//// return AC = new X

CMPR,	HEX 0
		LDA X
		CMA
		INC
		ADD TMP	/ AC <- TMP - X
		SPA		/ AC >= 0 (TMP >= X) then skip next step
		BUN CMPR_1	/ return AC = X + TMP
		BUN CMPR I	/ return AC = TMP - X
CMPR_1,
		LDA TMP
		ADD X
		BUN CMPR I

///////////////// end : CMPR ///////////////////

////////// subroutine (write X to X_MG) //////////
WRITE_X,	HEX 0		/ return address
		LDA P_X_MG
		ADD VH4
		STA TMX2
		LDA VM4
		STA CNT_X
		LDA X
		STA TMX_MG
PUT_DGT,
		LDA TMX_MG
		BSA DV10
		LDA R_X
		ADD CH_0
STR_DGT,
		STA TMX2 I
		LDA P_X2
		STA TMX_MG
		CLA
		STA P_X2
		LDA TMX2
		ADD VM1
		STA TMX2
		ISZ CNT_X
		BUN PUT_DGT
		BUN WRITE_X I

// compute TMX % 10 -> P_X_, R_X
DV10,	HEX 0
		STA TMR
LOP,	STA R_X		/ M[R] <- AC
		ADD VM10	
		STA TMR	/ X <- AC
		ISZ P_X2		/ M[P]++
		SNA		/ if (AC < 0) then skip next step
		BUN LOP	/ goto to LOP
		CLA		/ AC <- 0	
		LDA P_X2		/ AC <- M[P]
		ADD VM1	/ AC <- AC - 1
		STA P_X2		/ M[P] <- AC
		BUN DV10 I

////////// SET_ML : set messages ///////////

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
		BUN IRT
/ output 1 message character at address M[PTR_MG]
		LDA CNT_MG
		ADD VH4
		SZA
		BUN OUT1		/ CNT_MG = -4 then skip this step
		BUN OUT2
	OUT1,
		LDA PTR_MG I	/ AC   <- M[M[PTR_MG]]
		OUT				/ OUTR <- AC(7:0)
		BUN OUT3
	OUT2,
		LDA PTR_MG I	/ AC   <- M[M[PTR_MG]]
		OUT				/ OUTR <- AC(7:0)
		/LDA A_TEST I	/ change this to LE1
		/OUT				/ after changing to LE1, clear this line
		BUN OUT3
	OUT3,	
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
R_X,		DEC 0
P_X2,		DEC 0

/ temporary variable
TMA,	DEC 0		/temporal
TMB,	DEC 0		/temporal
TMP_IN,	DEC 0		/ char (raw) input
TMP,  	DEC 0
TMR,	DEC 0
TMX, 	DEC 0
TMX2,	DEC 0
TMX_MG,	DEC 0
TMP_X,	DEC 0
TMP_CPY,	DEC 0
TMP_CNT,	DEC 0
TMP_PROB,	DEC 0
P_TMP, DEC 0
P_TMP_NXT,	DEC 0
BA,		HEX 0		/ backup storage for AC during interrupt handling
BE,		HEX 0		/ backup storage for  E during interrupt handling
PTR_MG,	HEX 0		/message pointer
CNT_CH,	DEC 0		/char counter
CLEAR,	DEC 0		/Clear flag

/ data (need initialization code : one-time)
BYE,	DEC 0		/ (init: 0) bye
NXT_BYE,DEC 0		/ (init: 0) next bye
STT,	DEC 0		/ (init: 0) current state
NXT_STT,DEC 0		/ (init: 0) next state
OUT_STT,DEC 0		/ set start message
NXT_INP,DEC 0		/ (init: 0) next process input

CNT_MG,	DEC 0		/message count
P_MG_LST,	HEX 0	/message list pointer
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
VH6,	HEX 6
VH7,	HEX 7
VH8,	HEX 8		/ VH8 = 8
VH9,	HEX 9
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
CH_SP, HEX 20
/CH_X,	HEX FF
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
MG_GMO,	DEC 11	/ MG_GMO length
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
		HEX 0A	/ '\n'
		
A_MG_CLR, SYM MG_CLR
MG_CLR,	DEC 16	/ MG_CLR length
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
		HEX 0A	/ '\n'

MG_IVMV,DEC 15	/ MG_IVMV length
		HEX 0A	/ '\n'
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
		HEX 0A	/ '\n'
		
MG_SEL,DEC 74	/ MG_SEL length
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
		CHR ,
		HEX 20
		CHR 4
		CHR [
		CHR t
		CHR s
		CHR u
		CHR b
		CHR a
		CHR m
		CHR e
		CHR ]
		CHR ,
		HEX 20
		CHR 5
		CHR [
		CHR m
		CHR a
		CHR z
		CHR e
		CHR ]
		CHR ,
		HEX 20
		CHR q
		CHR [
		CHR q
		CHR u
		CHR i
		CHR t
		CHR ]
		CHR )
		HEX 0A	/ '\n'
/MAZE'N MATH

MG_SEPR,DEC 6	/ MG_SEPR length
		CHR -
		CHR -
		CHR -
		CHR -
		CHR -
		HEX 0A	/ '\n'
		
//// X data ////
P_X,		DEC 0
P_X_NXT,	DEC 0
X,			DEC 0

P_X_OUT,	SYM X_OUT
A_X_OUT,	SYM X_OUT
X_OUT,	DEC 3
		CHR X
		CHR :
		HEX 20	/ ' '
		/CHR 0
		/CHR 0
		/CHR 0
		/CHR 0
		/HEX 0A	/ '\n'

// array to store decimal value of X
CNT_X,	DEC 0
P_X_MG,	SYM X_MG
A_X_MG,	SYM X_MG
X_MG,	DEC 4
	CHR 0
	CHR 0
	CHR 0
	CHR 0

X_COL,	DEC 0
X_ROW,	DEC 0

OLD_COL,	DEC 0
OLD_ROW,	DEC 0

COL,		DEC 0
ROW,		DEC 0
CNT_N,	DEC 0

///////// problems /////////

/// BRD1 setup data///
PROB1,
		DEC 0	/ X
		DEC 12	/ start point of X1
		DEC 0	/ X_COL
		DEC 2	/ X_ROW
		DEC -3	/ CNT_N
		DEC 6	/ COL
		DEC 5	/ ROW

P_BRD1,	SYM BRD1	/ MAZ
BRD1,	DEC 30

		CHR 0			/ 0
		HEX 20	/ ' '	/ 1
		CHR 0			/ 2
		HEX 20		/ 2
		CHR 1			/ 4
		HEX 0A	/ '\n'	/ 5
		
		HEX 20/ 6
		HEX 20	/ 7
		HEX 20	/ 8
		HEX 20	/ 9
		HEX 20	/ 10
		HEX 0A	/ '\n'	/ 11
		
		CHR X			/ 12
		HEX 20		/ 13
		CHR 0			/ 14
		HEX 20		/ 15
		CHR 2			/ 16
		HEX 0A	/ '\n'  / 17
		
		HEX 20/ 18
		HEX 20 18
		HEX 20 18
		HEX 20 18
		HEX 20/ 18
		HEX 0A	/ '\n'	/ 23
		
		CHR 0			/ 24
		HEX 20		/ 25
		CHR 0			/ 26
		HEX 20		/ 27
		CHR 3			/ 28
		HEX 0A	/ '\n'	/ 29		
		
/// BRD2 setup data ///

PROB2,
		DEC 0	/ X
		DEC 34	/ start point of X1
		DEC 2	/ X_COL
		DEC 4	/ X_ROW
		DEC -8	/ CNT_N
		DEC 8		/ COL
		DEC 9		/ ROW

P_BRD2,	SYM BRD2	/ MAZ
BRD2,	DEC 72

		CHR 2		
		HEX 20	/ ' '	
		CHR 0			
		HEX 20
		CHR 0
		HEX 20
		CHR 4		
		HEX 0A	/ '\n'

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A
		
		CHR 1			
		HEX 20	/ ' '	
		CHR 0			
		HEX 20
		CHR 0
		HEX 20
		CHR 2		
		HEX 0A	/ '\n'

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A

		CHR 0			
		HEX 20	/ ' '	
		CHR X			
		HEX 20		
		CHR 0
		HEX 20
		CHR 0		
		HEX 0A	/ '\n'

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A
	
		CHR 4			
		HEX 20	/ ' '	
		CHR 0			
		HEX 20		
		CHR 0
		HEX 20
		CHR 3		
		HEX 0A	/ '\n'

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A

		CHR 8			
		HEX 20	/ ' '	
		CHR 0			
		HEX 20		
		CHR 0
		HEX 20
		CHR 6		
		HEX 0A	/ '\n'
		
/// BRD3 setup data ///

PROB3,
		DEC 0	/ X
		DEC 90	/ start point of X1
		DEC 6	/ X_COL
		DEC 6	/ X_ROW
		DEC -20	/ CNT_N
		DEC 14		/ COL
		DEC 13		/ ROW

P_BRD3,	SYM BRD3	/ MAZ
BRD3,	DEC 182

		HEX 20
		HEX 20	/ ' '	
		HEX 20
		HEX 20
		HEX 20
		HEX 20	/ ' '	
		CHR 5			
		HEX 20	
		HEX 20
		HEX 20	/ ' '	
		HEX 20
		HEX 20
		HEX 20
		HEX 0A	/ '\n'	/13
		
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20
		HEX 20			
		HEX 20			
		HEX 20						
		HEX 0A	/ '\n'	/27
		
		HEX 20
		HEX 20	/ ' '	
		HEX 20
		HEX 20
		CHR 4			
		HEX 20	
		CHR 3			
		HEX 20		
		CHR 1		
		HEX 20	/ ' '	
		HEX 20
		HEX 20
		HEX 20
		HEX 0A	/ '\n'  	/41
		
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20
		HEX 20			
		HEX 20			
		HEX 20						
		HEX 0A	/ '\n'	/55
		
		HEX 20
		HEX 20	/ ' '	
		CHR 2		
		HEX 20
		HEX 20
		HEX 20	
		CHR 1			
		HEX 20		
		HEX 20
		HEX 20	/ ' '	
		CHR 3			
		HEX 20
		HEX 20
		HEX 0A	/ '\n' 	/69

		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20
		HEX 20			
		HEX 20			
		HEX 20						
		HEX 0A	/ '\n'	/83

		CHR 5		
		HEX 20	/ ' '	
		CHR 4		
		HEX 20
		CHR 2		
		HEX 20	
		CHR X				/90		
		HEX 20		
		CHR 4		
		HEX 20	/ ' '	
		CHR 2			
		HEX 20
		CHR 5					
		HEX 0A	/ '\n' 

		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20
		HEX 20			
		HEX 20			
		HEX 20						
		HEX 0A	/ '\n'

		HEX 20
		HEX 20	/ ' '	
		CHR 1		
		HEX 20
		HEX 20
		HEX 20	
		CHR 3			
		HEX 20		
		HEX 20
		HEX 20	/ ' '	
		CHR 4			
		HEX 20
		HEX 20
		HEX 0A	/ '\n' 

		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20
		HEX 20			
		HEX 20			
		HEX 20						
		HEX 0A	/ '\n'

		HEX 20
		HEX 20	/ ' '	
		HEX 20
		HEX 20
		CHR 3		
		HEX 20	
		CHR 1			
		HEX 20		
		CHR 2		
		HEX 20	/ ' '	
		HEX 20
		HEX 20
		HEX 20
		HEX 0A	/ '\n' 

		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20			
		HEX 20
		HEX 20			
		HEX 20			
		HEX 20						
		HEX 0A	/ '\n'

		HEX 20
		HEX 20	/ ' '	
		HEX 20
		HEX 20
		HEX 20
		HEX 20	
		CHR 5			
		HEX 20		
		HEX 20
		HEX 20	/ ' '	
		HEX 20
		HEX 20
		HEX 20
		HEX 0A	/ '\n' 

/// BRD4 setup data ///

PROB4,
		DEC 0	/ X
		DEC 80	/ start point of X1
		DEC 8	/ X_COL
		DEC 4	/ X_ROW
		DEC -19	/ CNT_N
		DEC 18		/ COL
		DEC 17	/ ROW

P_BRD4,	SYM BRD4	/ MAZ
BRD4,	DEC 306

		CHR 0		
		HEX 20	/ ' '	
		CHR 0			
		HEX 20		
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 6
		HEX 20
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 0		
		HEX 0A	/ '\n'

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20	
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A

		CHR 0		
		HEX 20	/ ' '	
		CHR 0			
		HEX 20		
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 5
		HEX 20
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 0		
		HEX 0A	/ '\n'

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20	
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A
	
		CHR 0		
		HEX 20	/ ' '	
		CHR 3			
		HEX 20		
		CHR 3
		HEX 20
		CHR 4
		HEX 20
		CHR X
		HEX 20
		CHR 4
		HEX 20
		CHR 3
		HEX 20
		CHR 3
		HEX 20
		CHR 0		
		HEX 0A	/ '\n'

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20	
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A

		CHR 0		
		HEX 20	/ ' '	
		CHR 1			
		HEX 20		
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 6
		HEX 20
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 1
		HEX 20
		CHR 0		
		HEX 0A	/ '\n'

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20	
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A

		CHR 0		
		HEX 20	/ ' '	
		CHR 2			
		HEX 20		
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 4
		HEX 20
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 2
		HEX 20
		CHR 0		
		HEX 0A	/ '\n'

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20	
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A

		CHR 0		
		HEX 20	/ ' '	
		CHR 0			
		HEX 20		
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 3
		HEX 20
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 0		
		HEX 0A	/ '\n'

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20	
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A

		CHR 0		
		HEX 20	/ ' '	
		CHR 0			
		HEX 20		
		CHR 0
		HEX 20
		CHR 2
		HEX 20
		CHR 0
		HEX 20
		CHR 2
		HEX 20
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 0		
		HEX 0A	/ '\n'

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20	
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A

		CHR 0		
		HEX 20	/ ' '	
		CHR 0			
		HEX 20		
		CHR 1
		HEX 20
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 1
		HEX 20
		CHR 0
		HEX 20
		CHR 0		
		HEX 0A	/ '\n'

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20	
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A

		CHR 0		
		HEX 20	/ ' '	
		CHR 0			
		HEX 20		
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 0
		HEX 20
		CHR 0		
		HEX 0A	/ '\n'

PROB5,
		DEC 0	/ X
		DEC 0	/ start point of X1
		DEC 0	/ X_COL
		DEC 0	/ X_ROW
		DEC -56	/ CNT_N
		DEC 18		/ COL
		DEC 17	/ ROW

P_BRD5,	SYM BRD4	/ MAZ
BRD5,	DEC 306

		CHR X
		HEX 20
		CHR 3
		HEX 20
		CHR 4
		HEX 20
		CHR 2
		HEX 20
		CHR 5
		HEX 20
		CHR 1
		HEX 20
		CHR 6
		HEX 20
		CHR 2
		HEX 20
		CHR 6
		HEX 0A

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A

		CHR 2
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		CHR 0
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		CHR 1
		HEX 0A

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A

		CHR 1
		HEX 20
		HEX 20		
		HEX 20
		CHR 1
		HEX 20
		CHR 2
		HEX 20
		CHR 3
		HEX 20
		CHR 4
		HEX 20
		CHR 5
		HEX 20
		HEX 20
		HEX 20
		CHR 3
		HEX 0A

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A

		CHR 3
		HEX 20
		HEX 20
		HEX 20
		CHR 5
		HEX 20
		CHR 4
		HEX 20
		CHR 3
		HEX 20
		CHR 2
		HEX 20
		CHR 1
		HEX 20
		HEX 20
		HEX 20
		CHR 2
		HEX 0A

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A

		CHR 5
		HEX 20
		HEX 20
		HEX 20
		CHR 1
		HEX 20
		CHR 2
		HEX 20
		CHR 3
		HEX 20
		CHR 4
		HEX 20
		CHR 5
		HEX 20
		CHR 0
		HEX 20
		CHR 4
		HEX 0A

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A

		CHR 6
		HEX 20
		HEX 20
		HEX 20
		CHR 5
		HEX 20
		CHR 4
		HEX 20
		CHR 3
		HEX 20
		CHR 2
		HEX 20
		CHR 1
		HEX 20
		HEX 20
		HEX 20
		CHR 3
		HEX 0A

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A

		CHR 3
		HEX 20
		HEX 20
		HEX 20
		CHR 1
		HEX 20
		CHR 2
		HEX 20
		CHR 3
		HEX 20
		CHR 4
		HEX 20
		CHR 5
		HEX 20
		HEX 20
		HEX 20
		CHR 5
		HEX 0A

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A

		CHR 2
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		CHR 0
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		CHR 1
		HEX 0A

		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 20
		HEX 0A

		CHR 4
		HEX 20
		CHR 5
		HEX 20
		CHR 1
		HEX 20
		CHR 2
		HEX 20
		CHR 2
		HEX 20
		CHR 3
		HEX 20
		CHR 4
		HEX 20
		CHR 2
		HEX 20
		CHR 2
		HEX 0A

A_TEST,	SYM TEST
TEST,	CHR T

CPY_BRD,	SYM BRD	/ pointer used to copy
P_BRD,	SYM BRD
A_BRD,	SYM BRD
BRD,	DEC 1
		CHR A
END
