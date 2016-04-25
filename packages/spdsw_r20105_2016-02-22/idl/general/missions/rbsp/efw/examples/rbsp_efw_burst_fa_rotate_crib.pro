;+
; NAME: rbsp_efw_burst_fa_rotate_crib
; SYNTAX: 
; PURPOSE: Rotate RBSP EFW burst data to field-aligned coordinates
; INPUT: 
; OUTPUT: 
; KEYWORDS: 
; HISTORY: Created by Aaron W Breneman, Univ. Minnesota  4/10/2014
; VERSION: 
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2015-01-09 11:50:11 -0800 (Fri, 09 Jan 2015) $
;   $LastChangedRevision: 16615 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/examples/rbsp_efw_burst_fa_rotate_crib.pro $
;-


;B1 test date
;2014-08-27 18:18:39 - 18:18:41.200    -- example with ringing


rbsp_efw_init


                                ;Make tplot plots looks pretty
charsz_plot = 0.8               ;character size for plots
charsz_win = 1.2  
!p.charsize = charsz_win
tplot_options,'xmargin',[20.,15.]
tplot_options,'ymargin',[3,6]
tplot_options,'xticklen',0.08
tplot_options,'yticklen',0.02
tplot_options,'xthick',2
tplot_options,'ythick',2
tplot_options,'labflag',-1	

fileroot = '~/Desktop/code/Aaron/datafiles/'


;------------------------------------------------------------------------
;VARIABLES TO SET
;------------------------------------------------------------------------


;********************
start_after_step = 0.

;choose where down the line to load data. Every step builds on
;previous steps.
;step 0 -> start from scratch
;step 1 -> despins the UVW data
;..........saves as filename=fileroot+fn + '.tplot'
;step 2 -> divides data into chunks and bandpasses if requested
;..........saves as filename=fileroot+fn + '_chunk.tplot'
;step 3 -> rotate into FA coord (rotation is optional, but must do
;this step anyways)
;..........saves as filename=fileroot+fn + '_fa.tplot'
;step 4 -> Chasten crib
;..........saves as filename=fileroot+fn + '_chasten.tplot'
;step 5 -> calculates pflux
;..........saves as filename=fileroot+fn + '_pflux.tplot'
;********************



;set filename. If loading data, set to file to load.
;Otherwise set to the file to be saved. 
;fn = 'burst_crib_b2_a_20140827'
;fn = 'burst_crib_b1_b_20140827'
;fn = 'burst_crib_b2_a_20140123'
fn = 'burst_crib_b2_a_20121101'
;;fn = 'burst_crib_b1_a_20140716'


nostop = 0   ;if set, stop statements are ignored and program attempts to plow through to end. 
		     ;Useful for overnight runs, etc. 

rotate_to_fa = 1              ;rotate to FA coord? If so, this will be used when calling Chasten crib. 

pflux_spec = 1                ;Calculate the Poynting flux spectrum?
								;WARNING...takes very long time to run for large chunks of burst data.
								;and output save file can be many GB in size.

df = 50.                     ;Hz. The delta-freq size for Poynting flux spectrum program


                                ;Set max chunk size to divide up B1
                                ;variable (e.g. analyze only 20 min
                                ;chunks). Value must be greater than 1 sec
maxchunktime = 5.               ;min. N/A for B2
bandpass_data = 'y'
fmin = 50.                      ;Hz
fmax = 4000.

minduration = 1.                ;minimum duration of each burst (sec). This is used to eliminate
                                ;spuriously short bursts that occur when there are short data gaps.
                                ;These can screw up twavpol



;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
if start_after_step eq 1 then begin
;Loads the burst data that has been rotated to MGSE coord
   tplot_restore,filename=fileroot+fn + '.tplot'
   restore,fileroot+fn+'.idl'
endif 
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


if start_after_step eq 0 then begin

   e56_zero = 1                 ;Set the UVW 56 component to zero (spin axis)?
                                ;Not used for Pflux calculation
   
   bt = '2'                     ;burst 1 or 2

;   date = '2014-08-27'
;   date = '2014-01-23'
   date = '2012-11-01'
  timespan,date
   tr = timerange()
                                ;Define timerange for loading of burst waveform
                                ;(CURRENTLY NEED AT LEAST 1 SEC OF BURST FOR MGSE TRANSFORMATION TO WORK!!!)
   ;; t0 = date + '/06:00'  ;2014-07-16 B1
   ;; t1 = date + '/08:00'

   ;bt=2
  ;; t0 = date + '/13:00'
  ;; t1 = date + '/14:00'

   ;bt=2
  ;; t0 = date + '/05:17'
  ;; t1 = date + '/05:19'


  t0 = date + '/09:00'
  t1 = date + '/09:10'


;; ;bt=1  (2014-08-27, probe b)
;;    t0 = date + '/14:00'
;;    t1 = date + '/14:30'




   probe='a'
   rbspx = 'rbsp'+probe

   dt = time_double(t1) - time_double(t0)

 
   
;--------------------------------------------------------------------------------
;Find the GSE coordinates of the sc spin axis. This will be used to transform the 
;Mag data from GSE -> MGSE coordinates
;--------------------------------------------------------------------------------


   rbsp_efw_position_velocity_crib,/noplot
   store_data,'*both*',/delete


;------------------------------------------------------
;Get EMFISIS DC mag data in GSE
;------------------------------------------------------

                                ;Load EMFISIS data (defaults to 'hires', but can also choose '1sec' or '4sec')
   rbsp_load_emfisis,probe=probe,coord='gse',cadence='hires',level='l3'

   store_data,[rbspx+'_emfisis_l3_hires_gse_delta',rbspx+'_emfisis_l3_hires_gse_lambda',rbspx+'_emfisis_l3_hires_gse_coordinates'],/delete

   tinterpol_mxn,rbspx+'_spinaxis_direction_gse',rbspx+'_emfisis_l3_hires_gse_Mag'
   get_data,rbspx+'_spinaxis_direction_gse_interp',data=wsc_GSE_tmp
   wsc_GSE_tmp = wsc_GSE_tmp.y

   rbsp_gse2mgse,rbspx+'_emfisis_l3_hires_gse_Mag',reform(wsc_GSE_tmp),newname=rbspx+'_Mag_mgse'


