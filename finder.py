#!/usr/bin/env python

# Charles McEachern

# Spring 2016

# #############################################################################
# #################################################################### Synopsis
# #############################################################################

# Lei's got some filters in his data which are designed to screen out
# fundamental mode Pc4 pulsations. We run through the same date with different
# filters, specifically to find those fundamental mode poloidal Pc4 events. 

# #############################################################################
# ######################################################### Load Python Modules
# #############################################################################

from day import *
from plotmod import *

# #############################################################################
# ######################################################################## Main
# #############################################################################

# A timestamped directory, in case we want to save any plots.  
plotdir = '/home/user1/mceachern/Desktop/plots/' + now() + '/'

def main():

#  # Append Dst information to the list of events. 
#  return adddst_events()

#  # Append Dst to the list of probe locations. 
#  return adddst_pos()

#  # Append LPP to the list of probe locations. 
#  return addlpp_pos()

  # What dates do we have data for? 
  dates = sorted( os.listdir('/media/My Passport/rbsp/pkls/') )

#  # If we're saving our data, nuke the previous list to avoid double-counting. 
#  if '-i' in argv and os.path.exists('pos.txt'):
#    print 'Removing old position listing'
#    os.remove('pos.txt')

#  # Tally the probes' positions. 
#  for date in dates:
#    print date
#    [ trackpos(probe, date, mpc=5) for probe in ('a', 'b') ]

  # If we're saving our data, nuke the previous list to avoid double-counting. 
  if '-i' in argv and os.path.exists('events_new.txt'):
    print 'Removing old event listing'
    os.remove('events_new.txt')
    append(evheader(), 'events_new.txt')

  # Search for events. Do the days in random order, for easier debugging. We
  # can just look at the first event we find. 
  for date in np.random.permutation(dates):

    print date
    # Check both probes. Thirty minute chunks. 
    [ checkdate(probe, date, mpc=30) for probe in ('a', 'b') ]
  return

# #############################################################################
# ###################################################### Tabulate RBSP Position
# #############################################################################

def trackpos(probe, date, mpc=5):
  # This takes forever to run... 
  print 'THERE IS NO REASON YOU SHOULD BE CALLING THIS AGAIN. '
  exit()
  # Load the day's data into a day object. 
  today = day(probe=probe, date=date)
  # If the event is no good, bail. 
  if today.garbage:
    return
  # Scroll through the day a few minutes at a time. 
  for t in range(0, 86400, 60*mpc):
    # Grab a slice of the day. Print location and if the data is OK. 
    ev = today.getslice(t, duration=60*mpc)
    lshell, mlt, mlat = [ ev.avg(name) for name in ('lshell', 'mlt', 'mlat') ]
    evline = ( ev.probe + '\t' + ev.date + '\t' + ev.time + '\t' +
               format(ev.avg('lshell'), '.1f') + '\t' +
               format(ev.avg('mlt'), '.1f') + '\t' + 
               format(ev.avg('mlat'), '.1f') )
    append(evline + '\t' + ( 'ok' if ev.isok() else 'X' ), 'pos.txt')
  return

# #############################################################################
# ############################################################# Tabulate Events
# #############################################################################

# =============================================================================
# ===================================================== Search a Day for Events
# =============================================================================

# The day is broken into chunks (mpc is minutes per chunk). Each chunk is run
# through a few different filters to seek out odd-harmonic poloidal Pc4 waves. 
def checkdate(probe, date, mpc=30):
  # Load the day's data into a day object. 
  today = day(probe=probe, date=date)
  # Iterate over each chunk of the day. 
  for t in range(0, 86400, 60*mpc):
#    print '\t' + timestr(t)[1]
    # Check for poloidal and toroidal events independently. 
    ev = today.getslice(t, duration=60*mpc)
    evdicts = [ ev.wave(m, pc4=True) for m in ('p', 't') ]
    # If there's anything to save, do so, then plot it. 
    if keepevent(evdicts):
      plotevent(ev, save='-i' in argv)
      # If we're debugging, stop after a single plot. 
      if '-i' not in argv:
        exit()
  return

# =============================================================================
# ============================================================== Store an Event
# =============================================================================

def evheader():
  pdt = col('probe') + col('date') + col('time')
  pos = col('lshell') + col('mlt') + col('mlat')
  lpp = col('lpp')
  mh = col('mode+harm')
  fdf = col('freq') + col('FWHM')
  phase = col('phase')
  mag = col('amplitude')
  comp = col('Bz/Bx')
  dst = col('Dst')
  return pdt + pos + lpp + mh + fdf + phase + mag + comp + dst + col('double?')

