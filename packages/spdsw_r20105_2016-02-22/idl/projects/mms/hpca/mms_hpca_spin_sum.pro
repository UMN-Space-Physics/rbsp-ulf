;+
; PROCEDURE:
;         mms_hpca_spin_sum
;
; PURPOSE:
;         Calculates spin-summed fluxes for the HPCA instrument
;
; KEYWORDS:
;
; OUTPUT:
;
;
; NOTES:
;     Must have support data loaded with mms_load_hpca, /get_support_data
;        tplot variable required is: mms#_hpca_start_azimuth
;     Still under developement, egrimes, 1/29/2016
;     
;     
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-02-03 14:39:41 -0800 (Wed, 03 Feb 2016) $
;$LastChangedRevision: 19894 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/hpca/mms_hpca_spin_sum.pro $
;-

pro mms_hpca_spin_sum, probe = probe, datatype=datatype, species=species, fov=fov, tplotnames=tplotnames
    if undefined(probe) then begin
        dprint, dlevel = 0, 'Error, must provide probe # to spin-sum the HPCA data'
        return
    endif else begin
        probe = strcompress(string(probe), /rem)
    endelse
    if undefined(datatype) then datatype =['*_count_rate', '*_RF_corrected', '*_bkgd_corrected', '*_norm_counts', '*_flux']
    if undefined(species) then species = ['hplus', 'oplus', 'oplusplus', 'heplus', 'heplusplus']
    if undefined(fov) then fov = ['0', '360'] else fov = strcompress(string(fov),/rem)
    if undefined(tplotnames) then tplotnames = tnames()
    
    get_data, 'mms'+probe+'_hpca_start_azimuth', data=start_az
    
    if ~is_struct(start_az) then begin
        dprint, dlevel = 0, 'Error, couldn''t find the variable containing the start azimuth'
        return
    endif
    spin_starts = where(start_az.Y eq 0, count_starts)
    
    if count_starts eq 0 then begin
        dprint, dlevel = 0, 'Error, couldn''t identify spin starts from start_azimuth tplot variable'
        return
    endif

    for sum_idx = 0, n_elements(datatype)-1 do begin
        vars_to_sum = strmatch(tplotnames, datatype[sum_idx]+'_elev_'+fov[0]+'-'+fov[1])

        for vars_idx = 0, n_elements(vars_to_sum)-1 do begin
            if vars_to_sum[vars_idx] eq 1 then begin
                for species_idx = 0, n_elements(species)-1 do begin
                  
                  ;varname = 'mms'+probe+'_hpca_'+species[species_idx]+'_'+datatype+'_elev_'+fov[0]+'-'+fov[1]
                  varname = tplotnames[vars_idx]
                  
                  get_data, varname, data=hpca_data
        
                  if ~is_struct(hpca_data) then begin
                    dprint, dlevel = 0, 'Error, couldn''t load data from the variable: ' + varname
                    return
                  endif
        
                  spin_summed = dblarr(n_elements(spin_starts), n_elements(hpca_data.Y[0, *]))
        
                  for spin_idx = 0, n_elements(spin_starts)-2 do begin
                    spin_summed[spin_idx, *] = total(hpca_data.Y[spin_starts[spin_idx]:spin_starts[spin_idx+1]-1,*], 1, /nan, /double)
                  endfor
        
                  new_varname = varname+'_spin'
        
                  store_data, new_varname, data={x: start_az.X[spin_starts], y: spin_summed, v: hpca_data.V}
                  options, new_varname, spec=1
                  ylim, new_varname, 0, 0, 1
                  zlim, new_varname, 0, 0, 1
                endfor
            endif
        endfor
    endfor
end