;----------------------------------------------------------
;Load burst data
;----------------------------------------------------------

   dt2 = time_double(t1) - time_double(t0)
   timespan,t0,dt2,/seconds


   rbsp_load_efw_waveform_partial,probe=probe,type='calibrated',datatype=['mscb'+bt]
   rbsp_load_efw_waveform_partial,probe=probe,type='calibrated',datatype=['eb'+bt]
   ;load Vburst if there is no Eburst
   if ~tdexists(rbspx+'_efw_eb'+bt,tr[0],tr[1]) then rbsp_load_efw_waveform_partial,probe=probe,$
      type='calibrated',datatype=['vb'+bt]


   store_data,[rbspx+'_efw_eb'+bt+'_ccsds_data_BEB_config',rbspx+'_efw_eb'+bt+'_ccsds_data_DFB_config',$
               rbspx+'_efw_mscb'+bt+'_ccsds_data_BEB_config',rbspx+'_efw_mscb'+bt+'_ccsds_data_DFB_config',$
               rbspx+'_efw_vb'+bt+'_ccsds_data_BEB_config',rbspx+'_efw_vb'+bt+'_ccsds_data_DFB_config'],/delete


   copy_data,rbspx+'_efw_mscb'+bt,rbspx+'_efw_mscb'+bt+'_uvw'
   store_data,rbspx+'_efw_mscb'+bt,/delete
   

                                ;--------------------------------------------------
                                ;Check to see if there is Eburst
                                ;data. Otherwise, create it from
                                ;Vburst data


   if tdexists(rbspx+'_efw_vb'+bt,tr[0],tr[1]) then begin

                                ;Create E-field variables (mV/m)
      trange = timerange()
      print,time_string(trange)
      cp0 = rbsp_efw_get_cal_params(trange[0])

      if probe eq 'a' then cp = cp0.a else cp = cp0.b


      boom_length = cp.boom_length
      boom_shorting_factor = cp.boom_shorting_factor

      get_data,rbspx+'_efw_vb'+bt,data=dd
      e12 = 1000.*(dd.y[*,0]-dd.y[*,1])/boom_length[0]
      e34 = 1000.*(dd.y[*,2]-dd.y[*,3])/boom_length[1]
      e56 = 1000.*(dd.y[*,4]-dd.y[*,5])/boom_length[2]


;SET 56 COMPONENT TO ZERO
      if e56_zero then e56[*] = 0.
      
      
      eb = [[e12],[e34],[e56]]
      store_data,rbspx+'_efw_eb'+bt+'_uvw',data={x:dd.x,y:eb}
      

   endif else begin
      copy_data,rbspx+'_efw_eb'+bt,rbspx+'_efw_eb'+bt+'_uvw'

      get_data,rbspx+'_efw_eb'+bt+'_uvw',data=tmp
      if e56_zero then tmp.y[*,2] = 0.
      store_data,rbspx+'_efw_eb'+bt+'_uvw',data=tmp
   endelse

   store_data,rbspx+'_efw_eb'+bt,/delete


   tplot,[rbspx+'_efw_eb'+bt+'_uvw',rbspx+'_efw_mscb'+bt+'_uvw']
   
                                ;Convert from UVW (spinning sc) to MGSE coord
   rbsp_uvw_to_mgse,probe,rbspx+'_efw_mscb'+bt+'_uvw',/no_spice_load,/nointerp,/no_offset	
   rbsp_uvw_to_mgse,probe,rbspx+'_efw_eb'+bt+'_uvw',/no_spice_load,/nointerp,/no_offset	



   copy_data,rbspx+'_efw_eb'+bt+'_uvw_mgse',rbspx+'_efw_eb'+bt+'_mgse'
   copy_data,rbspx+'_efw_mscb'+bt+'_uvw_mgse',rbspx+'_efw_mscb'+bt+'_mgse'


;   tplot,[rbspx+'_efw_eb'+bt+'_mgse',rbspx+'_efw_mscb'+bt+'_mgse']

   split_vec,rbspx+'_efw_eb'+bt+'_mgse'
   split_vec,rbspx+'_efw_mscb'+bt+'_mgse'

                                ;Check to see how things look (MGSEx is spin axis)
;   tplot,[rbspx+'_efw_eb'+bt+'_mgse_x',rbspx+'_efw_eb'+bt+'_mgse_y',rbspx+'_efw_eb'+bt+'_mgse_z']
;stop
;   tplot,[rbspx+'_efw_mscb'+bt+'_mgse_x',rbspx+'_efw_mscb'+bt+'_mgse_y',rbspx+'_efw_mscb'+bt+'_mgse_z']
;stop


                                ;--------
                                ;These are the variables we will be working with
   varM_s1 = rbspx+'_efw_mscb'+bt+'_mgse'
   varE_s1 = rbspx+'_efw_eb'+bt+'_mgse'



;Delete unnecessary tplot variables to save space
   store_data,tnames(rbspx+'_efw_vb'+bt),/delete
   store_data,tnames('*uvw*'),/delete
   store_data,tnames('*mgse_?'),/delete
   store_data,tnames(rbspx+'_efw_eb?'),/delete
   store_data,tnames(rbspx+'_efw_vb?'),/delete
   store_data,tnames(rbspx+'_efw_mscb?'),/delete
   if rbspx eq 'rbspa' then store_data,'*rbspb*',/delete
   if rbspx eq 'rbspb' then store_data,'*rbspa*',/delete
   store_data,'*hires*',/delete
   store_data,'*config*',/delete
   store_data,'*diff*',/delete
   store_data,'*foot*',/delete

;Delete unnecessary IDL variables to save space
   undefine,tmp,tmpp,eburst,wsc_gse,wsc_gse_tmp

;Save what we've done so far so we can pick up here next time by restoring
   start_after_step += 1
   tplot_save,'*',filename=fileroot+fn
   save,filename=fileroot+fn+'.idl'

endif


;----------------------------------------------------------------------------------------------------
;Bandpass data or load bandpassed data


;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
if start_after_step eq 2 then begin
   tplot_restore,filename=fileroot+fn + '_chunk.tplot'
   restore,fileroot+fn+'_chunk.idl'
endif
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

if ~nostop then if start_after_step le 2 then stop
if start_after_step lt 2 then begin

   if bandpass_data eq 'y' then begin
      get_data,varE_s1,data=dat
      srt = 1/(dat.x[1] - dat.x[0])
      tmp = rbsp_vector_bandpass(dat.y,srt,fmin,fmax)
      store_data,varE_s1+'_bp',data={x:dat.x,y:tmp}

      get_data,varM_s1,data=dat
      srt = 1/(dat.x[1] - dat.x[0])
      tmp = rbsp_vector_bandpass(dat.y,srt,fmin,fmax)
      store_data,varM_s1+'_bp',data={x:dat.x,y:tmp}

      varM_s2 = varM_s1 + '_bp'
      varE_s2 = varE_s1 + '_bp'
   endif else begin
   	 varM_s2 = varM_s1
   	 varE_s2 = varE_s1
   endelse


;--------------------------------------------------
;Divide into chunks based on data gaps (for both B1 and B2)
;--------------------------------------------------

   get_data,varE_s2,data=varr

                                ;Separate the bursts by comparing the delta-time b/t each
                                ;data point to 1/samplerate

   dt = varr.x - shift(varr.x,1)
   dt = dt[1:n_elements(dt)-1]

   sr = rbsp_sample_rate(varr.x,out_med_av=medavg)
   ;; store_data,varE_s2 +'_samplerate',data={x:varr.x,y:sr}
   ;; store_data,varE_s2+'_samplerate_diff',data={x:varr.x,y:abs(sr-medavg[0])}

   threshold = 1/medavg
   goo = where(abs(dt) ge 2*threshold[1])

   b = 0L
   q = 0L

                                ;left and right location of each burst chunk
   chunkL = [0,goo+1]
   chunkR = [goo-1,n_elements(sr)-1]

                                ;Get rid of abnormally small chunks. These sometimes occur if there is a small
                                ;gap in the data. 

   chunkduration = (chunkR - chunkL)/medavg[1]

   goo = where(chunkduration ge minduration)
   chunkL = chunkL[goo]
   chunkR = chunkR[goo]
   nchunks = n_elements(goo)

   print,'Duration (sec) of each chunk: ',(chunkR - chunkL)/medavg[1]


