;+
; PROCEDURE:
;         mms_load_fpi_calc_pad
;
; PURPOSE:
;         Calculates the omni-directional pitch angle distribution (summed and averaged)
;         from the individual tplot variables
;
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-02-19 15:40:47 -0800 (Fri, 19 Feb 2016) $
;$LastChangedRevision: 20070 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_load_fpi_calc_pad.pro $
;-
pro mms_load_fpi_calc_pad, probe, autoscale = autoscale, level = level, datatype = datatype, $
    data_rate = data_rate, suffix = suffix
    if undefined(suffix) then suffix = ''
    if undefined(datatype) then begin
        dprint, dlevel = 0, 'Error, must provide a datatype to mms_load_fpi_calc_pad'
        return
    endif
    if undefined(autoscale) then autoscale = 1
    if undefined(level) then level = 'sitl'
    if undefined(data_rate) then data_rate = ''
    
    ; in case the user passes datatype = '*'
    if (datatype[0] eq '*' || datatype[0] eq '') && level eq 'ql' then datatype=['des', 'dis']
    if (datatype[0] eq '*' || datatype[0] eq '') && level ne 'ql' then datatype=['des-dist', 'dis-dist']

    species = strmid(datatype, 1, 1)
    for sidx=0, n_elements(species)-1 do begin
        spec_str_format = level eq 'sitl' ? 'PitchAngDist' : 'pitchAngDist'
        obs_str_format = level eq 'sitl' ? '_fpi_'+species[sidx] : '_d'+species[sidx]+'s_'
        spec_str_format = level eq 'l2' ? 'pitchangdist' : spec_str_format
        obsstr='mms'+STRING(probe,FORMAT='(I1)')+obs_str_format

        ; now concatenate the full variable names, based on the level
        pad_vars = level eq 'l2' ? obsstr+spec_str_format+'_'+['low', 'mid', 'high']+'en_'+data_rate+suffix : obsstr+spec_str_format+'_'+['low', 'mid', 'high']+'En'+suffix
        
        ; get the PAD from the tplot variables
        get_data, pad_vars[0], data=lowEn, dlimits=dl
        get_data, pad_vars[1], data=midEn, dlimits=dl
        get_data, pad_vars[2], data=highEn, dlimits=dl

        ; skip avg/sum when we can't find the tplot names
        if ~is_struct(lowEn) || ~is_struct(midEn) || ~is_struct(highEn) then continue

        e_PAD_sum=(lowEn.Y+midEn.Y+highEn.Y)
        e_PAD_avg=e_PAD_sum/3.0

        if is_array(e_PAD_sum) then begin
            store_data, obsstr+'PitchAngDist_sum'+suffix, data = {x:lowEn.X, y:e_PAD_sum, v:lowEn.V}, dlimits=dl
            store_data, obsstr+'PitchAngDist_avg'+suffix, data = {x:lowEn.X, y:e_PAD_avg, v:lowEn.V}, dlimits=dl
        endif

        species_str = species[sidx] eq 'e' ? 'electron' : 'ion'
        ; set the metadata for the PADs
        options, obsstr+'PitchAngDist_sum'+suffix, ytitle='MMS'+STRING(probe,FORMAT='(I1)')+'!C'+species_str+'!CPAD!Csum'
        options, obsstr+'PitchAngDist_avg'+suffix, ytitle='MMS'+STRING(probe,FORMAT='(I1)')+'!C'+species_str+'!CPAD!Cavg'
        options, obsstr+'PitchAngDist_sum'+suffix, ysubtitle='[deg]'
        options, obsstr+'PitchAngDist_avg'+suffix, ysubtitle='[deg]'
;        options, obsstr+'PitchAngDist_sum'+suffix, ztitle='Counts'
;        options, obsstr+'PitchAngDist_avg'+suffix, ztitle='Counts'
        if autoscale then zlim, obsstr+'PitchAngDist_avg'+suffix, 0, 0, 1 else $
            zlim, obsstr+'PitchAngDist_avg'+suffix, min(e_PAD_avg), max(e_PAD_avg), 1
        ylim, obsstr+'PitchAngDist_avg'+suffix, 0, 180, 0
        if autoscale then zlim, obsstr+'PitchAngDist_sum'+suffix, 0, 0, 1 else $
            zlim, obsstr+'PitchAngDist_sum'+suffix, min(e_PAD_sum), max(e_PAD_sum), 1
        ylim, obsstr+'PitchAngDist_sum'+suffix, 0, 180, 0

        if ~autoscale then zlim, obsstr+'PitchAngDist_'+['lowEn', 'midEn', 'highEn']+suffix, min(e_PAD_avg), max(e_PAD_avg), 1
    endfor
end