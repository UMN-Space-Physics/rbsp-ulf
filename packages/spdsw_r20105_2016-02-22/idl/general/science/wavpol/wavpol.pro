;+
;
; NAME:wavpol
;
; MODIFICATION HISTORY:Written By Chris Chaston, 30-10-96
;		      :Modified by Vassilis, 2001-07-11
;             :Modified by Olivier Le Contel, 2008-07
;              to be able to change nopfft and steplength
;PURPOSE:To perform polarisation analysis of three orthogonal component time
;         series data.
;
;EXAMPLE: wavpol,ct,Bx,By,Bz,timeline,freqline,powspec,degpol,waveangle,elliptict,helict
;
;CALLING SEQUENCE: wavpol,ct,Bx,By,Bz,timeline,freqline,powspec,degpol,waveangle,elliptict,helict
;
;INPUTS:ct,Bx,By,Bz, are IDL arrays of the time series data; ct is cline time
;
;       Subroutine assumes data are in righthanded fieldaligned
;	coordinate system with Z pointing the direction
;       of the ambient magnetic field.
;
;       threshold:-if this keyword is set then results for ellipticity,
;       helicity and wavenormal are set to Nan if below 0.6 deg pol
;
;;Keywords:
;  nopfft(optional) = Number of points in FFT
;  
;  steplength(optional) = The amount of overlap between successive FFT intervals
;
;OUTPUTS: The program outputs five spectral results derived from the
;         fourier transform of the covariance matrix (spectral matrix)
;         These are follows:
;
;         Wave power: On a linear scale, at this stage no units
;
;         Degree of Polarisation:
;		This is similar to a measure of coherency between the input
;		signals, however unlike coherency it is invariant under
;		coordinate transformation and can detect pure state waves
;		which may exist in one channel only.100% indicates a pure
;		state wave. Less than 70% indicates noise. For more
;		information see J. C. Samson and J. V. Olson 'Some comments
;		on the description of the polarization states
;		of waves' Geophys. J. R. Astr. Soc. (1980) v61 115-130
;
;   Wavenormal Angle:
;     The angle between the direction of minimum variance
;     calculated from the complex off diagonal elements of the
;     spectral matrix and the Z direction of the input ac field data.
;     for magnetic field data in field aligned coordinates this is the
;     wavenormal angle assuming a plane wave. See:
;     Means, J. D. (1972), Use of the three-dimensional covariance
;     matrix in analyzing the polarization properties of plane waves,
;     J. Geophys. Res., 77(28), 5551-5559,
;     doi:10.1029/JA077i028p05551.
;
;   Ellipticity:
;     The ratio (minor axis)/(major axis) of the ellipse transcribed
;     by the field variations of the components transverse to the
;     Z direction (Samson and Olson, 1980). The sign indicates
;     the direction of rotation of the field vector in the plane (cf.
;     Means, (1972)).
;     Negative signs refer to left-handed rotation about the Z
;     direction. In the field aligned coordinate system these signs
;     refer to plasma waves of left and right handed polarization.
;         
;
;         Helicity:Similar to Ellipticity except defined in terms of the
;	direction of minimum variance instead of Z. Stricltly the Helicity
;	is defined in terms of the wavenormal direction or k.
;	However since from single point observations the
;	sense of k cannot be determined,  helicity here is
;	simply the ratio of the minor to major axis transverse to the
;       minimum variance direction without sign.
;
;
;RESTRICTIONS:-If one component is an order of magnitude or more  greater than
;	the other two then the polarisation results saturate and erroneously
;	indicate high degrees of polarisation at all times and
;	frequencies. Time series should be eyeballed before running the program.
;	 For time series containing very rapid changes or spikes
;	 the usual problems with Fourier analysis arise.
;	 Care should be taken in evaluating degree of polarisation results.
;	 For meaningful results there should be significant wave power at the
;	 frequency where the polarisation approaches
;	 100%. Remembercomparing two straight lines yields 100% polarisation.
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2014-11-07 16:36:07 -0800 (Fri, 07 Nov 2014) $
; $LastChangedRevision: 16154 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/wavpol/wavpol.pro $
;-
pro wavpol,ct,Bx,By,Bz,timeline,freqline,powspec,degpol,waveangle,elliptict,helict,pspec3,$
nopfft=nopfft_input,steplength = steplength_input
nopoints=n_elements(Bx)
If size(nopfft_input, /type) ne 0 then nopfft = nopfft_input else nopfft = 256
If size(steplength_input, /type) ne 0 then steplength = steplength_input else steplength =  nopfft/2
;
;steplength =128                                  ;overlap between successive FFT intervals
;nopfft=256										  ;no. of points in FFT

