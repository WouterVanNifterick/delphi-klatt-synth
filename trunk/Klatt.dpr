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
    procedure Init;
  end;

procedure TAppSettings.Init;
begin
  self := default(TAppSettings);
  InFileName        := '';
  OutFileName       := '';
  SampeFileName     := '';
  MsPerFrame        := 10;
  DoOutputRawSample := FALSE;
end;

procedure Main;
var
  OutFile       : File of byte;
  KlattSynth    : TKlattSynth;
  FrameSamples  : TArray<single>;
  FrameSampleIndex : Integer;
  Sample        : uint16;
  AppSettings   : TAppSettings;
  FrameIndex    : Integer;
begin
  if(ParamCount=0) then
  begin
    usage;
    halt(1);
  end;

  AppSettings.Init;

  KlattSynth := TKlattSynth.Create;

  SetLength(FrameSamples, cMaxSampleRateHz);

  CommandLine.ProcessKeys( procedure(const key:char; const name,value:string )
    begin
      case Key of
        'i': AppSettings.InFileName := Value;
        'o': AppSettings.OutFileName := Value;
        'q': KlattSynth.Quiet := TRUE;
        't': KlattSynth.OutputChannel := TOutputChannel(StrToInt(Value));
        'c': begin KlattSynth.SynthesisModel := CascadeParallel; KlattSynth.nfcascade := 5; end;
        's': KlattSynth.SampleRateHz := StrToInt(Value);
        'f': AppSettings.MsPerFrame := StrToInt(Value);
//      'v': Globals.glsource :=  StrToInt(Value);
        'V': AppSettings.SampeFileName := Value;
        'h': begin usage(); halt(1); end;
        'n': KlattSynth.nfcascade := StrToInt(Value);
        'F': KlattSynth.f0_flutter := StrToInt(Value);
        'r': begin AppSettings.DoOutputRawSample := TRUE; AppSettings.OutputByteOrder := StrToInt(Value); end;
      end;
    end
  );
  KlattSynth.SamplesPerFrame := Round((KlattSynth.SampleRateHz * AppSettings.MsPerFrame) / 2000);

  {
  if SampleFileName <> '' then
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

  if AppSettings.OutFileName = '' then
    KlattSynth.Quiet := True
  else
  begin
    AssignFile(OutFile, AppSettings.OutFileName);
    Rewrite(OutFile);
  end;

  KlattSynth.InitParWave;
  WriteLn('Reading ',AppSettings.InFileName,' ...');
  KlattSynth.LoadFromFile(AppSettings.InFileName);

  WriteLn(length(KlattSynth.Frames),' frames -> Rendering to ',length(KlattSynth.Frames)*KlattSynth.SamplesPerFrame, ' samples ...');
  WriteLn('Saving ', AppSettings.OutFileName,' ...');
  for FrameIndex := 0 to High(KlattSynth.Frames) do
  begin
    KlattSynth.RenderParWave(KlattSynth.Frames[FrameIndex], FrameSamples);

    for FrameSampleIndex := 0 to KlattSynth.SamplesPerFrame-1 do
    begin
      Sample := Round(FrameSamples[FrameSampleIndex]);
      if AppSettings.DoOutputRawSample then
      begin
        Sample := Round((Sample / 256) + 32768) and $FFFF;
        Write(OutFile, Sample);
      end
      else
        Writeln(format('%d', [round(FrameSamples[FrameSampleIndex])]));
    end;
  end;
  if AppSettings.OutFileName <> '' then CloseFile(OutFile);
  if (not KlattSynth.Quiet) then  Writeln('Done');
  WriteLn('Done.');
end;

begin
  try
    Main;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
