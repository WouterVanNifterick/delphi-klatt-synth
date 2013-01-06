unit Klatt.ParWave;

interface

uses System.SysUtils;

const
  CASCADE_PARALLEL = 1;     // Type of synthesis model
  ALL_PARALLEL     = 2;
  NPAR             = 40;    // Number of control parameters
  MAX_SAM          = 20000; // Maximum sample rate
  IMPULSIVE        = 1;     // Type of voicing source
  NATURAL          = 2;
  SAMPLED          = 3;

type
  Resonator_t = record
    a, b, c, p1, p2: Single;
  end;

  TResonator    = Resonator_t;
  resonator_ptr = ^TResonator;

  flag = Byte;

  { Structure for Klatt Globals }
type
  TKlattGlobal = record
    synthesis_model: flag;  // cascade-parallel or all-parallel 
    outsl: byte;            // Output waveform selector 
    samrate: Integer;       // Number of output samples per second 
    FLPhz: Integer;         // Frequeny of glottal downsample low-pass filter 
    BLPhz: Integer;         // Bandwidth of glottal downsample low-pass filter 
    nfcascade: Integer;     // Number of formants in cascade vocal tract 
    glsource: flag;         // Type of glottal source 
    f0_flutter: Integer;    // Percentage of f0 flutter 0-100 
    quiet_flag: boolean;    // set to TRUE for error messages 
    nspfr: Integer;         // number of samples per frame 
    nper: Integer;          // Counter for number of samples in a pitch period 
    current_sample: Integer;//
    T0: Integer;            // Fundamental period in output samples times 4 
    nopen: Integer;         // Number of samples in open phase of period 
    nmod: Integer;          // Position in period to begin noise amp. modul 
    nrand: Integer;         // Varible used by random number generator 
    pulse_shape_a: Single;  // Makes waveshape of glottal pulse when open 
    pulse_shape_b: Single;  // Makes waveshape of glottal pulse when open 
    minus_pi_t: Single;
    two_pi_t: Single;
    onemd: Single;
    decay: Single;
    amp_bypas: Single;                 // AB converted to linear gain 
    amp_voice: Single;                 // AVdb converted to linear gain 
    par_amp_voice: Single;             // AVpdb converted to linear gain 
    amp_aspir: Single;                 // AP converted to linear gain 
    amp_frica: Single;                 // AF converted to linear gain 
    amp_breth: Single;                 // ATURB converted to linear gain 
    amp_gain0: Single;                 // G0 converted to linear gain 
    num_samples: Integer;              // number of glottal samples 
    sample_factor: Single;             // multiplication factor for glottal samples 
    natural_samples: array of Integer; // pointer to an array of glottal samples 
    original_f0: Integer;              // original value of f0 not modified by flutter 
    rnpp: Resonator_t;                 // internal storage for resonators 
    r1p: Resonator_t;
    r2p: Resonator_t;
    r3p: Resonator_t;
    r4p: Resonator_t;
    r5p: Resonator_t;
    r6p: Resonator_t;
    r1c: Resonator_t;
    r2c: Resonator_t;
    r3c: Resonator_t;
    r4c: Resonator_t;
    r5c: Resonator_t;
    r6c: Resonator_t;
    r7c: Resonator_t;
    r8c: Resonator_t;
    rnpc: Resonator_t;
    rnz: Resonator_t;
    rgl: Resonator_t;
    rlp: Resonator_t;
    rout: Resonator_t;
  end;

  Tklatt_global    = TKlattGlobal;
  klatt_global_ptr = ^TKlattGlobal;

  { Structure for Klatt Parameters }

