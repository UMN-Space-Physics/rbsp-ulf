
;+
;Procedure:
;  mms_part_products_crib
;
;Purpose:
;  Basic example on how to use mms_part_products to generate pitch angle and gyrophase distributions
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-02-10 19:23:21 -0800 (Wed, 10 Feb 2016) $
;$LastChangedRevision: 19951 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_part_products_crib.pro $
;
;-

;===================================
; FPI
;===================================

  ;clear data
  del_data,'*'
  ;set time interval
  probe='3'
  species='e'
  rate='brst'
  ;timespan,'2015-09-21/13:52', 2, /min
  ;trange = timerange()
  ;trange = ['2015-09-19/09:08:13', '2015-09-19/09:09']
  ;trange = ['2015-09-19/09:08:48', '2015-09-19/09:09:00']
  trange = ['2015-09-19/09:08:00', '2015-09-19/09:08:15']
  timespan,trange
  
  level = 'def'     ; 'pred'
 
  ;load state data.(needed for coordinate transforms and field aligned coordinates)
  mms_load_state, probes=probe, level=level

  ;load particle data
  mms_load_fpi, data_rate=rate, level='l1b', datatype='d'+species+'s-dist', $
    probe=probe, trange=trange
    
  ;load magnetic field data
  mms_load_dfg, probe=probe, trange=trange 
 
  ;Until coordinate systems are properly labeled in mms metadata, this variable must be dmpa
  bname = 'mms'+probe+'_dfg_srvy_l2pre_dmpa_bvec'
  
  ;Not all mms position data have coordinate systems labeled in metadata, this one does
  pos_name = 'mms' + probe+ '_defeph_pos'
  
  ;convert particle data to 3D structures
  name =  'mms'+probe+'_d'+species+'s_'+rate+'SkyMap_dist'
 
  mms_part_products,name,mag_name=bname,pos_name=pos_name,trange=trange,outputs=['phi','theta','pa','gyro','energy'],probe=probe

  tplot,name+'_'+['energy','theta','phi','pa','gyro']
  tlimit,['2015-09-19/09:08:14', '2015-09-19/09:08:15'] 

  stop
 

;===================================
; HPCA
;===================================

  ;clear data
  del_data,'*'

  ;setup
  probe='1'
  species='hplus'
  data_rate = 'brst'
  ;data_rate = 'srvy'

  timespan, '2015-10-20/05:56:30', 5, /min  ;brst
  ;timespan, '2015-11-16/06:32:00', 20, /min  ;brst/srvy
  trange = timerange()
  
  ;load particle data
  mms_load_hpca, data_rate=data_rate, level='l1b', datatype='vel_dist', $
                 probe=probe, trange=trange

  ;load azimuth data
  mms_load_hpca, probe=probe, trange=trange, $
                 data_rate=data_rate, level='l1a', datatype='spinangles', $
                 varformat='*_angles_per_ev_degrees'

  ;load state data (needed for coordinate transforms and field aligned coordinates)
  mms_load_state, probes=probe, trange=trange

  ;load magnetic field data (for field aligned coordinates)
  mms_load_dfg, probe=probe, trange=trange 
 
  ;until coordinate systems are properly labeled in mms metadata, this variable must be dmpa
  bname = 'mms'+probe+'_dfg_srvy_l2pre_dmpa_bvec'
  
  ;not all mms position data have coordinate systems labeled in metadata, this one does
  pos_name = 'mms' + probe+ '_defeph_pos'
  
  ;name of tplot variable containing the particle data
  name =  'mms'+probe+'_hpca_'+species+'_vel_dist_fn'
 
  mms_part_products, name, mag_name=bname, pos_name=pos_name, trange=trange,$
                    outputs=['phi','theta','pa','gyro','energy'],probe=probe

  tplot,name+'_'+['energy','theta','phi','pa','gyro']

  

  

end