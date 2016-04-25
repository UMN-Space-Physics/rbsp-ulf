;+
;PROCEDURE:   mvn_swe_init
;PURPOSE:
;  Initializes SWEA common block (mvn_swe_com).
;
;
;USAGE:
;  mvn_swe_init
;
;INPUTS:
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-05-26 13:47:11 -0700 (Tue, 26 May 2015) $
; $LastChangedRevision: 17725 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_init.pro $
;
;CREATED BY:    David L. Mitchell  02-01-15
;FILE: mvn_swe_init.pro
;-
pro mvn_swe_init

  @mvn_swe_com
  common snap_layout, snap_index, Dopt, Sopt, Popt, Nopt, Copt, Fopt, Eopt, Hopt
  
  if (size(snap_index,/type) eq 0) then swe_snap_layout,0

; Decompression: 19-to-8
;   16-bit instrument messages are summed into 19-bit counters 
;   in the PFDPU.  These 19-bit values are rounded down onboard
;   to fit into the 8-bit compression scheme, so each compressed
;   value corresponds to a range of possible counts.  I take the
;   middle of each range for decompression, so there are half 
;   counts.  This is less than a ~3% (systematic) correction.
;
;   Compression introduces digitization noise, which dominates
;   the variance at high count rates.  I treat digitization noise
;   as additive white noise.

  decom = fltarr(16,16)
  decom[0,*] = findgen(16)
  decom[1,*] = 16. + findgen(16)
  for i=2,15 do decom[i,*] = 2.*decom[(i-1),*]
    
  d_floor = reform(transpose(decom),256)        ; FSW rounds down
  d_ceil = shift(d_floor,-1) - 1.
  d_ceil[255] = 2.^19. - 1.                     ; 19-bit counter max
  d_mid = (d_ceil + d_floor)/2.                 ; mid-point
  n_pts = d_ceil - d_floor + 1.                 ; number of values in range
  d_var = d_mid + (n_pts^2. - 1.)/12.           ; variance w/ dig. noise
    
  decom = d_mid  ; decompressed counts
  devar = d_var  ; variance w/ digitization noise

; Housekeeping conversions

  swe_v = [ 1.000     , $   ;  0: LVPS Temperature
           -0.153355  , $   ;  1: MCP HV Voltage
           -0.000203  , $   ;  2: NRHV +5V Supply Voltage
           -0.030795  , $   ;  3: Analyzer Voltage
           -0.076870  , $   ;  4: Deflector 1 Voltage
           -0.075839  , $   ;  5: Deflector 2 Voltage
            1.000     , $   ;  6: ground/spare
            1.000     , $   ;  7: ground/spare
            0.000763  , $   ;  8: V0 Voltage
            1.000     , $   ;  9: Analyzer Temperature
           -0.000459  , $   ; 10: +12V Voltage
           -0.000459  , $   ; 11: -12V Voltage
           -0.001055  , $   ; 12: +28V Voltage (after MCPHV enable plug)
           -0.001055  , $   ; 13: +28V Voltage (after NRHV enable plug)
            1.000     , $   ; 14: ground/spare
            1.000     , $   ; 15: ground/spare
            1.000     , $   ; 16: Digital Temperature
           -0.000169  , $   ; 17: +2.5V Digital Voltage
           -0.000191  , $   ; 18: +5V Digital Voltage
           -0.000169  , $   ; 19: +3.3V Digital Voltage
           -0.000191  , $   ; 20: +5V Analog Voltage
           -0.000191  , $   ; 21: -5V Analog Voltage
           -0.001055  , $   ; 22: +28V Voltage
            1.000        ]  ; 23: ground/spare

  swe_t = [1.6484d2, 3.9360d-2, 5.6761d-6, 4.4329d-10, 1.6701d-14, 2.4223d-19]

; Grouping and Period

  swe_ne = [64, 32, 16, 0]       ; number of energy bins for group=0,1,2
  swe_dt = 2D^(dindgen(6) + 1D)  ; sample interval (sec) for period=0,1,2,3,4,5

; Define structures for raw and processed data

  mvn_swe_struct

; Define times of configuration changes

  mvn_swe_config

  return

end