type
  TKlattFrame = record
    F0hz10: Integer; // Voicing fund freq in Hz *)
    AVdb: Integer;   // Amp of voicing in dB,            0 to   70 
    F1hz: Integer;   // First formant freq in Hz,        200 to 1300 
    B1hz: Integer;   // First formant bw in Hz,          40 to 1000 
    F2hz: Integer;   // Second formant freq in Hz,       550 to 3000 
    B2hz: Integer;   // Second formant bw in Hz,         40 to 1000 
    F3hz: Integer;   // Third formant freq in Hz,        1200 to 4999 
    B3hz: Integer;   // Third formant bw in Hz,          40 to 1000 
    F4hz: Integer;   // Fourth formant freq in Hz,       1200 to 4999 
    B4hz: Integer;   // Fourth formant bw in Hz,         40 to 1000 
    F5hz: Integer;   // Fifth formant freq in Hz,        1200 to 4999 
    B5hz: Integer;   // Fifth formant bw in Hz,          40 to 1000 
    F6hz: Integer;   // Sixth formant freq in Hz,        1200 to 4999 
    B6hz: Integer;   // Sixth formant bw in Hz,          40 to 2000 
    FNZhz: Integer;  // Nasal zero freq in Hz,           248 to  528 
    BNZhz: Integer;  // Nasal zero bw in Hz,             40 to 1000 
    FNPhz: Integer;  // Nasal pole freq in Hz,           248 to  528 
    BNPhz: Integer;  // Nasal pole bw in Hz,             40 to 1000 
    ASP: Integer;    // Amp of aspiration in dB,         0 to   70 
    Kopen: Integer;  // # of samples in open period,     10 to   65 
    Aturb: Integer;  // Breathiness in voicing,          0 to   80 
    TLTdb: Integer;  // Voicing spectral tilt in dB,     0 to   24 
    AF: Integer;     // Amp of frication in dB,          0 to   80 
    Kskew: Integer;  // Skewness of alternate periods,   0 to   40 in sample#/2 
    A1: Integer;     // Amp of par 1st formant in dB,    0 to   80 
    B1phz: Integer;  // Par. 1st formant bw in Hz,       40 to 1000 
    A2: Integer;     // Amp of F2 frication in dB,       0 to   80 
    B2phz: Integer;  // Par. 2nd formant bw in Hz,       40 to 1000 
    A3: Integer;     // Amp of F3 frication in dB,       0 to   80 
    B3phz: Integer;  // Par. 3rd formant bw in Hz,       40 to 1000 
    A4: Integer;     // Amp of F4 frication in dB,       0 to   80 
    B4phz: Integer;  // Par. 4th formant bw in Hz,       40 to 1000 
    A5: Integer;     // Amp of F5 frication in dB,       0 to   80 
    B5phz: Integer;  // Par. 5th formant bw in Hz,       40 to 1000 
    A6: Integer;     // Amp of F6 (same as r6pa),        0 to   80 
    B6phz: Integer;  // Par. 6th formant bw in Hz,       40 to 2000 
    ANP: Integer;    // Amp of par nasal pole in dB,     0 to   80 
    AB: Integer;     // Amp of bypass fric. in dB,       0 to   80 
    AVpdb: Integer;  // Amp of voicing,  par in dB,      0 to   70 
    Gain0: Integer;  // Overall gain, 60 dB is unity,    0 to   60 
  end;

  Tklatt_frame_t = TKlattFrame;
{$EXTERNALSYM Tklatt_frame_t}
  klatt_frame_ptr = ^TKlattFrame;
{$EXTERNALSYM klatt_frame_ptr}
  { function prototypes that need to be exported }
procedure ParWave(var globals: TKlattGlobal; var frame: TKlattFrame; var output: TArray<Single>);
procedure parwave_init(var globals: TKlattGlobal);

implementation

function DBtoLIN(db: Integer): Single;
const
  AmpTable: array [0 .. 87] of Single = (
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
	6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 13.0, 14.0, 16.0, 18.0, 20.0, 22.0, 
	25.0, 28.0, 32.0, 35.0, 40.0, 45.0, 51.0, 57.0, 64.0, 71.0, 80.0, 
	90.0, 101.0, 114.0, 128.0, 142.0, 159.0, 179.0, 202.0, 227.0, 256.0, 
	284.0, 318.0, 359.0, 405.0, 455.0, 512.0, 568.0, 638.0, 719.0, 811.0, 
	911.0, 1024.0, 1137.0, 1276.0, 1438.0, 1622.0, 1823.0, 2048.0, 2273.0, 
	2552.0, 2875.0, 3244.0, 3645.0, 4096.0, 4547.0, 5104.0, 5751.0, 6488.0, 
	7291.0, 8192.0, 9093.0, 10207.0, 11502.0, 12976.0, 14582.0, 16384.0, 
	18350.0, 20644.0, 23429.0, 26214.0, 29491.0, 32767
  );
	