# Assemble a dictionary about the event into a one-line summary. 
def evline(d):
  pdt = col( d['probe'] ) + col( d['date'] ) + col( d['time'] )
  pos = col( d['lshell'] ) + col( d['mlt'] ) + col( d['mlat'] )
  lpp = col( d['lpp'] )
  mh = col( d['mode'].upper() + str( d['harm'] ) )
  fdf = col( d['f'] ) + col( 2.355*d['df'] )
  phase = col( d['phase'] )
  mag = col( d['s'], digs=5 )
  comp = col( d['comp'] )
  dst = col( d['dst'] )
  return pdt + pos + lpp + mh + fdf + phase + mag + comp + dst

# Write out the event to file. If there are two simultaneous events, indicate
# which is larger. 
def keepevent(evdicts):
  # Filter out non-events.
  evds = [ d for d in evdicts if d ]
  # If there are no events, bail. 
  if len(evds)==0:
    return 0
  # If there's one event, save it. 
  elif len(evds)==1:
    text = evline( evds[0] ) + col('---')
  # If there are two events, indicate which is larger. 
  elif len(evds)==2:
    ip = 0 if evds[0]['s'] > evds[1]['s'] else 1
    text = ( evline( evds[ip] ) + col('BIG') + '\n' + 
             evline( evds[1-ip] ) + col('SMALL') )
  # If we're storing the data, do so. In either case, print it. 
  if '-i' in argv:
    print append(text, 'events_new.txt')
  else:
    print evheader()
    print text
  # Return an indication of how many events. 
  return len(evds)

# #############################################################################
# ############################################################### Plot an Event
# #############################################################################

def evtitle(d):
  if 45 < np.abs( d['phase'] ) < 135:
    harm = 'Even' if d['harm']%2 else 'Odd'
  else:
    harm = 'Traveling'
  mode = 'Poloidal' if d['mode'].upper()=='P' else 'Toroidal'
  return notex(harm + ' ' + mode + ' Wave')

#  harm = 'Even' if d['harm']%2 else 'Odd'
#  mode = 'Poloidal' if d['mode'].upper()=='P' else 'Toroidal'
#  name = notex(harm + ' ' + mode + ' Event:  ')
#  # For FWHM, use 2.355*df. This is standard deviation. 
#  freq = fmt(d['f'], digs=1) + tex('mHz') + '\\pm' + fmt(d['df'], digs=1) + tex('mHz')
#  ampl = fmt(d['s'], digs=3) + tex('mW/m^2')
#  phas = fmt(d['phase'], digs=0) + '^{\\circ}'
#  return name + ampl + notex(',  ') + freq + notex(',  ') + phas

def evtop(d):
  if d is None:
    return ''
  freq = fmt(d['f'], digs=1) + tex('mHz')
  ampl = fmt(d['s'], digs=3) + tex('mW/m^2')
  phas = fmt(d['phase'], digs=0) + '^{\\circ}'
  return '\\;\\;\\;\\;'.join( (ampl, freq, phas) )

# Wrapper around np.log10 to avoid complaints about zero. 
def log10(x):
  return np.log10( np.maximum(x, 1e-20) )

def plotevent(ev, save=False):
  global plotdir
  # Create plot window to hold waveforms and spectra. 
  PW = plotWindow(nrows=3, ncols=2, footlabel=True)
  # Index the poloidal, toroidal, and field-aligned modes. 
  modes = ('p', 't', 'z')
  # Plot waveforms as a function of time. 
  PW[:, 0].setParams( **ev.coords('waveform', cramped=True) )
  [ PW[i, 0].setLine(ev.get('B' + m), 'r') for i, m in enumerate(modes) ]
  [ PW[i, 0].setLine(ev.get('E' + m), 'b') for i, m in enumerate(modes) ]
  # Grab the Fourier-domain Poynting flux. It's scaled by L^3 to give values at
  # the ionosphere. 
  scomplex = [ ev.sfft(m) for m in modes ]
  sreal = [ np.abs( np.real(s) ) for s in scomplex ]
  simag = [ np.abs( np.imag(s) ) for s in scomplex ]
  stotal = [ np.abs(s) for s in scomplex ]
  # Find the waves in this event. 
  waves = [ ev.wave(m, pc4=True) for m in modes ]
  [ PW[i, 1].setParams( toptext=evtop(w) ) for i, w in enumerate(waves) ]

  # Plot the spectra. 
  PW[:, 1].setParams( **ev.coords('spectra', cramped=True) )
  [ PW[i, 1].setLine(log10(s), 'm') for i, s in enumerate(simag) ]
  [ PW[i, 1].setLine(log10(s), 'g') for i, s in enumerate(sreal) ]
  # Plot the Gaussian fit of the total Poynting flux. 
  f = np.linspace(0, 50, 1000)
  for i, w in enumerate(waves):
    args = (0, 0, 1) if w is None else ( w['s'], w['f'], w['df'] )
    PW[i, 1].setLine(f, log10( ev.gauss(f, *args) ), 'k--')

  # Plot title and labels. 
  rowlabels = ( notex('Poloidal'), notex('Toroidal'), notex('Parallel') )
  collabels = ( notex('B (Red) ; E (Blue)'), 
                tex('imag') + tex('S') + notex(' (Magenta) ; ') + 
                tex('real') + tex('S') + notex(' (Green)') )
  PW.setParams(collabels=collabels, footer=ev.label(), rowlabels=rowlabels)
  # Information about the wave(s) goes in the side label. 
  tlist = [ evtitle(w) for w in waves if w is not None ]
  PW.setParams( title=notex('Waveforms and Spectra: ') + notex(' and ').join(tlist) )

  # Show the plot, or save it as an image. 
  if save is True:
    return PW.render(plotdir + ev.name + '.png')
  else:
    return PW.render()