nosteps=(nopoints-nopfft)/steplength             ;total number of FFTs
leveltplot=0.000001                                         ;power rejection level 0 to 1
lam=dblarr(2)
nosmbins=7                                       ;No. of bins in frequency domain
;!p.charsize=2                                    ;to include in smoothing (must be odd)
aa=[0.024,0.093,0.232,0.301,0.232,0.093,0.024]   ;smoothing profile based on Hanning
;
;ARRAY DEFINITIONS

fields=make_array(3, nopoints,/double)
power=Make_Array(nosteps,nopfft/2)
specx=Make_Array(nosteps,nopfft,/dcomplex)
specy=Make_Array(nosteps,nopfft,/dcomplex)
specz=Make_Array(nosteps,nopfft,/dcomplex)
wnx=DBLARR(nosteps,nopfft/2)
wny=DBLARR(nosteps,nopfft/2)
wnz=DBLARR(nosteps,nopfft/2)
vecspec=Make_Array(nosteps,nopfft/2,3,/dcomplex)
matspec=Make_Array(nosteps,nopfft/2,3,3,/dcomplex)
ematspec=Make_Array(nosteps,nopfft/2,3,3,/dcomplex)
matsqrd=Make_Array(nosteps,nopfft/2,3,3,/dcomplex)
matsqrd1=Make_Array(nosteps,nopfft/2,3,3,/dcomplex)
trmatspec=Make_Array(nosteps,nopfft/2,/double)
xrmatspec=Make_Array(nosteps,nopfft/2,/double) ; added 10Sep2013 jhl
yrmatspec=Make_Array(nosteps,nopfft/2,/double) ; added 10Sep2013 jhl
zrmatspec=Make_Array(nosteps,nopfft/2,/double) ; added 10Sep2013 jhl
powspec=Make_Array(nosteps,nopfft/2,/double)
trmatsqrd=Make_Array(nosteps,nopfft/2,/double)
degpol=Make_Array(nosteps,nopfft/2,/double)
alpha=Make_Array(nosteps,nopfft/2,/double)
alphasin2=Make_Array(nosteps,nopfft/2,/double)
alphacos2=Make_Array(nosteps,nopfft/2,/double)
alphasin3=Make_Array(nosteps,nopfft/2,/double)
alphacos3=Make_Array(nosteps,nopfft/2,/double)
alphax=Make_Array(nosteps,nopfft/2,/double)
alphasin2x=Make_Array(nosteps,nopfft/2,/double)
alphacos2x=Make_Array(nosteps,nopfft/2,/double)
alphasin3x=Make_Array(nosteps,nopfft/2,/double)
alphacos3x=Make_Array(nosteps,nopfft/2,/double)
alphay=Make_Array(nosteps,nopfft/2,/double)
alphasin2y=Make_Array(nosteps,nopfft/2,/double)
alphacos2y=Make_Array(nosteps,nopfft/2,/double)
alphasin3y=Make_Array(nosteps,nopfft/2,/double)
alphacos3y=Make_Array(nosteps,nopfft/2,/double)
alphaz=Make_Array(nosteps,nopfft/2,/double)
alphasin2z=Make_Array(nosteps,nopfft/2,/double)
alphacos2z=Make_Array(nosteps,nopfft/2,/double)
alphasin3z=Make_Array(nosteps,nopfft/2,/double)
alphacos3z=Make_Array(nosteps,nopfft/2,/double)
gammay=Make_Array(nosteps,nopfft/2,/double)
gammarot=Make_Array(nosteps,nopfft/2,/double)
upper=Make_Array(nosteps,nopfft/2,/double)
lower=Make_Array(nosteps,nopfft/2,/double)
lambdau=Make_Array(nosteps,nopfft/2,3,3,/dcomplex)
lambdaurot=Make_Array(nosteps,nopfft/2,2,/dcomplex)
thetarot=Make_Array(nopfft/2,/double)
thetax=DBLARR(nosteps,nopfft)
thetay=DBLARR(nosteps,nopfft)
thetaz=DBLARR(nosteps,nopfft)
aaa2=DBLARR(nosteps,nopfft/2)
helicity=Make_Array(nosteps,nopfft/2,3)
ellip=Make_Array(nosteps,nopfft/2,3)
waveangle=Make_Array(nosteps,nopfft/2)
halfspecx=Make_Array(nosteps,nopfft/2,/dcomplex)
halfspecy=Make_Array(nosteps,nopfft/2,/dcomplex)
halfspecz=Make_Array(nosteps,nopfft/2,/dcomplex)
;
; DEFINE ARRAYS
;
xs=Bx & ys=By & zs=Bz
sampfreq=1/(ct[1]-ct[0])
endsampfreq=1/(ct[nopoints-1]-ct[nopoints-2])
   if sampfreq NE endsampfreq then dprint, 'Warning: file sampling ' + $
  'frequency changes',sampfreq,'Hz to',endsampfreq,'Hz' else dprint, 'ac ' + $
  'file sampling frequency',sampfreq,'Hz'
