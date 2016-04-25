;+
; PROCEDURE:
;         mms_load_fgm
;         
; PURPOSE:
;         Load MMS AFG and/or DFG data
; 
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format 
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day 
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4']. 
;                       if no probe is specified the default is probe '1'
;         level:        indicates level of data processing. fgm levels include 'l1a', 'l1b',
;                        'ql'. the default if no level is specified is 'ql'
;         datatype:     currently all data types for fgm are retrieved (datatype not specified)
;         data_rate:    instrument data rates for fgm include 'brst' 'fast' 'slow' 'srvy'. The
;                       default is 'srvy'.
;         instrument:   fgm instruments are 'dfg' and 'afg'. default value is 'dfg'
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission system 
;                       variable is !mms
;         get_support_data: not yet implemented. when set this routine will load any support data
;                       (support data is specified in the CDF file)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're using 
;                       this load routine from a terminal without an X server runningdo not set colors
;         time_clip:    clip the data to the requested time range; note that if you do not use 
;                       this keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer data is 
;                       found the existing data will be overwritten
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         varformat:    should be a string (wildcards accepted) that will match the CDF variables
;                       that should be loaded into tplot variables
;         cdf_filenames:  this keyword returns the names of the CDF files used when loading the data
;             
; OUTPUT:
; 
; EXAMPLE:
;     For examples see crib sheets mms_load_fgm_crib.pro, and mms_load_fgm_brst_crib.pro
;     
;     load MMS AFG burst data for MMS 1
;     MMS>  mms_load_fgm, probes=['1'], instrument='afg', data_rate='brst', level='ql'
;     
;     load MMS QL DFG data for MMS 1 and MMS 2
;     MMS>  mms_load_dfg, probes=[1, 2], trange=['2015-06-22', '2015-06-23'], level='ql'
;
; NOTES:
;     1) See the notes in mms_load_data for rules on the use of MMS data
;     
;     2) This routine is meant to be called from mms_load_afg and mms_load_dfg
;     
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-02-12 11:21:57 -0800 (Fri, 12 Feb 2016) $
;$LastChangedRevision: 19973 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fgm/mms_load_fgm.pro $
;-


pro mms_load_fgm, trange = trange, probes = probes, datatype = datatype, $
                  level = level, instrument = instrument, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update, suffix = suffix, $
                  no_attitude_data = no_attitude_data, varformat = varformat, $
                  cdf_filenames = cdf_filenames, cdf_version = cdf_version, $
                  latest_version = latest_version, min_version = min_version
    
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    probes = strcompress(string(probes), /rem) ; force the array to be an array of strings
    if undefined(datatype) then datatype = '' ; grab all data in the CDF
    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    ; default to QL if the trange is within the last 2 weeks, L2pre if older
    if undefined(level) then begin 
        fourteen_days_ago = systime(/seconds)-60*60*24.*14.
        if trange[1] ge fourteen_days_ago then level = 'ql' else level = 'l2pre'
    endif else level = strlowcase(level)
    if undefined(instrument) then begin
        dprint, dlevel = 0, 'Error, must provide an instrument (currently afg or dfg) to mms_load_fgm'
        return
    endif
    if undefined(data_rate) then data_rate = 'srvy'
    if undefined(suffix) then suffix = ''

    mms_load_data, trange = trange, probes = probes, level = level, instrument = instrument, $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, tplotnames = tplotnames, $
        no_color_setup = no_color_setup, time_clip = time_clip, no_update = no_update, $
        suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
        cdf_version = cdf_version, latest_version = latest_version, min_version = min_version

    
    ; load the atttude data to do the coordinate transformation 
    if undefined(no_attitude_data) && level ne 'l2pre' then begin
      mms_load_state, trange = trange, probes = probes, level = 'def', /attitude_only, suffix = suffix
    endif
    ; Note: not all MEC files have right ascension and declination data, commented out until LANL reprocesses
  ;  if undefined(no_attitude_data) && level ne 'l2pre' then mms_load_mec, trange = trange, probes = probes, suffix = suffix

    ; DMPA coordinates to GSE, for each probe
    for probe_idx = 0, n_elements(probes)-1 do begin
        this_probe = 'mms'+strcompress(string(probes[probe_idx]), /rem)
        ; make sure the attitude data has been loaded before doing the cotrans operation
        if tnames(this_probe+'_defatt_spinras'+suffix) ne '' && tnames(this_probe+'_defatt_spindec'+suffix) ne '' $
            && tnames(this_probe+'_'+instrument+'_'+data_rate+'_dmpa'+suffix) ne '' $
            && undefined(no_attitude_data) && level ne 'l2pre' then begin 

            dmpa2gse, this_probe+'_'+instrument+'_'+data_rate+'_dmpa'+suffix, this_probe+'_defatt_spinras'+suffix, $
                this_probe+'_defatt_spindec'+suffix, this_probe+'_'+instrument+'_'+data_rate+'_gse'+suffix, /ignore_dlimits
            append_array, tplotnames, this_probe+'_'+instrument+'_'+data_rate+'_gse'+suffix
            
        endif
        ; split the FGM data into 2 tplot variables, one containing the vector and one containing the magnitude
        mms_split_fgm_data, this_probe, instrument=instrument, tplotnames = tplotnames, suffix = suffix, level = level, data_rate = data_rate
    endfor

    
    ; set some of the metadata for the DFG/AFG instruments
    mms_fgm_fix_metadata, tplotnames, prefix = 'mms' + probes, instrument = instrument, data_rate = data_rate, suffix = suffix, level=level

end