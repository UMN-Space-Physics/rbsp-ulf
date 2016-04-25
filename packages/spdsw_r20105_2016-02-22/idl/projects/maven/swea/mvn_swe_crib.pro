;--------------------------------------------------------------------
; MAVEN SWEA Crib
;
; Additional information for all procedures and functions can be
; displayed using doc_library.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-05-26 17:21:07 -0700 (Tue, 26 May 2015) $
; $LastChangedRevision: 17734 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_crib.pro $
;--------------------------------------------------------------------
;

; General note: All SWEA procedures have their own documentation, 
; describing how to call them and what the options are.  There are
; many more options than are listed in this help file.  To list the
; documentation for routine_name.pro:

doc_library, 'routine_name'

; Before loading SWEA data, set the time range.  You only need to do 
; this once.  If you have already done this to load the data from another
; instrument, you don't need to do it again.

timespan, ['2014-12-10','2014-12-11']

; Load SWEA L0 data into a common block

mvn_swe_load_l0

; You can override the time range set by timespan by explicitly providing
; a time range to the loader.  You might want to do this if you're only
; interested in a shorter time interval of SWEA data.

mvn_swe_load_l0, ['2014-12-10/08','2014-12-10/12']

; You can also request data by orbit number using the ORBIT keyword.
;   SWEA software uses the NAIF orbit numbering convention, where
;   the orbit number increments at geometric periapsis.  When you
;   request data for orbit X, you get data from apoapsis X-1 through 
;   periapsis X, extending to apoapsis X.

mvn_swe_load_l0, orbit=[357,360]

; Load L2 data by unix time range or orbit number into a common block
;   Data loaded from L2 are identical to data loaded from L0 (by design).
;   L2 data load quickly but consume about 6 times more RAM.  A full day
;   of L2 survey data can consume ~4 GB of RAM.  Add burst data to this
;   and ~8 GB are needed.  So, you may need to manage RAM, depending on
;   your hardware.
;
;   All SWEA routines automatically detect which type of data are loaded 
;   and work the same.  L2 data are loaded using the same methods as L0:

mvn_swe_load_l2

mvn_swe_load_l2, orbit=[357,360]

; To conserve RAM, you can load individual data products over different
; time ranges.  Make sure to use the NOERASE option, so that you don't 
; reinitialize the common block with each call.
;
; (I recommend that you load burst data in this way.)

mvn_swe_load_l2, /spec         ; load SPEC survey data over the full range

smaller_trange = ['2014-12-10/10','2014-12-10/12']
mvn_swe_load_l2, smaller_trange, /pad, /noerase          ; PAD survey data
mvn_swe_load_l2, smaller_trange, /pad, /burst, /noerase  ; PAD burst data

; Summary plot.  Loads ephemeris data and includes a panel for 
; spacecraft altitude (aerocentric).  Orbit numbers appear along
; the time axis.
;
;   Many optional keywords for plotting additional panels.
;   Use doc_library for details.

mvn_swe_sumplot, /eph, /orb

; Load MAG data, rotate to SWEA coordinates, and smooth to SWEA PAD 
; resolution (1-sec averages over second half of sweep).  These data 
; are stored in a common block for quick access by mvn_swe_getpad and 
; mvn_swe_get3d.  This procedure loads the highest level MAG data
; available:
;
;   L0 --> unit vector in direction of B (calculated onboard)
;   L1 --> MAG "quicklook" with only gains and offsets applied
;   L2 --> MAG Level 2 data with all corrections
;
; See the MAGLEV tag in the SWEA PAD and 3D structures to see which
; MAG level you have.  Pitch angle mapping is performed with the 
; level shown in the structure.

mvn_swe_addmag

; Calculate the electron distribution symmetry direction.  Return new
; tplot variables in keyword pans.

swe_3d_strahl_dir, pans=pans

; Calculate the spacecraft potential from SPEC data
;   This is a semi-empirical method with a fudge factor based on 
;   experience in previous missions.  This will be refined as we
;   get cross calibrations with LPW, SWIA, and STATIC.

mvn_swe_sc_pot, /overlay

; Calculate the spacecraft potential from 3D data
;   Allows bin masking, but has a lower cadence and can be less 
;   accurate because of energy bin summing.

mvn_swe_sc_pot, /overlay, /ddd, /mask_sc

