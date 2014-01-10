unit Klatt.ParWave;

{
  Description : Klatt synthesizer
  Author      : Wouter van Nifterick
}

interface

uses System.SysUtils, Math, System.Generics.Collections;


const
  /// <summary>Number of control parameters</summary>
  cNumberOfParameters = 40; //
  cNumberOfSamples    = 100;
  cMaxSampleRateHz    = 20000; // Maximum sample rate
  cSampleFactor       = 0.00001;

  natural_samples: array[0..cNumberOfSamples-1] of integer=
  (
    -310,-400,530,356,224,89,23,-10,-58,-16,461,599,536,701,770,
    605,497,461,560,404,110,224,131,104,-97,155,278,-154,-1165,
    -598,737,125,-592,41,11,-247,-10,65,92,80,-304,71,167,-1,122,
    233,161,-43,278,479,485,407,266,650,134,80,236,68,260,269,179,
    53,140,275,293,296,104,257,152,311,182,263,245,125,314,140,44,
    203,230,-235,-286,23,107,92,-91,38,464,443,176,98,-784,-2449,
    -1891,-1045,-1600,-1462,-1384,-1261,-949,-730
  );

type
  TVoicingSource = (
    IMPULSIVE        = 1,
    NATURAL          = 2,
    SAMPLED          = 3
  );

  TSynthesisModel = (
    CASCADE_PARALLEL = 1,
    ALL_PARALLEL     = 2
  );

  TResonator = record
    a, b, c, p1, p2: double;
  end;

  TOutputChannel=(
     OutputNone = 0,
     OutputVoice,
     OutputAspiration,
     OutputFrics,
     OutputGlotout,
     OutputPar_glotout,
     OutputOutbypas,
     OutputSourc
  );


  flag = Byte;

type
  /// <summary>Structure for Klatt Globals</summary>
  TKlattGlobal = record
  public
    synthesis_model: TSynthesisModel; // cascade-parallel or all-parallel
    outsl          : TOutputChannel;  // Output waveform selector
    samrate        : integer;         // Number of output samples per second
    FLPhz          : integer;         // Frequeny of glottal downsample low-pass filter
    BLPhz          : integer;         // Bandwidth of glottal downsample low-pass filter
    nfcascade      : integer;         // Number of formants in cascade vocal tract
    VoicingSource  : TVoicingSource;  // Type of glottal source
    f0_flutter     : integer;         // Percentage of f0 flutter 0-100
    quiet          : boolean;         // set to TRUE for error messages
    SamplesPerFrame: integer;         // number of samples per frame
    nper           : integer;         // Counter for number of samples in a pitch period
    current_sample : integer;         //
    T0             : integer;         // Fundamental period in output samples times 4
    nopen          : integer;         // Number of samples in open phase of period
    nmod           : integer;         // Position in period to begin noise amp. modul
    nrand          : integer;         // Varible used by random number generator
    pulse_shape_a  : double;          // Makes waveshape of glottal pulse when open
    pulse_shape_b  : double;          // Makes waveshape of glottal pulse when open
    minus_pi_t     : double;
    two_pi_t       : double;
    onemd          : Single;
    decay          : Single;
    amp_bypas      : Single;           // AB converted to linear gain
    amp_voice      : Single;           // AVdb converted to linear gain
    par_amp_voice  : Single;           // AVpdb converted to linear gain
    amp_aspir      : Single;           // AP converted to linear gain
    amp_frica      : Single;           // AF converted to linear gain
    amp_breth      : Single;           // ATURB converted to linear gain
    amp_gain0      : Single;           // G0 converted to linear gain
    num_samples    : integer;          // number of glottal samples
    SAMPLE_FACTOR  : Single;           // multiplication factor for glottal samples
    natural_samples: array of integer; // pointer to an array of glottal samples
    original_f0    : integer;          // original value of f0 not modified by flutter
    rnpp           : TResonator;       // internal storage for resonators
    rp             : array [1 .. 6] of TResonator;
    rc             : array [1 .. 8] of TResonator;
    rnpc           : TResonator;
    rnz            : TResonator;
    rgl            : TResonator;
    rlp            : TResonator;
    rout           : TResonator;
  end;

  { Structure for Klatt Parameters }

