<%@ page isErrorPage="true" %> 
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
<link rel="stylesheet" type="text/css" href="http://localhost:8080/spring-web/css/site.css">

<link rel="stylesheet" type="text/css" href="//fonts.googleapis.com/css?family=Josefin+Slab" />
<link rel="stylesheet" type="text/css" href="//fonts.googleapis.com/css?family=Ubuntu" />
<link rel="stylesheet" href="http://localhost:8080/spring-web/libs/pure-release-0.6.0/pure-min.css">
<title>Acceso Negado!</title>
</head>
<body>

	<div class="bigtitle">ACCESS-DENIED</div>
	<div class="box">views/errors/access_denied.jsp</div>

	<div class="clearfix float-my-children">
		 <div>
			 <span class="text-green">Response Status-Code: </span><span class="text-yellow-big"><%=response.getStatus() %></span>
		 </div>
	 </div>
	 
	 <div style="color: #00AA00; font-weight: bold;">
	 	<pre>
Clock

CGROUP	 GROUP VECTOR,CODESEG
VECTOR	 SEGMENT AT 0H
	 DB    6CH DUP(?)	    ;FILLER
TIME_LO  DW    ?		    ;DOS TIME
TIME_HI  DW    ?		    ;DOS TIME
VEC_IP	 DW			    ;CLOCK UPDATE VECTOR IP
VEC_CS	 DW			    ;CLOCK UPDATE VECTOR CS
VECTOR	 ENDS

CODESEG  SEGMENT PARA
	 ASSUME CS:CODESEG,DS:CGROUP
	 ORG   100H
CLK	 PROC  FAR
	 JMP   SETUP		    ;ATTACH TO DOS
INTRPT	 LABEL DWORD
INT_IP	 DW    0		    ;OLD UPDATE VECTOR IP
INT_CS	 DW    0		    ;OLD UPDATE VECROR CS
TICKS	 DW    0		    ;TICK COUNTER
SCR_OFF  DB    0,0		    ;SCREEN OFFSET IN BUFFER
CRT_PORT DW    0		    ;SCREEN STATUS PORT
flag	 db    0
TIME	 DB    8 DUP(':',0BH)       ;TIME SAVE AREA
CLK_INT  LABEL NEAR
	 PUSH  AX		    ;SAVE REGISTERS
	 PUSH  CX
	 PUSH  DI
	 PUSH  SI
	 PUSH  DS
	 PUSH  ES
	 PUSHF			    ; AND FLAGS
	 CALL  CS:[INTRPT]	    ;DO OLD UPDATE INTERRUPT
	 MOV   CX,0040H 	    ;GET SEGMENT OF DOS TABLE
	 MOV   DS,CX		    ;PUT IN DS
	 MOV   CX,CS:TICKS	    ;GET TICK COUNT
	 INC   CX		    ;INCREMENT IT
	 CMP   CX,20	    ;01F4H	       ;HAS A MINUTE GONE BY?
	 JB    NO_MINUTE	    ;NO, MOVE ON
	 CALL  UPDATE		    ;YES, UPDATE CLOCK AND
	 MOV   CX,0		    ; RESET TICK COUNTER
NO_MINUTE:
	 MOV   CS:TICKS,CX	    ;SAVE UPDATED TICK COUNT
	 MOV   CX,0B000H	    ;GET VIDEO SEGMENT
	 MOV   ES,CX		    ;PUT IN ES
	 MOV   DX,CS:CRT_PORT	    ;GET CRT STATUS PORT ADDR
	 MOV   DI,WORD PTR CS:SCR_OFF  ;GET SCREEN BUFFER OFFSET
	 LEA   SI,CS:TIME	    ;GET DOS TIME
	 MOV   CX,16		    ;SET UP TO MOVE 10 BYTES
	 CLI			    ;DISABLE OTHER INTERRUPTS
WAIT1:	 IN    AL,DX		    ;READ CRT STATUS
	 TEST  AL,1		    ;CHECK FOR VERTICAL RETRACE
	 JNZ   WAIT1		    ;WAIT FOR RETRACE LOW
	 MOV   AH,CS:[SI]	    ;GET FIRST BYTE TO MOVE
WAIT2:	 IN    AL,DX		    ;GET CRT STATUS
	 TEST  AL,1		    ;CHECK FOR VERTICAL RETRACE
	 JZ    WAIT2		    ;WAIT FOR RETRACE HIGH
	 MOV   ES:[DI],AH	    ;MOVE BYTE TO SCREEN
	 INC   DI		    ;INCREMENT INDEX
	 INC   SI
	 LOOP  WAIT1		    ;MOVE NEXT BYTE
	 STI			    ;ENABLE INTERRUPTS
	 POP   ES		    ;RESTORE REGISTERS
	 POP   DS
	 POP   SI
	 POP   DI
	 POP   CX
	 POP   AX
	 IRET			    ;RETURN FROM INTERRUPT
