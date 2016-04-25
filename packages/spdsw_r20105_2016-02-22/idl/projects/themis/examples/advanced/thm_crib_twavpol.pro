;+
;Name:
;  thm_crib_twavpol
;
;Purpose:
;  
;  This version stores these outputs as tplot variables with the
;  specified prefix
;         These are follows:
;
;         Wave power: On a linear scale, at this stage no units
;
;         Degree of Polarisation:
;		This is similar to a measure of coherency between the input
;		signals, however unlike coherency it is invariant under
;		coordinate transformation and can detect pure state waves
;		which may exist in one channel only.100% indicates a pure
;		state wave. Less than 70% indicates noise. For more
;		information see J. C. Samson and J. V. Olson 'Some comments
;		on the description of the polarization states
;		of waves' Geophys. J. R. Astr. Soc. (1980) v61 115-130
;
;         Wavenormal Angle:
;		the angle between the direction of minimum
;		variance calculated from the complex off diagonal
;		elements of the spectral matrix and the Z direction
;		of the input
;		ac field data. For magnetic field data in
;		field aligned coordinates this is the
;		wavenormal angle assuming a plane wave.
;
;         Ellipticity:The ratio (minor axis)/(major axis) of the
;		ellipse transcribed by the field variations of the
;		components transverse to the Z direction. The sign
;		indicates the direction of rotation of the field vector in
;  		the plane. Negative signs refer to left-handed
;		rotation about the Z direction. In the field
;		aligned coordinate system these signs refer to
;		plasma waves of left and right handed
;		polarisation.
;
;         Helicity:Similar to Ellipticity except defined in terms of the
;	direction of minimum variance instead of Z. Stricltly the Helicity
;	is defined in terms of the wavenormal direction or k.
;	However since from single point observations the
;	sense of k cannot be determined,  helicity here is
;	simply the ratio of the minor to major axis transverse to the
;       minimum variance direction without sign.
;
;
;History:
;  Written by : Kaori(I'll remember to get her last name soon)
;
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2007-12-06 14:56:54 -0800 (Thu, 06 Dec 2007) $
; $LastChangedRevision: 2161 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/ssl_general/trunk/misc/tplotxy.pro $
;-

;; =============================
;; Select date and time interval
;; =============================

date = '2007-05-08'
timespan, date,1,/day

;; =============================
;; Select probe and mode
;; =============================

;; Select satellites

sc = ['c']

;;　Select mode (scf, scp, scw, fgs, fsl, fgh, fge)

mode = 'scf'
;mode = 'fge'

;; =============================
;; Get auxiliary data from STAT 
;; =============================

thm_load_state, probe=sc, /get_support_data

;; ==============================================================
;; Get SCM/FGM data and SCM/FGM header file with easy calibration method
;; ==============================================================

;; If you want to set up a limited timespan for calibration,
;; For best cleanup, it is best to specify a relatively short time range,
;; over which the noise signal is relatively uniform.

starting_date = strmid(date, 0, 10)
starting_time = '03:30:00.0'
ending_time   = '04:30:00.0'

trange = [starting_date+'/'+starting_time,starting_date+'/'+ending_time]

;; Get SCM/FGM data

thm_load_scm, probe=sc, datatype=mode, level=1, trange=trange
;thm_load_fgm, probe=sc, datatype=mode, level=2, trange=trange,coord='gsm'

thscs_mode = 'th'+sc+'_'+mode
;thscs_mode = 'th'+sc+'_'+mode+'_gsm'

;; =======================
;; Calculate polarisation
;; =======================

twavpol,'thc_scf'
;twavpol,'thc_fgl_gsm'

;; =====================
;; Plot calculated data
;; =====================

zlim,'*_powspec',0.0,0.0,1
tplot, [thscs_mode+'_powspec', thscs_mode+'_degpol', thscs_mode+'_waveangle', thscs_mode+'_elliptict', thscs_mode+'_helict'], $
       trange=trange


 
;; ********************************************
;; end of thm_crib_twavpol.pro
;; ********************************************

end
