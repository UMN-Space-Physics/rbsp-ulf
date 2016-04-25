;+
; PROCEDURE aacgmloadcoef 
; 
; :PURPOSE:
; A wrapper procedure to choose AACGM DLM or IDL-native routines 
; to load the coefficients of AACGM conversion. Actually this procedure 
; does load the coefficients for given year if AACGM DLM is available. 
; 
; The wrapper procedures/functions check !sdarn.aacgm_dlm_exists 
; (if not defined, then define it by sd_init) to select appropriate 
; AACGM routines (DLM, or IDL native ones attached to TDAS). 
; 
; :Params:
;   year:   4-digit year for which the AACGM coefficients are loaded.
; 
; :Examples:
;   aacgmloadcoef, 2005
;   
; :AUTHOR: 
;   Tomo Hori (E-mail: horit@stelab.nagoya-u.ac.jp)
;   
; :HISTORY:
;   2011/10/04: created and got through the initial bug fixes
;
; $LastChangedBy: crussell $
; $LastChangedDate: 2013-03-21 10:10:35 -0700 (Thu, 21 Mar 2013) $
; $LastChangedRevision: 11857 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/ground/radar/superdarn/sdaacgmlib/aacgmloadcoef.pro $
;-
pro aacgmloadcoef, year

;Initialize !sdarn if not defined
help, name='!sdarn',out=out
if out eq '' then sd_init

;Exit unless the argument is given
npar = n_params()
if npar ne 1 then return

;Only AACGM DLM has a subroutine to load the S-H coefficients for given year
if !sdarn.aacgm_dlm_exists then begin 
  ;print, 'using AACGM_DLM'
  
  ;Choose the coef. file of the year closest to the one given as an argument
  yrlist = [ 1975, 1980, 1985, 1990, 1995, 2000, 2005, 2010 ] 
  yr_selected = yrlist[ nn( yrlist, year ) ]
 
  aacgm_load_coef, yr_selected
  
endif 

return
end


