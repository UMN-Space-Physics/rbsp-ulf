
pro mvn_sep_pfdpu_tplot_options,tplot=tplot
   tplot_options,'no_interp',1                       ;  This is rude!
   tplot_options,'ynozero',1
;   store_data,'mav_apid_all',data=tnames('MAV_APIDS MAV_APID_SKIPPED') ;,dlimit=tplot_routine='bitplot'
   options,'mvn_sep?_noise_DATA mvn_sep?_svy_DATA mvn_sep?_arc_DATA',spec=1
   zlim,'mvn_sep?_svy_DATA',.9,10000,1
   ylim,'mvn_sep?_svy_DATA',0,260,0
   options,'mvn_sep?_svy_DATA',panel_size=2
   zlim,'mvn_sep?_arc_DATA',.9,100,1
   ylim,'mvn_sep?_arc_DATA',0,260,0
   options,'mvn_sep?_arc_DATA',panel_size=2
;   ylim,'mvn_sep?_hkp_RATE_CNTR',0,0,0
   ylim,'mvn_sep?_hkp_RATE_CNTR',.5,1e5,1,/default
   options,'mvn_sep?_hkp_RATE_CNTR',/default,psym=-3
   ylim,'mvn_sep?_svy_COUNTS_TOTAL',1,1,1  ;,0,0,0
   ylim,'mvn_sep?_noise_SIGMA',1,2
   store_data,'mvn_sep1_COUNTS',data='mvn_sep1_svy_RATE mvn_sep1_hkp_RATE_CNTR mvn_sep1_hkp_EVENT_CNTR'
   store_data,'mvn_sep2_COUNTS',data='mvn_sep2_svy_RATE mvn_sep2_hkp_RATE_CNTR mvn_sep2_hkp_EVENT_CNTR'
   store_data,'APIDS',data='MAV_APIDS MAV_APID_SKIPPED',dlim={panel_size:3.}
 
   
   options,'mvn_sep?_hkp_RATE_CNTR',psym=-3,/default
   options,'mvn_pfdpu_shkp_ACT_PWRCNTRL_FLAG',colors='BGR',labels=strsplit('Mag1 Mag2 SWEA SWIA LPW STA SEP',/extract)
   options,'mvn_pfdpu_oper_ACT_REQUEST_FLAG',colors = 'GR',labels=strsplit('S1o S1s S2o S2s SWIA SWIA STATIC STATIC . . EUVEo EUVEs',/extract)
   options,'mvn_pfdpu_oper_ACT_STATUS_FLAG',colors = 'GR',labels=strsplit('S1o S1s S2o S2s SWIAo SWIAs STATICo STATICs . . EUVEo EUVEs',/extract)
   options,'mvn_pfdpu_*FLAG',panel_size=.4
   options,'mvn_sep?_hkp_MODE_FLAGS',colors='BGRBGRYYBGRBGRMD',labels=strsplit(/extract,'D1 D2 D3 D4 D5 D6 BLR1 BLR2 TP_AO TP_AT TP_AF TP_BO TP_BT TP_BF TP_ENA Spare')
   options,'mvn_sep?_hkp_NOISE_FLAGS',labels=strsplit(/extract,'. . . . . . . . R R R Ena D1 D2 D3 D4'),colors='GGGGGGGGRRRBGRGR'
   store_data,'mvn_DPU_TEMP',data='mvn_sep1_hkp_AMON_TEMP_DAP mvn_sep2_hkp_AMON_TEMP_DAP mvn_pfdpu*_TEMP'
   store_data,'mvn_SEPS_TEMP',data='mvn_sep?_hkp_AMON_TEMP_S?'
   store_data,'mvn_pfp_TEMPS',data = 'mvn_sep?_hkp_AMON_TEMP_* mvn_pfdpu*_TEMP',dlim={yrange:[-45.,50],ystyle:1,panel_size:2.}
   options,'mvn_sep1_hkp_* mvn_sep1_svy_ATT mvn_sep1_svy_COUNTS_TOTAL',colors='b',ystyle=2
   options,'mvn_sep2_hkp_* mvn_sep2_svy_ATT mvn_sep2_svy_COUNTS_TOTAL',colors='r',ystyle=2
   options,'mvn_sep?_???_ATT',yrange=[0,3],panel_size=.3
  ; options,'mvn_sep?_???_ATT',yrange=[0,1],zrange=[0,2],/ystyle,spec=1,panel_size=.2
   
   options,'mvn_sep?_*DACS mvn_sep?_hkp_*RATE_CNTR','colors'
   options,'mvn_sep?_*DACS',colors='bgrdbgrdbgrd'