type
  TKlattFrame = record
  public
    /// <summary>Voicing fund freq in Hz          </summary><remarks>                         </remarks>
    F0hz10: Integer;
    /// <summary>Amp of voicing in dB,            </summary><remarks>0 to   70                </remarks>
    AVdb  : Integer;
    /// <summary>First formant freq in Hz,        </summary><remarks>200 to 1300              </remarks>
    F1hz  : Integer;
    /// <summary>First formant bw in Hz,          </summary><remarks>40 to 1000               </remarks>
    B1hz  : Integer;
    /// <summary>Second formant freq in Hz,       </summary><remarks>550 to 3000              </remarks>
    F2hz  : Integer;
    /// <summary>Second formant bw in Hz,         </summary><remarks>40 to 1000               </remarks>
    B2hz  : Integer;
    /// <summary>Third formant freq in Hz,        </summary><remarks>1200 to 4999             </remarks>
    F3hz  : Integer;
    /// <summary>Third formant bw in Hz,          </summary><remarks>40 to 1000               </remarks>
    B3hz  : Integer;
    /// <summary>Fourth formant freq in Hz,       </summary><remarks>1200 to 4999             </remarks>
    F4hz  : Integer;
    /// <summary>Fourth formant bw in Hz,         </summary><remarks>40 to 1000               </remarks>
    B4hz  : Integer;
    /// <summary>Fifth formant freq in Hz,        </summary><remarks>1200 to 4999             </remarks>
    F5hz  : Integer;
    /// <summary>Fifth formant bw in Hz,          </summary><remarks>40 to 1000               </remarks>
    B5hz  : Integer;
    /// <summary>Sixth formant freq in Hz,        </summary><remarks>1200 to 4999             </remarks>
    F6hz  : Integer;
    /// <summary>Sixth formant bw in Hz,          </summary><remarks>40 to 2000               </remarks>
    B6hz  : Integer;
    /// <summary>Nasal zero freq in Hz,           </summary><remarks>248 to  528              </remarks>
    NasalZeroFrequency : Integer;
    /// <summary>Nasal zero bw in Hz,             </summary><remarks>40 to 1000               </remarks>
    BNZhz : Integer;
    /// <summary>Nasal pole freq in Hz,           </summary><remarks>248 to  528              </remarks>
    FNPhz : Integer;
    /// <summary>Nasal pole bw in Hz,             </summary><remarks>40 to 1000               </remarks>
    BNPhz : Integer;
    /// <summary>Amp of aspiration in dB,         </summary><remarks>0 to   70                </remarks>
    ASP   : Integer;
    /// <summary># of samples in open period,     </summary><remarks>10 to   65               </remarks>
    Kopen : Integer;
    /// <summary>Breathiness in voicing,          </summary><remarks>0 to   80                </remarks>
    Aturb : Integer;
    /// <summary>Voicing spectral tilt in dB,     </summary><remarks>0 to   24                </remarks>
    TLTdb : Integer;
    /// <summary>Amp of frication in dB,          </summary><remarks>0 to   80                </remarks>
    AF    : Integer;
    /// <summary>Skewness of alternate periods,   </summary><remarks>0 to   40 in sample#/2   </remarks>
    Kskew : Integer;
    /// <summary>Amp of par 1st formant in dB,    </summary><remarks>0 to   80                </remarks>
    A1    : Integer;
    /// <summary>Par. 1st formant bw in Hz,       </summary><remarks>40 to 1000               </remarks>
    B1phz : Integer;
    /// <summary>Amp of F2 frication in dB,       </summary><remarks>0 to   80                </remarks>
    A2    : Integer;
    /// <summary>Par. 2nd formant bw in Hz,       </summary><remarks>40 to 1000               </remarks>
    B2phz : Integer;
    /// <summary>Amp of F3 frication in dB,       </summary><remarks>0 to   80                </remarks>
    A3    : Integer;
    /// <summary>Par. 3rd formant bw in Hz,       </summary><remarks>40 to 1000               </remarks>
    B3phz : Integer;
    /// <summary>Amp of F4 frication in dB,       </summary><remarks>0 to   80                </remarks>
    A4    : Integer;
    /// <summary>Par. 4th formant bw in Hz,       </summary><remarks>40 to 1000               </remarks>
    B4phz : Integer;
    /// <summary>Amp of F5 frication in dB,       </summary><remarks>0 to   80                </remarks>
    A5    : Integer;
    /// <summary>Par. 5th formant bw in Hz,       </summary><remarks>40 to 1000               </remarks>
    B5phz : Integer;
    /// <summary>Amp of F6 (same as rp[6]a),      </summary><remarks>  0 to   80              </remarks>
    A6    : Integer;
    /// <summary>Par. 6th formant bw in Hz,       </summary><remarks>40 to 2000               </remarks>
    B6phz : Integer;
    /// <summary>Amp of par nasal pole in dB,     </summary><remarks>0 to   80                </remarks>
    ANP   : Integer;
    /// <summary>Amp of bypass fric. in dB,       </summary><remarks>0 to   80                </remarks>
    ByPassPathAmp : Integer;
    /// <summary>Amp of voicing,  par in dB,      </summary><remarks>0 to   70                </remarks>
    AVpdb : Integer;
    /// <summary>Overall gain, 60 dB is unity,    </summary><remarks>0 to   60                </remarks>
    Gain0 : Integer;
  end;