;
print,' '
dprint,  'Total number of steps',nosteps
print,' '
counter_start = 0
for j=0L,(nosteps-1) do begin

if 10*double(j)/(nosteps-1) gt (counter_start+1) then begin
  dprint, strtrim(100*double(j)/(nosteps-1),2) + ' % Complete '
  dprint, ' Processing step no. :'+ strtrim(j+1,2)
  counter_start++
endif
;
;FFT CALCULATION

     smooth=0.08+0.46*(1-cos(2*!DPI*findgen(nopfft)/nopfft))
     tempx=smooth*xs[0:nopfft-1]
     tempy=smooth*ys[0:nopfft-1]
     tempz=smooth*zs[0:nopfft-1]
     specx[j,*]=(fft(tempx,/double));+Complex(0,j*steplength*3.1415/32))
     specy[j,*]=(fft(tempy,/double));+Complex(0,j*steplength*3.1415/32))
     specz[j,*]=(fft(tempz,/double));+Complex(0,j*steplength*3.1415/32))
     halfspecx[j,*]=specx[j,0:(nopfft/2-1)]
     halfspecy[j,*]=specy[j,0:(nopfft/2-1)]
     halfspecz[j,*]=specz[j,0:(nopfft/2-1)]
     xs=shift(xs,-steplength)
     ys=shift(ys,-steplength)
     zs=shift(zs,-steplength)

;CALCULATION OF THE SPECTRAL MATRIX

    matspec[j,*,0,0]=halfspecx[j,*]*conj(halfspecx[j,*])
    matspec[j,*,1,0]=halfspecx[j,*]*conj(halfspecy[j,*])
    matspec[j,*,2,0]=halfspecx[j,*]*conj(halfspecz[j,*])
    matspec[j,*,0,1]=halfspecy[j,*]*conj(halfspecx[j,*])
    matspec[j,*,1,1]=halfspecy[j,*]*conj(halfspecy[j,*])
    matspec[j,*,2,1]=halfspecy[j,*]*conj(halfspecz[j,*])
    matspec[j,*,0,2]=halfspecz[j,*]*conj(halfspecx[j,*])
    matspec[j,*,1,2]=halfspecz[j,*]*conj(halfspecy[j,*])
    matspec[j,*,2,2]=halfspecz[j,*]*conj(halfspecz[j,*])

;CALCULATION OF SMOOTHED SPECTRAL MATRIX

     for k=(nosmbins-1)/2, (nopfft/2-1)-(nosmbins-1)/2 do begin
          ematspec[j,k,0,0]=TOTAL(aa[0:(nosmbins-1)]*matspec[j,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),0,0])
          ematspec[j,k,1,0]=TOTAL(aa[0:(nosmbins-1)]*matspec[j,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),1,0])
          ematspec[j,k,2,0]=TOTAL(aa[0:(nosmbins-1)]*matspec[j,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),2,0])
          ematspec[j,k,0,1]=TOTAL(aa[0:(nosmbins-1)]*matspec[j,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),0,1])
          ematspec[j,k,1,1]=TOTAL(aa[0:(nosmbins-1)]*matspec[j,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),1,1])
          ematspec[j,k,2,1]=TOTAL(aa[0:(nosmbins-1)]*matspec[j,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),2,1])
          ematspec[j,k,0,2]=TOTAL(aa[0:(nosmbins-1)]*matspec[j,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),0,2])
          ematspec[j,k,1,2]=TOTAL(aa[0:(nosmbins-1)]*matspec[j,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),1,2])
          ematspec[j,k,2,2]=TOTAL(aa[0:(nosmbins-1)]*matspec[j,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),2,2])
      endfor