;   tnames = 'sep1_hkp_AMON_*'
   store_data,'mvn_SEPS_hkp_VCMD_CNTR',data='mvn_sep?_hkp_VCMD_CNTR'
   store_data,'mvn_SEPS_hkp_MEM_CHECKSUM',data='mvn_sep?_hkp_MEM_CHECKSUM'
   store_data,'mvn_SEPS_svy_ATT',data='mvn_sep?_svy_ATT',dlim={panel_size:.4,yrange:[0,3]}
   store_data,'mvn_SEPS_svy_COUNTS_TOTAL',data='mvn_sep?_svy_COUNTS_TOTAL',dlim={yrange:[.8,1e5],ylog:1,panel_size:1.5}
   store_data,'mvn_SEPS_svy_ALLTID',data='mvn_sep?_?'
   store_data,'mvn_SEPS_QL' , data='mvn_sep?_?_????_tot mvn_sep?_svy_ATT',dlim={yrange:[.8,1e5],ylog:1,panel_size:2.}
   
   
   temps = tnames('SEPS_TEMP DPU_TEMP HTR_TEMP HTR_DC')
   
   if keyword_set(tplot) then $
      tplot,'mvn_SEPS_hkp_VCMD_CNTR mvn_sep?_svy_DATA mvn_sep?_noise_SIGMA mvn_sep?_hkp_RATE_CNTR'
   
  if 0 then begin
     tplot,'SEPS_hkp_VCMD_CNTR sep1_svy_DATA sep1_svy_COUNTS_TOTAL sep1_hkp_RATE_CNTR P*ACT_*T*_FLAG'
     tplot,'SEPS_hkp_VCMD_CNTR sep2_svy_DATA sep2_svy_COUNTS_TOTAL sep2_noise_SIGMA sep2_hkp_RATE_CNTR P*ACT_*T*_FLAG'
     tplot,'SEPS_hkp_VCMD_CNTR sep?_svy_DATA sep?_noise_SIGMA sep?_hkp_RATE_CNTR'
     tplot,'SEPS_hkp_VCMD_CNTR sep1_svy_DATA sep1_noise_SIGMA sep1_hkp_RATE_CNTR SEPS_svy_COUNTS_TOTAL SEPS_svy_ATT SEPS_TEMP'  ; P*ACT_*T*_FLAG'
     tplot,'SEPS_hkp_VCMD_CNTR sep2_svy_DATA sep2_noise_SIGMA sep2_hkp_RATE_CNTR SEPS_svy_COUNTS_TOTAL SEPS_svy_ATT SEPS_TEMP'  ;P*ACT_*T*_FLAG'
     tplot,/add,'IG_* Beam_Current'
     tplot,/add,'sep1_hkp_DACS'
     tplot,'sep1_hkp_AMON_*'
     tplot,'sep2_hkp_AMON_*'
     tplot,'sep?_svy_DATA sep?_noise_DATA
     tplot,'sep1_hkp_MEM_ADDR sep1_svy_DATA sep1_noise_DATA sep1_hkp_RATE_CNTR'
     tplot,'sep2_hkp_MEM_ADDR sep2_svy_DATA sep2_noise_DATA sep2_hkp_RATE_CNTR'
     tplot,'SEPS_hkp_VCMD_CNTR sep?_svy_DATA sep?_noise_DATA sep?_hkp_RATE_CNTR'
     tplot,'SEPS_hkp_VCMD_CNTR sep?_svy_DATA sep?_noise_SIGMA sep?_hkp_RATE_CNTR'
     tplot,'SEPS_TEMP DPU_TEMP HTR_TEMP HTR_DC'
     tplot,'sep1'+strsplit('_hkp_VCMD_CNTR _svy_DATA _noise_DATA _hkp_RATE_CNTR',/extract)
     tplot,'sep?_hkp_RATE_CNTR'
     tplot,'sep?_hkp_VCMD_CNTR'
     tplot, 'mav_apid_all'
     tplot,'*FLAGS'
     tplot,'C*'
     tplot,'PFDPU_HKP_PFP28* PFDPU_HKP_SEP* PFDPU_*_TEMP sep?_hkp_AMON_*5* 
endif

end