function DBtoLIN(db: Integer): Single;
function LINtoDB(n:double):double;
procedure ParWave(var globals: TKlattGlobal; var frame: TKlattFrame; var output: TArray<Single>);
procedure InitParWave(var globals: TKlattGlobal);
procedure GlobalsInit(var globals:TKlattGlobal);
procedure InitFrame(var globals: TKlattGlobal; var frame: TKlattFrame);

implementation

/// <summary>Initialize Globals variable</summary>
procedure GlobalsInit(var globals:TKlattGlobal);
begin
  Globals                 := default (TKlattGlobal);
  Globals.quiet           := FALSE;
  Globals.synthesis_model := TSynthesisModel.ALL_PARALLEL;
  Globals.samrate         := 11025;
  Globals.VoicingSource   := TVoicingSource.NATURAL;
//  Globals.natural_samples := natural_samples;
  Globals.num_samples     := cNumberOfSamples;
  Globals.sample_factor   := cSampleFactor;
  Globals.nfcascade       := 0;
  Globals.outsl           := TOutputChannel.OutputNone;
  Globals.f0_flutter      := 0;
end;

function LINtoDB(n:double):double;
begin
  if (n > 1E-12) then
    Exit(LOG10(n) * 20.0)
  else
    Exit(-200.0)
end;

function DBtoLIN(db: Integer): Single;
const
  AmpTable: array [0 .. 87] of Single = (
    0,0,0,0,0,0,0,0,0,0,0,0,0,
    6, 7, 8, 9, 10, 11, 13, 14, 16, 18, 20, 22,
    25, 28, 32, 35, 40, 45, 51, 57, 64, 71, 80,
    90, 101, 114, 128, 142, 159, 179, 202, 227, 256,
    284, 318, 359, 405, 455, 512, 568, 638, 719, 811,
    911, 1024, 1137, 1276, 1438, 1622, 1823, 2048, 2273,
    2552, 2875, 3244, 3645, 4096, 4547, 5104, 5751, 6488,
    7291, 8192, 9093, 10207, 11502, 12976, 14582, 16384,
    18350, 20644, 23429, 26214, 29491, 32767

{
1.295291, 1.455383, 1.635262, 1.837373, 2.064464, 2.319622, 2.606317, 2.928446,
3.290389, 3.697066, 4.154007, 4.667423, 5.244296, 5.892467, 6.620750, 7.439045,
8.358477, 9.391547, 10.552300, 11.856517, 13.321929, 14.968460, 16.818494,
18.897185, 21.232792, 23.857069, 26.805696, 30.118759, 33.841303, 38.023936,
42.723523, 48.003959, 53.937032, 60.603407, 68.093716, 76.509793, 85.966059,
96.591078, 108.529301, 121.943035, 137.014646, 153.949041, 172.976450, 194.355562,
218.377036, 245.367456, 275.693771, 309.768282, 348.054249, 391.072190, 439.406955,
493.715680, 554.736719, 623.299685, 700.336724, 786.895196, 884.151905, 993.429107,
1116.212480, 1254.171326, 1409.181265, 1583.349736, 1779.044647, 1998.926570,
2245.984910, 2523.578550, 2835.481517, 3185.934289, 3579.701448, 4022.136458,
4519.254448, 5077.813986, 5705.408973, 6410.571880, 7202.889753, 8093.134554,
9093.409611, 10217.314169, 11480.128280, 12899.020540, 14493.281505, 16284.585961,
18297.287597, 20558.750108, 23099.719223, 25954.740700, 29162.630000, 32767
}
  );

