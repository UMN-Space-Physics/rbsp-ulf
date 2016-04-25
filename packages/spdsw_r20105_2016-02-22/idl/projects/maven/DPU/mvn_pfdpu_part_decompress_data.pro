

function mvn_pfdpu_getbit,bfr,bitinx
  inx = bitinx / 8
  bit = bitinx mod 8
  bmask = [128b,64b,32b,16b,8b,4b,2b,1b]
  bitinx++
  return ,  (bfr[Inx] and bmask[bit]) ne 0
end



function mvn_pfdpu_GetBits,bfr,bitinx, leng
  if leng gt (n_elements(bfr)*8 - bitinx) then begin
     return,0
  endif
  r=0
  for i=0,leng-1 do begin              ;  for(i=0;i<leng;i++) 
      r = r*2 + mvn_pfdpu_GetBit(bfr,bitinx)
  endfor
  return, r
end



function  mvn_pfdpu_NextA,bfr,bitinx
  if(mvn_pfdpu_GetBits(bfr,bitinx,1) eq 0) then return,0  ;  // 0
  if(mvn_pfdpu_GetBits(bfr,bitinx,1) eq 0) then return,1  ;  // 10    
  n = mvn_pfdpu_GetBits(bfr,bitinx,2)    
  if( n lt 3 ) then return, n+2            ;  // 1100-1110 
  n = mvn_pfdpu_GetBits(bfr,bitinx,8)    
  return,n                                ;     // 1111xxxxxxxx
end