;--------------------------------------------------
;Burst 1: Further subdivide each B1 chunk into maxchunktime-sized chunks. 
;Otherwise it's too much to process.
;--------------------------------------------------


   if bt eq '1' then begin


      maxchunktime = maxchunktime * 60. ;sec

      chunkR2 = 0L
      chunkL2 = 0L

;For each large chunk (defined by data gaps) find number of subchunks
;based on user-defined maxchunktime
      for j=0,nchunks-1 do begin

         nsubchunks = floor((chunkR[j] - chunkL[j])/medavg[1]/maxchunktime)
         subduration = floor(maxchunktime*medavg[1])

         if nsubchunks ge 1 then begin

            chlocL = lonarr(nsubchunks)
            chlocR = chlocL

            chstart = chunkL[j]


            chlocL[0] = chstart
            chlocR[0] = chlocL[0] + subduration
            if nsubchunks ge 2 then begin
               for b=1,nsubchunks-1 do begin
                  chlocL[b] = chlocL[b-1] + subduration
                  chlocR[b] = chlocR[b-1] + subduration
               endfor
            endif
            b = nsubchunks-1
                                ;Account for any remainder data
                                ;left over that doesn't neatly
                                ;fall into chunks of size maxchunktime
            remainder = chunkR[j] - chlocR[b]
            remainder_frac = float(remainder)/float(chunkr[j]) * 100.

;make sure there's more than 1 sec of remainder left
            if remainder/medavg[1] gt 1 then begin
               chlocL = [chlocL,chlocR[b]+1]
               chlocR = [chlocR,chlocL[b+1] + remainder]
            endif

         endif else begin
            chlocL = chunkL[j]
            chlocR = chunkR[j]
         endelse


         chunkL2 = [chunkL2,chlocL]
         chunkR2 = [chunkR2,chlocR]


      endfor


      chunkL = chunkL2[1:n_elements(chunkL2)-1]
      chunkR = chunkR2[1:n_elements(chunkR2)-1]
      chunkR = chunkR - 1

      nchunks = n_elements(chunkL)

   endif


;Let's see how the burst data are divided up (both B1 and B2)
   tplot,varE_s2
   timebar,varr.x[chunkL],color=250,thick=2
   timebar,varr.x[chunkR],color=250,thick=2

   
;Delete unnecessary IDL variables to save space
   undefine,dat,dt,sr,tmp


   start_after_step += 1
   tplot_save,'*',filename=fileroot+fn+'_chunk'
   save,filename=fileroot+fn+'_chunk.idl'

endif



;--------------------------------------------------
;Rotate each chunk to FA coord
;--------------------------------------------------


;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
if start_after_step eq 3 then begin
   tplot_restore,filename=fileroot+fn + '_fa.tplot'
   restore,fileroot+fn+'_fa.idl'
endif
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
if ~nostop then if start_after_step le 3 then stop
if start_after_step lt 3 then begin

   if rotate_to_fa then begin

      BurstE = [[0.],[0.],[0.]]
      BurstB = [[0.],[0.],[0.]]
      BursttimesE = 0d
      BursttimesB = 0d

      theta_kbE = 0.
      thetatimesE = 0d
      dtheta_kbE = 0.
      eigsE = [[0.],[0.],[0.]]
      emax2eintE = 0.
      eint2eminE = 0.
      emax_vecE = [[0.],[0.],[0.]]
      eint_vecE = [[0.],[0.],[0.]]
      emin_vecE = [[0.],[0.],[0.]]

      theta_kbB = 0.
      thetatimesB = 0d
      dtheta_kbB = 0.
      eigsB = [[0.],[0.],[0.]]
      emax2eintB = 0.
      eint2eminB = 0.
      emax_vecB = [[0.],[0.],[0.]]
      eint_vecB = [[0.],[0.],[0.]]
      emin_vecB = [[0.],[0.],[0.]]


      for i=0,nchunks-1 do begin

         t0z = varr.x[chunkL[i]]
         t1z = varr.x[chunkR[i]]

         ve = tsample(varE_s2,[t0z,t1z],times=te)
         vb = tsample(varM_s2,[t0z,t1z],times=tb)
         vm = tsample(rbspx+'_Mag_mgse',[t0z,t1z],times=tm)

         store_data,varE_s2+'_tmp',data={x:te,y:ve}
         store_data,varM_s2+'_tmp',data={x:tb,y:vb}
         tinterpol_mxn,varM_s2+'_tmp',varE_s2+'_tmp',newname=varM_s2+'_tmp'
         store_data,rbspx+'_Mag_mgse_tmp',data={x:tm,y:vm}
         

         tplot,[varE_s2+'_tmp',varM_s2+'_tmp',rbspx+'_Mag_mgse_tmp'],trange=[t0z,t1z]


                                ;Efield: Rotate each chunk to FA/minvar coord
         fa = rbsp_rotate_field_2_vec(varE_s2+'_tmp',rbspx+'_Mag_mgse_tmp')
         get_data,varE_s2+'_tmp_FA_minvar',data=dtmp
         BurstE = [BurstE,dtmp.y]
         BursttimesE = [BursttimesE,dtmp.x]

         get_data,'theta_kb',data=dtmp
         theta_kbE = [theta_kbE,dtmp.y]
         thetatimesE = [thetatimesE,dtmp.x]
         get_data,'dtheta_kb',data=dtmp
         dtheta_kbE = [dtheta_kbE,dtmp.y]
         get_data,'emax2eint',data=dtmp
         emax2eintE = [emax2eintE,dtmp.y]
         get_data,'eint2emin',data=dtmp
         eint2eminE = [eint2eminE,dtmp.y]
         get_data,'minvar_eigenvalues',data=dtmp
         eigsE = [eigsE,dtmp.y]
         get_data,'emax_vec_minvar',data=dtmp
         emax_vecE = [emax_vecE,dtmp.y]
         get_data,'eint_vec_minvar',data=dtmp
         eint_vecE = [eint_vecE,dtmp.y]
         get_data,'emin_vec_minvar',data=dtmp
         emin_vecE = [emin_vecE,dtmp.y]


                                ;Bfield: Rotate each chunk to FA/minvar coord
         fa = rbsp_rotate_field_2_vec(varM_s2+'_tmp',rbspx+'_Mag_mgse_tmp')




         get_data,varM_s2+'_tmp_FA_minvar',data=dtmp
         BurstB = [BurstB,dtmp.y]
         BursttimesB = [BursttimesB,dtmp.x]

         get_data,'theta_kb',data=dtmp
         theta_kbB = [theta_kbB,dtmp.y]
         thetatimesB = [thetatimesB,dtmp.x]
         get_data,'dtheta_kb',data=dtmp
         dtheta_kbB = [dtheta_kbB,dtmp.y]
         get_data,'emax2eint',data=dtmp
         emax2eintB = [emax2eintB,dtmp.y]
         get_data,'eint2emin',data=dtmp
         eint2eminB = [eint2eminB,dtmp.y]
         get_data,'minvar_eigenvalues',data=dtmp
         eigsB = [eigsB,dtmp.y]
         get_data,'emax_vec_minvar',data=dtmp
         emax_vecB = [emax_vecB,dtmp.y]
         get_data,'eint_vec_minvar',data=dtmp
         eint_vecB = [eint_vecB,dtmp.y]
         get_data,'emin_vec_minvar',data=dtmp
         emin_vecB = [emin_vecB,dtmp.y]

         tplot,[varE_s2+'_tmp_FA_minvar',varM_s2+'_tmp_FA_minvar',rbspx+'_Mag_mgse_tmp']


      endfor

      varE_s4 = varE_s2 + '_FA_minvar'
      varM_s4 = varM_s2 + '_FA_minvar'


 
                                ;Store the field-aligned burst data
      nn = n_elements(BursttimesE)-1
      store_data,varE_s4,data={x:BursttimesE[1:nn],y:BurstE[1:nn,*]}
      nn = n_elements(BursttimesB)-1
      store_data,varM_s4,data={x:BursttimesB[1:nn],y:BurstB[1:nn,*]}

      tplot,[varE_s4,varM_s4]

      ;; ;Store the minvar analysis variables
      nn = n_elements(thetatimesB)-1
      store_data,varM_s4+'_theta_kb',data={x:thetatimesB[1:nn],y:theta_kbB[1:nn]}
      store_data,varM_s4+'_dtheta_kb',data={x:thetatimesB[1:nn],y:dtheta_kbB[1:nn]}
      store_data,varM_s4+'_emax2eint',data={x:thetatimesB[1:nn],y:emax2eintB[1:nn]}
      store_data,varM_s4+'_eint2emin',data={x:thetatimesB[1:nn],y:eint2eminB[1:nn]}
