;+
; PROCEDURE:
;         mms_fgm_fix_metadata
;
; PURPOSE:
;         Helper routine for setting FGM metadata
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-01-08 08:59:26 -0800 (Fri, 08 Jan 2016) $
;$LastChangedRevision: 19697 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fgm/mms_fgm_fix_metadata.pro $
;-

pro mms_fgm_fix_metadata, tplotnames, prefix = prefix, instrument = instrument, data_rate = data_rate, suffix = suffix, level=level
    if undefined(prefix) then prefix = ''
    if undefined(suffix) then suffix = ''
    if undefined(level) then level = ''
    if undefined(instrument) then instrument = 'dfg'
    if undefined(data_rate) then data_rate = 'srvy'
    instrument = strlowcase(instrument) ; just in case we get an upper case instrument
    if level eq 'l2pre' then data_rate_mod = data_rate + '_l2pre' else data_rate_mod = data_rate

    for sc_idx = 0, n_elements(prefix)-1 do begin
        for name_idx = 0, n_elements(tplotnames)-1 do begin
            tplot_name = tplotnames[name_idx]

            case tplot_name of
                prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_gse_bvec'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz']
                end
                prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_gse_btot'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [0]
                    options, /def, tplot_name, 'ytitle',  strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['B_total']
                end
                prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_dmpa_bvec'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz']
                end
                prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_dmpa_btot'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [0]
                    options, /def, tplot_name, 'ytitle',  strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['B_total']
                end
                prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_gsm_dmpa'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz', 'Btotal']
                end
                prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_dmpa'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz', 'Btotal']
                end
                prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_omb'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument) + ' OMB'
                end
                prefix[sc_idx] + '_'+instrument+'_'+data_rate_mod+'_bcs'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument) + ' BCS'
                end
                prefix[sc_idx] + '_ql_pos_gsm'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'labels', ['Xgsm', 'Ygsm', 'Zgsm', 'R']
                end
                prefix[sc_idx] + '_ql_pos_gse'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'labels', ['Xgse', 'Ygse', 'Zgse', 'R']
                end
                else: ; not doing anything
            endcase
        endfor
    endfor
end