;+
;PROCEDURE:
;  thm_part_energy_interpolate
;
;PURPOSE:
;  Interpolate particle data by energy between sst & esa distributions using 
;  a weighted curve fitting routine.
;
;INPUTS:
;  dist_sst: SST particle distribution structure in flux 
;  dist_esa: ESA particle distribution structure in flux
;  energies: The set of target energies to interpolated the SST to.
;    
;OUTPUTS:
;   Replaces dist_sst with the interpolated data set
;
;KEYWORDS: 
;  error: Set to 1 on error, zero otherwise
;  
;NOTES:
;   #1 The number of time samples and the times of those samples must 
;      be the same for dist_sst & dist_esa (use thm_part_time_interpolate.pro)
;   #2 The number of angles and the angles of each sample must be 
;      the same for dist_sst & dist_esa (use thm_part_sphere_interp.pro)
;
;SEE ALSO:
;   thm_part_dist_array
;   thm_part_smooth
;   thm_part_subtract,
;   thm_part_omni_convert
;   thm_part_time_interpolate.pro
;   thm_part_sphere_interp.pro
;
;  $LastChangedBy: pcruce $
;  $LastChangedDate: 2013-09-26 16:32:05 -0700 (Thu, 26 Sep 2013) $
;  $LastChangedRevision: 13156 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/themis/spacecraft/particles/thm_part_energy_interpolate.pro $
;-

pro thm_part_energy_interp,dist_sst,dist_esa,energies,error=error;,dist_sst_counts=dist_sst_counts,dist_esa_counts=dist_esa_counts,emin=emin

   compile_opt idl2
   
   error=1
   
   dist_esa_i = 0
   dist_esa_j = 0
    
   min_flux = 1e-4 ; order of magnitude of min 1 count flux for esa/sst.  Used so that we can to log/log interpolation on data with a lot of zeros
    
   ;TBD units must be FLUX
    
   ;TBD input validation
   ;TBD verification that number of samples in dist_sst matches the number in dist_esa...
   ;TBD verification that the number of angles in dist_sst match the number in dist_esa 
   ;TBD verification of units on input distributions
   
   blankarr = (fltarr(n_elements(energies))+1)
  
   for i = 0,n_elements(dist_sst)-1 do begin
   
     ;Note that most of the calculations below assume that variables
     ;are not changing along one dimension or another.  If that assumption
     ;fails, these calculations will need to be made more complex.
     sst_dim = dimen((*dist_sst[i])[0].data)
     sst_template_out = (*dist_sst[i])[0]
     sst_energy_out = energies # (fltarr(sst_dim[1])+1)
     sst_denergy_out = blankarr # (fltarr(sst_dim[1]))
     sst_data_out = blankarr # (fltarr(sst_dim[1]))
     sst_bins_out =  blankarr # (*dist_sst[i])[0].bins[0,*]
     sst_phi_out = blankarr # sst_template_out.phi[0,*]
     sst_theta_out = blankarr # sst_template_out.theta[0,*]
     sst_dphi_out = blankarr # sst_template_out.dphi[0,*]
     sst_dtheta_out = blankarr # sst_template_out.dtheta[0,*]
     
     ;update all the supplemental variables that are required by the moment routines
     str_element,sst_template_out,'energy',sst_energy_out,/add_replace
     str_element,sst_template_out,'denergy',sst_denergy_out,/add_replace
     str_element,sst_template_out,'data',sst_data_out,/add_replace
     str_element,sst_template_out,'bins',sst_bins_out,/add_replace
     str_element,sst_template_out,'phi',sst_phi_out,/add_replace
     str_element,sst_template_out,'theta',sst_theta_out,/add_replace
     str_element,sst_template_out,'dphi',sst_dphi_out,/add_replace 
     str_element,sst_template_out,'dtheta',sst_dtheta_out,/add_replace
     
     ;expand to match number of samples
     sst_mode_out = replicate(sst_template_out,n_elements(*dist_sst[i]))
     
     ;look over samples for this combined mode
     for j = 0,n_elements(*dist_sst[i])-1 do begin
     
       sample_sst = (*dist_sst[i])[j]
       sample_esa = (*dist_esa[dist_esa_i])[dist_esa_j]

       combined_energy = [sample_esa.energy,sample_sst.energy]
       combined_data = [sample_esa.data,sample_sst.data]
       combined_bins = [sample_esa.bins,sample_sst.bins]
       
       ;Calculate energy bin widths.  If energies do not change between samples
       ;in a single mode for both ESA and SST then this could be moved out of the loop. 
       combined_denergy = abs(deriv(combined_energy))
       ncde = n_elements(combined_denergy)
       sst_mode_out[j].denergy = combined_denergy[ ncde-n_elements(energies):ncde-1 ] # (fltarr(sst_dim[1])+1) 
       
       if max(sample_esa.energy,/nan) gt min(energies,/nan) then begin
         dprint,dlevel=1,'ERROR: ESA maximum energy(' + strtrim(max(sample_esa.energy,/nan),2) + ' eV) greater than minimum energy target(' + strtrim(min(energies,/nan),2) + ' eV)' 
         return
       endif
       
       sst_mode_out[j].time=sample_sst.time ;copy time over
       sst_mode_out[j].end_time=sample_sst.end_time ;copy time over
       
       ;loop over look directions and interpolate 
       for l=0,sst_dim[1]-1 do begin
       
         ;generate bins data for new bins(not needed...I think?)
         ;sst_mode_out[j].bins[*,l] = round(interpol(sample_sst.bins[*,l],sample_sst.energy[*,l],energies)) > 0 < 1
         
         ;need to use proper bins so that disabled bins aren't included in interpolation calculations
         combined_idx = where(combined_bins[*,l],c)
         if c eq 0 then begin
           dprint,dlevel=1,'ERROR: No bins enabled for angle:'+strtrim(l,2)
           return
         endif

         sst_idx = where(sample_sst.bins[*,l],c)
         if c eq 0 then begin
           dprint,dlevel=1,'ERROR: No SST bins enabled for angle:'+strtrim(l,2)
           return
         endif 
         
         ;The +min_flux -min_flux, turns alog(0) to alog(min_flux) preventing lots of -infinities in our interpolation 
         sst_mode_out[j].data[*,l] = exp(interpol(alog(combined_data[combined_idx,l]+min_flux),alog(combined_energy[combined_idx,l]),alog(energies)))-min_flux 
;         sst_mode_out[j].data[*,l] = interpol(combined_data[combined_idx,l],combined_energy[combined_idx,l],energies) 
       
       endfor
   
       ;dist_two should have matching time samples, but not necessarily 
       ;matching mode transitions, the index logic below synchronizes 
       ;iterations over the two data structures 
       dist_esa_j++
       if n_elements(*dist_esa[dist_esa_i]) eq dist_esa_j then begin
         dist_esa_i++
         dist_esa_j=0
       endif 
       
     endfor
     
     ;temporary routine bombs on some machines if out_dist is undefined, but not others
     if ~undefined(dist_out) then begin
       dist_out=array_concat(ptr_new(sst_mode_out,/no_copy),temporary(dist_out))
     endif else begin
       dist_out=array_concat(ptr_new(sst_mode_out,/no_copy),dist_out)
     endelse
   endfor
   
   dist_sst=temporary(dist_out)
   heap_gc   
   error=0

end