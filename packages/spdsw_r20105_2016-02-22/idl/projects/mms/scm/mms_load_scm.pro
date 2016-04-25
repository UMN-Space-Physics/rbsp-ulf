;+
; PROCEDURE:
;         mms_load_scm
;         
; PURPOSE:
;         Load data from the MMS Search Coil Magnetometer (SCM)
; 
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format 
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day 
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss'] 
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4']. If 
;                       no probe is specified the default is '1'
;         level:        indicates level of data processing. scm levels include 'l1a', 'l1b', 
;                       'l2'. The default if no level is specified is 'l1b'
;         datatype:     scm data types include ['cal', 'scb', 'scf', 'schb', 'scm', 'scs'].
;                       If no value is given the default is scf.
;         data_rate:    instrument data rates for MMS scm include 'brst' 'fast' 'slow' 'srvy'. 
;                       The default is 'fast'. 
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission system 
;                       ariable is !mms
;         get_support_data: not yet implemented. when set this routine will load any support data 
;                       (support data is specified in the CDF file)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're 
;                       using this load
;                       routine from a terminal without an X server runningdo not set colors
;         time_clip:    clip the data to the requested time range; note that if you do not use 
;                       this keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer data 
;                       is found the existing data will be overwritten 
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         varformat:    should be a string (wildcards accepted) that will match the CDF variables
;                       that should be loaded into tplot variables
;         cdf_filenames:  this keyword returns the names of the CDF files used when loading the data
; 
; OUTPUT:
; 
; EXAMPLE:
;     load scm burst data
;     MMS> mms_load_scm, trange=['2015-09-13',2015-09-14'], probes='1', level='l1b', $
;                    data_rate='brst', datatype='scb'
;
;     set time span and load probes 1 and 2 survey data
;     timespan, '2015-09-13', 1d
;     MMS> mms_load_scm, probes=['1','2'], level='l1b', data_rate='srvy', datatype='scm'
;
;     get list of valid scm rates, levels, and datatypes
;     MMS> mms_load_options, 'scm', rate=r, level=l, datatype=dt 
;     
;     See crib sheet mms_load_scm_crib.pro for more detailed usage examples
;     
; NOTES:
;     Please see the notes in mms_load_data for more information 
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-01-29 11:47:45 -0800 (Fri, 29 Jan 2016) $
;$LastChangedRevision: 19843 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/scm/mms_load_scm.pro $
;-
pro mms_set_scm_options, tplotnames, prefix = prefix,datatype = datatype, coord=coord
    if undefined(prefix) then prefix = ''

    for sc_idx = 0, n_elements(prefix)-1 do begin
        for name_idx = 0, n_elements(tplotnames)-1 do begin
            tplot_name = tplotnames[name_idx]
            
            case tplot_name of
                prefix[sc_idx] + '_scm_'+datatype+'_'+coord : begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) +' '+ datatype +' ('+coord+')' ;' SCM'
                    options, /def, tplot_name, 'labels', ['1', '2', '3']
                    
                end
                else: ; not doing anything
            endcase
        endfor
    endfor

end

pro mms_load_scm, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, tplotnames = tplotnames, $
                  no_color_setup = no_color_setup, time_clip = time_clip, $
                  no_update = no_update, suffix = suffix, varformat = varformat, $
                  cdf_filenames = cdf_filenames, cdf_version = cdf_version, $
                  latest_version = latest_version, min_version = min_version
                  
    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'scf' 
    if undefined(level) then level = 'l1b' 
    if undefined(data_rate) then data_rate = 'fast'
      
    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'scm', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, tplotnames = tplotnames, $
        no_color_setup = no_color_setup, time_clip = time_clip, no_update = no_update, $
        suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
        cdf_version = cdf_version, latest_version = latest_version, min_version = min_version
    
    if level eq 'l1a' then coord = '123'
    if level eq 'l1b' then coord = 'scm123'
    if level eq 'l2'  then coord = 'gse'
    
    mms_set_scm_options, tplotnames, prefix = 'mms' + probes,datatype = datatype, coord=coord
end