begin
  if ((db < 0) or (db > 87)) then
    exit(0);

  Result := AmpTable[db] * 0.001;
end;

{
  Random number generator (return a number between -8191 and +8191)
  Noise spectrum is tilted down by soft low-pass filter having a pole near
  the origin in the z-plane, i.e. output = input + (0.75 * lastoutput)
}
var
  nlast: Single;

function gen_noise(noise: Single; var globals: TKlattGlobal): Single;
var
  temp: Integer;
begin
  temp          := random(2 * 8191) - 8191;
  globals.nrand := temp;
  noise         := globals.nrand + (0.75 * nlast);
  nlast         := noise;
  exit(noise);
end;

function resonator(var r: Resonator_t; input: Single): Single;
var
  x: Single;
begin
  { This is a generic resonator function. Internal memory for the resonator
    is stored in the globals structure. }
  x      := (r.a * input + r.b * r.p1 + r.c * r.p2);
  r.p2   := r.p1;
  r.p1   := x;
  Result := x;
end;

function antiresonator(var r: Resonator_t; input: Single): Single;
var
  x: Single;
begin
  x      := r.a * input + r.b * r.p1 + r.c * r.p2;
  r.p2   := r.p1;
  r.p1   := input;
  Result := x;
end;

var
  time_count: Integer;

procedure Flutter(var globals: TKlattGlobal; var frame: TKlattFrame);
var
  delta_f0, fla, flb, flc, fld, fle: Double;
begin
  { This function adds F0 flutter, as specified in:

    "Analysis, synthesis and perception of voice quality variations among
    female and male talkers" D.H. Klatt and L.C. Klatt JASA 87(2) February 1990.

    Flutter is added by applying a quasi-random element constructed from three
    slowly varying sine waves. }

  fla          := globals.f0_flutter / 50;
  flb          := globals.original_f0 / 100;
  flc          := sin(2 * PI * 12.7 * time_count);
  fld          := sin(2 * PI * 7.1 * time_count);
  fle          := sin(2 * PI * 4.7 * time_count);
  delta_f0     := fla * flb * (flc + fld + fle) * 10;
  frame.F0hz10 := frame.F0hz10 + Round(delta_f0);
  Inc(time_count);
end;


//  Convert formant freqencies and bandwidth into resonator difference  equation constants.
procedure setabc(f: Integer; { Frequency of resonator in Hz }
  bw: Integer;               { Bandwidth of resonator in Hz }
  var rp: Resonator_t; var globals: TKlattGlobal);
var
  r  : Single;
  arg: Double;
begin
  // Let r  =  exp(-pi bw t)
  arg := globals.minus_pi_t * bw;
  r   := exp(arg);

  // Let c  =  -r**2
  rp.c := -(r * r);

  // Let b = r * 2*cos(2 pi f t)
  arg  := globals.two_pi_t * f;
  rp.b := r * cos(arg) * 2.0;

  // Let a = 1.0 - b - c
  rp.a := 1.0 - rp.b - rp.c;
end;


//  Convert formant freqencies and bandwidth into anti-resonator difference equation constants.
procedure setzeroabc(f: Integer; { Frequency of resonator in Hz }
  bw: Integer;                   { Bandwidth of resonator in Hz }
  var rp: Resonator_t; var globals: TKlattGlobal);
var
  r  : Single;
  arg: Double;

