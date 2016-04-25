;+
; PROCEDURE:
;         mms_hpca_calc_anodes
;
; PURPOSE:
;         Sums over anodes (or a given field of view) for HPCA ion data
;
; KEYWORDS:
;         tplotnames: names of tplot variables to pick the HPCA 
;             ion spectra out of; will use tnames() if this is not set
;         fov: field of view to sum over
;         anodes: anodes to sum over (can not be set at the same time as fov)
;         probe: MMS probe # 
;
; OUTPUT:
;
;
; EXAMPLE:
;
; NOTES:
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-01-27 12:46:35 -0800 (Wed, 27 Jan 2016) $
;$LastChangedRevision: 19821 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/hpca/mms_hpca_calc_anodes.pro $
;-
function mms_hpca_elevations
    anode_theta = [123.75000, 101.25000, 78.750000, 56.250000, 33.750000, $
        11.250000, 11.250000, 33.750000, 56.250000, 78.750000, $
        101.25000, 123.75000, 146.25000, 168.75000, 168.75000, $
        146.25000]
    anode_theta[6:13] += 180.
    return, anode_theta
end

function mms_hpca_anodes, fov = fov
    if undefined(fov) then begin
        dprint, dlevel = 0, 'Error, must give a field of view'
        return, -1
    endif

    anodes = mms_hpca_elevations()

    fov_tmp = float(fov)
    anodes_in_fov = where(anodes ge fov_tmp[0] and anodes le fov_tmp[1], anode_count)
    return, anodes_in_fov
end


function mms_hpca_energies
    return, [1.35500, 1.57180, 1.84280, 2.22220, 2.60160, 3.08940, 3.63140, 4.28180, $
        5.04060, 5.96200, 6.99180, 8.23840, 9.75600, 11.4904, 13.5500, 15.9890, $
        18.8616, 22.2762, 26.2328, 30.9482, 36.5308, 43.0890, 50.7854, 59.9452, $
        70.6768, 83.4138, 98.3730, 116.042, 136.855, 161.462, 190.459, 224.659, $
        264.984, 312.571, 368.723, 434.955, 513.057, 605.197, 713.868, 842.051, $
        993.323, 1171.70, 1382.10, 1630.28, 1923.07, 2268.43, 2675.80, 3156.28, $
        3723.11, 4391.72, 5180.44, 6110.72, 7208.11, 8502.57, 10029.5, 11830.6, $
        13955.2, 16461.4, 19417.5, 22904.6, 27017.9, 31869.8, 37593.1]
end

; Input:
;       data_struct: structure containing: {x: times, y: flux}
;
; Keywords:
;       fov: field of view
;
;
; averages over elevation angles inside the field of view
;
; output:
;   structure containing {x: times, y: flux, v: energies}
function mms_hpca_avg_fov, data_struct, fov = fov, anodes = anodes
    if ~is_struct(data_struct) then begin
        dprint, dlevel = 0, 'Error - invalid structure.'
        return, -1
    endif
    if ~undefined(fov) and ~undefined(anodes) then begin
        dprint, dlevel = 0, 'Error, should only specify a field of view (fov) or list of anodes, but not both.'
        return, -1
    endif
    if undefined(fov) and undefined(anodes) then begin
        dprint, dlevel = 0, 'Error, must specify either field of view or a list of anodes'
        return, -1
    endif
    if undefined(fov) then anodes_in_fov = anodes else anodes_in_fov = mms_hpca_anodes(fov=fov)

    times = data_struct.X

    ;anode_elevation = mms_hpca_elevations()
    energies = mms_hpca_energies()

    data_within_fov = data_struct.Y[*,*,anodes_in_fov]
    
    if n_elements(anodes_in_fov) eq 1 then data_total = reform(data_within_fov) else data_total = total(data_within_fov, 3, /nan)

    data_mean = dblarr(n_elements(times), n_elements(energies))
    data_mean = average(data_within_fov, 3, /nan)

    data_mean(where(data_mean eq 0.)) = !VALUES.F_NAN
    return, {x: times, y: data_mean, v: energies}
end

; Input:
;       data_struct: structure containing: {x: times, y: flux}
;
; Keywords:
;       fov: field of view
;
;
; sums over elevation angles inside the field of view
;
; output:
;   structure containing {x: times, y: flux, v: energies}

