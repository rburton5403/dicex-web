UNIT RAWSUPP;
{$X+}

INTERFACE

PROCEDURE SHOWRAW(FN: STRING);

IMPLEMENTATION

USES GRAPH, CRT;

PROCEDURE SHOWRAW(FN: STRING);
TYPE
  PTYPE = ARRAY[1..32768] OF BYTE;
VAR
  F: FILE;
  READS: BYTE;
  C: WORD;
  P: POINTER;
  TOP: POINTER;
  X,Y: INTEGER;
  CR,CG,CB: BYTE;
BEGIN
  ASSIGN(F, FN+'.RAW');
  RESET(F,1);
  X := 1;
  Y := 1;  GETMEM(P, 32768);
  TOP := PTR($A000,0);
  FOR READS := 1 TO 5 DO
  BEGIN
    BLOCKREAD(F,P^,32768);
    FOR C := 1 TO 32768 DO
    BEGIN
      IF X > 640 THEN
      BEGIN
        X := 1;
        INC(Y);
      END;
      IF Y > 479 THEN Y := 479;

      { REMAP COLORS }
      CASE PTYPE(P^)[C] OF
        12: PTYPE(P^)[C] := 9;
        8: PTYPE(P^)[C] := 7;
        7: PTYPE(P^)[C] := 8;
        9: PTYPE(P^)[C] := 12;
        1: PTYPE(P^)[C] := 4;
        11: PTYPE(P^)[C] := 14;
        3: PTYPE(P^)[C] := 6;
        14: PTYPE(P^)[C] := 11;
        6: PTYPE(P^)[C] := 3;
        12: PTYPE(P^)[C] := 9;
        4: PTYPE(P^)[C] := 1;
      END;

      PUTPIXEL(X,Y,PTYPE(P^)[C]);
      IF PTYPE(P^)[X] > 15 THEN
        WRITE;
      INC(X);
    END;
{    ASM
      PUSH DS

      MOV AX, SEG TOP
      PUSH AX
      POP ES
      MOV DI, OFFSET TOP

      MOV AX, SEG P
      PUSH AX
      POP DS
      MOV SI, OFFSET P

      MOV CX, 32768
      REP MOVSB

      POP DS
@@END:
    END;}
  END;

{  FOR Y := 1 TO 480 DO
  BEGIN
    BLOCKREAD(F, P, 640);
    FOR X := 1 TO 640 DO
    BEGIN
      PUTPIXEL(X,Y, P[X]);
    END;
  END;}
  FREEMEM(P, 32768);
  CLOSE(F);
            WRITE(#7);

{  FOR C := 1 TO 777-16 DO
  BEGIN
    ASSIGN(F, FN+'.PLT');
    RESET(F,1);
    FOR X := 1 TO C DO BLOCKREAD(F, CR, 1);
    FOR X := 0 TO 15 DO
    BEGIN
      BLOCKREAD(F, CR, 1);
      BLOCKREAD(F, CG, 1);
      BLOCKREAD(F, CB, 1);
      SETRGBPALETTE(X,CR,CG,CB);
    END;
    CLOSE(F);
    WRITE(#7);
    REPEAT UNTIL KEYPRESSED; READKEY;
  END;}

{  SETRGBPALETTE(0,0,0,0);
  SETRGBPALETTE(1,$80,0,0);
  SETRGBPALETTE(2,0,$80,0);
  SETRGBPALETTE(3,$80,$80,0);
  SETRGBPALETTE(4,0,0,$80);
  SETRGBPALETTE(5,$80,0,$80);
  SETRGBPALETTE(6,0,$80,$80);
  SETRGBPALETTE(7,$80,$80,$80);
  SETRGBPALETTE(8,$C0,$C0,$C0);
  SETRGBPALETTE(9,$FF,0,0);
  SETRGBPALETTE(10,0,$FF,0);
  SETRGBPALETTE(11,$FF,$FF,0);
  SETRGBPALETTE(12,0,0,$FF);
  SETRGBPALETTE(13,$FF,0,$FF);
  SETRGBPALETTE(14,0,$FF,$FF);
  SETRGBPALETTE(15,$FF,$FF,$FF);}

{  FOR C := 0 TO 15 DO
  BEGIN
    SETRGBPALETTE(C,0,0,$FF);
    WRITE(#7);
    READLN;
  END;}
END;

END.