;      store_data,varM_s4+'_minvar_eigenvalues',data={x:thetatimesB[1:nn],y:eigsB[1:nn]}
      store_data,varM_s4+'_emax_vec',data={x:thetatimesB[1:nn],y:emax_vecB[1:nn]}
      store_data,varM_s4+'_eint_vec',data={x:thetatimesB[1:nn],y:eint_vecB[1:nn]}
      store_data,varM_s4+'_emin_vec',data={x:thetatimesB[1:nn],y:emin_vecB[1:nn]}

      nn = n_elements(thetatimesE)-1
      store_data,varE_s4+'_theta_kb',data={x:thetatimesE[1:nn],y:theta_kbE[1:nn]}
      store_data,varE_s4+'_dtheta_kb',data={x:thetatimesE[1:nn],y:dtheta_kbE[1:nn]}
      store_data,varE_s4+'_emax2eint',data={x:thetatimesE[1:nn],y:emax2eintE[1:nn]}
      store_data,varE_s4+'_eint2emin',data={x:thetatimesE[1:nn],y:eint2eminE[1:nn]}
 ;     store_data,varE_s4+'_minvar_eigenvalues',data={x:thetatimesE[1:nn],y:eigsE[1:nn]}
      store_data,varE_s4+'_emax_vec',data={x:thetatimesE[1:nn],y:emax_vecE[1:nn]}
      store_data,varE_s4+'_eint_vec',data={x:thetatimesE[1:nn],y:eint_vecE[1:nn]}
      store_data,varE_s4+'_emin_vec',data={x:thetatimesE[1:nn],y:emin_vecE[1:nn]}

      options,varM_s4+'_theta_kb','ytitle',rbspx+ '!CWave normal!Cangle'
      options,varM_s4+'_dtheta_kb','ytitle',rbspx+'!CWave normal!Cangle!Cuncertainty'
      options,varE_s4+'_theta_kb','ytitle',rbspx+ '!CWave normal!Cangle'
      options,varE_s4+'_dtheta_kb','ytitle',rbspx+'!CWave normal!Cangle!Cuncertainty'
      
      tplot,[varE_s4,varE_s4+'_theta_kb',varE_s4+'_emax2eint',varE_s4+'_eint2emin']
      tplot,[varM_s4,varM_s4+'_theta_kb',varM_s4+'_emax2eint',varM_s4+'_eint2emin']

 

   endif


   store_data,tnames('*tmp*'),/delete
   store_data,['pflux_para','pflux_perp1','pflux_perp2','pflux_nospinaxis_para',$
               'pflux_nospinaxis_perp'],/delete

   store_data,[rbspx+'_pflux_para',rbspx+'_pflux_perp?'],/delete
   store_data,['emax_vec_minvar','eint_vec_minvar','emin_vec_minvar',$
               'minvar_eigenvalues','emax2eint','eint2emin','theta_kb','dtheta_kb'],/delete

   undefine,burstb,burste,bursttimesb,bursttimese,dtheta_kbb,dtheta_kbe,dtmp,eigsb,eigse,eint2eminb
   undefine,eint2emine,eint_vecb,eint_vece,emax2eintb,emax2einte,emax_vecb,emax_vece,emin_vecb,emin_vece
   undefine,fa,tb,te,thetatimesb,thetatimese,theta_kbb,theta_kbe,vb,ve,vm


   start_after_step += 1
   tplot_save,'*',filename=fileroot+fn+'_fa'
   save,filename=fileroot+fn+'_fa.idl'

endif




;------------------------------------------------------------------
;Run Chasten's routine for both E and B
;------------------------------------------------------------------



;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
if start_after_step eq 4 then begin
   tplot_restore,filename=fileroot+fn + '_chasten.tplot'
   restore,fileroot+fn+'_chasten.idl'
endif
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


if ~nostop then if start_after_step le 4 then stop
if start_after_step lt 4 then begin

   get_data,varE_s4,data=varr

                                ;Separate the bursts by comparing the delta-time b/t each
                                ;data point to 1/samplerate

   dt = varr.x - shift(varr.x,1)
   dt = dt[1:n_elements(dt)-1]

   sr = rbsp_sample_rate(varr.x,out_med_av=medavg)
