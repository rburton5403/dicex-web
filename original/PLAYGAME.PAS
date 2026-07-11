UNIT PLAYGAME;
INTERFACE

VAR
  LEVEL: INTEGER;
  SIXTY9S: INTEGER;
  SCORE: LONGINT;

PROCEDURE GAMELOOP;
PROCEDURE UPDBOARD;

IMPLEMENTATION

USES CRT, GRAPH, STRINGS,
     PLAYAREA;

PROCEDURE GAMELOOP;
VAR
  NEXTDIE: INTEGER;
  C: CHAR;
  DIEX,
  DIEY: INTEGER;
  DIDGRAVITY,
  ANYFALL: BOOLEAN;
  SUB69: INTEGER;
BEGIN
  NEWPLAYAREA;
  LEVEL := 1;
  SIXTY9S := 0;
  SCORE := 0;
  UPDBOARD;
  GRAVITYAT := 100 DIV LEVEL +10;

  RANDOMIZE;
  REPEAT

    REPEAT
      NEXTDIE := RANDOM(7);
    UNTIL NEXTDIE IN [1..6];

    DIEX := 5;
    DIEY := 1;
    PUTDIE(DIEX,DIEY,NEXTDIE);
    STARTGRAVITY;
    REPEAT
      IF KEYPRESSED THEN
      BEGIN
        C := READKEY;
        IF C = #0 THEN
        BEGIN
          C := READKEY;
          CASE C OF
            #75: {LEFT}
              IF (DIEX > 1) AND (PLAYFIELD[DIEX-1,DIEY]=0) THEN
              BEGIN
                PUTDIE(DIEX-1,DIEY, PLAYFIELD[DIEX,DIEY]);
                PUTDIE(DIEX,DIEY, 0);
                DEC(DIEX);
              END;

            #77: {RIGHT}
              IF (DIEX < FIELDMAXX) AND (PLAYFIELD[DIEX+1,DIEY]=0) THEN
              BEGIN
                PUTDIE(DIEX+1,DIEY, PLAYFIELD[DIEX,DIEY]);
                PUTDIE(DIEX,DIEY, 0);
                INC(DIEX);
              END;

            #80: {DOWN}
              IF (DIEY < FIELDMAXY) AND (PLAYFIELD[DIEX,DIEY+1]=0) THEN
              BEGIN
                PUTDIE(DIEX,DIEY+1, PLAYFIELD[DIEX,DIEY]);
                PUTDIE(DIEX,DIEY, 0);
                INC(DIEY);
              END;

          END;
        END;
      END;

      CHECKGRAVITY(DIDGRAVITY, ANYFALL);
      IF DIDGRAVITY AND ANYFALL THEN INC(DIEY);   { TRACK DIE COORDS }

    UNTIL DIDGRAVITY AND NOT ANYFALL;

    CHECKELIM(SUB69);

    IF SUB69 > 0 THEN
    BEGIN
      INC(SIXTY9S, SUB69);
      INC(SCORE, SUB69*(50+(SUB69*5)));
      IF SIXTY9S > 6 THEN
      BEGIN
        INC(LEVEL, 1);
        INC(SCORE, LEVEL*1000);
        GRAVITYAT := 100 DIV LEVEL +10;
      END;

      UPDBOARD;
    END;

  UNTIL PLAYFIELD[5,1] <> 0;
END;

PROCEDURE UPDBOARD;
BEGIN

  OUTTEXTXY(1,1,'SCORE: '+INTTOSTR(SCORE)+'     ');
  OUTTEXTXY(1,20,'69''S: '+INTTOSTR(SIXTY9S)+'   ');
  OUTTEXTXY(1,30,'LEVEL: '+INTTOSTR(LEVEL)+'    ');
END;

END.