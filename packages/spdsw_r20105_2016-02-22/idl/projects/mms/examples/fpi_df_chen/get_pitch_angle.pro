;+
; Function get_pitch_angle
;
; Purpose: to compute pitch angle from the 3d distribution for the MMS FPI
; 	instrument
;
; Input: 
;
; Keywords: combine  0: project bins with (BinvecXB)_z < 0 to 360-PA
;                    1: leave PArange 0-180
;
; Created By: 	Dimple P. Patel (for EQS - ESIC)
;		University of New Hampshire
;		Space Science Group
;		dpatel@teams.sr.unh.edu
;
; Date: 2/24/99
; Version: 1.3
; Last Modification: 04/09/01
; Modification History:
;	3/5/99 - added check  - if B-field does not exist then inform user
;		and continue without computing PA 
;       7/14/99 - improve method of calculating pitch angle for
;                 certain time periods (ie 5 min averages)
;       8/26/99 - able to handle getting magnetic field data for
;                 multiple days
;      04/08/01 - Modified for the needs of the CLUSTER/CODIF data.
;      09/12/01 - The phi angle correction (as a function of energy) is
;                 moved to the get_cis_cod_3d routine
;      11/20/01 - combine MF
;      07/09/2015 - remvoe the keyword of 'combine' --swang
;-

FUNCTION get_pitch_angle, data, mag_theta, mag_phi

  phi = data.phi
  theta = data.theta 
  nbins = data.nbins
  nenergy = data.nenergy
  
  n_t = n_elements(data.time)
  PA = DBLARR(data.nenergy, data.nbins, n_t)
  FOR ii = 0, n_t - 1 DO BEGIN
    ; Normalize B
    Bx_norm = COS(!DTOR*mag_theta(ii))*COS(!DTOR*mag_phi(ii))
    By_norm = COS(!DTOR*mag_theta(ii))*SIN(!DTOR*mag_phi(ii))
    Bz_norm = SIN(!DTOR*mag_theta(ii))
    ; compute the pitch angle 	
    PA(*,*,ii) = (ACOS(COS(!DTOR*theta)*COS(!DTOR*phi)*Bx_norm + $ 
                       COS(!DTOR*theta)*SIN(!DTOR*phi)*By_norm + $
                       SIN(!DTOR*theta)*Bz_norm))*!RADEG
  ENDFOR

  RETURN, PA
  
END