begin
  f := -f;
  if (f >= 0) then
    f := -1;

  // First compute ordinary resonator coefficients
  // Let r  =  exp(-pi bw t)
  arg := globals.minus_pi_t * bw;
  r   := exp(arg);

  // Let c  =  -r**2
  rp.c := -(r * r);

  // Let b = r * 2*cos(2 pi f t)
  arg  := globals.two_pi_t * f;
  rp.b := r * cos(arg) * 2.;

  // Let a = 1.0 - b - c
  rp.a := 1.0 - rp.b - rp.c;

  // Now convert to antiresonator coefficients (a'=1/a, b'=b/a, c'=c/a)
  rp.a := 1.0 / rp.a;
  rp.c := rp.c * -rp.a;
  rp.b := rp.b * -rp.a;
end;

//  Initialises all parameters used in parwave, sets resonator internal memory to zero.
procedure parwave_init(var globals: TKlattGlobal);
begin
  globals.FLPhz      := Round((950 * globals.samrate) / 10000);
  globals.BLPhz      := Round((630 * globals.samrate) / 10000);
  globals.minus_pi_t := -PI / globals.samrate;
  globals.two_pi_t   := -2.0 * globals.minus_pi_t;
  setabc(globals.FLPhz, globals.BLPhz, globals.rlp, globals);
  globals.nper  := 0;
  globals.T0    := 0;
  globals.nopen := 0;
  globals.nmod  := 0;

  globals.rnpp.p1 := 0;
  globals.r1p.p1  := 0;
  globals.r2p.p1  := 0;
  globals.r3p.p1  := 0;
  globals.r4p.p1  := 0;
  globals.r5p.p1  := 0;
  globals.r6p.p1  := 0;
  globals.r1c.p1  := 0;
  globals.r2c.p1  := 0;
  globals.r3c.p1  := 0;
  globals.r4c.p1  := 0;
  globals.r5c.p1  := 0;
  globals.r6c.p1  := 0;
  globals.r7c.p1  := 0;
  globals.r8c.p1  := 0;
  globals.rnpc.p1 := 0;
  globals.rnz.p1  := 0;
  globals.rgl.p1  := 0;
  globals.rlp.p1  := 0;
  globals.rout.p1 := 0;

  globals.rnpp.p2 := 0;
  globals.r1p.p2  := 0;
  globals.r2p.p2  := 0;
  globals.r3p.p2  := 0;
  globals.r4p.p2  := 0;
  globals.r5p.p2  := 0;
  globals.r6p.p2  := 0;
  globals.r1c.p2  := 0;
  globals.r2c.p2  := 0;
  globals.r3c.p2  := 0;
  globals.r4c.p2  := 0;
  globals.r5c.p2  := 0;
  globals.r6c.p2  := 0;
  globals.r7c.p2  := 0;
  globals.r8c.p2  := 0;
  globals.rnpc.p2 := 0;
  globals.rnz.p2  := 0;
  globals.rgl.p2  := 0;
  globals.rlp.p2  := 0;
  globals.rout.p2 := 0;
end;

//  Use parameters from the input frame to set up resonator coefficients.
procedure frame_init(var globals: TKlattGlobal; var frame: TKlattFrame);
var
  amp_parF1,
  amp_parFNP,
  amp_parF2,
  amp_parF3,
  amp_parF4,
  amp_parF5,
  amp_parF6: Single;
