;+
;PROCEDURE: thm_esa_bgnd_remove
;
;PURPOSE: 
;Background removal code from Vassilis
;This abstracts the code as the same algorithm is used in many of the get_th?_pexx routines  
;INPUT:   
;  dat:  The dat structure from the parent routine
;  gf: The geometric factor array from the parent routine
;  eff: The efficiency array from the parent routine
;  nenergy: The number of energy bins for the data being calibrated
;  nbins: The number of angle bins for the data being calibrated
;  theta: angles in theta for the angle bins of the data being calibrated 
;
;OUTPUTS:
;  Modifies the dat structure that was provided to it.
;
;KEYWORDS:
; 
;/bdnd_remove:  Turn on ESA background removal.
;
;bgnd_type(Default 'anode'): Set to string naming background removal type:
;'angle','omni', or 'anode'.
;
;bgnd_npoints(Default = 3): Set to the number of lowest values points to average over when determining background.
;              
;bgnd_scale(Default=1): Set to a scaling factor that the background will be multiplied by before it is subtracted
;
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-04-06 17:11:34 -0700 (Mon, 06 Apr 2015) $
; $LastChangedRevision: 17247 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/packet/thm_esa_bgnd_remove.pro $
;- 

pro thm_esa_bgnd_remove, dat, gf, eff, nenergy, nbins, theta, bgnd_scale = bgnd_scale, bgnd_type = bgnd_type, $
                         bgnd_npoints = bgnd_npoints, _extra = _extra


  if (keyword_set(bgnd_scale) eq 0) then bgnd_scale=1
  
  if (keyword_set(bgnd_type) eq 0) then begin
    bgnd_type='anode'
  endif else begin
    bgnd_type=strlowcase(bgnd_type)
  endelse
  if (keyword_set(bgnd_npoints) eq 0) then bgnd_npoints=3
  gfeff = gf*eff
  narrdims=size(dat,/dimensions)
  case bgnd_type of
  'angle' : bgnd= gfeff * (make_array(nenergy,value=1,/float) # $
            minjmin(dat/gf,dim=1,jmin_points=bgnd_npoints)) ;  2d or 1d
  'omni' : begin
             if (n_elements(narrdims) eq 1) then bgnd=gfeff * $
               minjmin(dat/gf,jmin_points=bgnd_npoints)
             if (n_elements(narrdims) eq 2) then bgnd=gfeff * $
               minjmin(average(dat/gf,2),jmin_points=bgnd_npoints)
           end
  'anode' : begin
             if (n_elements(narrdims) eq 1) then bgnd=gfeff * $
               minjmin(dat/gf,jmin_points=bgnd_npoints)
             if (n_elements(narrdims) eq 2) then begin ; here compute anode dependent bgnd, 22.5 deg at a time
               bgnd = make_array(nenergy,nbins,value=0,/float)
;               nths=16 ; max number of anodes, general case
;               thmin=[0,22.5,45.,56.25,67.5,73.125,78.75,84.375] & thmin=-[90.-thmin,-thmin]
;               thmax=[22.5,45.,56.25,67.5,73.125,78.75,84.375,90.] & thmax=-[90.-thmax,-thmax]
               ;set theta bins
               thbins = [67.5, 45.0, 33.75, 22.5, 16.875, 11.25, 5.625] 
               thmin = [-90, -thbins, 0, reverse(thbins) ] 
               thmax =      [-thbins, 0, reverse(thbins), 90]
               for ith=0, n_elements(thmin)-1 do begin 
                 ian=where((theta[0,*] ge thmin[ith]) and (theta[0,*] lt thmax[ith]),jan)
                 if jan gt 0 then begin
                   if jan eq 1 then begin
                    bgnd[*,ian]=gfeff[*,ian] * $
                     minjmin(dat[*,ian]/gf[*,ian],jmin_points=bgnd_npoints)
                   endif else begin
                     bgnd[*,ian]=gfeff[*,ian] * $
                     minjmin(average(dat[*,ian]/gf[*,ian],2),jmin_points=bgnd_npoints)
                   endelse
                 endif
               endfor
             endif
           end
  else:    dprint,'unknown bgnd_type entered'
  endcase
  dat=dat-bgnd*bgnd_scale
  izeros=where(dat le 0., jzeros)
  if (jzeros gt 0) then dat[izeros]=0.

end
  