function mms_hpca_sum_fov, data_struct, fov = fov, anodes = anodes
    if ~is_struct(data_struct) then begin
        dprint, dlevel = 0, 'Error - invalid structure.'
        return, -1
    endif
    if ~undefined(fov) and ~undefined(anodes) then begin
        dprint, dlevel = 0, 'Error, should only specify a field of view (fov) or list of anodes, but not both.'
        return, -1
    endif
    if undefined(fov) and undefined(anodes) then begin
        dprint, dlevel = 0, 'Error, must specify either field of view or a list of anodes'
        return, -1
    endif
    if undefined(fov) then anodes_in_fov = anodes else anodes_in_fov = mms_hpca_anodes(fov=fov)
    times = data_struct.X

    ;anode_elevation = mms_hpca_elevations()
    energies = mms_hpca_energies()

    data_within_fov = data_struct.Y[*,*,anodes_in_fov]

    data_total = dblarr(n_elements(times), n_elements(energies))
    if n_elements(anodes_in_fov) eq 1 then data_total = reform(data_within_fov) else data_total = total(data_within_fov, 3, /nan)

    data_total(where(data_total eq 0.)) = !VALUES.F_NAN
    return, {x: times, y: data_total, v: energies}
end

pro mms_hpca_calc_anodes, tplotnames=tplotnames, fov=fov, probe=probe, anodes = anodes, suffix = suffix
    
    if ~undefined(fov) and ~undefined(anodes) then begin
        dprint, dlevel = 0, 'Error, should only specify a field of view (fov) or list of anodes, but not both.'
        return
    endif
    if undefined(fov) and undefined(anodes) then begin
        dprint, dlevel = 0, 'Error, must specify either field of view or a list of anodes'
        return
    endif
    if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
    if undefined(tplotnames) then tplotnames = tnames()
    if undefined(suffix) then suffix = ''
    sum_anodes = ['*_count_rate', '*_RF_corrected', '*_bkgd_corrected', '*_norm_counts']+suffix

    if ~undefined(fov) then begin
        fov_str = strcompress('_elev_'+string(fov[0])+'-'+string(fov[1]), /rem)
    endif else fov_str = '_anodes_' + strjoin(strcompress(string(anodes), /rem), '_')

    ;avg_anodes = ['*_flux', '*_vel_dist_fn']
    ; removed velocity distribution from above because
    ; we need the full (non-avg'd) data for 2d slices
    avg_anodes = ['*_flux']+suffix

    for sum_idx = 0, n_elements(sum_anodes)-1 do begin
        vars_to_sum = strmatch(tplotnames, sum_anodes[sum_idx])

        for vars_idx = 0, n_elements(vars_to_sum)-1 do begin

            if vars_to_sum[vars_idx] eq 1 then begin
                get_data, tplotnames[vars_idx], data=var_data, dlimits=var_dl, limits=var_l
                if is_struct(var_data) then begin
                    updated_spectra = mms_hpca_sum_fov(var_data, fov=fov, anodes=anodes)
                    store_data, tplotnames[vars_idx]+fov_str, data=updated_spectra, dlimits=var_dl, limits=var_l
                    append_array, tplotnames, tplotnames[vars_idx]+fov_str
                    options, tplotnames[vars_idx]+fov_str, spec=1
                endif
            endif
        endfor
    endfor

    for avg_idx = 0, n_elements(avg_anodes)-1 do begin
        vars_to_avg = strmatch(tplotnames, avg_anodes[avg_idx])
        for vars_idx = 0, n_elements(vars_to_avg)-1 do begin
            if vars_to_avg[vars_idx] eq 1 then begin
                get_data, tplotnames[vars_idx], data=var_data, dlimits=var_dl, limits=var_l
                if is_struct(var_data) then begin
                    updated_spectra = mms_hpca_avg_fov(var_data, fov=fov, anodes=anodes)
                    store_data, tplotnames[vars_idx]+fov_str, data=updated_spectra, dlimits=var_dl, limits=var_l
                    append_array, tplotnames, tplotnames[vars_idx]+fov_str
                    options, tplotnames[vars_idx]+fov_str, spec=1
                endif
            endif
        endfor
    endfor
   
    mms_hpca_set_metadata, tplotnames, prefix = 'mms'+probe, fov = fov, anodes = anodes, suffix = suffix+fov_str

end