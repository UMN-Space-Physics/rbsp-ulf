;+
;NAME:
;fa_esa_l2_crib
;PURPOSE:
;Crib for loading FAST ESA L2 data
;-

; Set timespan 

	timespan, '1996-11-12'

; Load data

	fa_esa_load_l2

; You can also load by orbit number, 
        
        fa_esa_load_l2, orbit = 900

; Or an orbit range

        fa_esa_load_l2, orbit = [900, 905]

;Variables are in common blocks:

        common fa_ies_l2, get_ind_ies, all_dat_ies
        common fa_ees_l2, get_ind_ees, all_dat_ees
        common fa_ieb_l2, get_ind_ieb, all_dat_ieb
        common fa_eeb_l2, get_ind_eeb, all_dat_eeb

        help, all_dat_ies


; Generate tplot structures; fa_esa_l2_tplot creates an angle averaged
; energy spectrum using the eflux variable for each type, with names
; fa_ies_l2_en_quick, fa_ees_l2_en_quick, fa_ieb_l2_en_quick, fa_eeb_l2_en_quick

	fa_esa_l2_tplot

        tplot, 'fa_*_l2_en_quick'

; If you set the /counts keyword, fa_esa_l2_tplot will generate the
; 'l1' tplot variables, for comparison with the tplot vars created in
; fa_load_esa_l1.pro

	fa_esa_l2_tplot, /counts

        tplot, 'fa_*_l1_en_quick'

; If you don't want all of the data types, use the type keyword:

        fa_esa_load_l2, orbit = 900, type = ['ies', 'ees']

	fa_esa_l2_tplot

        tplot, 'fa_*_l2_en_quick'


End