;CALCULATION OF THE MINIMUM VARIANCE DIRECTION AND WAVENORMAL ANGLE

     aaa2[j,*]=SQRT(IMAGINARY(ematspec[j,*,0,1])^2+IMAGINARY(ematspec[j,*,0,2])^2+IMAGINARY(ematspec[j,*,1,2])^2)
     wnx[j,*]=ABS(IMAGINARY(ematspec[j,*,1,2])/aaa2[j,*])
     wny[j,*]=-ABS(IMAGINARY(ematspec[j,*,0,2])/aaa2[j,*])
     wnz[j,*]=IMAGINARY(ematspec[j,*,0,1])/aaa2[j,*]
     waveangle[j,*]=ATAN(Sqrt(wnx[j,*]^2+wny[j,*]^2),abs(wnz[j,*]))

;CALCULATION OF THE DEGREE OF POLARISATION

;calc of square of smoothed spec matrix
     matsqrd[j,*,0,0]=ematspec[j,*,0,0]*ematspec[j,*,0,0]+ematspec[j,*,0,1]*ematspec[j,*,1,0]+ematspec[j,*,0,2]*ematspec[j,*,2,0]
     matsqrd[j,*,0,1]=ematspec[j,*,0,0]*ematspec[j,*,0,1]+ematspec[j,*,0,1]*ematspec[j,*,1,1]+ematspec[j,*,0,2]*ematspec[j,*,2,1]
     matsqrd[j,*,0,2]=ematspec[j,*,0,0]*ematspec[j,*,0,2]+ematspec[j,*,0,1]*ematspec[j,*,1,2]+ematspec[j,*,0,2]*ematspec[j,*,2,2]
     matsqrd[j,*,1,0]=ematspec[j,*,1,0]*ematspec[j,*,0,0]+ematspec[j,*,1,1]*ematspec[j,*,1,0]+ematspec[j,*,1,2]*ematspec[j,*,2,0]
     matsqrd[j,*,1,1]=ematspec[j,*,1,0]*ematspec[j,*,0,1]+ematspec[j,*,1,1]*ematspec[j,*,1,1]+ematspec[j,*,1,2]*ematspec[j,*,2,1]
     matsqrd[j,*,1,2]=ematspec[j,*,1,0]*ematspec[j,*,0,2]+ematspec[j,*,1,1]*ematspec[j,*,1,2]+ematspec[j,*,1,2]*ematspec[j,*,2,2]
     matsqrd[j,*,2,0]=ematspec[j,*,2,0]*ematspec[j,*,0,0]+ematspec[j,*,2,1]*ematspec[j,*,1,0]+ematspec[j,*,2,2]*ematspec[j,*,2,0]
     matsqrd[j,*,2,1]=ematspec[j,*,2,0]*ematspec[j,*,0,1]+ematspec[j,*,2,1]*ematspec[j,*,1,1]+ematspec[j,*,2,2]*ematspec[j,*,2,1]
     matsqrd[j,*,2,2]=ematspec[j,*,2,0]*ematspec[j,*,0,2]+ematspec[j,*,2,1]*ematspec[j,*,1,2]+ematspec[j,*,2,2]*ematspec[j,*,2,2]

     Trmatsqrd[j,*]=matsqrd[j,*,0,0]+matsqrd[j,*,1,1]+matsqrd[j,*,2,2]
     Trmatspec[j,*]=ematspec[j,*,0,0]+ematspec[j,*,1,1]+ematspec[j,*,2,2]
     degpol[j,(nosmbins-1)/2:(nopfft/2-1)-(nosmbins-1)/2]=(3*Trmatsqrd[j,(nosmbins-1)/2:(nopfft/2-1)-(nosmbins-1)/2]-Trmatspec[j,(nosmbins-1)/2: (nopfft/2-1)-(nosmbins-1)/2]^2)/(2*Trmatspec[j,(nosmbins-1)/2: (nopfft/2-1)-(nosmbins-1)/2]^2)

     Xrmatspec[j,*]=ematspec[j,*,0,0] ; added 10Sep2013 jhl
     Yrmatspec[j,*]=ematspec[j,*,1,1] ; added 10Sep2013 jhl
     Zrmatspec[j,*]=ematspec[j,*,2,2] ; added 10Sep2013 jhl
     
