pro mms_test_j2000
  
  mms_load_state, probe='1', datatype='pos', trange=['2015-09-01', '2015-09-02']
  
  get_data, 'mms1_defeph_pos', data=dj2000, dlimits=dlj2000, limits=lj2000
  
  cotrans, 'mms1_defeph_pos', 'mms1_defeph_gei', /j20002gei 
  cotrans, 'mms1_defeph_gei', 'mms1_defeph_j2000', /gei2j2000
  
  get_data, 'mms1_defeph_pos', data=dj2000, dlimits=dlj2000, limits=lj2000
  get_data, 'mms1_defeph_gei', data=dgei, dlimits=dlgei, limits=lgei
  get_data, 'mms1_defeph_j2000', data=dj20001, dlimits=dlj20001, limits=lj20001
 
  tsgei=time_struct(dgei.x)
  tsj2000=time_struct(dj2000.x)
  tsj20001=time_struct(dj20001.x)
  
  ; create an integer array for ic_conv_matrix
  ; the format is  YYYYDDD for [n,0] and  sss (seconds of day) for [n,1]
  orbtime = make_array(n_elements(dgei.x), 2, /long)
  orbtime[*,0] = long((tsgei.year * 1000.) + tsgei.doy)
  orbtime[*,1] = long(fix(tsgei.sod))
  data_ic = dj2000 
  
  for i=0,n_elements(dgei.x)-1 do begin
    ic_conv_matrix, reform(orbtime[i,*]), cmatrix
    data_ic.y[i,*] = reform(dj2000.y[i,*]) # (cmatrix)  
  endfor

  j2000_mag = sqrt(total(dj2000.y^2,2))
  gei_mag = sqrt(total(dgei.y^2,2))
  j20001_mag = sqrt(total(dj20001.y^2,2))

  print, 'Compare Radial distances - they should be close to zero'
  print, 'min/max j2000/j20001 '
  mm = minmax(abs(j2000_mag-j20001_mag))
  print, mm

stop  

end