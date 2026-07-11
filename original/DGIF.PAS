unit dgif;

       { Steve Enns Feb.26 1989
         Copyright 1989 Steve Enns   All rights reserved.
         Synergrafix - Graphical and Numerical Software
         2425 Haultain Ave. Saskatoon, Sask. Canada  S7J 1R2

         GIF DEcoding for BGI graphics
         Based on GIFSLOW.PAS by Jim Griebel
         Must be in graphics mode before call
         Uses EGA palette.

         This software is provided for unlimited use and
         distribution EXCEPT for the following conditions:
           - No fee is to be charged for the use or distribution
             of this software, including any works which include
             the source code or compiled form of this software.
           - Any derived software or software which uses the source
             code or compiled versions of this software must include
             the source code of the derived software, and this notice.
           - This software is to be distributed in the original
             archived form, with the SAME name, GIFPASSE,
             i.e. GIFPASSE.ZIP, GIFPASSE.ARC.

         This software is provided without warranty of any kind,
         express or implied. YOU, the user assume complete
         responsibility for any and all incidental or consequential
         damages arising out of the use of this program. Use
         at your own risk.

         This license is intended to encourage the distribution of
         programs which include source code!

         'GIF' and 'Graphics Interchange Format' are trademarks
          of Compuserve, Inc., an H&R Block Company. }

interface

Function degif(filename :string; { Name of GIF file to decode }
               x,y      :integer { Location for upper left corner of image }
              ):boolean;         { Returns FALSE on failure }

implementation

{$R-,S-}                     { Speed }

uses graph, { PUTPIXEL }
     crt;   { KEYPRESSED, READKEY }

Function degif(filename:string;x,y:integer):boolean;

const maxcodes   :array[0..9] of word=(4,8,16,$20,$40,$80,$100,$200,$400,$800);
      codemask   :array[1..8] of byte=(1,3,7,15,31,63,127,255);
      powersof2  :array[0..8] of word=(1,2,4,8,16,32,64,128,256);
      masks      :array[0..9] of Integer=(7,15,$1f,$3f,$7f,$ff,$1ff,$3ff,$7ff,$fff);
      rastersize :word=64000;

type rasterarray=array[0..63999] of byte;
     rasterp=^rasterarray;

var giffile  :file of rasterarray;{The input file}
    gifstuff :rasterp;  {The heap array to hold it, raw}
    raster   :rasterp;  {The raster data stream, unblocked}
    raster2  :rasterp;  {more raster data stream if needed}
    byteoffset,         {computed byte position in rasTEr array}
    bitoffset :longint; {bit offset of next code in rasTEr array}

    width,      {read from gif header, image width}
    height,     { ditto, image height}
    leftofs,    { ditto, image offset from left}
    topofs,     { ditto, image offset from top}
    rwidth,     { ditto, raster width}
    rheight,    { ditto, raster height}
    clearcode,  {gif clear code}
    eofcode,    {gif end-of-information code}
    outcount,   {decompressor output 'stack count'}
    maxcode,    {decompressor limiting value for current code size}
    code,       {Value returned by readcode}
    curcode,    {decompressor variable}
    oldcode,    {decompressor variable}
    incode,     {decompressor variable}
    firstfree,  {first free code, generated per gif spec}
    freecode,   {decompressor, next free slot in hash table}
    gifptr,     {array pointers used during file read}
    rasterptr,
    xc,yc,      {screen X and Y coords of current pixel}
    pindex,     {Index into screen save array}
    readmask,   {code and mask for current code size}
    i       :word;

    interlace,  {True if interlaced image}
    nextraster, {True if file > 64000 bytes}
    colormap :boolean; {True if colormap present}

    ch      :char;
    a,              {Utility}
    resolution,     {resolution, read from gif header}
    bitsperpixel,   {bits per pixel, read from gif header}
    background,     {background color, read from gif header}
    colormapsize,   {Length of color map, from gif header}
    codesize,       {code size, read from gif header}
    initcodesize,   {starting code size, used during clear}
    finchar,        {decompressor variable}
    pass,           {Used by video output if interlaced pic}
    bitmask,        {and mask for data size}
    r,g,b      :byte;
    filestring :string[80];
    ioerror    :boolean;

    {The hash table used by the decompressor}
    prefix  :array[0..4095] of word;
    suffix  :array[0..4095] of byte;

    {an output array used by the decompressor}
    outcode :array[0..1024] of byte;

    {The color map, read from the gif header}
    red,green,blue  :array[0..255] of byte;

    {The ega palette, derived from the color map}
    palette         :array[0..255] of byte;