CLK	 ENDP
UPDATE	 PROC  NEAR
	 PUSH  AX		    ;SAVE REGISTERS
	 PUSH  BX
	 PUSH  CX
	 PUSH  DX
	 PUSH  DS
	 MOV   AX,0040H 	    ;GET ADDRESS OF DOS TABLE
	 MOV   DS,AX		    ;PUT IN DS
	 MOV   AX,TIME_HI	    ;GET HIGH BYTE OF DOS TIME
	 mov   flag,0		    ;am flag
HOUR:	 CMP   AX,0CH		    ;CONVERT TO HOURS
	 JLE   H1
	 mov   flag,1		    ;set to pm
	 SUB   AX,0CH
	 JMP   HOUR
H1:	 AAM			    ;CONVERT TO ASCII
	 ADD   AX,3030H
	 LEA   BX,CS:TIME	    ;GET ADDRESS OF TIME AREA
	 MOV   CS:[BX],AH	    ;SAVE HOURS FIRST DIGIT
	 MOV   CS:[BX+2],AL	    ;SAVE HOURS SECOND DIGIT
	 MOV   AX,TIME_LO	    ;GET DOS TIME LOW BYTE
	 MOV   CX,8H		    ;CONVERT TO MINUTES
	 SHR   AX,CL
	 MOV   DX,3CH
	 MUL   DL
	 SHR   AX,CL
	 AAM			    ;CONVERT TO ASCII
	 ADD   AX,3030H
	 MOV   CS:[BX+6],AH	    ;SAVE MINUTES FIRST DIGIT
	 MOV   CS:[BX+8],AL	    ;SAVE MINUTES SECOND DIGIT
	 mov   byte ptr cs:[bx+12],'a'
	 cmp   flag,0		    ;is it am?
	 jz    goahead
	 mov   byte ptr cs:[bx+12],'p'
goahead:
	 mov   byte ptr cs:[bx+14],'m'
	 POP   DS		    ;RESTORE REGISTERS
	 POP   DX
	 POP   CX
	 POP   BX
	 POP   AX
	 RET
UPDATE	 ENDP
SETUP:	 MOV   AX,0		    ;GET ADDRESS OF VECTOR TABLE
	 MOV   DS,AX		    ;PUT IN DS
	 CLI			    ;DISABLE FURTHER INTERRUPTS
	 MOV   AX,[VEC_IP]	    ;GET ADDRESS OF OLD UPDATE IP
	 MOV   CS:[INT_IP],AX	    ;SAVE IT
	 MOV   AX,[VEC_CS]	    ;GET ADDRESS OF OLD UPDATE CS
	 MOV   CS:[INT_CS],AX	    ;SAVE IT
	 MOV   VEC_IP,OFFSET CLK_INT ;PUT ADDRESS OF CLK IN VECTOR IP
	 MOV   VEC_CS,CS	    ;PUT CS OF CLK IN VECTOR CS
	 STI			    ;ENABLE INTERRUPTS
	 MOV   AH,0FH		    ;READ VIDEO STATUS
	 INT   10H
	 SUB   AH,8		    ;SUBTRACT 8 CHAR TIME FROM NCOLS
	 SHL   AH,1		    ;MULTIPLY BY 2 FOR ATTRIBUTE
	 MOV   CS:SCR_OFF,AH	    ;SAVE SCREEN TIME LOCATION
	 MOV   WORD PTR CS:CRT_PORT,03BAH  ;SAVE MONO STATUS PORT ADDR
	 TEST  AL,4		    ;CHECK FOR COLOR MONITOR
	 JNZ   MONO		    ;IF MONO, MOVE ON
	 ADD   WORD PTR CS:SCR_OFF,8000H   ;ADD COLOR OFFSET TO TIME OFFSET
	 MOV   WORD PTR CS:CRT_PORT,03DAH  ;SAVE COLOR STATUS PORT ADDR
MONO:	 CALL  UPDATE		    ;DO FIRST UPDATE & PRINT TIME
	 MOV   DX,OFFSET SETUP	    ;GET END ADDRESS OF NEW INTERRUPT
	 INT   27H		    ;TERMINATE AND REMAIN RESIDENT
	 DB    117 DUP(0)	    ;FILLER
CODESEG  ENDS
	 END   CLK
	 	</pre>
	 </div>
	 
	 <style type="text/css">
	 	.denied{
	 		position: fixed;
	 		width: 800px;
			height: 100px; 
	 		top: 50%; 
	 		left: 50%; 
	 		margin-top: -50px;
	 		margin-left: -500px;
	 		
	 		text-align: center;
	 		color: #00FF00;
	 		font-size: 500%;
	 		background-color: black;
	 		border-style: solid;
	 		padding-left: 40px;
	 		padding-right: 40px;
	 		padding-top: 10px;
	 		padding-bottom: 10px;
	 	}
	 </style>
	 
	 <div class="denied">ACCESS DENIED</div>
	 
</body>
</html>