;	store_data,varE_s4+'_samplerate',data={x:varr.x,y:sr}
;	store_data,varE_s4+'_samplerate_diff',data={x:varr.x,y:abs(sr-medavg[0])}
                                ;tplot,[varE_s4,varE_s4+'_samplerate',varE_s4+'_samplerate_diff']
   

   threshold = 1/medavg
   goo = where(abs(dt) ge 2*threshold[1])

   b = 0L
   q = 0L
   
                                ;left and right location of each burst chunk
   chunkL = [0,goo+1]
   chunkR = [goo-1,n_elements(sr)-1]

                                ;Get rid of abnormally small chunks. These sometimes occur if there is a small
                                ;gap in the data. 

   chunkduration = (chunkR - chunkL)/medavg[1]
   
   goo = where(chunkduration ge minduration)
   chunkL = chunkL[goo]
   chunkR = chunkR[goo]
   nchunks = n_elements(goo)

   print,'Duration (sec) of each chunk: ',(chunkR - chunkL)/medavg[1]

   BurstE = [[0.],[0.],[0.]]
   BurstB = [[0.],[0.],[0.]]
   Bursttimes = 0d

   for i=0,nchunks-1 do begin

      t0z = varr.x[chunkL[i]]
      t1z = varr.x[chunkR[i]]

      ve = tsample(varE_s4,[t0z,t1z],times=te)
      vb = tsample(varM_s4,[t0z,t1z],times=tb)
      vm = tsample(rbspx+'_Mag_mgse',[t0z,t1z],times=tm)

      store_data,varE_s4+'_tmp',data={x:te,y:ve}
      store_data,varM_s4+'_tmp',data={x:tb,y:vb}
      tinterpol_mxn,varM_s4+'_tmp',varE_s4+'_tmp',newname=varM_s4+'_tmp'
      store_data,rbspx+'_Mag_mgse_tmp',data={x:tm,y:vm}

      get_data,varE_s4+'_tmp',data=dtmp
      BurstE = [BurstE,dtmp.y]
      get_data,varM_s4+'_tmp',data=dtmp
      BurstB = [BurstB,dtmp.y]
      Bursttimes = [Bursttimes,dtmp.x]


      
                                ;Bfield: Run Chaston crib on each chunk	
      twavpol,varM_s4+'_tmp',prefix='tmp'
                                ;twavpol,varM_s4+'_tmp',prefix='tmp',nopfft=16448,steplength=4112
                                ;twavpol,varM_s4+'_tmp',prefix='tmp',nopfft=16448,steplength=4096

                                ;Find the size of returned data
      get_data,'tmp'+'_waveangle',data=dtmp
      sz = n_elements(dtmp.v)

      if i eq 0 then begin
         waveangleB = replicate(0.,[1,sz])
         degpolB = replicate(0.,[1,sz])
         elliptictB = replicate(0.,[1,sz])
         helicitB = replicate(0.,[1,sz])
         pspec3B = replicate(0.,[1,sz,3])
         chastontimesB = 0d
      endif

                                ;change wave normal angle to degrees
      get_data,'tmp'+'_waveangle',data=dtmp
      dtmp.y = dtmp.y/!dtor	
      waveangleB = [waveangleB,dtmp.y]
      chastontimesB = [chastontimesB,dtmp.x]		
      
      get_data,'tmp'+'_degpol',data=dtmp
      degpolB = [degpolB,dtmp.y]
      get_data,'tmp'+'_elliptict',data=dtmp
      elliptictB = [elliptictB,dtmp.y]
      get_data,'tmp'+'_helict',data=dtmp
      helicitB = [helicitB,dtmp.y]
      get_data,'tmp'+'_pspec3',data=dtmp
      pspec3B = [pspec3B,dtmp.y]
      if i eq 0 then freqvalsB = dtmp.v
      


                                ;Efield: Run Chaston crib on each chunk	
      twavpol,varE_s4+'_tmp',prefix='tmp'
                                ;twavpol,varE_s4+'_tmp_FA',prefix='tmp',nopfft=16448,steplength=4112
                                ;twavpol,varE_s4+'_tmp_FA',prefix='tmp',nopfft=16448,steplength=4096


      if i eq 0 then begin
         waveangleE = replicate(0.,[1,sz])
         degpolE = replicate(0.,[1,sz])
         elliptictE = replicate(0.,[1,sz])
         helicitE = replicate(0.,[1,sz])
         pspec3E = replicate(0.,[1,sz,3])
         chastontimesE = 0d
      endif

                                ;change wave normal angle to degrees
      get_data,'tmp'+'_waveangle',data=dtmp
      dtmp.y = dtmp.y/!dtor	
      waveangleE = [waveangleE,dtmp.y]
      chastontimesE = [chastontimesE,dtmp.x]		
      
      
      get_data,'tmp'+'_degpol',data=dtmp
      degpolE = [degpolE,dtmp.y]
      get_data,'tmp'+'_elliptict',data=dtmp
      elliptictE = [elliptictE,dtmp.y]
      get_data,'tmp'+'_helict',data=dtmp
      helicitE = [helicitE,dtmp.y]
      get_data,'tmp'+'_pspec3',data=dtmp
      pspec3E = [pspec3E,dtmp.y]
      if i eq 0 then freqvalsE = dtmp.v

   endfor



                                ;Store the field-aligned burst data
   nn = n_elements(bursttimes)-1
   store_data,varM_s4,data={x:Bursttimes[1:nn],y:BurstB[1:nn,*]}
   store_data,varE_s4,data={x:Bursttimes[1:nn],y:BurstE[1:nn,*]}


                                ;Store the Chaston crib variables
   nn = n_elements(chastontimesB)-1
   store_data,varM_s4+'_theta_kb_chaston',data={x:chastontimesB[1:nn],y:waveangleB[1:nn,*],v:freqvalsB}
   store_data,varM_s4+'_degpol_chaston',data={x:chastontimesB[1:nn],y:degpolB[1:nn,*],v:freqvalsB}
   store_data,varM_s4+'_elliptict_chaston',data={x:chastontimesB[1:nn],y:elliptictB[1:nn,*],v:freqvalsB}
   store_data,varM_s4+'_helict_chaston',data={x:chastontimesB[1:nn],y:helicitB[1:nn,*],v:freqvalsB}
   store_data,varM_s4+'_pspec3_chaston',data={x:chastontimesB[1:nn],y:pspec3B[1:nn,*,*],v:freqvalsB}


   nn = n_elements(chastontimesE)-1
   store_data,varE_s4+'_theta_kb_chaston',data={x:chastontimesE[1:nn],y:waveangleE[1:nn,*],v:freqvalsE}
   store_data,varE_s4+'_degpol_chaston',data={x:chastontimesE[1:nn],y:degpolE[1:nn,*],v:freqvalsE}
   store_data,varE_s4+'_elliptict_chaston',data={x:chastontimesE[1:nn],y:elliptictE[1:nn,*],v:freqvalsE}
   store_data,varE_s4+'_helict_chaston',data={x:chastontimesE[1:nn],y:helicitE[1:nn,*],v:freqvalsE}
   store_data,varE_s4+'_pspec3_chaston',data={x:chastontimesE[1:nn],y:pspec3E[1:nn,*,*],v:freqvalsE}



   ylim,[varM_s4+'_degpol_chaston',$
         varM_s4+'_theta_kb_chaston',$
         varM_s4+'_elliptict_chaston',$
         varM_s4+'_helict_chaston',$
         varM_s4+'_pspec3_chaston'],100,8000,1

   zlim,varM_s4+'_waveangle_chaston',0,90,0
   zlim,varM_s4+'_pspec3_chaston',1d-9,1d-4,1

   ylim,[varE_s4+'_degpol_chaston',$
         varE_s4+'_theta_kb_chaston',$
         varE_s4+'_elliptict_chaston',$
         varE_s4+'_helict_chaston',$
         varE_s4+'_pspec3_chaston'],100,8000,1

   zlim,varE_s4+'_waveangle_chaston',0,90,0
   zlim,varE_s4+'_pspec3_chaston',1d-9,1d-4,1




                                ;eliminate data under a certain deg of polarization threshold
   minpol = 0.7

   get_data,varM_s4+'_degpol_chaston',data=degp
   goo = where(degp.y le minpol)
   if goo[0] ne -1 then degp.y[goo] = !values.f_nan
   store_data,varM_s4+'_degpol_chaston',data=degp
   get_data,varM_s4+'_theta_kb_chaston',data=tmp
   if goo[0] ne -1 then tmp.y[goo] = !values.f_nan
   store_data,varM_s4+'_theta_kb_chaston',data=tmp
   get_data,varM_s4+'_elliptict_chaston',data=tmp
   if goo[0] ne -1 then tmp.y[goo] = !values.f_nan
   store_data,varM_s4+'_elliptict_chaston',data=tmp
   get_data,varM_s4+'_helict_chaston',data=tmp
   if goo[0] ne -1 then tmp.y[goo] = !values.f_nan
   store_data,varM_s4+'_helict_chaston',data=tmp


   get_data,varE_s4+'_degpol_chaston',data=degp
   goo = where(degp.y le minpol)
   if goo[0] ne -1 then degp.y[goo] = !values.f_nan
   store_data,varE_s4+'_degpol_chaston',data=degp
   get_data,varE_s4+'_theta_kb_chaston',data=tmp
   if goo[0] ne -1 then tmp.y[goo] = !values.f_nan
   store_data,varE_s4+'_theta_kb_chaston',data=tmp
   get_data,varE_s4+'_elliptict_chaston',data=tmp
   if goo[0] ne -1 then tmp.y[goo] = !values.f_nan
   store_data,varE_s4+'_elliptict_chaston',data=tmp
   get_data,varE_s4+'_helict_chaston',data=tmp
   if goo[0] ne -1 then tmp.y[goo] = !values.f_nan
   store_data,varE_s4+'_helict_chaston',data=tmp




   options,[varM_s4+'_degpol_chaston',$
            varM_s4+'_theta_kb_chaston',$
            varM_s4+'_elliptict_chaston',$
            varM_s4+'_helict_chaston',$
            varM_s4+'_pspec3_chaston'],'spec',1

   options,[varE_s4+'_degpol_chaston',$
            varE_s4+'_theta_kb_chaston',$
            varE_s4+'_elliptict_chaston',$
            varE_s4+'_helict_chaston',$
            varE_s4+'_pspec3_chaston'],'spec',1


   tplot,[varE_s4,$
          varE_s4+'_pspec3_chaston',$
          varE_s4+'_degpol_chaston',$
          varE_s4+'_theta_kb_chaston',$
          varE_s4+'_elliptict_chaston',$
          varE_s4+'_helict_chaston']


   tplot,[varM_s4,$
          varM_s4+'_pspec3_chaston',$
          varM_s4+'_degpol_chaston',$
          varM_s4+'_theta_kb_chaston',$
          varM_s4+'_elliptict_chaston',$
          varM_s4+'_helict_chaston']


                                ;remove unnecessary variables
   store_data,['theta_kb','dtheta_kb','minvar_eigenvalues','emax2eint','eint2emin','emax_vec_minvar','eint_vec_minvar','emin_vec_minvar'],/delete

   store_data,'*tmp*',/delete
   undefine,burstb,burste,bursttimes,chastontimesb,chastontimese,degpolb,degpole,dt,dtmp
   undefine,elliptictb,ellipticte,goo,helicitb,helicite,powspecb,powspece,pspec3b,pspec3e,sr
   undefine,tb,te,tmp,vb,ve,vm,waveangleb,waveanglee


   start_after_step += 1
   tplot_save,'*',filename=fileroot+fn+'_chasten'
   save,filename=fileroot+fn+'_chasten.idl'


