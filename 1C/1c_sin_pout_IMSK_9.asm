	ORG 0		/ interrupt entry point
ST0,HEX 0		/ interrupt return address
	BUN I_HND	/ goto I_HND (interrupt handler)

	ORG 10		/ program entry point
INI, / initialize data
	CLA			/ AC <- 0
	STA STT		/ M[STT] <- 0
	STA SFG		/ M[SFG] <- 0

/ IMSK[3:0] : { S_IN, S_OUT, P_IN, P_OUT }
	SIO
	/LDA VH8		/ AC <- M[VH8] (1000)
	LDA VHF
	STA MSK		/ M[MSK] <- (1000)
	IMK			/ IMSK   <- (1000) (S_IN enabled)
	ION			/ enable interrupt
	
L0, LDA STT		/ AC <- M[STT]
	SNA			/ (M[STT] < 0) ? skip next
	BUN L0
	HLT

/////////// subroutine (check end-character) ////////
CEC,	HEX 0
/ arg0 (AC) : output character
/ end-character = 0x4 (ctrl-D)
		ADD VM4		/ AC <- AC - 4
		SZA			/ (AC == 0) ? skip next
		BUN CEC I		/ return from CEC
/ output character matches (ctrl-D)
		LDA VM1		/ AC <- -1
		STA STT		/ M[STT] <- -1
		CLA			/ AC <- 0
		IMK			/ IMSK <- 0 (all interrupts disabled)
		BUN CEC I		/ return from CEC

/////////// subroutine (update IMSK) ////////
UMK,HEX 0
/ arg0 (AC) : unchanged bit mask
/ arg1 : added mask bit
	AND MSK		/ AC <- arg0 & M[MSK]
	ADD UMK I	/ AC <- AC + M[M[UMK]]
	STA MSK		/ M[MSK] <- AC
	IMK			/ IMSK <- AC[3:0]
	ISZ UMK		/ ++M[UMK]
	BUN UMK I	/ return from UMK

/////////// interrupt handler /////////
/ 1. store AC & E to memory
I_HND, 	STA BA	/ M[BA] <- AC	(store AC)
		CIL			/ AC[0] <- E	(AC[15:1] is not important here...)
		STA BE		/ M[BE] <- AC	(store E)

/ 2. check SFG and S_IN
SIN,
	SIO
		LDA SFG		/ AC <- M[SFG]
		SZA			/ (M[SFG] == 0) ? skip next
		BUN POU		/ goto POU
		SIO			/ IOT <- 1 (serial-IO selected)
		SKI			/ (UART_RX ready) ? skip next
		BUN IRT		/ goto PIN
		
	/ S_IN is ready --> (P_OUT : enabled)
	/	LDA VH1
	/	IMK

	/ S_IN is ready --> update IMSK (disable S_IN, enable P_OUT)
	LDA VH6		/ AC <- (0110) (S_OUT, P_IN : unchanged)
	BSA UMK		/ call UMK (update IMSK)
	HEX 1		/ (0001) (P_OUT : enabled)

	/ read S_IN data
		INP			/ AC(7:0) <- INPR
		STA SDT		/ M[SDT] <- AC
		ISZ SFG		/ ++M[SFG]

/ 3. check P_OUT
POU, / M[SFG] != 0
		PIO			/ IOT <- 0 (parallel-IO selected)
		SKO			/ (P_OUT ready) ? skip next
		BUN IRT		/ goto PIN
	
	/ P_OUT is ready --> (S_IN : enabled)
	/	LDA VH8
	/	IMK

	/ P_OUT is ready --> update IMSK (disable P_OUT, enable S_IN)
	LDA VH9		/ AC <- (0110) (S_OUT, P_IN : unchanged)
	BSA UMK		/ call UMK (update IMSK)
	HEX 8		/ (1000) (S_IN : enabled)

	/ output to P_OUT
		LDA SDT		/ AC <- M[SDT]
		OUT			/ OUTR <- AC
		BSA CEC		/ call CEC (check end-character)
		CLA			/ AC <- 0
		STA SFG		/ M[SFG] <- 0
		BUN SIN

/ 4. restore AC & E from memory
IRT,LDA BE		/ AC <- M[BE]
	CIR			/ E <- AC[0]	(restore E)
	LDA BA		/ AC <- M[BA]	(restore AC)
	ION			/ IEN <- 1		(enable interrupt)
	BUN ST0 I	/ indirect return (return address stored in ST0)

/ data (no initialization)
BA, DEC 000		/ backup storage for AC during interrupt handling
BE, DEC 000		/ backup storage for  E during interrupt handling
SDT,DEC 0		/ S_IN data
PDT,DEC 0		/ P_IN data
/ data (need initialization code)
STT,DEC 0       / state
SFG,DEC 0       / S_IN flag
PFG,DEC 0       / P_IN flag
MSK,DEC 0		/ IMSK data
/ data (read-only)
VH6,HEX 6       / VH6 = 0x6 (0110)
VH1,HEX 1
VH2,HEX 2
VH8,HEX 8
VHF,HEX F
VH9,HEX 9       / VH9 = 0x9 (1001)
VHA,HEX A       / VHA = 0xA (1010)
VM1,DEC -1      / VM1 = -1
VM4,DEC -4		/ VM4 = -4
MAX,DEC -4
	END