# #############################################################################
# ################################################# Append a Column to the Data
# #############################################################################

# =============================================================================
# ==================================================== Add Dst to Event Listing
# =============================================================================

def adddst_events():
  dst = read('dst.txt')
  # Load Dst values into an array. The first column is epoch time. 
  dstarr = np.zeros( (2*len(dst) - 1, 2), dtype=np.int )
  for i, d in enumerate(dst):
    date, time, val = d.split()
    dstarr[2*i, 0] = timeint(date=date, time=time)
    dstarr[2*i, 1] = int(val)
  # Average to get half hours. 
  dstarr[1::2] = ( dstarr[:-2:2] + dstarr[2::2] )/2
  # Read in the events. 
  events = read('events.txt')
  for e in events:
    date, time = e.split()[1:3]
    t = timeint(date=date, time=time)
    # Find the line of Dst that matches this. 
    i = np.argmin( np.abs( t - dstarr[:, 0] ) )
    # For a consistent number of columns, non-double events are labeled ONLY. 
    only = col('ONLY') if 'BIG' not in e and 'SMALL' not in e else ''
    # Print out a new file which includes Dst along with the event info. 
    append(e + only + col( dstarr[i, 1] ), 'events_with_dst.txt')
  return

# =============================================================================
# ================================================= Add Dst to Position Listing
# =============================================================================

def adddst_pos():
  dst = sorted( read('dst.txt') )
  # Load Dst values into an array. The first column is epoch time. 
  dstarr = np.zeros( (2*len(dst) - 1, 2), dtype=np.int )
  for i, d in enumerate(dst):
    date, time, val = d.split()
    dstarr[2*i, 0] = timeint(date=date, time=time)
    dstarr[2*i, 1] = int(val)
  # Average to get half hours. 
  dstarr[1::2] = ( dstarr[:-2:2] + dstarr[2::2] )/2
  # Read in the probe positions. 
  pos = read('pos.txt')
  for p in pos:
    date, time = p.split()[1:3]
    t = timeint(date=date, time=time)
    # Find the line of Dst that matches this. 
    i = np.argmin( np.abs( t - dstarr[:, 0] ) )
    # Print out a new file which includes Dst along with the position info. 
    append(p + col( dstarr[i, 1] ), 'pos_with_dst.txt')
  return

# =============================================================================
# ================================================= Add LPP to Position Listing
# =============================================================================

def addlpp_pos():
  # Read the LPP values into an array. The first column is epoch time. 
  lpp = sorted( read('lpp.txt') )
  lpparr = np.zeros( (2*len(lpp) - 1, 2), dtype=np.float )
  for i, l in enumerate(lpp):
    date, time, val = l.split()[:3]
    lpparr[2*i, 0] = timeint(date=date, time=time)
    lpparr[2*i, 1] = np.float(val)
  # Linearly interpolate to double time resolution. 
  lpparr[1::2] = ( lpparr[:-2:2] + lpparr[2::2] )/2
  # Print out a header for the new position file. 
  append( col('probe') + col('date') + col('time') + col('lshell') +
          col('mlt') + col('mlat') + col('data?') + col('dst') + col('LPP'),
         'pos_with_lpp.txt' )
  # Read in the probe positions. 
  pos = read('pos.txt')
  for p in pos:
    date, time = p.split()[1:3]
    t = timeint(date=date, time=time)
    # Find the line of Dst that matches this. 
    i = np.argmin( np.abs( t - lpparr[:, 0] ) )
    # Print out a new file which includes LPP along with the position info. 
    append(p + col( lpparr[i, 1] ), 'pos_with_lpp.txt')
  return

# #############################################################################
# ############################################################ Helper Functions
# #############################################################################

# Space out a nice right-justified column. 
def col(x, width=12, unit='', digs=2):
  d = str(digs)
  if isinstance(x, float):
    return format(x, str(width - len(unit) - 1) + '.' + d + 'f') + unit + ' '
  else:
    return str(x).rjust(width - len(unit) - 1) + unit + ' '

# #############################################################################
# ########################################################### For Importability
# #############################################################################

if __name__=='__main__':
  main()


