mms_init

!mms.no_server = 0

;timespan,'2015-08-28/14:53:30',45,/sec

;timespan,'2015-08-28/14:50',5,/min

;timespan,'2015-08-28/14:53:30',45,/sec

;timespan,'2015-09-19/07:40', 6, /min

;timespan,'2015-09-19/07:43:20', 20, /sec ; zoom

;timespan,'2015-10-01/06:50', 6, /min

;timespan,'2015-10-03/14:45', 4.4, /min

;timespan,'2015-10-03/14:46:50', 35,/sec

;timespan,'2015-10-16/10:30', 5,/min ; yuri; FPI not available

;timespan,'2015-10-16/13:05', 2.5,/min ; Jonathan

;timespan,'2015-10-16/13:06:30', 1,/min ; Jonathan

timespan,'2015-09-19/09:04:30', 6.5, /min




;timespan,'2015-09-19/07:40', 6, /min

;timespan,'2015-09-19/07:43:20', 20, /sec ; zoom

;timespan,'2015-09-19/09:59', 15, /min

;timespan,'2015-10-05/11:40',7,/min

;timespan,'2015-09-30/16:40',4,/min

;timespan,'2015-10-03/14:45', 5, /min

;timespan,'2015-10-16/10:30', 5, /min

;timespan,'2015-10-16/13:05', 5, /min





probe_id=3

level='ql' ;'ql' or 'l2pre' or 'srvy'  (specify DFG data level)

sc_id='mms'+string(probe_id,format='(I1)')

mms_load_data, instrument='fpi',probes=probe_id, datatype='dis-moms', level='l1b', data_rate='brst'
mms_load_data, instrument='fpi',probes=probe_id, datatype='des-moms', level='l1b', data_rate='brst'
mms_load_data, instrument='dfg',probes=probe_id, datatype='',  data_rate='srvy'; 7 samples/s
mms_load_data, instrument='edp',probes=probe_id, level='ql', data_rate='fast', datatype='dce'

if level eq 'l2pre' then begin
	mms_load_dfg, probes=probe_id, level='l2pre', data_rate='brst', /no_attitude_data 
	copy_data,sc_id+'_dfg_brst_l2pre_dmpa','B'
endif

if level eq 'ql' then begin
	mms_load_dfg, probes=probe_id, level='ql', data_rate='brst', /no_attitude_data 
	copy_data,sc_id+'_dfg_brst_dmpa','B'

endif

if level eq 'srvy' then begin
	mms_load_dfg, probes=probe_id, data_rate='srvy', /no_attitude_data 
	copy_data,sc_id+'_dfg_srvy_dmpa','B'
endif

copy_data,sc_id+'_dis_numberDensity','Ni'
copy_data,sc_id+'_des_numberDensity','Ne'
copy_data,sc_id+'_dis_bulkSpeed','Vi_mag'
copy_data,sc_id+'_des_bulkSpeed','Ve_mag'
copy_data,sc_id+'_dis_bulkX','Vix'
copy_data,sc_id+'_dis_bulkY','Viy'
copy_data,sc_id+'_dis_bulkZ','Viz'
copy_data,sc_id+'_des_bulkX','Vex'
copy_data,sc_id+'_des_bulkY','Vey'
copy_data,sc_id+'_des_bulkZ','Vez'
copy_data,sc_id+'_edp_dce_xyz_dsl','E'



;copy_data,sc_id+'_dfg_brst_l2pre_dmpa','B'
;copy_data,sc_id+'_dfg_srvy_l2pre_dmpa','B'
;copy_data,sc_id+'_dfg_srvy_dmpa','B'
;copy_data,sc_id+'_dfg_brst_dmpa','B'


get_data,'B',data=d
store_data,'B',data={x:d.x-0.00390625d,y:d.y(*,0:2)}
store_data,'Bmag',data={x:d.x-0.00390625d,y:d.y(*,3)}

