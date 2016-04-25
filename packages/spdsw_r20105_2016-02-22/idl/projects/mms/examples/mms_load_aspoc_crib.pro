;+
; MMS ASPOC crib sheet
; 
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-08-28 12:56:27 -0700 (Fri, 28 Aug 2015) $
; $LastChangedRevision: 18659 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_aspoc_crib.pro $
;-

;;  example  for mms1
scid='1'
;
;; load l1b  data for MMS 1   for aspoc1 and aspoc2
mms_load_aspoc, datatype='asp1', trange=['2015-07-15', '2015-07-16'], level='l1b', probe=scid
mms_load_aspoc, datatype='asp2', trange=['2015-07-15', '2015-07-16'], level='l1b', probe=scid

;; load l2  data for MMS 1    (merged data for aspoc1 and aspoc2)
mms_load_aspoc, trange=['2015-07-15', '2015-07-16'], probe=scid

;; Make tplot parameter for combined aspoc ioncurrent using l2 data
;;
join_vec, 'mms'+scid+['_asp_ionc_l2', '_asp1_ionc_l2', '_asp2_ionc_l2'], 'mms'+scid+'_asp_ionc_all'

; plot ioncurrent from aspoc1, aspoc2, and total current,  all current in one panel,  onboard processed spacecraft potential
;
tplot, 'mms'+scid+['_asp1_ionc_l2','_asp2_ionc_l2','_asp_ionc_l2','_asp_ionc_all','_asp1_spot_l1b'], trange=trange0
stop

mms_load_aspoc, datatype='asp1', trange=['2015-08-06', '2015-08-07'], level='sitl', probe=scid

tplot, '*_sitl'
stop

end