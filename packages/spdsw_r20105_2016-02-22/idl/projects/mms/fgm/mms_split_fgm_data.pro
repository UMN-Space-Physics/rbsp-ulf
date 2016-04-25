;+
; PROCEDURE:
;         mms_split_fgm_data
;
; PURPOSE:
;         Helper routine for splitting 4-vector FGM data (Bx, By, Bz, b_total)
;         into 2 tplot variables, one for the vector (Bx, By, Bz), and one for the total 
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-12-10 14:14:24 -0800 (Thu, 10 Dec 2015) $
;$LastChangedRevision: 19585 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fgm/mms_split_fgm_data.pro $
;-
pro mms_split_fgm_data, probe, tplotnames = tplotnames, suffix = suffix, level = level, data_rate = data_rate, instrument = instrument
    if undefined(level) then level = ''
    if undefined(suffix) then suffix = ''
    if level eq 'l2pre' then data_rate_mod = data_rate + '_l2pre' else data_rate_mod = data_rate
    coords = ['dmpa', 'gse', 'gsm']

    for c_idx = 0, n_elements(coords)-1 do begin
        ; assumption here: tplot names loaded from FGM CDFs are in lower case
        tplot_name = strlowcase(probe + '_'+instrument+'_'+data_rate_mod+'_'+coords[c_idx])+suffix

        get_data, tplot_name, data=fgm_data, dlimits=fgm_dlimits

        if is_struct(fgm_data) && is_struct(fgm_dlimits) then begin

            ; strip suffix off tplot_name. this prevents suffix from occuring twice in tplot variable name
            if suffix NE '' then tplot_name=strmid(tplot_name, 0, strpos(tplot_name, suffix))
            store_data, tplot_name + '_bvec'+suffix, data={x: fgm_data.X, y: [[fgm_data.Y[*, 0]], [fgm_data.Y[*, 1]], [fgm_data.Y[*, 2]]]}, dlimits=fgm_dlimits
            store_data, tplot_name + '_btot'+suffix, data={x: fgm_data.X, y: fgm_data.Y[*, 3]}, dlimits=fgm_dlimits

            ; need to add the newly created variables from the previous procedure to the list of tplot names
            append_array, tplotnames, tplot_name + '_bvec'+suffix
            append_array, tplotnames, tplot_name + '_btot'+suffix

            ; uncomment the following to remove the old variable
            ; del_data, tplot_name+suffix
            ; tplotnames = ssl_set_complement([tplot_name+suffix], tplotnames)
        endif else begin
            dprint, dlevel = 0, 'Error splitting the tplot variable: ', tplot_name+suffix
        endelse
    endfor
end