Procedure detcolor(var pvalue:byte;mapvalue:byte);
var local :byte;
begin
   pvalue:=mapvalue div 64;
   if pvalue=1 then pvalue:=2 else
   if pvalue=2 then pvalue:=1
end;

Function allocmem(var p:rasterp):boolean;
var asize :longint;
begin
   asize:=maxavail;
   if asize<rastersize then
      allocmem:=false
   else
   begin
      getmem(p,rastersize);
      allocmem:=true
   end
end;

Function getbyte:byte;
begin
   if gifptr=rastersize then exit;
   getbyte:=gifstuff^[gifptr];
   inc(gifptr)
end;

Function getword:word;
var a :byte;
begin
   a:=getbyte;
   getword:=a+getbyte shl 8
end;

Function readraster:boolean;
var blocklength :byte;
    i,ior       :integer;
begin
   readraster:=true;
   rasterptr:=0;
   repeat
      blocklength:=getbyte;
      for i:=0 to blocklength-1 do
      begin
         if gifptr=rastersize then
         begin
            {$I-}
            read(giffile,gifstuff^);
            {$I+}
            ior:=ioresult;
            gifptr:=0
         end;
         if not nextraster then
            raster^[rasterptr]:=getbyte
         else
            raster2^[rasterptr]:=getbyte;
         inc(rasterptr);
         if rasterptr=rastersize then
         begin
            nextraster:=True;
            rasterptr:=0;
            if not allocmem(raster2) then
               readraster:=false
         end
      end
   until blocklength=0
end;

Procedure readcode;
var rawcode :longint;
    a       :word;
begin
   byteoffset:=bitoffset shr 3 {div 8};

   {pick up our 24-bit chunk}

   a:=raster^[byteoffset]+(raster^[byteoffset+1] shl 8);

   if codesize>=8 then
      rawcode:=a+(raster^[byteoffset+2]*65536)
   else
      rawcode:=a;

   {  doing the above calculation as a single statement, i.e.

   rawcode:=raster^[byteoffset]+(256*raster^[byteoffset+1])+
           (65536*raster[byteoffset+2])
   sometimes returns incorrect results. This may or may not be a bug.}


   rawcode:=rawcode shr(bitoffset mod 8);
   code:=rawcode and readmask;

   {cope with overflow of the first raster array}

   if (nextraster) and (byteoffset>=63000) then
   begin
      move(raster^[byteoffset],raster^[0],rastersize-byteoffset);
      move(raster2^[0],raster^[rastersize-byteoffset],63000);
      bitoffset:=bitoffset mod 8;
      freemem(raster2,rastersize)
   end;

   bitoffset:=bitoffset+codesize

end;

Procedure doclear;
begin
   codesize:=Initcodesize;
   maxcode:=maxcodes[codesize-2];
   freecode:=firstfree;
   readmask:=masks[codesize-3]
end;

Procedure addtopixel(index:byte);
begin

{   putpixel(xc,yc,not index);
}
   putpixel(xc,yc,index);

   inc(xc);
   if xc=width+x then
   begin
      xc:=x;
      if not interlace then
         inc(yc)
      else
      case pass of
         0: begin
               inc(yc,8);
               if yc>=height+y then
               begin
                  inc(pass);
                  yc:=4+y
               end
            end;
         1: begin
               inc(yc,8);
               if yc>=height+y then
               begin
                  inc(pass);
                  yc:=2+y
               end
            end;
         2: begin
               inc(yc,4);
               if yc>=height+y then
               begin
                  inc(pass);
                  yc:=1+y
               end
            end;
         3: inc(yc,2)
      end
   end
end;

