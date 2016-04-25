FUNCTION eva_data_load_mms, state, no_gui=no_gui
  compile_opt idl2

  ;-------------
  ; INITIALIZE
  ;-------------
  paramlist = strlowcase(state.paramlist_mms); list of parameters read from parameterSet file
  imax = n_elements(paramlist)
  sc_id = state.probelist_mms
  if (size(sc_id[0],/type) ne 7) then return, 'No'; STRING=7
  pmax = n_elements(sc_id)
  if pmax eq 1 then sc = sc_id[0] else sc = sc_id
  ts = str2time(state.start_time)
  te = str2time(state.end_time)
  timespan,state.start_time, te-ts, /seconds
  
  ;----------------------
  ; NUMBER OF PARAMETERS
  ;----------------------
  cparam = imax*pmax
  if not keyword_set(no_gui) then begin
    if cparam ge 17 then begin
      rst = dialog_message('Total of '+strtrim(string(cparam),2)+' MMS parameters. Still plot?',/question,/center)
    endif else rst = 'Yes'
    if rst eq 'No' then return, 'No'
  endif
  
  ;-------------
  ; CATCH ERROR
  ;-------------
  perror = -1
  catch, error_status; !ERROR_STATE is set
  if error_status ne 0 then begin
    catch, /cancel; Disable the catch system
    eva_error_message, error_status
    msg = [!Error_State.MSG,' ','...EVA will igonore this error.']
    ok = dialog_message(msg,/center,/error)
    progressbar -> Destroy
    message, /reset; Clear !ERROR_STATE
    perror = [perror,pcode]
    ;return, answer; 'answer' will be 'Yes', if at least some of the data were succesfully loaded.
  endif

  ;-------------
  ; LOAD
  ;-------------
  progressbar = Obj_New('progressbar', background='white', Text='Loading MMS data ..... 0 %')
  progressbar -> Start
  c = 0
  answer = 'No'
  for p=0,pmax-1 do begin; for each requested probe
    sc = sc_id[p]
    prb = strmid(sc,3,1)
    for i=0,imax-1 do begin; for each requested parameter
      
      if progressbar->CheckCancel() then begin
        ok = Dialog_Message('User cancelled operation.',/center) ; Other cleanup, etc. here.
        break
      endif
      
      prg = 100.0*float(c)/float(cparam)
      sprg = 'Loading MMS data ....... '+string(prg,format='(I2)')+' %'
      progressbar -> Update, prg, Text=sprg
      
      ; Check pre-loaded tplot variables. 
      ; Avoid reloading if already exists.
      tn=strlowcase(tnames('*',jmax))
      param = strlowcase(sc+strmid(paramlist[i],4,1000))
      if jmax eq 0 then begin; if no pre-loaded variable
        ct = 0
      endif else begin; if pre-loaded variable exists...
        idx = where(strmatch(tn,param),ct); check if param is one of the preloaded variables.
      endelse
 
      if ct eq 0 then begin; if not loaded
        ;-----------
        ; ASPOC
        ;-----------
        pcode=10
        ip=where(perror eq pcode,cp)
        if(strmatch(paramlist[i],'*_asp1_*') and (cp eq 0))then begin
          mms_load_aspoc,datatype='asp1',level='sitl',probe=prb
          answer = 'Yes'
        endif
        pcode=11
        ip=where(perror eq pcode,cp)
        if(strmatch(paramlist[i],'*_asp2_*') and (cp eq 0))then begin
          mms_load_aspoc,datatype='asp2',level='sitl',probe=prb
          answer = 'Yes'
        endif
        
        ;-----------
        ; EPD FEEPS
        ;-----------
        pcode=21
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_feeps_*') and (cp eq 0)) then begin
          mms_load_epd_feeps, sc=sc
          answer = 'Yes'
        endif
        
        ;-----------
        ; EPD EIS
        ;-----------
        pcode=22
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_epd_eis_*') and (cp eq 0)) then begin
          mms_load_epd_eis, sc=sc
          tn=tnames(sc+'_epd_eis_electronenergy_electron_cps_t1',jmax)
          if (strlen(tn[0]) gt 0) and (jmax ge 1) then begin
            options,tn[0],ytitle='electrons',ylog=1,yrange=[0.8,1e+5]
            answer = 'Yes'
          endif
        endif
        
        ;-----------
        ; FIELDS/AFG
        ;-----------
        pcode=30
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_afg*') and (cp eq 0)) then begin
          mms_sitl_get_afg, sc_id=sc
          options,sc+'_afg_srvy_gsm_dmpa',$
            labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CAFG!Csrvy',ysubtitle='GSM [nT]',$
            colors=[2,4,6],labflag=-1,constant=0,cap=1
          options,sc+'_afg_srvy_dmpa',$
            labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CAFG!Csrvy',ysubtitle='DMPA [nT]',$
            colors=[2,4,6],labflag=-1,constant=0,cap=1
          answer = 'Yes'
        endif
        pcode=31
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_omb*') and (cp eq 0)) then begin
          mms_sitl_get_afg, sc_id=sc, level='l1b'
          tn=tnames(sc+'*_afg_srvy_omb*',cnt)
          if (strlen(tn[0]) gt 0) and (cnt gt 0) then begin
            options,sc+'_afg_srvy_omb',$
              labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CDFG!Csrvy',ysubtitle='OMB [nT]',$
              colors=[2,4,6],labflag=-1,constant=0, cap=1
            answer = 'Yes'
          endif
          tn=tnames(sc+'*_afg_srvy_bcs*',cnt)
          if (strlen(tn[0]) gt 0) and (cnt gt 0) then begin
            options,sc+'_afg_srvy_bcs',$
              labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CDFG!Csrvy',ysubtitle='BCS [nT]',$
              colors=[2,4,6],labflag=-1,constant=0, cap=1
            answer = 'Yes'
          endif
        endif
        
        ;-----------
        ; FIELDS/DFG
        ;-----------
        pcode=32
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_dfg*') and (cp eq 0)) then begin
          mms_sitl_get_dfg, sc_id=sc
          options,sc+'_dfg_srvy_gsm_dmpa',$
            labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CDFG!Csrvy',ysubtitle='GSM [nT]',$
            colors=[2,4,6],labflag=-1,constant=0, cap=1
          options,sc+'_dfg_srvy_dmpa',$
            labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CDFG!Csrvy',ysubtitle='DMPA [nT]',$
            colors=[2,4,6],labflag=-1,constant=0, cap=1
          answer = 'Yes'
        endif
        pcode=33
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_omb*') and (cp eq 0)) then begin
          mms_sitl_get_dfg, sc_id=sc, level='l1b'
          tn=tnames(sc+'*_dfg_srvy_omb*',cnt)
          if (strlen(tn[0]) gt 0) and (cnt gt 0) then begin
            options,sc+'_dfg_srvy_omb',$
              labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CDFG!Csrvy',ysubtitle='OMB [nT]',$
              colors=[2,4,6],labflag=-1,constant=0, cap=1
            answer = 'Yes'
          endif
          tn=tnames(sc+'*_dfg_srvy_bcs*',cnt)
          if (strlen(tn[0]) gt 0) and (cnt gt 0) then begin
            options,sc+'_dfg_srvy_bcs',$
              labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CDFG!Csrvy',ysubtitle='BCS [nT]',$
              colors=[2,4,6],labflag=-1,constant=0, cap=1
            answer = 'Yes'
          endif
        endif

        ;-----------
        ; FIELDS/DSP
        ;-----------
        pcode=40
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_dsp_lfb*') and (cp eq 0)) then begin
          mms_sitl_get_dsp, sc=sc, datatype='bpsd'
          tn=tnames(sc+'*dsp_lfb*',cnt)
          if (strlen(tn[0]) gt 0) and (cnt gt 0) then begin
            options,tn,zlog=1
            ylim,tn,30,6000,1
            answer = 'Yes'
          endif
        endif
        
        pcode=41
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_dsp_mfe*') and (cp eq 0)) then begin
          mms_sitl_get_dsp, sc=sc, datatype='epsd'
          tn=tnames(sc+'*dsp_mfe*',cnt)
          if (strlen(tn[0]) gt 0) and (cnt gt 0) then begin
            options,tn,zlog=1
            ylim,tn,500,130000,1
            answer = 'Yes'
          endif
        endif
        
        pcode=42
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_dsp_bpsd_*') and (cp eq 0)) then begin
          mms_sitl_get_dsp, sc = sc, datatype = 'bpsd', level = 'l2', data_rate='fast'
          tn = tnames(sc+'_dsp_bpsd_*',cnt)
          if (strlen(tn[0]) gt 0) and (cnt gt 1) then begin
            options,sc+'_dsp_bpsd_omni_fast_l2', spec=1,zlog=1,ytitle=sc+'!CDSP!Cfast!Cbpsd_omni',ysubtitle='[Hz]',ztitle='[(nT)!U2!N/Hz]'
            ylim, tn, 32, 4000, 1
            for m=1,3 do begin
              strm = strtrim(string(m),2)
              options,sc+'_dsp_bpsd_scm'+strm+'_fast_l2',spec=1,zlog=1,ytitle=sc+'!CDSP!Cfast!Cbpsd_scm'+strm,$
                ysubtitle='[Hz]',ztitle='[(nT)!U2!N/Hz]'
              ylim, sc+'_dsp_bpsd_scm'+strm+'_fast_l2', 32, 4000, 1
            endfor
            answer = 'Yes'
          endif
        endif
        
        ;-------------
        ; FIELDS EDI
        ;-------------
        pcode=35
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_edi_amb_*') and (cp eq 0)) then begin
          mms_sitl_get_edi_amb,sc=sc
          eva_data_proc_edi, sc
          options,sc+'_edi_amb_pa0_raw_counts',ytitle=sc+'!CEDI!Cpa0',ysubtitle='[cts]'
          options,sc+'_edi_amb_pa180_raw_counts',ytitle=sc+'!CEDI!Cpa180',ysubtitle='[cts]'
          options,sc+'_edi_amb_gdu1_raw_counts1',ytitle=sc+'!CEDI!Cgdu1',ysubtitle='[cts]',ylog=1
          options,sc+'_edi_amb_gdu2_raw_counts1',ytitle=sc+'!CEDI!Cgdu2',ysubtitle='[cts]',ylog=1
          options,sc+'_edi_pitch_gdu1',ytitle=sc+'!CEDI!Cgdu1',ysubtitle='[pitch]'
          options,sc+'_edi_pitch_gdu2',ytitle=sc+'!CEDI!Cgdu2',ysubtitle='[pitch]'
          answer = 'Yes'
        endif
        
        ;------------
        ; FIELDS EDP
        ;------------
        pcode=36
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_edp_fast_dce_*') and (cp eq 0)) then begin
          mms_sitl_get_edp,sc=sc
          
          tn = tnames(sc+'_edp_fast_dce_dsl',cnt)
          if (strlen(tn[0]) gt 0) and (cnt eq 1) then begin
            options,tn,labels=['X','Y','Z'],ytitle=sc+'!CEDP!Cfast',ysubtitle='[mV/m]',$
              colors=[2,4,6],labflag=-1,yrange=[-20,20],constant=0
          
            get_data,tn,data=D,dl=dl,lim=lim
            str_element,/add,'lim','labels',['X','Y']
            str_element,/add,'lim','colors',[2,4]
            store_data,sc+'_edp_fast_dce_dsl_xy',data={x:D.x,y:D.y[*,0:1]},dl=dl,lim=lim
            
          endif
          answer = 'Yes'
        endif
        
        pcode=37
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_edp_fast_scpot*') and (cp eq 0)) then begin
          mms_sitl_get_edp, sc=sc, data_rate = 'fast', level='sitl', datatype='scpot'
          tn = tnames(sc+'_edp_fast_scpot_sitl',cnt)
          if (strlen(tn[0]) gt 0) and (cnt eq 1) then begin
            get_data,tn,data=D,dl=dl,lim=lim
            ynew = (-1)*alog10(D.y > 0)
            store_data,tn,data={x:D.x,y:ynew},dl=dl,lim=lim
            options,tn,ytitle=sc+'!CEDP!C-log(scpot)';,ysubtitle='[arbitrary]'
          endif
          answer = 'Yes'
        endif
        
        pcode=38
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_edp_srvy_*') and (cp eq 0)) then begin
          mms_sitl_get_edp, sc = sc, datatype='hfesp', level = 'l1b', data_rate='srvy'
          tn = tnames(sc+'_edp_srvy_EPSD_x',cnt)
          if (strlen(tn[0]) gt 0) and (cnt eq 1) then begin
            options,tn,ytitle=sc+'!CEDP!Csrvy!Cepsd_x',ysubtitle='[Hz]',ztitle='[(V/m)!U2!N/Hz]'
            options,tn,spec=1,zlog=1
            ylim,tn,600,65536,1 
          endif
          answer = 'Yes'
        endif
        
        ;-----------
        ; FPI
        ;-----------
        pcode=50
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_fpi_*') and (cp eq 0)) then begin
          eva_data_load_mms_fpi, sc=sc
          answer = 'Yes'
        endif

        ;-----------
        ; FPI QL
        ;-----------
        pcode=51
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_des_*') and (cp eq 0)) then begin
          eva_data_load_mms_fpi_ql, prb=prb, datatype='des'
          answer = 'Yes'
        endif
        pcode=52
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_dis_*') and (cp eq 0)) then begin
          eva_data_load_mms_fpi_ql, prb=prb, datatype='dis'
          answer = 'Yes'
        endif
        
        ;--------------
        ; FPI BentPipe
        ;--------------
        pcode=53
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_fpi_bent*') and (cp eq 0)) then begin
          mms_load_fpi, probes = prb, level='sitl', data_rate='fast'
          get_data,sc+'_fpi_bentPipeB_X_DSC',data=Dx
          get_data,sc+'_fpi_bentPipeB_Y_DSC',data=Dy
          get_data,sc+'_fpi_bentPipeB_Z_DSC',data=Dz
          get_data,sc+'_fpi_bentPipeB_Norm',data=Dabs
          ydata = [[Dabs.Y*Dx.Y], [Dabs.Y*Dy.Y], [Dabs.Y*Dz.Y]]
          ysize = sqrt(ydata[*,0]^2+ydata[*,1]^2+ydata[*,2]^2)
          store_data,sc+'_fpi_bentPipeB_DSC',data={x:Dx.X, y:ydata}
          store_data,sc+'_fpi_bentPipeB_DSC_m',data={x:Dx.X, y:ysize}
          options,sc+'_fpi_bentPipeB_DSC',$
            labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CFPI!CbentPipeB',ysubtitle='DSC',$
            colors=[2,4,6],labflag=-1,constant=0
          options,sc+'_fpi_bentPipeB_DSC_m',constant=0,colors=[0],$
            ytitle=sc+'!CFPI!CbentPipeB',ysubtitle='(magnitude)'
          answer = 'Yes'
        endif
        
        ;-----------
        ; HPCA
        ;-----------
        pcode=60
        ip=where(perror eq pcode,cp)
        level = 'sitl'
        if (strmatch(paramlist[i],'*_hpca_*rf_corrected') and (cp eq 0)) then begin
          sh='H!U+!N'
          sa='He!U++!N'
          sp='He!U+!N'
          so='O!U+!N'
          mms_sitl_get_hpca, probes=prb, level=level, datatype='rf_corr'

          options, sc+'_hpca_hplus_RF_corrected', ytitle=sc+'!CHPCA!C'+sh,ysubtitle='[eV]',ztitle='eflux',/spec,/ylog,/zlog
          ylim,    sc+'_hpca_hplus_RF_corrected', 1, 40000
          options, sc+'_hpca_heplusplus_RF_corrected', ytitle=sc+'!CHPCA!C'+sa,ysubtitle='[eV]',ztitle='eflux',/spec,/ylog,/zlog
          ylim,    sc+'_hpca_heplusplus_RF_corrected', 1, 40000
          options, sc+'_hpca_heplus_RF_corrected', ytitle=sc+'!CHPCA!C'+sp,ysubtitle='[eV]',ztitle='eflux',/spec,/ylog,/zlog
          ylim,    sc+'_hpca_heplus_RF_corrected', 1, 40000
          options, sc+'_hpca_oplus_RF_corrected', ytitle=sc+'!CHPCA!C'+so,ysubtitle='[eV]',ztitle='eflux',/spec,/ylog,/zlog
          ylim,    sc+'_hpca_oplus_RF_corrected', 1, 40000
          answer = 'Yes'
        endif
        
        pcode=61
        ip=where(perror eq pcode,cp)
        level = 'sitl'
        if( (cp eq 0) and $
          (strmatch(paramlist[i],'*_hpca_*number_density') or strmatch(paramlist[i],'*_hpca_*bulk_velocity'))) then begin
          ;mms_sitl_get_hpca_moments, sc_id=sc, level=level
          mms_sitl_get_hpca, probes=prb, level=level, datatype='moments'
          sh='(H!U+!N)'
          so='(O!U+!N)'
          options, sc+'_hpca_hplus_number_density',ytitle=sc+'!CHPCA!CN '+sh,ysubtitle='[cm!U-3!N]',/ylog,$
            colors=1,labels=['N '+sh]
          options, sc+'_hpca_oplus_number_density',ytitle=sc+'!CHPCA!CN '+so,ysubtitle='[cm!U-3!N]',/ylog,$
            colors=3,labels=['N '+so]
          options, sc+'_hpca_hplus_bulk_velocity',ytitle=sc+'!CHPCA!CV '+sh,ysubtitle='[km/s]',ylog=0,$
            colors=[2,4,6],labels=['V!DX!N '+sh, 'V!DY!N '+sh, 'V!DZ!N '+sh],labflag=-1
          options, sc+'_hpca_oplus_bulk_velocity',ytitle=sc+'!CHPCA!CV '+so,ysubtitle='[km/s]',ylog=0,$
            colors=[2,4,6],labels=['V!DX!N '+so, 'V!DY!N '+so, 'V!DZ!N '+so],labflag=-1
          options, sc+'_hpca_hplus_scalar_temperature',ytitle=sc+'!CHPCA!CT '+sh,ysubtitle='[eV]',/ylog,$
            colors=1,labels=['T '+sh]
          options, sc+'_hpca_oplus_scalar_temperature',ytitle=sc+'!CHPCA!CT '+so,ysubtitle='[eV]',/ylog,$
            colors=3,labels=['T '+so]

          options, sc+'_hpca_hplusoplus_number_densities',ytitle=sc+'!CHPCA!CDensity',ysubtitle='[cm!U-3!N]',/ylog,$
            colors=[1,3],labels=['N '+sh, 'N '+so],labflag=-1
          options, sc+'_hpca_hplusoplus_scalar_temperatures',ytitle=sc+'!CHPCA!CTemp',ysubtitle='[eV]',$
            colors=[1,3],labels=['T '+sh, 'T '+so],labflag=-1

          answer = 'Yes'
        endif

        ;-----------
        ; AE Index
        ;-----------
        pcode=80
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'thg_idx_ae') and (cp eq 0)) then begin
          thm_load_pseudoAE,datatype='ae'
          if tnames('thg_idx_ae') eq '' then begin
            store_data,'thg_idx_ae',data={x:[ts,te], y:replicate(!values.d_nan,2)}
          endif
          options,'thg_idx_ae',ytitle='THEMIS!CAE Index'
          answer = 'Yes'
        endif
        
        ;-----------
        ; ExB
        ;-----------
        pcode=81
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_exb_*') and (cp eq 0)) then begin
          eva_data_load_mms_exb,sc=sc,vthres=500.
          answer = 'Yes'
        endif
        pcode=82
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_exbql_*') and (cp eq 0)) then begin
          eva_data_load_mms_exb,sc=sc,vthres=500.,/ql
          answer = 'Yes'
        endif
        
      endif;if ct eq 0 then begin; if not loaded
      c+=1
    endfor; for each requested parameter
    
    ;-------------
    ; ORBIT INFO
    ;-------------
    matched=0
    Re = 6371.2
    ; predicted orbit from AFG
    tn=tnames(sc+'_ql_pos_gsm',jmax)
    if (strlen(tn[0]) gt 0) and (jmax eq 1) then begin
      get_data,sc+'_ql_pos_gsm',data=D,lim=lim,dl=dl
      wtime = D.x
      wdist = D.y[*,3]/Re
      wposx = D.y[*,0]/Re
      wposy = D.y[*,1]/Re
      wposz = D.y[*,2]/Re
      wphi  = atan(wposy,wposx)/!DTOR
      wxlt  = 12. + wphi/15.
      wlat  = atan(wposz,sqrt(wposx^2+wposy^2))/!DTOR
      matched=1
    endif
    
    if matched then begin
      store_data,sc+'_position_z',data={x:wtime,y:wposz}
      options,sc+'_position_z',ytitle=sc+' Zgsm (Re)'
      store_data,sc+'_position_y',data={x:wtime,y:wposy}
      options,sc+'_position_y',ytitle=sc+' Ygsm (Re)'
      store_data,sc+'_position_x',data={x:wtime,y:wposx}
      options,sc+'_position_x',ytitle=sc+' Xgsm (Re)'
      store_data,sc+'_position_r',data={x:wtime,y:wdist}
      options,sc+'_position_r',ytitle=sc+' R (Re)'
      store_data,sc+'_position_mlt',data={x:wtime,y:wxlt}
      options,sc+'_position_mlt',ytitle=sc+' MLT (hr)'
      store_data,sc+'_position_mlat',data={x:wtime,y:wlat}
      options,sc+'_position_mlat',ytitle=sc+' MLAT (deg)'
    endif
    
  endfor; for each requested probe
  
  progressbar -> Destroy
  return, answer
END