if ~nostop then stop

endif



;-----------------------------------------------------------------------------------
;Calculate Poynting flux for each chunk
;If requested, plot spectral Pflux
;-----------------------------------------------------------------------------------


;			 Poynting flux coord system
;   		 	P1mgse = Bmgse x xhat_mgse  (xhat_mgse is spin axis component)
;				P2mgse = Bmgse x P1mgse
;  		   		P3mgse = Bmgse
;
;			 The output tplot variables are:
;
;			 	These three output variables contain a mix of spin axis and spin plane components:
;			 		pflux_p1  -> Poynting flux in perp1 direction
;			 		pflux_p2  -> Poynting flux in perp2 direction
; 			 		pflux_Bo  -> Poynting flux along Bo
;
;			 	These partial Poynting flux calculations contain only spin plane Ew.
;			 		pflux_nospinaxis_perp 
;			 		pflux_nospinaxis_para
;



;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
if start_after_step eq 5 then begin
   tplot_restore,filename=fileroot+fn + '_pflux.tplot'
   restore,fileroot+fn+'_pflux.idl'
endif
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
if ~nostop then if start_after_step le 5 then stop
if start_after_step lt 5 then begin

   tinterpol_mxn,rbspx+'_state_mlat',varr.x

   Tlong = 1/float(fmin)
   Tshort = 1/float(fmax)

