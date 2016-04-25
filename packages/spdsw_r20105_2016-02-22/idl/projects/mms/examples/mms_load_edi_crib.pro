;+
; MMS EDI crib sheet
; 
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-09-30 15:26:22 -0700 (Wed, 30 Sep 2015) $
; $LastChangedRevision: 18974 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_edi_crib.pro $
;-

timespan, '2015-09-6', 1, /day
probe = '1'

mms_load_edi, data_rate='srvy', probes=probe, datatype='efield', level='ql'

tplot, 'mms'+probe+['_edi_E_dmpa', $ electric field (computed via the "bestarg" method)
                    '_edi_E_bc_dmpa', $ ; electric field (computed via the "beam convergence" method)
                    '_edi_v_ExB_dmpa', $ ; ExB drift velocity (computed via the "bestarg" method)
                    '_edi_v_ExB_bc_dmpa'] ; ExB drift velocity (computed via the "beam convergence" method)
stop
end