begin
  globals.original_f0 := Round(frame.F0hz10 / 10);

  frame.AVdb := frame.AVdb - 7;
  if (frame.AVdb < 0) then
    frame.AVdb := 0;

  globals.amp_aspir     := DBtoLIN(frame.ASP) * 0.05;
  globals.amp_frica     := DBtoLIN(frame.AF) * 0.25;
  globals.par_amp_voice := DBtoLIN(frame.AVpdb);
  amp_parF1             := DBtoLIN(frame.A1) * 0.4;
  amp_parF2             := DBtoLIN(frame.A2) * 0.15;
  amp_parF3             := DBtoLIN(frame.A3) * 0.06;
  amp_parF4             := DBtoLIN(frame.A4) * 0.04;
  amp_parF5             := DBtoLIN(frame.A5) * 0.022;
  amp_parF6             := DBtoLIN(frame.A6) * 0.03;
  amp_parFNP            := DBtoLIN(frame.ANP) * 0.6;
  globals.amp_bypas     := DBtoLIN(frame.AB) * 0.05;
  frame.Gain0           := frame.Gain0 - 3;
  if (frame.Gain0 <= 0) then
    frame.Gain0 := 57;

  globals.amp_gain0 := DBtoLIN(frame.Gain0);

  // Set coefficients of variable cascade resonators
  if (globals.nfcascade >= 8) then
    setabc(7500, 600, globals.r8c, globals);
  if (globals.nfcascade >= 7) then
    setabc(6500, 500, globals.r7c, globals);
  if (globals.nfcascade >= 6) then
    setabc(frame.F6hz, frame.B6hz, globals.r6c, globals);
  if (globals.nfcascade >= 5) then
    setabc(frame.F5hz, frame.B5hz, globals.r5c, globals);

  setabc(frame.F4hz, frame.B4hz, globals.r4c, globals);
  setabc(frame.F3hz, frame.B3hz, globals.r3c, globals);
  setabc(frame.F2hz, frame.B2hz, globals.r2c, globals);
  setabc(frame.F1hz, frame.B1hz, globals.r1c, globals);

  // Set coeficients of nasal resonator and zero antiresonator
  setabc(frame.FNPhz, frame.BNPhz, globals.rnpc, globals);
  setzeroabc(frame.FNZhz, frame.BNZhz, globals.rnz, globals);

  // Set coefficients of parallel resonators, and amplitude of outputs
  setabc(frame.F1hz, frame.B1phz, globals.r1p, globals);
  globals.r1p.a := globals.r1p.a * amp_parF1;
  setabc(frame.FNPhz, frame.BNPhz, globals.rnpp, globals);
  globals.rnpp.a := globals.rnpp.a * amp_parFNP;
  setabc(frame.F2hz, frame.B2phz, globals.r2p, globals);
  globals.r2p.a := globals.r2p.a * amp_parF2;
  setabc(frame.F3hz, frame.B3phz, globals.r3p, globals);
  globals.r3p.a := globals.r3p.a * amp_parF3;
  setabc(frame.F4hz, frame.B4phz, globals.r4p, globals);
  globals.r4p.a := globals.r4p.a * amp_parF4;
  setabc(frame.F5hz, frame.B5phz, globals.r5p, globals);
  globals.r5p.a := globals.r5p.a * amp_parF5;
  setabc(frame.F6hz, frame.B6phz, globals.r6p, globals);
  globals.r6p.a := globals.r6p.a * amp_parF6;

  // output low-pass filter
  setabc(0, Round(globals.samrate / 2), globals.rout, globals);
end;

{
  Generate a low pass filtered train of impulses as an approximation of
  a natural excitation waveform. Low-pass filter the differentiated impulse
  with a critically-damped second-order filter, time constant proportional
  to Kopen.
}
const
  doublet: array [0 .. 2] of Single = (0.0, 13000000.0, -13000000.0);

var
  vwave: Single;

function impulsive_source(var globals: TKlattGlobal): Single;
begin

  if (globals.nper < 3) then
    vwave := doublet[globals.nper]
  else
    vwave := 0.0;

  exit(resonator(globals.rgl, vwave));
end;

{
  Vwave is the differentiated glottal flow waveform, there is a weak
  spectral zero around 800 Hz, magic constants a,b reset pitch synchronously.
}
var
  vwave2: Single;

function natural_source(var globals: TKlattGlobal): Single;
var
  lgtemp: Single;
begin
  if (globals.nper < globals.nopen) then
  begin
    globals.pulse_shape_a := globals.pulse_shape_a - globals.pulse_shape_b;
    vwave2                := vwave2 + globals.pulse_shape_a;
    lgtemp                := vwave2 * 0.028;
    exit(lgtemp);
  end
  else
  begin
    vwave2 := 0.0;
    exit(0.0);
  end;
end;

