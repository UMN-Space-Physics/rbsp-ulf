;+
; FUNCTION:
;       mvn_ngi_remote_list
; PURPOSE:
;       returns url lists of NGIMS L2 files in the server without downloading them
; CALLING SEQUENCE:
;       urls = mvn_ngi_remote_list(filetype='csn',latestversion=v,latestrevision=r)
; INPUTS:
;       None
; KEYWORDS:
;       trange: time range (if not present then timerange() is called)  
;       filetype: 'csn', 'cso', or 'ion' (Def: all) 
;       latestversion: returns the latest version number in string
;       latestrevision: returns the latest revision number in string
; CREATED BY:
;       Yuki Harada on 2015-07-13
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2015-09-17 10:20:42 -0700 (Thu, 17 Sep 2015) $
; $LastChangedRevision: 18815 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/ngi/mvn_ngi_remote_list.pro $
;-

function mvn_ngi_remote_list, trange=trange, filetype=filetype, verbose=verbose, _extra=_extra, latestversion=version, latestrevision=revision

  if ~keyword_set(filetype) then filetype = '???'
  dprint,verbose=verbose,'checking ngi remote file list: '+filetype

  pformat = 'maven/data/sci/ngi/l2/YYYY/MM/mvn_ngi_l2_'+filetype+'-abund-*_YYYYMMDD?hh????_v??_r??.csv'

  res = 3600L & sres = 0L       ;- hourly check
  tr = timerange(trange)
  str = (tr-sres)/res
  dtr = (ceil(str[1]) - floor(str[0]) )  > 1
  times = res * (floor(str[0]) + lindgen(dtr))+sres
  pathnames = time_string(times,tformat=pformat)
  pathnames = pathnames[uniq(pathnames)]
  s = mvn_file_source(no_download=2,last_version=0,_extra=_extra)

  f = ''
  if s.no_server eq 0 then begin
     for ipn=0,n_elements(pathnames)-1 do begin
        file_http_copy,pathnames[ipn],serverdir=s.remote_data_dir,localdir=s.local_data_dir,url_info=url_info,verbose=verbose,_extra=s
        w = where( url_info.exists ne 0 , nw )
        if nw gt 0 then f = [f,url_info[w].url]
     endfor
  endif else f = file_retrieve(pathnames,_extra=s,/valid_only)
  w = where( strlen(f) gt 0 , nw )
  if nw eq 0 then urls = '' else urls = f[w]

  vidx = strpos(f,'_v')
  w = where( vidx ne -1 , nw )
  if nw gt 0 then version = string(max(fix(strmid(f[w],vidx[w]+2,2))),f='(i2.2)') else version='' ;- latest version
  w = where( strmatch(f,'*_v'+version+'*') , nw )
  if nw gt 0 then f = f[w]      ;- only latest version files
  ridx = strpos(f,'_r')
  w = where( ridx ne -1 , nw )
  if nw gt 0 then revision = string(max(fix(strmid(f[w],ridx[w]+2,2))),f='(i2.2)') else revision='' ;- latest revision

  return,urls

end
