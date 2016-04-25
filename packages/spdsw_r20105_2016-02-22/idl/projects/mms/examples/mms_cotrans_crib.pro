;+
;Procedure:
;  mms_cotrans_crib
;
;Purpose:
;  Demonstrate usage of mms_cotrans.
;
;Notes:
;  
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-12-22 15:41:47 -0800 (Tue, 22 Dec 2015) $
;$LastChangedRevision: 19648 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_cotrans_crib.pro $
;-


;------------------------------------------------------
;  Supported coordinate systems:
;    -DMPA
;    -DSL  (currently treated as identical to DMPA)
;    -GSE
;    -GSM
;    -AGSM
;    -SM
;    -GEI
;    -J2000
;    -GEO
;    -MAG
;----------------------------------------------------



;setup
probe = '1'
level = 'ql'

timespan, '2015-12-01/01', 2, /hour
trange = timerange()

window, xs=900, ys=900


; load data
mms_load_dfg, probe=probe, trange=trange, level=level
mms_load_fpi, probe=probe, trange=trange, level=level, datatype='dis'


; load support data for transformations
mms_load_mec, probe=probe, trange=trange


; example variables to be transformed
v_name = 'mms'+probe+'_dis_bulk'
b_name = 'mms'+probe+'_dfg_srvy_dmpa_bvec'


; join components of velocity into single 3-vector
join_vec, v_name+['X','Y','Z'], v_name


; fix labels
options, b_name, labels='B'+['x','y','z']
options, v_name, labels='V'+['x','y','z']


; transform to GSE
;   -in_coord and ignore_dlimits keywords will be necessary until 
;    the metadata's coordinates are populated from the CDF
mms_cotrans, [v_name,b_name], out_coord='gse', out_suffix='_gse', $
             in_coord='dmpa', /ignore_dlimits



tplot, [v_name, v_name, b_name, b_name] + ['','_gse','','_gse']



stop ;------------------------------------------------------------



; transform to SM
;   -in_coord and ignore_dlimits keywords will be necessary until 
;    the metadata's coordinates are populated from the CDF
mms_cotrans, [v_name,b_name], out_coord='sm', out_suffix='_sm', $
             in_coord='dmpa', /ignore_dlimits

tplot, [v_name, v_name, b_name, b_name] + ['','_sm','','_sm']



stop ;------------------------------------------------------------


; use IN_SUFFIX keyword to replace the current suffix
;   -transformed variables will have correct metadata
mms_cotrans, b_name, out_coord='gsm', in_suffix='_sm', out_suffix='_gsm'

tplot, b_name + ['','_sm','_gsm']



stop ;------------------------------------------------------------



; in/out coordinates can be set implicitly with suffix keywords
mms_cotrans, v_name, in_suffix='_sm', out_suffix='_gsm'

tplot, v_name + ['','_sm','_gsm']


end