begin
  if ((db < 0) or (db > 87)) then
    exit(0);

  Result := AmpTable[db] * 0.001;
end;

var nlast: Single;

/// <summary>
///  Random number generator (return a number between -8191 and +8191)
///  Noise spectrum is tilted down by soft low-pass filter having a pole nea,
///
///  the origin in the z-plane, i.e. output = input + (0.75 * lastoutput)
/// </summary>
function GenerateNoise(aNoise: Single; var aGlobals: TKlattGlobal): Single;
var
  temp: Integer;
begin
  temp          := random(2 * 8191) - 8191;
  aGlobals.nrand := temp;
  aNoise         := aGlobals.nrand + (0.75 * nlast);
  nlast         := aNoise;
  exit(aNoise);
end;

function Resonator(var r: TResonator; input: Single): Single;
var
  x: Single;
begin
  { This is a generic resonator function. Internal memory for the resonator,
    is stored in the globals structure. }
  x      := (r.a * input + r.b * r.p1 + r.c * r.p2);
  r.p2   := r.p1;
  r.p1   := x;
  Result := x;
end;

function AntiResonator(var aResonator: TResonator; aInput: Single): Single;
var
  x: Single;
begin
  x := aResonator.a * aInput +
       aResonator.b * aResonator.p1 +
       aResonator.c * aResonator.p2;

  aResonator.p2   := aResonator.p1;
  aResonator.p1   := aInput;
  Result := x;
end;

var
  TimeCount: Integer;

/// <summary>
///    This function adds F0 flutter, as specified in:
///
///    "Analysis, synthesis and perception of voice quality variations among
///    female and male talkers" D.H. Klatt and L.C. Klatt JASA 87(2) February 1990.
///
///    Flutter is added by applying a quasi-random element constructed from three
///    slowly varying sine waves.
/// </summary>

procedure Flutter(var aGlobals: TKlattGlobal; var aFrame: TKlattFrame);
var delta_f0, fla, flb, flc, fld, fle: Double;
begin
  fla          := aGlobals.f0_flutter / 50;
  flb          := aGlobals.original_f0 / 100;
  flc          := sin(2 * PI * 12.7 * TimeCount);
  fld          := sin(2 * PI * 7.1 * TimeCount);
  fle          := sin(2 * PI * 4.7 * TimeCount);
  delta_f0     := fla * flb * (flc + fld + fle) * 10;
  aFrame.F0hz10 := aFrame.F0hz10 + Round(delta_f0);
  Inc(TimeCount);
end;


/// <summary>
/// Convert formant freqencies and bandwidth into resonator difference
/// equation constants.
/// </summary>
procedure SetABC(
  aResFrequencyHz: Integer; { Frequency of resonator in Hz }
  aResBandWidthHz: Integer; { Bandwidth of resonator in Hz }
  var aResonator: TResonator;
  var aGlobals: TKlattGlobal);
var
  r  : Single;
  arg: Double;
begin
  // Let r  =  exp(-pi bw t)
  arg := aGlobals.minus_pi_t * aResBandWidthHz;
  r   := exp(arg);

  // Let c  =  -r**2
  aResonator.c := -(r * r);

  // Let b = r * 2*cos(2 pi f t)
  arg  := aGlobals.two_pi_t * aResFrequencyHz;
  aResonator.b := r * cos(arg) * 2.0;

  // Let a = 1.0 - b - c
  aResonator.a := 1.0 - aResonator.b - aResonator.c;
