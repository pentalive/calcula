
{$mode objfpc}{$H+}

{ This program licenced under the GNU general licence V3  } 
{ See file LICENSE for details or visit                   }
{ https://www.gnu.org/licenses/gpl-3.0.en.html            }

program calcula;

uses crt,math;

type
 mem = array[1..26] of double;

const
   e:double = 2.7182821828;

VAR
   filehandle	   : file of mem;  { to load or save registers and stack }
   s		   : mem;          { The STACK                           }
   r		   : mem;          { The Registers                       }

   { The Statistical Registers  }
   SumX,SumY,n,Sumx2,Sumy2,SumXY:double;
   
   anglemode	   : integer;   { 0= degrees 1=rads should probs be}
                                { an enumerated type               }
   collected	   : string;    { collect number, keep error text  }
   i,k		   : integer;   { integer indexes - k is ord of c  }
   c		   : char;      { The readkey pressed by user      }
   done		   : boolean;   { Remembers if esc is pressed      }
   stacklift	   : boolean;   { Automatic Stack Lift             }   
   t		   : double;    { gemeral temporary storage        }
   mtemp1	   : double;    { Used when pulling numbers off    }
   mtemp2	   : double;    { the stack for calculations       }
   statusx,statusy : tcrtcoord; { location of the status line      }
   regc		   : char;      { char for getting register letter }
   regk		   : integer;   { ord of regc                      }
   LastX	   : double;    { store LastX values               }

function IsNumber(c:char):boolean;


begin

   IsNumber := false;

   if c in ['0'..'9'] then IsNumber := true;
   if c='_' then IsNumber := true;
   if c='.' then IsNumber := true;
   if ord(c) = 8 then IsNumber := true;

   IsNumber := result;

end;


procedure display;
var
   i : byte;
   ch : char;

begin
   gotoxy(1,1);
   clrscr;

   if c='' then c := ' ';
   
   writeln('|-Calcula ------------------------------------------------',c:2,k:04,'--------------|');
   writeln('| stack                                  | registers                          |');
   writeln('|----------------------------------------|------------------------------------|');
   i := 13;
   repeat
      write('|s',i:02,s[i]:15:4);
      write(' |s',i+13:02,' ',s[i+13]:15:4);
      ch := chr(64 + i);
      write(' |',ch,' ',r[i]:15:4);
      ch := chr(64 + 13 + i);
      write(' |',ch,' ',r[i+13]:15:4,'|');
      writeln;
      i := i - 1;
   until i = 0;
   writeln('|----------------------------------------|------------------------------------|');
   writeln('|         x        y        n      x^2      y^2       xy         LastX        |');
   write('| ',SumX:9:4,SumY:9:4,n:9:0,SumX2:9:4,SumY2:9:4,SumXY:9:4,LastX:15:4);
   if anglemode = 0 then writeln(' DEG   |') else writeln(' RAD   |');
   writeln('|----------------------------------------|------------------------------------|');
   statusx := wherex;
   statusy := wherey;
   writeln('|         ',collected:60,'        |');
   writeln('|----------------------------------------------------------------? for help---|');
end;


{ Push a number onto the stack }
procedure Push(x : double);

var
   i : integer;

begin
   for i:= 26 downto 2 do
      begin
	 s[i] := s[i-1];
      end;
   s[1] := x;
end;



{ pop a number from the stack }
function Pop : Double;

var
   i : integer;

begin;
   Pop := s[1];
   for i:= 1 to 25 do s[i] := s[i+1];
end;




function CollectNumber : double;

var
   neg	  : boolean;
   x,y	  : tcrtcoord;
   number : double;
   
Begin
   neg := false;
   collected := c;
   x := statusx;
   y := statusy;
   repeat
      gotoxy(x,y);
      write('| ');
      if neg then write('-');
      write(collected:20,'  ');

      c := readkey;
      
      if (ord(c) = 8) and (length(collected) > 0) then
	 begin
	    delete(collected,length(collected),1);
	 end;
      
      if IsNumber(c) then
	 begin
	 if (c = '_') then
	    begin
	       neg := not neg;
	    end else begin
	       if ord(c) <> 8 then  collected := collected + c;
	    end;
	 end;
      
   until not IsNumber(c);
   val(collected,number);
   if neg then number := number * -1.0;
   if ord(c) = 13 then c := ' ';
   display;
   CollectNumber := number;
end;



begin

   stacklift := true;
   LastX := 0;
   anglemode := 0;

   SumX  := 0.0;
   SumY  := 0.0;
   n     := 0.0;
   SumX2 := 0.0;
   SumY2 := 0.0;
   SumXY := 0.0;
   
   
   for i:=1 to 26 do begin
      s[i] := 0.0;
      r[i] := 0.0;
   end;

   
   done := false;
   repeat
      display;

      {get next keystroke}
      c := readkey;
      k := ord(c);

      {have we begun entering a number?}
      if (k <= ord('9')) and (k>= ord('0')) then
	    push(CollectNumber);

      
      if (c = '_') or (c = '.') then
	    push(CollectNumber);
 

      k := ord(c);

      {clear status line}
      collected := '';


      {handle non number keystrokes}
      case (k) of

	76  : begin { 'L' LastX }
		 push(LastX);
	      end;


	65  : begin  { 'A' angle mode - toggle degrees or radians }
		 if anglemode = 0 then anglemode := 1 else anglemode := 0;
	      end;
	
	115 : begin  { 's' sin }
		 mtemp1 := pop;
		 if anglemode = 0 then mtemp1 := mtemp1 * (pi / 180.0);
		 Push(sin(mtemp1));
	      end;

	63  : begin {'?' helpscreen }
		 gotoxy(1,1);
		 clrscr;
		 writeln('|-Calcula Help ---------------------------------------------------------------|');
		 writeln('| 0-9 . _ [backspace]  Number entry                       [esc] exit program  |');
		 writeln('| _ changes sign, [backspace] deletes last digit                              |');
		 writeln('|-----------------------------------------------------------------------------|');
		 writeln('| + - * / ^   Math: add,subtract,multiply,divide, s2^s1                       |');
		 writeln('|-----------------------------------------------------------------------------|');
		 writeln('| s sin, c cos, t tangent, q square root, r reciprocal                        |');
		 writeln('| l logx - Log base Stack level 1, of number in Stack level 2                 |');
		 writeln('|                                                                             |');
		 writeln('|                                                                             |');
		 writeln('|                                                                             |');
		 writeln('|-----------------------------------------------------------------------------|');
		 writeln('| L Last X, >x Store to reg x, >x Recall from reg x                           |');
		 writeln('| ] Save all to file, [ Read all from writeln                                 |');
		 writeln('| X s1 exchange s2                                                            |');
		 writeln('|-----------------------------------------------------------------------------|');
		 writeln('| p pi, e Euler Number                                                        |');
		 writeln('|                                                                             |');
		 writeln('|                                                                             |');
		 writeln('|                                                                             |');
	
		 writeln('|------------------------------------------------- Press any key to continue -|');
		 c := readkey;
	      end;

	88  : begin {'X' s1 exchange s2 }
		 mtemp1 := s[1];
		 mtemp2 := s[2];
		 s[2] := mtemp1;
		 s[1] := mtemp2;
	      end;
	

	95  : begin { 'c' cosin }
		 mtemp1 := pop;
		 if anglemode = 0 then mtemp1 := mtemp1 * (pi / 180.0);
		 Push(cos(mtemp1));
	      end;

	116 : begin { 't' tan }
		 mtemp1 := pop;
		 if anglemode = 0 then mtemp1 := mtemp1 * (pi / 180.0);
		 Push(tan(mtemp1));
	      end;

	83  : begin { del - drop s1}
		pop;
	     end;

	27  : begin { esc }
		done := true;
	     end;

        43  : begin  {'+'}
		LastX := s[1];
		Push(Pop + Pop);
	     end;

	47  : begin {'/ divide'}
		if s[1] = 0 then
		   begin
		      collected := 'Divide by zero? '
		   end else begin
		      LastX := s[1];
                      mtemp1 := Pop;
		      mtemp2 := Pop;
		      push(mtemp2 / mtemp1);
		   end;
	     end;

	112 : begin {p pi 3.1415...}
		 Push(Pi);
	      end;

	101 : begin { 'e' euler's number }
		 push(e);
	      end;

	113 : begin {q square root}
		 if s[1] < 0 then
		    begin
		       collected := 'Square root of a negative?';
		    end else begin
		       LastX := s[1];
		       push(sqrt(pop));
		    end;	  
	      end;
	
	114 : begin {'r reciprocal'}
		if s[1] = 0 then
		begin
		   collected := 'Reciprocal of zero?'
		end else begin
		   LastX := s[1];
		   mtemp1 := Pop;
		   mtemp2 := 1.0;
		   push(mtemp2 / mtemp1);
		end;
	     end;


	42  : begin {'*'}
		LastX := s[1];
		Push(Pop*Pop);
	     end;

	45  : begin {'-'}
		LastX := s[1];
		mtemp1 := Pop;
		mtemp2 := Pop;
		push(mtemp2 - mtemp1);
	      end;

		108 : begin { 'l' logx }
		 mtemp1 := pop;
		 mtemp2 := pop;
		 if (mtemp2 = 0) then
		 begin
		    collected := 'logx with x is zero?';
		 end else begin
		    LastX := mtemp1;
		    push(logn(mtemp1,mtemp2));
		 end;
	      end;
	


	94  : begin {'^' x^y }
		LastX := s[1];
		mtemp1 := Pop;
		mtemp2 := Pop;
		push(mtemp1 ** mtemp2);
	     end;

        62  : begin {'>' store }
		repeat
		   regc := UpCase(readkey);
		   regk := ord(regc);
		until regc in ['A'..'Z'];
		write('Store ',regc);
		regk := regk - ord('A') + 1;
		r[regk] := s[1];
	     end;

	60  : begin {'<' recall }
		repeat
		   regc := UpCase(readkey);
		   regk := ord(regc);
		until regc in ['A'..'Z'];
		write('Recall ',regc);
		regk := regk - ord('A') + 1;
		Push(r[regk]);
	     end;


	
	13  : begin { enter }
		t := Pop;
		Push(t);
		Push(t);
	     end;

	91  : begin { [ recall }
		 AssignFile(filehandle,'.calculamemory');
		 Reset(filehandle);
		 Read(filehandle,s);
		 Read(filehandle,r);
		 CloseFile(filehandle);
		 collected := 'Restored registers and stack';
		 LastX := s[1];
	      end;

	93  : begin { ] Save }
		 AssignFile(filehandle,'.calculamemory');

		 ReWrite(filehandle);
		 write(filehandle,s);
		 write(filehandle,r);
		 CloseFile(filehandle);
		 collected := 'Saved registers and stack';
	      end;
	
      else
         begin
            writeln('key code:',k:04);
         end;
      end; {case}

   until done;
end.