;Ew and Bw in Pflux coord
   BurstE = [[0.],[0.],[0.]]
   BurstB = [[0.],[0.],[0.]]
   Bursttimes = 0d
   pflux_nospinaxis_para = 0d
   pflux_para = 0d
   pflux_nospinaxis_perp = 0d
   pflux_perp1 = 0d
   pflux_perp2 = 0d
   nfreqbins = floor(fmax - fmin)/df
   ppara_p = replicate(0.,1,nfreqbins)
   ppara_n = replicate(0.,1,nfreqbins)
   ppara_b = replicate(0.,1,nfreqbins)


   for i=0,nchunks-1 do begin

      t0z = varr.x[chunkL[i]]
      t1z = varr.x[chunkR[i]]


      ve = tsample(varE_s2,[t0z,t1z],times=te)
      vb = tsample(varM_s2,[t0z,t1z],times=tb)
      vm = tsample(rbspx+'_Mag_mgse',[t0z,t1z],times=tm)

      store_data,varE_s2 +'_tmp',data={x:te,y:ve}
      store_data,varM_s2 +'_tmp',data={x:tb,y:vb}
      tinterpol_mxn,varM_s2+'_tmp',varE_s2+'_tmp',newname=varM_s2+'_tmp'
      store_data,rbspx+'_Mag_mgse_tmp',data={x:tm,y:vm}
      

      tplot,[varE_s2+'_tmp',varM_s2+'_tmp',rbspx+'_Mag_mgse_tmp'],trange=[t0z,t1z]


                                ;If pflux_spec keyword is set then
                                ;call rbsp_poynting_spec.pro. This program
                                ;calls rbsp_poynting_flux.pro, but
                                ;also does some extra work to produce
                                ;the spectra. Otherwise just call rbsp_poynting_flux.pro
      if keyword_set(pflux_spec) then begin

         fmin2 = fmin
         fmax2 = fmax
         df2 = df
         rbsp_poynting_spec,varE_s2+'_tmp',$
         				varM_s2+'_tmp',$
         				rbspx+'_Mag_mgse_tmp',$
         				df2,fmin2,fmax2,min_sf=1000.,/noplot
         				
         tplot,[varE_s2+'_tmp',varM_s2+'_tmp','ppara_p','ppara_n','ppara_b',rbspx+'_state_mlat_interp']
         get_data,'ppara_p',data=dtmp
         ppara_p = [ppara_p,dtmp.y]
         get_data,'ppara_n',data=dtmp
         ppara_n = [ppara_n,dtmp.y]
         get_data,'ppara_b',data=dtmp
         ppara_b = [ppara_b,dtmp.y]
         if i eq 0 then freqbins = dtmp.v

      endif 
      
      
    	;Even if option to run rbsp_poynting_spec is set, we still want to run
    	;rbsp_poynting_flux on the waveform. Otherwise many of the variables are essentially
    	;empty b/c they are filled with the bandpassed version at the highest bandpass
    	;channel from rbsp_poynting_spec.pro
         rbsp_poynting_flux,$
            varM_s2+'_tmp',$
            varE_s2+'_tmp',$
            Tshort,Tlong,$
            Bo=rbspx+'_Mag_mgse_tmp'
    
    
         store_data,rbspx+'_efw_eb'+bt+'_mgse_bp_tmp_interp'
         store_data,'*iono*',/delete
         store_data,[rbspx+'_efw_eb'+bt+'_mgse_bp_tmp',rbspx+'_efw_mscb'+bt+'_mgse_bp_tmp',$
                     rbspx+'_Mag_mgse_tmp',rbspx+'_Mag_mgse_tmp_interp',rbspx+'_efw_mscb'+bt+'_mgse_bp_tmp_interp',$
                     rbspx+'_efw_eb'+bt+'_mgse_bp_tmp_interp'],/delete



      get_data,'pflux_Bw',data=dtmp
      BurstB = [BurstB,dtmp.y]
      get_data,'pflux_Ew',data=dtmp
      BurstE = [BurstE,dtmp.y]
      Bursttimes = [Bursttimes,dtmp.x]

      get_data,'pflux_nospinaxis_para',data=dtmp
      pflux_nospinaxis_para = [pflux_nospinaxis_para,dtmp.y]
      get_data,'pflux_para',data=dtmp
      pflux_para = [pflux_para,dtmp.y]
      get_data,'pflux_nospinaxis_perp',data=dtmp
      pflux_nospinaxis_perp = [pflux_nospinaxis_perp,dtmp.y]
      get_data,'pflux_perp1',data=dtmp
      pflux_perp1 = [pflux_perp1,dtmp.y]
      get_data,'pflux_perp2',data=dtmp
      pflux_perp2 = [pflux_perp2,dtmp.y]



      
   endfor


                                ;Store the field-aligned burst data
   nn = n_elements(bursttimes)-1
   store_data,rbspx+'_efw_eb'+bt+'_pflux_coord',data={x:Bursttimes[1:nn],y:BurstE[1:nn,*]}
   store_data,rbspx+'_efw_mscb'+bt+'_pflux_coord',data={x:Bursttimes[1:nn],y:BurstB[1:nn,*]}
   store_data,rbspx+'_pflux_nospinaxis_para',data={x:Bursttimes[1:nn],y:pflux_nospinaxis_para[1:nn]}
   store_data,rbspx+'_pflux_nospinaxis_perp',data={x:Bursttimes[1:nn],y:pflux_nospinaxis_perp[1:nn]}
   store_data,rbspx+'_pflux_para',data={x:Bursttimes[1:nn],y:pflux_para[1:nn]}
   store_data,rbspx+'_pflux_perp1',data={x:Bursttimes[1:nn],y:pflux_perp1[1:nn]}
   store_data,rbspx+'_pflux_perp2',data={x:Bursttimes[1:nn],y:pflux_perp2[1:nn]}


   if keyword_set(pflux_spec) then begin
      store_data,rbspx+'_pflux_spec_ppara_plusBo',data={x:Bursttimes[1:nn],y:ppara_p[1:nn,*],v:freqbins}
      store_data,rbspx+'_pflux_spec_ppara_minusBo',data={x:Bursttimes[1:nn],y:ppara_n[1:nn,*],v:freqbins}
      store_data,rbspx+'_pflux_spec_ppara_binaryBo',data={x:Bursttimes[1:nn],y:ppara_b[1:nn,*],v:freqbins}
      
      
      options,rbspx+'_pflux_spec_ppara_?','spec',1
      zlim,rbspx+'_pflux_spec_ppara_plusBo',max(ppara_p)/1d4,max(ppara_p),1
      zlim,rbspx+'_pflux_spec_ppara_minusBo',max(ppara_n)/1d4,max(ppara_n),1
      
                                ;Remove gaps in spectral data
      
                                ;First fix the structure form. There's a bunch of other crap in here that confuses
                                ;tplot_removegaps.pro
      get_data,rbspx+'_pflux_spec_ppara_plusBo',data=du
      store_data,rbspx+'_pflux_spec_ppara_plusBo',data={x:du.x,y:du.y,v:du.v}	
      get_data,rbspx+'_pflux_spec_ppara_minusBo',data=du
      store_data,rbspx+'_pflux_spec_ppara_minusBo',data={x:du.x,y:du.y,v:du.v}	
      get_data,rbspx+'_pflux_spec_ppara_binaryBo',data=du
      store_data,rbspx+'_pflux_spec_ppara_binaryBo',data={x:du.x,y:du.y,v:du.v}	
      
      tplot_removegaps,rbspx+'_pflux_spec_ppara_plusBo'
      tplot_removegaps,rbspx+'_pflux_spec_ppara_minusBo'
      tplot_removegaps,rbspx+'_pflux_spec_ppara_binaryBo'
      
      options,[rbspx+'_pflux_spec_ppara_plusBo',$
               rbspx+'_pflux_spec_ppara_minusBo',$
               rbspx+'_pflux_spec_ppara_binaryBo'],'spec',1
      
   endif   
   
   ylim,['rbsp'+probe+'_pflux_nospinaxis_para','rbsp'+probe+'_pflux_nospinaxis_perp'],-1d-5,1d-5


	;Remove gaps in spectral data
	
	;First fix the structure form. There's a bunch of other crap in here that confuses
	;tplot_removegaps.pro
	get_data,rbspx+'_pflux_nospinaxis_para',data=du
	store_data,rbspx+'_pflux_nospinaxis_para',data={x:du.x,y:du.y}
	get_data,rbspx+'_pflux_nospinaxis_perp',data=du
	store_data,rbspx+'_pflux_nospinaxis_perp',data={x:du.x,y:du.y}
	get_data,rbspx+'_efw_eb'+bt+'_pflux_coord',data=du
	store_data,rbspx+'_efw_eb'+bt+'_pflux_coord',data={x:du.x,y:du.y}
	get_data,rbspx+'_efw_mscb'+bt+'_pflux_coord',data=du
	store_data,rbspx+'_efw_mscb'+bt+'_pflux_coord',data={x:du.x,y:du.y}


	tplot_removegaps,rbspx+'_efw_eb'+bt+'_pflux_coord'
	tplot_removegaps,rbspx+'_efw_mscb'+bt+'_pflux_coord'
	tplot_removegaps,rbspx+'_pflux_nospinaxis_para'
	tplot_removegaps,rbspx+'_pflux_nospinaxis_perp'



   tlimit,/full
   ylim,'*pflux_nospinaxis*',0,0
   tplot,[rbspx+'_efw_eb'+bt+'_pflux_coord',$
          rbspx+'_efw_mscb'+bt+'_pflux_coord',$
          rbspx+'_pflux_nospinaxis_para',$
          rbspx+'_pflux_nospinaxis_perp',$
          rbspx+'_state_mlat_interp',$
          rbspx+'_pflux_spec_ppara_?']



   store_data,['ppara_p','ppara_n','ppara_p2','ppara_n2','ppara_b'],/delete
   store_data,['etst','btst','etst_interp'],/delete
   store_data,['*iono*'],/delete
   store_data,['pflux_Ew','pflux_Bw'],/delete

   undefine,burstb,burste,bursttimes,dtmp,du,pflux_nospinaxis_para,pflux_nospinaxis_perp
   undefine,pflux_para,pflux_perp1,pflux_perp2,ppara_b,ppara_n,ppara_p,tb,te


   start_after_step += 1
   tplot_save,'*',filename=fileroot+fn+'_pflux'
   save,filename=fileroot+fn+'_pflux.idl'




