;+
;PROCEDURE:	load_wi_sfsp_3dp
;PURPOSE:
;   loads WIND 3D Plasma Experiment key parameter data for "tplot".
;
;INPUTS:
;  none, but will call "timespan" if time_range is not already set.
;KEYWORDS:
;  DATA:        Raw data can be returned through this named variable.
;  NVDATA:	Raw non-varying data can be returned through this variable.
;  TIME_RANGE:  2 element vector specifying the time range.
;  MASTERFILE:  (string) full file name to the master file.
;  RESOLUTION:  number of seconds resolution to return.
;  PREFIX:	Prefix for TPLOT variables created.  Default is 'sfsp'
;SEE ALSO:
;  "make_cdf_index","loadcdf","loadcdfstr","loadallcdf"
;
;CREATED BY:	Davin Larson
; $LastChangedBy: davin-win $
; $LastChangedDate: 2009-07-02 12:11:10 -0700 (Thu, 02 Jul 2009) $
; $LastChangedRevision: 6380 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/key_param/load_wi_sfsp_3dp.pro $
;-
pro load_wi_sfsp_3dp $
   ,time_range=trange $
   ,resolution=res $
   ,median = med $
   ,data=d $
   ,nvdata = nd $
   ,masterfile=masterfile $
   ,prefix = prefix

if not keyword_set(masterfile) then masterfile = 'wi_sfsp_3dp_files'

if not keyword_set(source) then begin
   wind_init
   source = !wind
endif
file_format = 'wind/3dp/sfsp/YYYY/wi_sfsp_3dp_YYYYMMDD_v01.cdf'
pathnames = file_dailynames(file_format=file_format,trange=trange)
filenames = file_retrieve(pathnames,_extra=source,/last_version)


cdfnames = ['FLUX',  'ENERGY' ]

d=0
loadallcdf,filenames=filenames,masterfile=masterfile,cdfnames=cdfnames,data=d, $
   novarnames=novarnames,novard=nd,time_range=trange,resolu=res,median=med
if not keyword_set(d) then return


if size(/type,prefix) eq 7 then px=prefix else px = 'sfsp'


evals = round(d(0).energy/1000.)
elab = strtrim(string(evals)+' keV',2)
elabpos=[ 1e-4, 4.2e-05,  1.3e-05,  5.7e-06,  2.5e-06,  8.4e-07, 1.3e-07]

store_data,px,data={x:d.time,y:dimen_shift(d.flux,1),v:dimen_shift(d.energy,1)}$
  ,min=-1e30,dlim={ylog:1,labels:elab,labpos:elabpos}



end
