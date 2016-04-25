;+
;Procedure: WI_OR_LOAD
;
;Purpose:  Loads WIND fluxgate magnetometer data
;
;keywords:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   /VERBOSE : set to output some useful info
;Example:
;   wi_mfi_load
;Notes:
;  This routine is still in development.
; Author: Davin Larson
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2012-10-22 12:56:49 -0700 (Mon, 22 Oct 2012) $
; $LastChangedRevision: 11095 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/wind/wi_or_load.pro $
;-
pro wi_or_load,type,trange=trange,verbose=verbose,downloadonly=downloadonly, $
      varformat=varformat,datatype=datatype, $
      addmaster=addmaster,data_source=data_source,tplotnames=tn,source_options=source

if not keyword_set(datatype) then datatype = 'pre'

istp_init
if not keyword_set(source) then source = !istp

;path deprecated by changes at SPDF
;pathformat = 'wind/'+datatype+'_or/YYYY/wi_or_'+datatype+'_YYYYMMDD_v0?.cdf'
;New URL 2012/10 pcruce@igpp
pathformat = 'wind/orbit/'+datatype+'_or/YYYY/wi_or_'+datatype+'_YYYYMMDD_v0?.cdf'

if not keyword_set(varformat) then begin
   varformat = 'GSE_POS'
endif

relpathnames = file_dailynames(file_format=pathformat,trange=trange,addmaster=addmaster)

files = file_retrieve(relpathnames, _extra=source, /last_version)

if keyword_set(downloadonly) then return

prefix = 'wi_'+datatype+'_or_'
cdf2tplot,file=files,varformat=varformat,verbose=verbose,prefix=prefix ,tplotnames=tn    ; load data into tplot variables

; Set options for specific variables

dprint,dlevel=3,'tplotnames: ',tn

options,/def,tn+'',/lazy_ytitle          ; options for all quantities
options,/def,strfilter(tn,'*GSE* *GSM*',delim=' ') , colors='bgr' , labels=['X','Y','Z']    ; set colors for the vector quantities

end