end;


/// <summary>Convert formant freqencies and bandwidth into anti-resonator difference equation constants.</summary>
procedure SetZeroABC(
  aResFreqHz      : Integer; { Frequency of resonator in Hz }
  aResBandWidthHz : Integer; { Bandwidth of resonator in Hz }
  var aResonator  : TResonator;
  var aGlobals    : TKlattGlobal);
var
  r  : Single;
  arg: Double;
begin
  aResFreqHz := -aResFreqHz;
  if (aResFreqHz >= 0) then
    aResFreqHz := -1;

  // First compute ordinary resonator coefficients
  // Let r  =  exp(-pi bw t)
  arg := aGlobals.minus_pi_t * aResBandWidthHz;
  r   := exp(arg);

  // Let c  =  -r**2
  aResonator.c := -(r * r);

  // Let b = r * 2*cos(2 pi f t)
  arg  := aGlobals.two_pi_t * aResFreqHz;
  aResonator.b := r * cos(arg) * 2.;

  // Let a = 1.0 - b - c
  aResonator.a := 1.0 - aResonator.b - aResonator.c;

  // Now convert to antiresonator coefficients (a'=1/a, b'=b/a, c'=c/a)
  aResonator.a := 1.0 / aResonator.a;
  aResonator.c := aResonator.c * -aResonator.a;
  aResonator.b := aResonator.b * -aResonator.a;
end;

/// <summary>Initialises all parameters used in parwave, sets resonator internal memory to zero.</summary>
procedure InitParWave(var globals: TKlattGlobal);
begin
  globals.FLPhz      := Round((950 * globals.samrate) / 10000);
  globals.BLPhz      := Round((630 * globals.samrate) / 10000);
  globals.minus_pi_t := -PI / globals.samrate;
  globals.two_pi_t   := -2.0 * globals.minus_pi_t;
  SetABC(globals.FLPhz, globals.BLPhz, globals.rlp, globals);
  globals.nper  := 0;
  globals.T0    := 0;
  globals.nopen := 0;
  globals.nmod  := 0;

  globals.rnpp.p1 := 0;
  globals.rp[1].p1  := 0;
  globals.rp[2].p1  := 0;
  globals.rp[3].p1  := 0;
  globals.rp[4].p1  := 0;
  globals.rp[5].p1  := 0;
  globals.rp[6].p1  := 0;
  globals.rc[1].p1  := 0;
  globals.rc[2].p1  := 0;
  globals.rc[3].p1  := 0;
  globals.rc[4].p1  := 0;
  globals.rc[5].p1  := 0;
  globals.rc[6].p1  := 0;
  globals.rc[7].p1  := 0;
  globals.rc[8].p1  := 0;
  globals.rnpc.p1 := 0;
  globals.rnz.p1  := 0;
  globals.rgl.p1  := 0;
  globals.rlp.p1  := 0;
  globals.rout.p1 := 0;

  globals.rnpp.p2 := 0;
  globals.rp[1].p2  := 0;
  globals.rp[2].p2  := 0;
  globals.rp[3].p2  := 0;
  globals.rp[4].p2  := 0;
  globals.rp[5].p2  := 0;
  globals.rp[6].p2  := 0;
  globals.rc[1].p2  := 0;
  globals.rc[2].p2  := 0;
  globals.rc[3].p2  := 0;
  globals.rc[4].p2  := 0;
  globals.rc[5].p2  := 0;
  globals.rc[6].p2  := 0;
  globals.rc[7].p2  := 0;
  globals.rc[8].p2  := 0;
  globals.rnpc.p2 := 0;
  globals.rnz.p2  := 0;
  globals.rgl.p2  := 0;
  globals.rlp.p2  := 0;
  globals.rout.p2 := 0;
end;

