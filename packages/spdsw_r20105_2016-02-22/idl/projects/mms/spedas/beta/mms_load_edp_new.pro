;+
; PROCEDURE:
;         mms_load_edp
;
; PURPOSE:
;         Load data from the EDP (Electric field Double Probes) instrument
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4'].
;                       if no probe is specified the default is probe '1'
;         level:        indicates level of data processing. Current levels include: 
;                       ['l1a', 'l1b', 'l2', 'ql', 'sitl']
;         datatype:     data types include currently include  ['dce', 'dcv', 'ace', 'hmfe']; default is all
;         data_rate:    instrument data rates include ['brst', 'fast', 'slow', 'srvy']. 
;                       the default is 'fast'
;         local_data_dir: local directory to store the CDF files; should be set if you're on
;                       *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission 
;                       system variable is !mms
;         get_support_data: not yet implemented. when set this routine will load any 
;                       support data (support data is specified in the CDF file)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're 
;                       using this load routine from a terminal without an X server running
;                       do not set colors
;         time_clip:    clip the data to the requested time range; note that if you do not 
;                       use this keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer 
;                       data is found the existing data will be overwritten
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         varformat:    should be a string (wildcards accepted) that will match the CDF variables
;                       that should be loaded into tplot variables
;
; OUTPUT:
;
; EXAMPLE:
;     See crib sheet mms_load_edp_crib.pro for usage examples.
;     
;    set the time frame
;    MMS1> timespan, '2015-08-15', 1, /day
;    load quicklook edp dce data for all probes
;    MMS1> mms_load_edp, data_rate='slow', probes=[1, 2, 3, 4], datatype='dce', level='ql'
;
; HISTORY:
;   - Created by Matthew Argall @UNH
;   - Minor updates to defaults by egrimes@igpp
;    
;$LastChangedBy:  $
;$LastChangedDate:  $
;$LastChangedRevision:  $
;$URL:  $
;-
pro mms_load_edp_new, trange = trange, probes = probes, datatype = datatype, $
    level = level, data_rate = data_rate, $
    local_data_dir = local_data_dir, source = source, $
    get_support_data = get_support_data, $
    tplotnames = tplotnames, no_color_setup = no_color_setup, $
    time_clip = time_clip, no_update = no_update, suffix = suffix, $
    varformat = varformat

    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = [1, 2, 3, 4] 
    if undefined(datatype) then datatype = ['dce', 'dcv', 'ace', 'hmfe']
    if undefined(level) then level = ['l1a', 'l1b', 'l2', 'ql', 'sitl']
    if undefined(suffix) then suffix = ''
    if undefined(data_rate) then data_rate = 'fast'

    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'edp', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update, suffix = suffix, varformat = varformat
end