(*
  function PITCH_SYNC_PAR_RESET

  Reset selected parameters pitch-synchronously.


  Constant B0 controls shape of glottal pulse as a function
  of desired duration of open phase N0
  (Note that N0 is specified in terms of 40,000 samples/sec of speech)

  Assume voicing waveform V(t) has form: k1 t**2 - k2 t**3

  If the radiation characterivative, a temporal derivative
  is folded in, and we go from continuous time to discrete
  integers n:  dV/dt = vwave[n]
  = sum over i=1,2,...,n of { a - (i * b) }
  = a n  -  b/2 n**2

  where the  constants a and b control the detailed shape
  and amplitude of the voicing waveform over the open
  potion of the voicing cycle "nopen".

  Let integral of dV/dt have no net dc flow --> a = (b * nopen) / 3

  Let maximum of dUg(n)/dn be constant --> b = gain / (nopen * nopen)
  meaning as nopen gets bigger, V has bigger peak proportional to n

  Thus, to generate the table below for 40 <= nopen <= 263:

  B0[nopen - 40] = 1920000 / (nopen * nopen)
*)

const
  B0: array [0 .. 223] of uint16 = (1200, 1142, 1088, 1038, 991, 948, 907, 869, 833, 799, 768, 738, 710, 683, 658, 634, 612, 590, 570, 551, 533, 515, 499, 483, 468, 454, 440, 427, 415, 403, 391, 380, 370, 360, 350, 341, 332, 323, 315, 307, 300, 292, 285,
    278, 272, 265, 259, 253, 247, 242, 237, 231, 226, 221, 217, 212, 208, 204, 199, 195, 192, 188, 184, 180, 177, 174, 170, 167, 164, 161, 158, 155, 153, 150, 147, 145, 142, 140, 137, 135, 133, 131, 128, 126, 124, 122, 120, 119, 117, 115, 113, 111, 110,
    108, 106, 105, 103, 102, 100, 99, 97, 96, 95, 93, 92, 91, 90, 88, 87, 86, 85, 84, 83, 82, 80, 79, 78, 77, 76, 75, 75, 74, 73, 72, 71, 70, 69, 68, 68, 67, 66, 65, 64, 64, 63, 62, 61, 61, 60, 59, 59, 58, 57, 57, 56, 56, 55, 55, 54, 54, 53, 53, 52, 52,
    51, 51, 50, 50, 49, 49, 48, 48, 47, 47, 46, 46, 45, 45, 44, 44, 43, 43, 42, 42, 41, 41, 41, 41, 40, 40, 39, 39, 38, 38, 38, 38, 37, 37, 36, 36, 36, 36, 35, 35, 35, 35, 34, 34, 33, 33, 33, 33, 32, 32, 32, 32, 31, 31, 31, 31, 30, 30, 30, 30, 29, 29, 29,
    29, 28, 28, 28, 28, 27, 27);

var
  skew: Integer;

procedure pitch_synch_par_reset(var globals: TKlattGlobal; var frame: TKlattFrame);
var
  temp : Integer;
  temp1: Single;