if ~nostop then stop

endif





;-----------------------------------------------------
;PLOT CROSS-CORRELATIONS
;-----------------------------------------------------


for i=0,nchunks-1 do begin

   t0z = varr.x[chunkL[i]]
   t1z = varr.x[chunkR[i]]

   ve = tsample(varE_s4,[t0z,t1z],times=te)
   vb = tsample(varM_s4,[t0z,t1z],times=tb)
   vm = tsample(rbspx+'_Mag_mgse',[t0z,t1z],times=tm)

   store_data,varE_s4+'_tmp',data={x:te,y:ve}
   store_data,varM_s4+'_tmp',data={x:tb,y:vb}
   tinterpol_mxn,varM_s4+'_tmp',varE_s4+'_tmp',newname=varM_s4+'_tmp'
   store_data,rbspx+'_Mag_mgse_tmp',data={x:tm,y:vm}

   ;; get_data,varE+'_tmp',data=dtmp
   ;; BurstE = [BurstE,dtmp.y]
   ;; get_data,varM+'_tmp',data=dtmp
   ;; BurstB = [BurstB,dtmp.y]
   ;; Bursttimes = [Bursttimes,dtmp.x]


   ;Choose the variables to cross-correlate
   var1 = varM_s4+'_tmp'
   var2 = varE_s4+'_tmp'

   vardim1 = 1                  ;use this y-dim for var1 (x=0, y=1, z=2)
   vardim2 = 2                  ;use this y-dim for var2 (x=0, y=1, z=2)




;The following calculates the cross-phase and coherence between Ey-mgse and Ez-mgse 
;The function cross_spec_tplot return a multiple dimention array with
;the following structure. 
;[[E_FREQUENCE_coordinate],[PHASE_E1_E2],[COHERENCE_E1_E2],[Aver_Pow_E_1],[Aver_Pow_E_2]]

   Results=cross_spec_tplot(var1,vardim1,var2,vardim2,t0,t1,sub_interval=3,overlap_index=4)
   Time_rbsp=strmid(time_string(t0z),0,10)+'_'+strmid(time_string(t0z),11,2)+strmid(time_string(t0z),14,2)+$
             'UT'+'_to_'+strmid(time_string(t1),0,10)+'_'+strmid(time_string(t1),11,2)+strmid(time_string(t1),14,2)+'UT'



   freqplotrange = [0,4000]         ;Hz

;Plot the cross-phase and coherence in a .ps file
;Popen,rbspx+'_'+timerbsp
   !p.multi = [0,0,4]
   !p.charsize = 2
   Plot,Results[*,0],Results[*,2],xtitle='f, Hz', ytitle='Coherence_Ey_Ez',title=rbspx+time_rbsp,xrange=freqplotrange
   Plot,Results[*,0],Results[*,1]*180./3.14,xtitle='f, Hz', ytitle='Phase_Ey_Ez',title=rbspx+time_rbsp,xrange=freqplotrange
   Plot,Results[*,0],Results[*,3],xtitle='f, Hz', ytitle='Power_Ey,mV^2/Hz',title=rbspx+time_rbsp,xrange=freqplotrange
   Plot,Results[*,0],Results[*,4],xtitle='f, Hz', ytitle='Phase_Ez,MV^2/Hz',title=rbspx+time_rbsp,xrange=freqplotrange
;Pclose


if ~nostop then    stop
endfor


store_data,'*tmp*',/delete


;--------------------------------------------------
;TEST RESULTS
;--------------------------------------------------


ylim,[rbspx+'_pflux_spec_ppara_plusBo',$
      rbspx+'_pflux_spec_ppara_minusBo',$
      rbspx+'_pflux_spec_ppara_binaryBo'],400,4000,1

ylim,'*chaston*',400,4000,1

ylim,rbspx+'_state_mlat_interp',-25,25
!p.charsize = 1
tplot,[rbspx+'_efw_eb'+bt+'_mgse_bp_FA_minvar',$
       rbspx+'_efw_mscb'+bt+'_mgse_bp_FA_minvar',$
       rbspx+'_efw_mscb2_mgse_bp_FA_minvar_degpol_chaston',$
       rbspx+'_efw_mscb2_mgse_bp_FA_minvar_pspec3_chaston',$
       rbspx+'_efw_mscb'+bt+'_mgse_bp_FA_minvar_theta_kb_chaston',$
       rbspx+'_efw_mscb'+bt+'_mgse_bp_FA_minvar_theta_kb',$
       rbspx+'_pflux_nospinaxis_para',$
       rbspx+'_state_mlat_interp',$
       rbspx+'_pflux_spec_ppara_plusBo',$
       rbspx+'_pflux_spec_ppara_minusBo',$
       rbspx+'_pflux_spec_ppara_binaryBo']

tlimit,t0z,t1z







stop
stop
stop
end