;CALCULATION OF HELICITY, ELLIPTICITY AND THE WAVE STATE VECTOR

alphax[j,*]=Sqrt(ematspec[j,*,0,0])
alphacos2x[j,*]=Double(ematspec[j,*,0,1])/Sqrt(ematspec[j,*,0,0])
alphasin2x[j,*]=-Imaginary(ematspec[j,*,0,1])/Sqrt(ematspec[j,*,0,0])
alphacos3x[j,*]=Double(ematspec[j,*,0,2])/Sqrt(ematspec[j,*,0,0])
alphasin3x[j,*]=-Imaginary(ematspec[j,*,0,2])/Sqrt(ematspec[j,*,0,0])
lambdau[j,*,0,0]=alphax[j,*]
lambdau[j,*,0,1]=Complex(alphacos2x[j,*],alphasin2x[j,*])
lambdau[j,*,0,2]=Complex(alphacos3x[j,*],alphasin3x[j,*])

alphay[j,*]=Sqrt(ematspec[j,*,1,1])
alphacos2y[j,*]=Double(ematspec[j,*,1,0])/Sqrt(ematspec[j,*,1,1])
alphasin2y[j,*]=-Imaginary(ematspec[j,*,1,0])/Sqrt(ematspec[j,*,1,1])
alphacos3y[j,*]=Double(ematspec[j,*,1,2])/Sqrt(ematspec[j,*,1,1])
alphasin3y[j,*]=-Imaginary(ematspec[j,*,1,2])/Sqrt(ematspec[j,*,1,1])
lambdau[j,*,1,0]=alphay[j,*]
lambdau[j,*,1,1]=Complex(alphacos2y[j,*],alphasin2y[j,*])
lambdau[j,*,1,2]=Complex(alphacos3y[j,*],alphasin3y[j,*])

alphaz[j,*]=Sqrt(ematspec[j,*,2,2])
alphacos2z[j,*]=Double(ematspec[j,*,2,0])/Sqrt(ematspec[j,*,2,2])
alphasin2z[j,*]=-Imaginary(ematspec[j,*,2,0])/Sqrt(ematspec[j,*,2,2])
alphacos3z[j,*]=Double(ematspec[j,*,2,1])/Sqrt(ematspec[j,*,2,2])
alphasin3z[j,*]=-Imaginary(ematspec[j,*,2,1])/Sqrt(ematspec[j,*,2,2])
lambdau[j,*,2,0]=alphaz[j,*]
lambdau[j,*,2,1]=Complex(alphacos2z[j,*],alphasin2z[j,*])
lambdau[j,*,2,2]=Complex(alphacos3z[j,*],alphasin3z[j,*])

;HELICITY CALCULATION

for k=0, nopfft/2-1 do begin
    for xyz=0,2 do begin
        upper[j,k]=Total(2*double(lambdau[j,k,xyz,0:2])*(Imaginary(lambdau[j,k,xyz,0:2])))
        lower[j,k]=Total((Double(lambdau[j,k,xyz,0:2]))^2-(Imaginary(lambdau[j,k,xyz,0:2]))^2)
        if (upper[j,k] GT 0.00) then gammay[j,k]=ATAN(upper[j,k],lower[j,k]) else gammay[j,k]=!DPI+(!DPI+ATAN(upper[j,k],lower[j,k]))

        lambdau[j,k,xyz,*]=exp(Complex(0,-0.5*gammay[j,k]))*lambdau[j,k,xyz,*]

        helicity[j,k,xyz]=1/(SQRT(Double(lambdau[j,k,xyz,0])^2+Double(lambdau[j,k,xyz,1])^2+Double(lambdau[j,k,xyz,2])^2)/SQRT(Imaginary(lambdau[j,k,xyz,0])^2+Imaginary(lambdau[j,k,xyz,1])^2+Imaginary(lambdau[j,k,xyz,2])^2))