begin
   degif:=true;

   xc:=x;          {X and Y screen coords back to home}
   yc:=y;
   pass:=0;        {interlace pass counter back to 0}
   bitoffset:=0;   {point to the start of the raster data stream}
   gifptr:=0;      {mock file read pointer back to 0}

   nextraster:=false;    {over 64000 flag off}

   if (not allocmem(raster)) or (not allocmem(gifstuff)) then
      degif:=false
   else
   begin

      {$I-}
      assign(giffile,filename);
      reset(giffile);
      {$I+}

      degif:=(ioresult=0);

      {$I-}
      read(giffile,gifstuff^);
      {$I+}

      ioerror:=(ioresult<>0);

      if ioresult=0 then
      begin

         filestring:='';
         for i:=1 to 6 do
            filestring:=filestring+chr(getbyte);

         if filestring<>'GIF87a' then
            degif:=false
         else
         begin

            { get variables from the gif screen descriptor}

            rwidth:=getword;         {The raster width and height}
            rheight:=getword;

            {get the packed byte immediately following and decode it}

            b:=getbyte;
            if b and $80=$80 then
               colormap:=true
            else
               colormap:=false;
            resolution:=b and $70 shr 5 +1;
            bitsperpixel:=b and 7+1;
            if bitsperpixel=1 then
               i:=2
            else
               i:=1 shl bitsperpixel;

            bitmask:=codemask[bitsperpixel];
            background:=getbyte;
            b:=getbyte;         {skip byte of 0's}

            colormapsize:=(1 shl bitsperpixel)-1;

            if colormap then
            begin
               for i:=0 to colormapsize{-1} do
               begin
                  red[i]:=getbyte;
                  green[i]:=getbyte;
                  blue[i]:=getbyte;
                  detcolor(r,red[i]);
                  detcolor(g,green[i]);
                  detcolor(b,blue[i]);
                  palette[I]:=b and 1+(2*(g and 1))+(4*(r and 1))+(8*(b div 2))+(16*(G div 2))+(32*(r div 2))
               end;
               palette[16]:=background
            end;

            {now read in values from the image descriptor}

            b:=getbyte;  {skip image seperator}
            leftofs:=getword;
            topofs:=getword;
            width:=getword;
            height:=getword;
            a:=getbyte;
            if a and $40=$40 then
               interlace:=true
            else
               interlace:=false;

            codesize:=getbyte;

            {compute decompressor constant values, based on the code size}

            clearcode:=powersof2[codesize];
            eofcode:=clearcode+1;
            firstfree:=clearcode+2;
            freecode:=firstfree;

            inc(codesize);
            initcodesize:=codesize;
            maxcode:=maxcodes[codesize-2];
            readmask:=masks[codesize-3];

            if not readraster then
            begin
               degif:=false;
               exit
            end;

            freemem(gifstuff,rastersize);
            outcount:=0;

            repeat

               {get the next code from the raster array}

               readcode;

               if code<>eofcode then
               begin
                  if code=clearcode then
                  begin
                     doclear;
                     readcode;
                     curcode:=code;
                     oldcode:=code;
                     finchar:=code and bitmask;
                     addtopixel(finchar);
                  end else
                  begin
                     curcode:=code;
                     Incode:=code;
                     if code>=freecode then
                     begin
                        curcode:=oldcode;
                        outcode[outcount]:=finchar;
                        inc(outcount)
                     end;

                     if curcode>bitmask then
                     repeat
                        outcode[outcount]:=suffix[curcode];
                        inc(outcount);
                        curcode:=prefix[curcode];
                     until curcode<=bitmask;

                     finchar:=curcode and bitmask;
                     outcode[outcount]:=finchar;
                     inc(outcount);

                     for i:=outcount-1 downto 0 do
                        addtopixel(outcode[i]);

                     outcount:=0;

                     prefix[freecode]:=oldcode;
                     suffix[freecode]:=finchar;
                     oldcode:=incode;

                     inc(freecode);
                     if freecode>=maxcode then
                     begin
                        if codesize<12 then
                        begin
                           inc(codesize);
                           inc(maxcode,maxcode);
                           readmask:=masks[codesize-3]
                        end
                     end
                  end;

                  if keypressed then
                     if readkey=#27 then
                        exit

               end
            until code=eofcode

         end
      end else
         degif:=false;

      close(giffile);
      freemem(raster,rastersize)

   end

end;

begin
end.