/// <summary>Use parameters from the input frame to set up resonator coefficients.</summary>
procedure InitFrame(var globals: TKlattGlobal; var frame: TKlattFrame);
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
  globals.amp_frica     := DBtoLIN(frame.AF)  * 0.25;
  globals.par_amp_voice := DBtoLIN(frame.AVpdb);
  amp_parF1             := DBtoLIN(frame.A1) { * 0.4};
  amp_parF2             := DBtoLIN(frame.A2) { * 0.150};
  amp_parF3             := DBtoLIN(frame.A3) { * 0.060};
  amp_parF4             := DBtoLIN(frame.A4) { * 0.040};
  amp_parF5             := DBtoLIN(frame.A5) { * 0.022};
  amp_parF6             := DBtoLIN(frame.A6) { * 0.030};
  amp_parFNP            := DBtoLIN(frame.ANP){ * 0.60};
  globals.amp_bypas     := DBtoLIN(frame.ByPassPathAmp) * 0.05;
  frame.Gain0           := frame.Gain0 - 3;
  if (frame.Gain0 <= 0) then
    frame.Gain0 := 57;

  globals.amp_gain0 := DBtoLIN(frame.Gain0);

  // Set coefficients of variable cascade resonators
  if (globals.nfcascade >= 8) then
    SetABC(7500, 600, globals.rc[8], globals);
  if (globals.nfcascade >= 7) then
    SetABC(6500, 500, globals.rc[7], globals);
  if (globals.nfcascade >= 6) then
    SetABC(frame.F6hz, frame.B6hz, globals.rc[6], globals);
  if (globals.nfcascade >= 5) then
    SetABC(frame.F5hz, frame.B5hz, globals.rc[5], globals);

  SetABC(frame.F4hz, frame.B4hz, globals.rc[4], globals);
  SetABC(frame.F3hz, frame.B3hz, globals.rc[3], globals);
  SetABC(frame.F2hz, frame.B2hz, globals.rc[2], globals);
  SetABC(frame.F1hz, frame.B1hz, globals.rc[1], globals);

  // Set coeficients of nasal resonator and zero antiresonato,

  SetABC(frame.FNPhz, frame.BNPhz, globals.rnpc, globals);
  SetZeroABC(frame.NasalZeroFrequency, frame.BNZhz, globals.rnz, globals);

  // Set coefficients of parallel resonators, and amplitude of outputs
  SetABC(frame.F1hz, frame.B1phz, globals.rp[1], globals);  globals.rp[1].a := globals.rp[1].a * amp_parF1;
  SetABC(frame.FNPhz,frame.BNPhz, globals.rnpp,  globals);  globals.rnpp.a  := globals.rnpp.a * amp_parFNP;
  SetABC(frame.F2hz, frame.B2phz, globals.rp[2], globals);  globals.rp[2].a := globals.rp[2].a * amp_parF2;
  SetABC(frame.F3hz, frame.B3phz, globals.rp[3], globals);  globals.rp[3].a := globals.rp[3].a * amp_parF3;
  SetABC(frame.F4hz, frame.B4phz, globals.rp[4], globals);  globals.rp[4].a := globals.rp[4].a * amp_parF4;
  SetABC(frame.F5hz, frame.B5phz, globals.rp[5], globals);  globals.rp[5].a := globals.rp[5].a * amp_parF5;
  SetABC(frame.F6hz, frame.B6phz, globals.rp[6], globals);  globals.rp[6].a := globals.rp[6].a * amp_parF6;

  // output low-pass filte,

  SetABC(0, Round(globals.samrate / 2), globals.rout, globals);
end;

/// <summary>
///  Generate a low pass filtered train of impulses as an approximation of
///  a natural excitation waveform. Low-pass filter the differentiated impulse
///  with a critically-damped second-order filter, time constant proportional
///  to Kopen.
/// </summary>
const
  doublet: array [0 .. 2] of Single = (0.0, 13000000.0, -13000000.0);
var
  vwave: Single;

function ImpulsiveSource(var aGlobals: TKlattGlobal): Single;
begin
  if (aGlobals.nper < 3) then
    vwave := doublet[aGlobals.nper]
  else
    vwave := 0.0;

  Result := Resonator(aGlobals.rgl, vwave);
end;

var vwave2: Single;
/// <summary>
///  Vwave is the differentiated glottal flow waveform, there is a weak
///  spectral zero around 800 Hz, magic constants a,b reset pitch synchronously.
/// </summary>
function NaturalSource(var globals: TKlattGlobal): Single;
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


