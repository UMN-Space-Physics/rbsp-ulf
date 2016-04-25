;+
;
;NAME:
;iug_load_meteor_rish_txt
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for the horizontal wind data (uwnd, vwnd, uwndsig, vwndsig, mwnum)
;  in the text format taken by the meteor wind radar (MWR) at Kototabang and Serpong and loads data into
;  tplot format.
;
;SYNTAX:
; iug_load_meteor_rish, datatype = datatype, site=site, parameters = parameters, $
;                       downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS:
; datatype = Observation data type. For example, iug_load_meteor_rish_txt, datatype = 'thermosphere'.
;            The default is 'thermosphere'. 
;   site  = Observatory code name.  For example, iug_load_meteor_rish_txt, site = 'ktb'.
;           The default is 'all', i.e., load all available stations.
; parameters = Data parameter. For example, iug_load_meteor_rish_txt, parameter = 'h2t60min00'. 
;             A kind of parameters is 5 types of 'h2t60min00', 'h2t60min30', 'h4t60min00', 'h4t60min00', 'h4t240min00'.
;             The default is 'h2t60min00'. 
;  trange = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;
;CODE:
; A. Shinbori, 09/19/2010.
;
;MODIFICATIONS:
; A. Shinbori, 03/24/2011.
;
;ACKNOWLEDGEMENT:
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-04-30 15:28:49 -0700 (Thu, 30 Apr 2015) $
; $LastChangedRevision: 17458 $
; $URL $
;-


pro iug_load_meteor_rish_txt, datatype = datatype, site=site, parameter = parameter, $
                           downloadonly=downloadonly, trange=trange, verbose=verbose



;**************
;keyword check:
;**************
if (not keyword_set(verbose)) then verbose=2
 
;************************************
;Load 'thermosphere' data by default:
;************************************
if (not keyword_set(datatype)) then datatype='thermosphere'

;****************
;Parameter check:
;****************
if (not keyword_set(parameter)) then parameter='h2t60min00'

print, parameter
;***********
;site codes:
;***********
;--- all sites (default)
site_code_all = strsplit('ktb srp',' ', /extract)

;--- check site codes
if(not keyword_set(site)) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)

print, site_code

for i=0, n_elements(site_code)-1 do begin
  if (site_code[i] eq 'ktb') && (parameter ne 'h4t240min00') then iug_load_meteor_ktb_txt, datatype = datatype, parameter = parameter, $
                                                        downloadonly=downloadonly, trange=trange, verbose=verbose
  if site_code[i] eq 'srp' then iug_load_meteor_srp_txt, datatype = datatype, parameter = parameter, $
                                                        downloadonly=downloadonly, trange=trange, verbose=verbose
endfor

end