; Determine the direction of the Sun in SWEA coordinates
;   Requires SPICE.  There are several instances when the S/C
;   Z axis is not pointing at the Sun (some periapsis modes,
;   comm passes, MAG rolls).  When the sensor head is illuminated,
;   increased photoelectron background can occur.  This routine
;   also calculates the direction of the Sun in spacecraft
;   coordinates -- useful to identify pointing modes and times
;   when the spacecraft is communicating with Earth.

mvn_swe_sundir, pans=pans

; Determine the RAM direction in spacecraft coordinates
;   Requires SPICE.  The RAM direction is calculated with respect to
;   the IAU_MARS frame (planetocentric, body-fixed).
;
;   Use keyword FRAME to calculate the RAM direction in any MAVEN 
;   frame recognized by SPICE.  (Keyword APP is shorthand for 
;   FRAME='MAVEN_APP'.)

mvn_sc_ramdir, pans=pans

; Estimate electron density from 3D moment (allows bin masking).
; This method does not account for spacecraft photoelectron scattering
; into the SWEA aperture, or for photoelectrons created inside the 
; aperture (primarily from the top cap).  This overestimates the
; density.

mvn_swe_n3d, /mask_sc

; Estimate electron density and temperature from fitting the core to
; a Maxwell-Boltzmann distribution and taking a moment over energies
; above the core to estimate the contribution from the halo.  This 
; corrects for scattered electrons.

mvn_swe_n1d, /mb, pans=pans

; Estimate electron density and temperature from 1D moments.  Works in
; the post-shock region, where the distribution is not Maxwellian.  
; No correction for scattered electrons.  (This is the default for 
; key parameters.)

mvn_swe_n1d, /mom, pans=pans

; Resample the pitch angle distributions for a nicer plot.  SWEA measures
; the 0-180-degree pitch angle range twice.  This procedure averages these
; two independent measurements and oversamples.  Spacecraft blockage is 
; masked automatically (by default).

mvn_swe_pad_resample, nbins=128., erange=[100., 150.], /norm, /mask, /silent

; Calculate pitch angle distributions from 3D distributions

mvn_swe_pad_resample, nbins=128., erange=[100., 150.], /norm, /mask, $
                     /ddd, /map3d, /silent

; Load resampled PAD data from pre-calculated IDL save/restore files into
; a TPLOT variable.  (Much faster than above, but may use L1 MAG data, and
; there are no options.)

mvn_swe_pad_restore

; Snapshots selected by the cursor in the tplot window
;   Return data by keyword (ddd, pad, spec) at the last place clicked
;   Use keyword SUM to sum data between two clicks.  (Careful with
;   changing magnetic field.)  The structure element "var" (variance)
;   keeps track of counting statistics, including digitization noise.
;   Set the BURST keyword to show burst data instead of survey data.

swe_engy_snap,/mom,/fixy,spec=spec
swe_pad_snap,energy=130,pad=pad
swe_3d_snap,/spec,/symdir,energy=130,ddd=ddd,smo=[5,1,1]

;
; Get 3D, PAD, or SPEC data at a specified time or array of times.
;   Use keyword ALL to get all 3D/PAD distributions bounded by
;   the input time array.  Use keyword SUM to average all
;   distributions bounded by the input time array.  Set the BURST
;   keyword to get burst data instead of survey data.  (You have
;   to load burst data first.  See above.)

ddd = mvn_swe_get3d(time, units='eflux')
pad = mvn_swe_getpad(time)
spec = mvn_swe_getspec(time)

;
; Visualizing the orbit and spacecraft location

; Load the spacecraft ephemeris from MOI to the current date plus
; a few weeks into the future.  Uses reconstructed ephemeris data
; as much as possible, then predicts as far as NAIF provides them.
; Use the LOADONLY keyword to load the ephemeris into TPLOT without
; resetting the time range.
;
; Ephemeris data are updated daily at 3:30 am Pacific.

maven_orbit_tplot,/loadonly

; Plot snapshots of the orbit in three orthogonal MSO planes.
; Optionally plot the orbit in cylintrical coordinates (/CYL),
; IAU_MARS coordinates (MARS=1 or MARS=2), etc.  Use doc_library 
; to see all the options. (Each keyword opens a separate window.)
; Press and hold the left mouse button and drag for a movie effect.

maven_orbit_snap