const
  B0: array [0 .. 223] of uint16 = (1200, 1142, 1088, 1038, 991, 948, 907, 869, 833, 799, 768, 738, 710, 683, 658, 634, 612, 590, 570, 551, 533, 515, 499, 483, 468, 454, 440, 427, 415, 403, 391, 380, 370, 360, 350, 341, 332, 323, 315, 307, 300, 292, 285,
    278, 272, 265, 259, 253, 247, 242, 237, 231, 226, 221, 217, 212, 208, 204, 199, 195, 192, 188, 184, 180, 177, 174, 170, 167, 164, 161, 158, 155, 153, 150, 147, 145, 142, 140, 137, 135, 133, 131, 128, 126, 124, 122, 120, 119, 117, 115, 113, 111, 110,
    108, 106, 105, 103, 102, 100, 99, 97, 96, 95, 93, 92, 91, 90, 88, 87, 86, 85, 84, 83, 82, 80, 79, 78, 77, 76, 75, 75, 74, 73, 72, 71, 70, 69, 68, 68, 67, 66, 65, 64, 64, 63, 62, 61, 61, 60, 59, 59, 58, 57, 57, 56, 56, 55, 55, 54, 54, 53, 53, 52, 52,
    51, 51, 50, 50, 49, 49, 48, 48, 47, 47, 46, 46, 45, 45, 44, 44, 43, 43, 42, 42, 41, 41, 41, 41, 40, 40, 39, 39, 38, 38, 38, 38, 37, 37, 36, 36, 36, 36, 35, 35, 35, 35, 34, 34, 33, 33, 33, 33, 32, 32, 32, 32, 31, 31, 31, 31, 30, 30, 30, 30, 29, 29, 29,
    29, 28, 28, 28, 28, 27, 27);
var  skew: Integer;
/// <summary>
///   function PITCH_SYNC_PAR_RESET
///
///   Reset selected parameters pitch-synchronously.
///
///
///   Constant B0 controls shape of glottal pulse as a function
///   of desired duration of open phase N0
///   (Note that N0 is specified in terms of 40,000 samples/sec of speech)
///
///   Assume voicing waveform V(t) has form: k1 t**2 - k2 t**3
///
///   If the radiation characterivative, a temporal derivative
///   is folded in, and we go from continuous time to discrete
///   integers n:  dV/dt = vwave[n]
///   = sum over i=1,2,...,n of { a - (i * b) }
///   = a n  -  b/2 n**2
///
///   where the  constants a and b control the detailed shape
///   and amplitude of the voicing waveform over the open
///   potion of the voicing cycle "nopen".
///
///   Let integral of dV/dt have no net dc flow --> a = (b * nopen) / 3
///
///   Let maximum of dUg(n)/dn be constant --> b = gain / (nopen * nopen)
///   meaning as nopen gets bigger, V has bigger peak proportional to n
///
///   Thus, to generate the table below for 40 <= nopen <= 263:
///
///   B0[nopen - 40] = 1920000 / (nopen * nopen)
/// </summary>
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

    if ((globals.VoicingSource = IMPULSIVE) and (globals.nopen > 263)) then
      globals.nopen := 263;

    if (globals.nopen >= (globals.T0 - 1)) then
    begin
      globals.nopen := globals.T0 - 2;

      //if (globals.quiet = FALSE) then
     //        raise Exception.Create('Glottal open period cannot exceed T0, truncated');
    end;

    if (globals.nopen < 40) then
    begin
      // F0 max = 1000 Hz
      globals.nopen := 40;
      if (globals.quiet = FALSE) then
      begin
//        writeln('Warning: minimum glottal open period is 10 samples.');
//        writeln(format('truncated, nopen = %d', [globals.nopen]));
      end;
    end;

    // Reset a & b, which determine shape of "natural" glottal waveform
    globals.pulse_shape_b := B0[globals.nopen - 40];
    globals.pulse_shape_a := (globals.pulse_shape_b * globals.nopen) * 0.333;

    // Reset width of "impulsive" glottal pulse
    temp := Round(globals.samrate / globals.nopen);

    SetABC(0, temp, globals.rgl, globals);

    // Make gain at F1 about constant
    temp1         := globals.nopen * 0.00833;
    globals.rgl.a := globals.rgl.a * temp1 * temp1;

    // Truncate skewness so as not to exceed duration of closed phase of glottal period.
    temp := globals.T0 - globals.nopen;
    if (frame.Kskew > temp) then
    begin
      if (globals.quiet = FALSE) then
      begin
