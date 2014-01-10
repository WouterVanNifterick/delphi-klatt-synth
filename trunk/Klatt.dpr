program Klatt;

{
  Description : Klatt synthesizer
  Author      : Wouter van Nifterick
}

{$APPTYPE CONSOLE}

{$R *.res}

uses
  SysUtils,
  WvN.Util.CmdLine,
  Klatt.ParWave in 'Klatt.ParWave.pas';

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

type
  TAppSettings=record
    InFileName    ,
    OutFileName   ,
    SampeFileName : string;
    MsPerFrame    : Integer;
    DoOutputRawSample : Boolean;
    OutputByteOrder   : byte;
  end;

procedure InitAppSettings(var AppSettings: TAppSettings);
begin
  AppSettings := default(TAppSettings);
  AppSettings.InFileName := '';
  AppSettings.OutFileName := '';
  AppSettings.SampeFileName := '';
  AppSettings.MsPerFrame := 10;
  AppSettings.DoOutputRawSample := FALSE;
end;

procedure Main;
var
  InFile        : TextFile;
  OutFile       : File of byte;
  Globals       : TKlattGlobal;
  Frame         : TKlattFrame;
  FrameParamPtr : ^Integer;
  high_byte     ,
  low_byte      : byte;
  value         : LongWord;
  FrameSamples  : TArray<single>;
  FrameSampleIndex ,
  ParIndex      : Integer;
  Sample        : Integer;
  AppSettings:TAppSettings;
begin
  if(ParamCount=0) then
  begin
    usage;
    halt(1);
  end;

  InitAppSettings(AppSettings);

  SetLength(FrameSamples, cMaxSampleRateHz);

  Frame := default (TKlattFrame);

  GlobalsInit(Globals);


  CommandLine.ProcessKeys( procedure(const key:char; const name,value:string )
    begin
      case Key of
        'i': AppSettings.InFileName := Value;
        'o': AppSettings.OutFileName := Value;
        'q': Globals.quiet := TRUE;
        't': Globals.outsl := TOutputChannel(StrToInt(Value));
        'c': begin Globals.synthesis_model := CASCADE_PARALLEL; Globals.nfcascade := 5; end;
        's': Globals.samrate := StrToInt(Value);
        'f': AppSettings.MsPerFrame := StrToInt(Value);
//      'v': Globals.glsource :=  StrToInt(Value);
        'V': AppSettings.SampeFileName := Value;
        'h': begin usage(); halt(1); end;
        'n': Globals.nfcascade := StrToInt(Value);
        'F': Globals.f0_flutter := StrToInt(Value);
        'r': begin AppSettings.DoOutputRawSample := TRUE; AppSettings.OutputByteOrder := StrToInt(Value); end;
      end;
    end
  );
  Globals.SamplesPerFrame := Round((Globals.samrate * AppSettings.MsPerFrame) / 1000);

  {
  if SampeFileName <> '' then
  begin
    AssignFile(InFile, SampeFileName);
    Reset(InFile);
    read(InFile, Globals.num_samples);
    read(InFile, Globals.SAMPLE_FACTOR);
    SetLength(Globals.natural_samples, length(natural_samples));
    for I := 0 to Globals.num_samples - 1 do
      read(InFile, Globals.natural_samples[I]);
    CloseFile(InFile);
  end;
  }

  if AppSettings.InFileName = '' then
  begin
    Writeln('Error: No inputfile given');
    Halt(2);
  end;

  AssignFile(InFile, AppSettings.InFileName);
  Reset(InFile);

  if AppSettings.OutFileName = '' then
    Globals.quiet := TRUE
  else
  begin
    AssignFile(OutFile, AppSettings.OutFileName);
    Rewrite(OutFile);
  end;

  InitParWave(Globals);

  while not Eof(InFile) do
  begin
    FrameParamPtr := @Frame;
    for ParIndex := 1 to cNumberOfParameters do
    begin
      read(InFile, value);
      FrameParamPtr^ := value;
      Inc(FrameParamPtr);
    end;

    ParWave(Globals, Frame, FrameSamples);

    for FrameSampleIndex := 0 to Globals.SamplesPerFrame-1 do
    begin
      Sample := Round(FrameSamples[FrameSampleIndex]);
      if AppSettings.DoOutputRawSample then
      begin
        Sample := Round((Sample / 2) + 32768) and $FFFF;
        low_byte  := Byte(Sample and $FF);
        high_byte := Byte(Sample shr 8);

        if (AppSettings.OutputByteOrder = 1) then
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
  end;

  if AppSettings.InFileName = '' then CloseFile(InFile);
  if AppSettings.OutFileName = '' then CloseFile(OutFile);
  if (not Globals.quiet) then  Writeln('Done');
end;

begin
  try
    Main;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