function mvn_pfdpu_NextB,bfr,bitinx
;{int n,m,p;

  n = mvn_pfdpu_GetBits(bfr,bitinx,3);

  case n of 
     0: return, (0)
     1: return, (1)  
     2: return,( 2 + mvn_pfdpu_GetBits(bfr,bitinx,1));
     3: return,( 4 + mvn_pfdpu_GetBits(bfr,bitinx,2));
     4: begin
         m = mvn_pfdpu_GetBits(bfr,bitinx,2);
         if( m eq 0 )  then return,( 8 );
         if( m eq 1 )  then begin
             p = mvn_pfdpu_GetBits(bfr,bitinx,2);
             if( p lt 3) then return,( 9 + p);
             return,( mvn_pfdpu_GetBits(bfr,bitinx, 8 )); 
         endif
         if( m eq 2 ) then begin
             p = mvn_pfdpu_GetBits(bfr,bitinx,2);
             if( p gt 0) then return,( -12 + p);
             return,( - mvn_pfdpu_GetBits(bfr,bitinx, 8 ));
         endif
         if( m eq 3 ) then return,( -8 );
       end;
     5: return,( -7 + mvn_pfdpu_GetBits(bfr,bitinx,2));
     6: return,( -3 + mvn_pfdpu_GetBits(bfr,bitinx,1));
     7: return,( -1 );
   endcase
end

function mvn_pfdpu_NextC,bfr,bitinx
;{int n,m,p;
  n = mvn_pfdpu_GetBits(bfr,bitinx,4);
  switch (n) of
   0: 
   1: 
   2:
   3: return,(n);
   4: return,( 4 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   5: return,( 6 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   6: return,( 8 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   7: if( mvn_pfdpu_GetBits(bfr,bitinx,1) eq 0) then return,(10) $ 
      else return,( 11 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   8: begin 
      m = mvn_pfdpu_GetBits(bfr,bitinx,2);
      if( m eq 0 ) then return,( 13 );
      if( m eq 1 ) then begin
          p = mvn_pfdpu_GetBits(bfr,bitinx,1);
          if( p eq 0) then return,( 14 );
          return,( mvn_pfdpu_GetBits(bfr,bitinx,8 ));
      endif
      if( m eq 2 ) then begin
          p = mvn_pfdpu_GetBits(bfr,bitinx,1);
          if( p eq 1) then return,( -14 );
          return,( -mvn_pfdpu_GetBits(bfr,bitinx,8 ));
      endif
      if( m eq 3 ) then return,( -13 );
;      break;
      end
   9: if( mvn_pfdpu_GetBits(bfr,bitinx,1) eq 1) then return,(-10) $
      else  return,( -12 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   10: return,( -9 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   11: return,( -7 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   12: return,( -5 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   13: return,( -3 );
   14: return,( -2 );
   15: return,( -1 );
  endswitch
end



function mvn_pfdpu_NextD,bfr,bitinx
;{int n,m;
  n = mvn_pfdpu_GetBits(bfr,bitinx,4);
  switch (n) of
   0: 
   1: 
   2:
   3: return,(n);
   4: return,( 4 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   5: return,( 6 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   6: return,( 8 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   7: if( mvn_pfdpu_GetBits(bfr,bitinx,1) eq 0) then return,(10) $
      else return,( 11 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   8: begin 
      m = mvn_pfdpu_GetBits(bfr,bitinx,4);
      if( m lt 7 ) then return,( 13+m );
      if( m eq 7 ) then return,(  mvn_pfdpu_GetBits(bfr,bitinx,8));
      if( m eq 8 ) then return,( -mvn_pfdpu_GetBits(bfr,bitinx,8));
      if( m gt 8 ) then return,( -28+m );
     end  ; break;
   9: if( mvn_pfdpu_GetBits(bfr,bitinx,1) eq 1) then return,(-10) else $
      return,( -12 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   10: return,( -9 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   11: return,( -7 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   12: return,( -5 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   13: return,( -3 );
   14: return,( -2 );
   15: return,( -1 );
  endswitch
end



function mvn_pfdpu_DecodeA, bfr,bitinx 
  dst = bytarr(32)
;  dprint,bitinx,dlevel=3
  for i=0,32-1 do begin            ;  for(i=0;i<32;i++)
    dst[i] =  mvn_pfdpu_NextA(bfr,bitinx)
;    dprint,bitinx,dst[i],format='(i4," ",z02)',dlevel=3
  endfor
  return,dst 
end

function mvn_pfdpu_DecodeB, bfr,bitinx
  dst = bytarr(32)
  R =  mvn_pfdpu_GetBits(bfr,bitinx,8)
  dst[0] = R
  for i=1,32-1 do begin    ;  for(i=0;i<31;i++)
    Del = mvn_pfdpu_NextB( bfr,bitinx);    // Each B value is a delta
    R += Del;
    dst[i] = R;
  endfor
  return,dst
end


function mvn_pfdpu_DecodeC, bfr,bitinx
  dst = bytarr(32)
  R =  mvn_pfdpu_GetBits(bfr,bitinx,8)
  dst[0] = R
  for i=1,32-1 do begin    ;  for(i=0;i<31;i++)
    Del = mvn_pfdpu_NextC( bfr,bitinx);    // Each B value is a delta
        R += Del;
    dst[i] = R;
  endfor
  return, dst
end

function mvn_pfdpu_DecodeD, bfr,bitinx
  dst = bytarr(32)
  R =  mvn_pfdpu_GetBits(bfr,bitinx,8)
  dst[0] = R
  for i=1,32-1 do begin    ;  for(i=0;i<31;i++)
    Del = mvn_pfdpu_NextD( bfr,bitinx);    // Each B value is a delta
    R += Del;
    dst[i] = R;
  endfor
  return,dst
end


function mvn_pfdpu_part_decompress_data,cpkt,cfactor=cfactor  ; returns decompressed ccsds packet data for the particle instruments

  bfr = cpkt.data
  cmpbyte = bfr[2]
  cfactor=1.
  if ((cmpbyte) and 128) eq 0 then return,bfr   ; pkt not actually compressed return raw data.
;  dprint,'Decompressing',cpkt.apid,format = '(a,z3)',dlevel=3
  comp_size = n_elements(bfr)
  decomp_bfr= bytarr(2048 + 32)   ; max possible size uncompressed
  pktbits = 8 * (comp_size)
 
  nn = 6
  for DcmInx = 0,nn-1 do decomp_bfr[DcmInx] = bfr[DcmInx]  ; First nn bytes are not compressed
  BitInx = DcmInx*8;               // Start Bit

  while (BitInx lt (Pktbits-32) ) do begin      ;  // While Bits remain
    Type = mvn_pfdpu_GetBits(bfr,bitinx, 2 );
;    dprint,bitinx,type
    case (Type) of
       0: b32 = mvn_pfdpu_DecodeA(bfr, bitinx)
       1: b32 = mvn_pfdpu_DecodeB(bfr, bitinx)
       2: b32=  mvn_pfdpu_DecodeC(bfr, bitinx)
       3: b32 = mvn_pfdpu_DecodeD(bfr, bitinx)
    endcase   
;    dprint,type,b32,format = '(i2,"  ",32(" ",Z02))',dlevel=3
    if DcmInx ge 2048 then begin
        dprint,'Decompression error'
        error=1
        break
    endif
    decomp_bfr[DcmInx:DcmInx+31] = B32
    DcmInx += 32
  endwhile
    
  decomp_size = DcmInx;
  ddata = decomp_bfr[0:decomp_size-1]
 ; hexprint,ddata
  cfactor = float(decomp_size)/float(comp_size)
  return, ddata
end