get_data,'Vix',data=vix
get_data,'Viy',data=viy
get_data,'Viz',data=viz
vi=fltarr(n_elements(vix.x),3)
vi(*,0)=vix.y
vi(*,1)=viy.y
vi(*,2)=viz.y
store_data,'vi',data={x:vix.x,y:vi}

get_data,'Vex',data=vex
get_data,'Vey',data=vey
get_data,'Vez',data=vez
ve=fltarr(n_elements(vex.x),3)
ve(*,0)=vex.y
ve(*,1)=vey.y
ve(*,2)=vez.y
store_data,'ve',data={x:vex.x,y:ve}

box_ave_mms, variable1='vi', variable2='ve', var2ave='ve_ave'

box_ave_mms, variable1='vi', variable2='Ne', var2ave='Ne_ave'

get_data,'vi',data=vii
get_data,'ve_ave',data=vee
get_data,'Ni',data=ni

get_data,'Ne_ave',data=ne_ave

store_data,'diff_vi_ve',data={x:vii.x,y:vii.y-vee.y}
store_data,'current_vi_ve',data={x:vii.x,y:(ne_ave.y#[1.,1.,1.])*(vii.y-vee.y)*1.6e-10}


get_data,sc_id+'_dis_TempXX',data=tixx
get_data,sc_id+'_dis_TempYY',data=tiyy
get_data,sc_id+'_dis_TempZZ',data=tizz
get_data,sc_id+'_dis_TempXY',data=tixy
get_data,sc_id+'_dis_TempXZ',data=tixz
get_data,sc_id+'_dis_TempYZ',data=tiyz

ti_tensor=fltarr(n_elements(tixx.x),6)
ti_tensor(*,0)=tixx.y
ti_tensor(*,1)=tiyy.y
ti_tensor(*,2)=tizz.y
ti_tensor(*,3)=tixy.y
ti_tensor(*,4)=tixz.y
ti_tensor(*,5)=tiyz.y

store_data,'ti_tensor',data={x:tixx.x,y:ti_tensor}

diag_t,'ti_tensor'
copy_data,'T_diag','Ti'
get_data,'Ti',data=d
ylim,'Ti',min(d.y),max(d.y),1


get_data,sc_id+'_des_TempXX',data=texx
get_data,sc_id+'_des_TempYY',data=teyy
get_data,sc_id+'_des_TempZZ',data=tezz
get_data,sc_id+'_des_TempXY',data=texy
get_data,sc_id+'_des_TempXZ',data=texz
get_data,sc_id+'_des_TempYZ',data=teyz

te_tensor=fltarr(n_elements(texx.x),6)
te_tensor(*,0)=texx.y
te_tensor(*,1)=teyy.y
te_tensor(*,2)=tezz.y
te_tensor(*,3)=texy.y
te_tensor(*,4)=texz.y
te_tensor(*,5)=teyz.y

store_data,'te_tensor',data={x:texx.x,y:te_tensor}

diag_t,'te_tensor'
copy_data,'T_diag','Te'

get_data,'Te',data=d
ylim,'Te',min(d.y),max(d.y),1

store_data,'v_mag',data=['Vi_mag','Ve_mag']
options,'v_mag','colors',[2,6]

store_data,'N',data=['Ni','Ne']
options,'N','colors',[2,6]

;tplot_restore,fi='eastwood_20151016.tplot'

ylim,'vi',-500,500,0
ylim,'ve',-500,500,0
ylim,'ve_ave',-500,500,0

get_data,'E',data=d
store_data,'Exy',data={x:d.x,y:d.y(*,0:1)}

options,'Exy',colors=[2,4]

interpolate,'Exy','B','B_interp'

;ylim,'jtotal',-1.5e-6,2e-6,0   
tplot_options,'ygap',0.3

;options,'jtotal',colors=[2,4,6]





;tplot,['B','Bmag','N','v_mag','vi','ve','current_vi_ve','jtotal','E'],title=sc_id

tplot,['B','Bmag','N','v_mag','vi','ve','ve_ave','current_vi_ve','Exy','Ti','Te'],title=sc_id

;tplot,['N','v_mag','vi','ve','E','B','B_i','B_e']

stop

end