;ELLIPTICITY CALCULATION

        uppere=Imaginary(lambdau[j,k,xyz,0])*Double(lambdau[j,k,xyz,0])+Imaginary(lambdau[j,k,xyz,1])*Double(lambdau[j,k,xyz,1])
        lowere=-Imaginary(lambdau[j,k,xyz,0])^2+Double(lambdau[j,k,xyz,0])^2-Imaginary(lambdau[j,k,xyz,1])^2+Double(lambdau[j,k,xyz,1])^2
        if uppere GT 0 then gammarot[j,k]=ATAN(uppere,lowere) else gammarot[j,k]=!DPI+!DPI+ATAN(uppere,lowere)

        lam=lambdau[j,k,xyz,0:1]
        lambdaurot[j,k,*]=exp(complex(0,-0.5*gammarot[j,k]))*lam[*]

        ellip[j,k,xyz]=Sqrt(Imaginary(lambdaurot[j,k,0])^2+Imaginary(lambdaurot[j,k,1])^2)/Sqrt(Double(lambdaurot[j,k,0])^2+Double(lambdaurot[j,k,1])^2)
        ellip[j,k,xyz]=-ellip[j,k,xyz]*(Imaginary(ematspec[j,k,0,1])*sin(waveangle[j,k]))/abs(Imaginary(ematspec[j,k,0,1])*sin(waveangle[j,k]))


    endfor

endfor


endfor ; end of main body

;AVERAGING HELICITY AND ELLIPTICITY RESULTS

elliptict=(ellip[*,*,0]+ellip[*,*,1]+ellip[*,*,2])/3
helict=(helicity[*,*,0]+helicity[*,*,1]+helicity[*,*,2])/3

; CREATING OUTPUT STRUCTURES
;
timeline=ct[0]+ABS(nopfft/2)/sampfreq+findgen(nosteps)*steplength/sampfreq
binwidth=sampfreq/nopfft
freqline=binwidth*findgen(nopfft/2)
;scaling power results to units with meaning
;W=nopfft*Total(smooth^2); original Chaston

; redefining W ; 8Sep2012 jhl
W=Total(smooth^2) / double(nopfft) ; switch to divide by nopfft

powspec[*,1:nopfft/2-2]=1/W*2*trmatspec[*,1:nopfft/2-2]/binwidth
powspec[*,0]=1/W*trmatspec[*,0]/binwidth
powspec[*,nopfft/2-1]=1/W*trmatspec[*,nopfft/2-1]/binwidth

;     Trmatspec[j,*]=ematspec[j,*,0,0]+ematspec[j,*,1,1]+ematspec[j,*,2,2]
;     Xrmatspec[j,*]=ematspec[j,*,0,0]
;     Yrmatspec[j,*]=ematspec[j,*,1,1]
;     Zrmatspec[j,*]=ematspec[j,*,2,2]

; added 10Sep2013 jhl
pspecx=Make_Array(nosteps,nopfft/2,/double)
pspecy=Make_Array(nosteps,nopfft/2,/double)
pspecz=Make_Array(nosteps,nopfft/2,/double)
pspec3=Make_Array(nosteps,nopfft/2,3,/double)

pspecx[*,1:nopfft/2-2]=1/W*2*xrmatspec[*,1:nopfft/2-2]/binwidth
pspecx[*,0]=1/W*xrmatspec[*,0]/binwidth
pspecx[*,nopfft/2-1]=1/W*xrmatspec[*,nopfft/2-1]/binwidth

pspecy[*,1:nopfft/2-2]=1/W*2*yrmatspec[*,1:nopfft/2-2]/binwidth
pspecy[*,0]=1/W*yrmatspec[*,0]/binwidth
pspecy[*,nopfft/2-1]=1/W*yrmatspec[*,nopfft/2-1]/binwidth

pspecz[*,1:nopfft/2-2]=1/W*2*zrmatspec[*,1:nopfft/2-2]/binwidth
pspecz[*,0]=1/W*zrmatspec[*,0]/binwidth
pspecz[*,nopfft/2-1]=1/W*zrmatspec[*,nopfft/2-1]/binwidth

pspec3[*,*,0]=pspecx
pspec3[*,*,1]=pspecy
pspec3[*,*,2]=pspecz

return
end