//        writeln(format('Kskew duration=%d > glottal closed period=%d, truncate\n',
//        [
//          frame.Kskew, globals.T0 - globals.nopen
//        ]));
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
  InitFrame(globals, frame); // get parameters for next frame of speech
  Flutter(globals, frame);    // add f0 flutte,


  // MAIN LOOP, for each output sample of current frame:
  for i := 0 to globals.SamplesPerFrame - 1 do
  begin
    Inc(globals.current_sample);

    // Get low-passed random number for aspiration and frication noise
    noise := GenerateNoise(noise, globals);

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
      case (globals.VoicingSource) of
        IMPULSIVE : voice := ImpulsiveSource(globals);
        NATURAL   : voice := NaturalSource(globals);
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
      voice := Resonator(globals.rlp, voice);

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
      casc_next_in := AntiResonator(globals.rnz, glotout);
      casc_next_in := Resonator(globals.rnpc, casc_next_in);
      // Do not use unless sample rate >= 16000
      if (globals.nfcascade >= 8) then casc_next_in := Resonator(globals.rc[8], casc_next_in);
      // Do not use unless sample rate >= 16000
      if (globals.nfcascade >= 7) then casc_next_in := Resonator(globals.rc[7], casc_next_in);
      { Do not use unless long vocal tract or sample rate increased }
      if (globals.nfcascade >= 6) then casc_next_in := Resonator(globals.rc[6], casc_next_in);
      if (globals.nfcascade >= 5) then casc_next_in := Resonator(globals.rc[5], casc_next_in);
      if (globals.nfcascade >= 4) then casc_next_in := Resonator(globals.rc[4], casc_next_in);
      if (globals.nfcascade >= 3) then casc_next_in := Resonator(globals.rc[3], casc_next_in);
      if (globals.nfcascade >= 2) then casc_next_in := Resonator(globals.rc[2], casc_next_in);
      if (globals.nfcascade >= 1) then output[i]    := Resonator(globals.rc[1], casc_next_in);
      output[i] := output[i];
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
      outputs added with alternating sign. Sound sourc for othe,

      parallel resonators is frication plus first difference of
      voicing waveform.
    }
    output[i] := output[i] + Resonator(globals.rp[1], sourc);
    output[i] := output[i] + Resonator(globals.rnpp, sourc);

    sourc    := frics + par_glotout - glotlast;
    glotlast := par_glotout;

    output[i] := Resonator(globals.rp[6], sourc) - output[i];
    output[i] := Resonator(globals.rp[5], sourc) - output[i];
    output[i] := Resonator(globals.rp[4], sourc) - output[i];
    output[i] := Resonator(globals.rp[3], sourc) - output[i];
    output[i] := Resonator(globals.rp[2], sourc) - output[i];

    outbypas  := globals.amp_bypas * sourc;
    output[i] := outbypas - output[i];
    output[i] := output[i] / 10;

    if (globals.outsl <> OutputNone) then
    begin
      case globals.outsl of
        OutputNone:           ;
        OutputVoice:          output[i] := voice;
        OutputAspiration:     output[i] := aspiration;
        OutputFrics:          output[i] := frics;
        OutputGlotout:        output[i] := glotout;
        OutputPar_glotout:    output[i] := par_glotout;
        OutputOutbypas:       output[i] := outbypas;
        OutputSourc:          output[i] := sourc;
      end;

      output[i] := Resonator(globals.rout, output[i]);

      temp := output[i] * globals.amp_gain0/1000;

      (* Convert back to integer *)
      if (temp < -32768) then
        temp := -32768;

      if (temp > 32767) then
        temp := 32767;

      output[i] := temp;
    end;
  end;
end;

end.
