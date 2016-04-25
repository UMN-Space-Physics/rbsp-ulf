;+
; PROCEDURE:
;         mms_load_hpca
;         
; PURPOSE:
;         Load data from the MMS Hot Plasma Composition Analyzer (HPCA)
; 
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format 
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day 
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4']. 
;                       If no probe is specified the default is '1'
;         level:        indicates level of data processing. levels include 'l1b', 'sitl'. 
;                       the default if no level is specified is 'l1b'.
;         datatype:     data types include 
;                       ['bkgd_corr', 'count_rate', 'flux', 'moments', 'rf_corr', 'vel_dist'].
;                       if no value is given the default is 'rf_corr'.
;         data_rate:    instrument data rates include 'brst' 'srvy'. the default is 'srvy'.
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         varformat:    format of the variable names in the CDF to load. the default 
;                       varformat is '*_RF_corrected'
;         source:       specifies a different system variable. By default the MMS mission system 
;                       variable is !mms
;         get_support_data: not yet implemented. when set this routine will load any support data
;                       (support data is specified in the CDF file)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're using this 
;                       load routine from a terminal without an X server runningdo not set colors
;         time_clip:    clip the data to the requested time range; note that if you do not use this 
;                       keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer data is 
;                       found the existing data will be overwritten
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         cdf_filenames:  this keyword returns the names of the CDF files used when loading the data
; 
; OUTPUT:
; 
; EXAMPLE:
;     See crib sheet routines mms_load_hpca_crib, mms_load_hpca_brst_crib, and mms_load_hpca_crib_qlplots
;     for usage examples
;    
;     load hpca data examples (burst mode)
;     MMS>  mms_load_hpca, probes='1',  trange=['2015-09-03', '2015-09-04'], $
;             datatype='moments', data_rate='brst'
;     MMS>  mms_load_hpca, probes='1', trange=['2015-09-03', '2015-09-04'], $
;             datatype='rf_corr', data_rate='brst'
;
;     MMS>  mms_hpca_calc_anodes, fov=[0, 360] ; sum over the full field of view (FoV)
;     MMS>  tplot, 'mms1_hpca_hplus_RF_corrected_elev_0-360' ; plot the H+ spectra (full FoV)
;             
;
; 
; NOTES:
;     When loading HPCA energy spectra with this routine, all of the data are loaded in 
;        initially. To plot a meaningful spectra, the user must call mms_hpca_calc_anodes
;        to sum the data over the look directions for the instrument. This will append
;        the field of view (or anodes) used in the calculation to the name of the tplot variable.
;        See the example above, or in the crib sheets. 
; 
;     Please see the notes in mms_load_data for more information 
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-02-09 18:22:59 -0800 (Tue, 09 Feb 2016) $
;$LastChangedRevision: 19925 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/hpca/mms_load_hpca.pro $
;-

pro mms_load_hpca, trange = trange_in, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, varformat = varformat, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update, suffix = suffix, $
                  cdf_filenames = cdf_filenames, cdf_version = cdf_version, $
                  latest_version = latest_version, min_version = min_version
                
    if undefined(trange_in) then trange = timerange() else trange = timerange(trange_in)
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'ion'
    if undefined(level) then level = 'l1b' 
    if undefined(data_rate) then data_rate = 'srvy'
    if undefined(suffix) then suffix=''
    if undefined(varformat) then begin
        ;convert "datatypes" to actual datatype and varformat
        if n_elements(level) eq 1 && strlowcase(level) ne 'l1a' then begin
            ; allow for the following datatypes:
            ; count_rate, flux, vel_dist, rf_corr, bkgd_corr
            case datatype of 
                'ion': varformat = '*_RF_corrected'
                'rf_corr': varformat = '*_RF_corrected'
                'count_rate': varformat = '*_count_rate'
                'flux': varformat = '*_flux'
                'vel_dist': varformat = '*_vel_dist_fn'
                'bkgd_corr': varformat = '*_bkgd_corrected'
                'moments': varformat = '*'
                else: varformat = '*_RF_corrected'
            endcase
            if ~undefined(varformat) && varformat ne '*' then datatype = 'ion'
        endif
    endif
    ;if level eq 'sitl' then varformat = '*'
    
    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'hpca', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, varformat = varformat, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update, suffix = suffix, cdf_filenames = cdf_filenames, $
        cdf_version = cdf_version, latest_version = latest_version, min_version = min_version
    
    if undefined(tplotnames) then return
    
    ; if the user requested HPCA ion data, need to:
    ; 1) sum over anodes for normalized counts, count rate, 
    ;    RF and background corrected count rates
    ; 2) average over anodes for flux, velocity distributions
    ;if datatype eq 'ion' then mms_hpca_calc_anodes, tplotnames=tplotnames, fov=fov, probes=probes

    for probe_idx = 0, n_elements(probes)-1 do mms_hpca_set_metadata, tplotnames, prefix = 'mms'+probes[probe_idx], suffix=suffix
end