begin

  if (frame.F0hz10 > 0) then
  begin
    // T0 is 4* the number of samples in one pitch period
    globals.T0 := Round((40 * globals.samrate) / frame.F0hz10);

    globals.amp_voice := DBtoLIN(frame.AVdb);

    // Duration of period before amplitude modulation
    globals.nmod := globals.T0;
    if (frame.AVdb > 0) then
      globals.nmod := globals.nmod shr 1;

    // Breathiness of voicing waveform
    globals.amp_breth := DBtoLIN(frame.Aturb) * 0.1;

    // Set open phase of glottal period where  40 <= open phase <= 263
    globals.nopen := 4 * frame.Kopen;

    if ((globals.glsource = IMPULSIVE) and (globals.nopen > 263)) then
      globals.nopen := 263;

    if (globals.nopen >= (globals.T0 - 1)) then
    begin
      globals.nopen := globals.T0 - 2;
      if (globals.quiet_flag = FALSE) then
        writeln('Warning: glottal open period cannot exceed T0, truncated');
    end;

    if (globals.nopen < 40) then
    begin
      // F0 max = 1000 Hz
      globals.nopen := 40;
      if (globals.quiet_flag = FALSE) then
      begin
        writeln('Warning: minimum glottal open period is 10 samples.');
        writeln(format('truncated, nopen = %d', [globals.nopen]));
      end;
    end;

    // Reset a & b, which determine shape of "natural" glottal waveform
    globals.pulse_shape_b := B0[globals.nopen - 40];
    globals.pulse_shape_a := (globals.pulse_shape_b * globals.nopen) * 0.333;

    // Reset width of "impulsive" glottal pulse
    temp := Round(globals.samrate / globals.nopen);

    setabc(0, temp, globals.rgl, globals);

    // Make gain at F1 about constant
    temp1         := globals.nopen * 0.00833;
    globals.rgl.a := globals.rgl.a * temp1 * temp1;

    // Truncate skewness so as not to exceed duration of closed phase of glottal period.
    temp := globals.T0 - globals.nopen;
    if (frame.Kskew > temp) then
    begin
      if (globals.quiet_flag = FALSE) then
      begin
        writeln(format('Kskew duration=%d > glottal closed period=%d, truncate\n', [frame.Kskew, globals.T0 - globals.nopen]));
      end;
      frame.Kskew := temp;
    end;
    if (skew >= 0) then
      skew := frame.Kskew
    else
      skew := -frame.Kskew;

    // Add skewness to closed portion of voicing period
    globals.T0 := globals.T0 + skew;
    skew       := -skew;
  end
  else
  begin
    globals.T0            := 4; // Default for f0 undefined
    globals.amp_voice     := 0.0;
    globals.nmod          := globals.T0;
    globals.amp_breth     := 0.0;
    globals.pulse_shape_a := 0.0;
    globals.pulse_shape_b := 0.0;
  end;

  //Reset these pars pitch synchronously or at update rate if f0=0
  if ((globals.T0 <> 4) or (globals.current_sample = 0)) then
  begin
    // Set one-pole low-pass filter that tilts glottal source
    globals.decay := (0.033 * frame.TLTdb);

    if (globals.decay > 0.0) then
      globals.onemd := 1.0 - globals.decay
    else
      globals.onemd := 1.0;
  end;
end;

var
  noise, voice, vlast, glotlast, sourc: Single;

  /// <summary>
  /// Converts synthesis parameters to a waveform.
  /// </summary>
procedure ParWave(var globals: TKlattGlobal; var frame: TKlattFrame; var output: TArray<Single>);
var
  i                         : Integer;
  temp, outbypas            : Single;
  n4                        : Integer;
  frics, glotout, aspiration: Single;
  casc_next_in, par_glotout : Single;
