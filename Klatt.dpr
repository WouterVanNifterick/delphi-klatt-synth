program Klatt;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  SysUtils,
  WvN.Util.CmdLine,
  Klatt.ParWave in 'Klatt.ParWave.pas';

const NUMBER_OF_SAMPLES = 100;
const SAMPLE_FACTOR = 0.00001;

procedure Usage;
begin
  Writeln('Options...');
  Writeln('-h Displays this message');
  Writeln('-i <infile> sets input filename');
  Writeln('-o <outfile> sets output filename');
  Writeln('   If output filename not specified, stdout is used');
  Writeln('-q quiet - print no messages');
  Writeln('-t <n> select output waveform');
  Writeln('-c select cascade-parallel configuration');
  Writeln('   Parallel configuration is default');
  Writeln('-n <number> Number of formants in cascade branch.');
  Writeln('   Default is 5');
  Writeln('-s <n> set sample rate');
  Writeln('-f <n> set number of milliseconds per frame, default 10');
  Writeln('-v <n> Specifies voicing source.');
  Writeln('   1:=impulse train, 2=natural simulation, 3=sampled natural');
  Writeln('   Default is a simulation of natural voicing');
  Writeln('-V <filename> Input file of samples for natural voicing.');
  Writeln('-F <percent> percentage of f0 flutter');
  Writeln('    Default is 0');
  Writeln('-r <type> output 16 bit signed integers rather than ASCII');
  Writeln('   integers. cType := 1 gives high byte first, cType = 2 gives');
  Writeln('   low byte first.');
end;

const
  natural_samples: array[0..NUMBER_OF_SAMPLES-1] of integer=
  (
    -310,-400,530,356,224,89,23,-10,-58,-16,461,599,536,701,770,
    605,497,461,560,404,110,224,131,104,-97,155,278,-154,-1165,
    -598,737,125,-592,41,11,-247,-10,65,92,80,-304,71,167,-1,122,
    233,161,-43,278,479,485,407,266,650,134,80,236,68,260,269,179,
    53,140,275,293,296,104,257,152,311,182,263,245,125,314,140,44,
    203,230,-235,-286,23,107,92,-91,38,464,443,176,98,-784,-2449,
    -1891,-1045,-1600,-1462,-1384,-1261,-949,-730
  );

procedure Main;
var
  InFileName    ,
  OutFileName   ,
  SampeFileName : string;
  InFile        : TextFile;
  OutFile       : File of byte;
  value         : LongWord;
  FrameSamples  : TArray<single>;
  FrameSampleIndex ,
  FrameIndex    ,
  ParIndex      ,
  MsPerFrame    : Integer;
  Globals       : TKlattGlobal;
  Frame         : TKlattFrame;
  FrameParamPtr : ^Integer;
  high_byte     ,
  low_byte      : byte;
  raw_flag      : Boolean;
  raw_type      : byte;
  loop          : Integer;
  Sample        : Integer;

begin
  if(ParamCount=0) then
  begin
    usage;
    halt(1);
  end;

  InFileName       := '';
  OutFileName      := '';
  SampeFileName := '';

  SetLength(FrameSamples, MAX_SAM);

  Frame   := default (TKlattFrame);
  Globals := default (TKlattGlobal);

  Globals.quiet_flag      := FALSE;
  Globals.synthesis_model := ALL_PARALLEL;
  Globals.samrate         := 10000;
  Globals.glsource        := NATURAL;
  // globals.natural_samples := natural_samples;
  Globals.num_samples     := NUMBER_OF_SAMPLES;
  Globals.SAMPLE_FACTOR   := SAMPLE_FACTOR;
  MsPerFrame               := 10;
  Globals.nfcascade       := 0;
  Globals.outsl           := 0;
  Globals.f0_flutter      := 0;
  raw_flag                := FALSE;

  CommandLine.ProcessKeys( procedure(const key:char; const name,value:string )
    begin
      case Key of
        'i': InFileName := Value;
        'o': OutFileName := Value;
        'q': Globals.quiet_flag := TRUE;
        't': Globals.outsl := StrToInt(Value);
        'c': begin Globals.synthesis_model := CASCADE_PARALLEL; Globals.nfcascade := 5; end;
        's': Globals.samrate := StrToInt(Value);
        'f': MsPerFrame := StrToInt(Value);
        'v': Globals.glsource := StrToInt(Value);
        'V': SampeFileName := Value;
        'h': begin usage(); halt(1); end;
        'n': Globals.nfcascade := StrToInt(Value);
        'F': Globals.f0_flutter := StrToInt(Value);
        'r': begin raw_flag := TRUE; raw_type := StrToInt(Value); end;
      end;
    end
  );

  Globals.nspfr := Round((Globals.samrate * MsPerFrame) / 1000);

  if SampeFileName <> '' then
  begin
    AssignFile(InFile, SampeFileName);
    Reset(InFile);
    read(InFile, Globals.num_samples);
    read(InFile, Globals.SAMPLE_FACTOR);
    SetLength(Globals.natural_samples, length(natural_samples));
    for loop := 0 to Globals.num_samples - 1 do
      read(InFile, Globals.natural_samples[loop]);
    CloseFile(InFile);
  end;

  if InFileName = '' then
  begin
    Writeln('Error: No inputfile given');
    Halt(2);
  end;

  AssignFile(InFile, InFileName);
  Reset(InFile);

  if OutFileName = '' then
    Globals.quiet_flag := TRUE
  else
  begin
    AssignFile(OutFile, OutFileName);
    Rewrite(OutFile);
  end;

  FrameIndex    := 0;
  parwave_init(Globals);

  while not Eof(InFile) do
  begin
    FrameParamPtr := @Frame;
    for ParIndex := 1 to NPAR do
    begin
      read(InFile, value);
      FrameParamPtr^ := value;
      Inc(FrameParamPtr);
    end;

    ParWave(Globals, Frame, FrameSamples);

    if (Globals.quiet_flag = FALSE) then
      Writeln(format('Frame %d', [FrameIndex]));

    for FrameSampleIndex := 0 to Globals.nspfr-1 do
    begin
      Sample := Round(FrameSamples[FrameSampleIndex]);
      if raw_flag then
      begin
        Sample := Round((Sample / 2) + 32768) and $FFFF;
        low_byte  := Byte(Sample and $FF);
        high_byte := Byte(Sample shr 8);

        if (raw_type = 1) then
        begin
          Write(OutFile, high_byte);
          Write(OutFile, low_byte);
        end
        else
        begin
          Write(OutFile, low_byte);
          Write(OutFile, high_byte);
        end;
      end
      else
        Writeln(format('%d', [FrameSamples[FrameSampleIndex]]));
    end;
    Inc(FrameIndex);
  end;

  if InFileName = '' then
    CloseFile(InFile);

  if OutFileName = '' then
    CloseFile(OutFile);

  if (Globals.quiet_flag = FALSE) then
  begin
    Writeln;
    Writeln('Done');
    Writeln;
  end;

end;



begin
  try
    Main;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