begin
  // get parameters for next frame of speech
  frame_init(globals, frame); // get parameters for next frame of speech
  Flutter(globals, frame);    // add f0 flutter

  // MAIN LOOP, for each output sample of current frame:
  for i := 0 to globals.nspfr - 1 do
  begin
    Inc(globals.current_sample);

    // Get low-passed random number for aspiration and frication noise
    noise := gen_noise(noise, globals);

    // Amplitude modulate noise (reduce noise amplitude during
    // second half of glottal period) if voicing simultaneously present.
    if (globals.nper > globals.nmod) then
      noise := noise * 0.5;

    // Compute frication noise
    frics := globals.amp_frica * noise;


    // Compute voicing waveform. Run glottal source simulation at 4
    // times normal sample rate to minimize quantization noise in
    // period of female voice.
    for n4 := 0 to 3 do
    begin
      case (globals.glsource) of
        IMPULSIVE : voice := impulsive_source(globals);
        NATURAL   : voice := natural_source(globals);
      //SAMPLED   : voice := sampled_source(globals);
      end;

      // Reset period when counter 'nper' reaches T0
      if (globals.nper >= globals.T0) then
      begin
        globals.nper := 0;
        pitch_synch_par_reset(globals, frame);
      end;

      //  Low-pass filter voicing waveform before downsampling from 4*samrate
      //  to samrate samples/sec.  Resonator f=.09*samrate, bw=.06*samrate
      voice := resonator(globals.rlp, voice);

      // Increment counter that keeps track of 4*samrate samples per sec
      Inc(globals.nper);
    end;

    //  Tilt spectrum of voicing source down by soft low-pass filtering,
    // amount of tilt determined by TLTdb
    voice := (voice * globals.onemd) + (vlast * globals.decay);
    vlast := voice;

    {
      Add breathiness during glottal open phase. Amount of breathiness
      determined by parameter Aturb Use nrand rather than noise because
      noise is low-passed.
    }
    if (globals.nper < globals.nopen) then
      voice := voice + (globals.amp_breth * globals.nrand);

    // Set amplitude of voicing
    glotout     := globals.amp_voice * voice;
    par_glotout := globals.par_amp_voice * voice;

    // Compute aspiration amplitude and add to voicing source
    aspiration := globals.amp_aspir * noise;
    glotout    := glotout + aspiration;

    par_glotout := par_glotout + aspiration;

    //  Cascade vocal tract, excited by laryngeal sources.
    //  Nasal antiresonator, then formants FNP, F5, F4, F3, F2, F1
    if (globals.synthesis_model <> ALL_PARALLEL) then
    begin
      casc_next_in := antiresonator(globals.rnz, glotout);
      casc_next_in := resonator(globals.rnpc, casc_next_in);
      // Do not use unless sample rate >= 16000
      if (globals.nfcascade >= 8) then casc_next_in := resonator(globals.r8c, casc_next_in);
      // Do not use unless sample rate >= 16000
      if (globals.nfcascade >= 7) then casc_next_in := resonator(globals.r7c, casc_next_in);
      (* Do not use unless long vocal tract or sample rate increased *)
      if (globals.nfcascade >= 6) then casc_next_in := resonator(globals.r6c, casc_next_in);
      if (globals.nfcascade >= 5) then casc_next_in := resonator(globals.r5c, casc_next_in);
      if (globals.nfcascade >= 4) then casc_next_in := resonator(globals.r4c, casc_next_in);
      if (globals.nfcascade >= 3) then casc_next_in := resonator(globals.r3c, casc_next_in);
      if (globals.nfcascade >= 2) then casc_next_in := resonator(globals.r2c, casc_next_in);
      if (globals.nfcascade >= 1) then output[i]    := resonator(globals.r1c, casc_next_in);
    end
    else
    begin
      // we are not using the cascade tract, set out to zero
      output[i] := 0.0;
    end;

    // Excite parallel F1 and FNP by voicing waveform
    sourc := par_glotout; // Source is voicing plus aspiration

    {
      Standard parallel vocal tract Formants F6,F5,F4,F3,F2,
      outputs added with alternating sign. Sound sourc for other
      parallel resonators is frication plus first difference of
      voicing waveform.
    }
    output[i] := output[i] + resonator(globals.r1p, sourc);
    output[i] := output[i] + resonator(globals.rnpp, sourc);

    sourc    := frics + par_glotout - glotlast;
    glotlast := par_glotout;

    output[i] := resonator(globals.r6p, sourc) - output[i];
    output[i] := resonator(globals.r5p, sourc) - output[i];
    output[i] := resonator(globals.r4p, sourc) - output[i];
    output[i] := resonator(globals.r3p, sourc) - output[i];
    output[i] := resonator(globals.r2p, sourc) - output[i];

    outbypas  := globals.amp_bypas * sourc;
    output[i] := outbypas - output[i];

    if (globals.outsl <> 0) then
    begin
      case (globals.outsl) of
        1: output[i] := voice;
        2: output[i] := aspiration;
        3: output[i] := frics;
        4: output[i] := glotout;
        5: output[i] := par_glotout;
        6: output[i] := outbypas;
        7: output[i] := sourc;
      end;

      output[i] := resonator(globals.rout, output[i]);

      temp := output[i] * globals.amp_gain0;

      (* Convert back to integer *)
      if (temp < -32768.0) then
        temp := -32768.0;

      if (temp > 32767.0) then
        temp := 32767.0;

      output[i] := temp;
    end;
  end;

end;

end.
