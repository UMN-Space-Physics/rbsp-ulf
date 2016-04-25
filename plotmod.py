#!/usr/bin/env python

# Charles McEachern

# Spring 2016

# Note: This document wraps at column 80. 

# #############################################################################
# #################################################################### Synopsis
# #############################################################################

# The Plot Window and Plot Cell classes are wrappers around Matplotlib, 
# designed to produce nice looking plots to put in a thesis. The width of the
# plot is fixed to remove the need for rescaling, and to ensure that fonts show
# up true to size regardless of how many frames/cells are in the figure (up to
# 4 columns). The Tuna Plotter class exists to provide easy access to Tuna's
# output; it keeps track of where the data is located, it knows how to read in
# arrays, etc. 

# #############################################################################
# ##################################################### Import Python Libraries
# #############################################################################


# Change matplotlib settings to allow use over SSH without X forwarding. 
import matplotlib
import os
if 'DISPLAY' not in os.environ or os.environ['DISPLAY'] is '':
  matplotlib.use('Agg')
# The cPickle module is faster, but not always available. 
try:
  import cPickle as pickle
except ImportError:
  import pickle
from matplotlib import gridspec, rc
from matplotlib.colorbar import ColorbarBase
from matplotlib.colors import LinearSegmentedColormap as LSC
from matplotlib.colors import BoundaryNorm, ListedColormap
from matplotlib.colors import LogNorm, Normalize
from matplotlib.patches import Wedge
import matplotlib.pyplot as plt
import numpy as np
from os.path import basename
from random import choice
from sys import argv, stdout
from time import localtime as lt, time

from numpy.ma import masked_where


# #############################################################################
# ####################################################### Constants of Interest
# #############################################################################

# Physical constants. 
class phys():
  mu0 = 1256.63706 # nH/m
  eps0 = 8.854e-9 # mF/m
  qe = 1.60218e-25 # MC
  me = 9.10938e-28 # g
  RE = 6.378388 # Mm
  RI = 6.478388 # Mm

# #############################################################################
# ###################################################### LaTeX Helper Functions
# #############################################################################

def notex(x):
  if '\n' in x:
    return '$\n$'.join( notex(y) for y in x.split('\n') )
  else:
    return '\\operatorname{' + x.replace(' ', '\\;') + '}'

def tex(x):
  # Format frequencies nicely. 
  if isinstance(x, float):
    return notex(format(1e3*x, '.0f') + 'mHz ')
  # Check the input against our dictionary of LaTeX strings. 
  texdict = {
             # Spell out what each model means. 
             1:notex('Active Day'),
             2:notex('Quiet Day'),
             3:notex('Active Night'),
             4:notex('Quiet Night'),
             # Electric and magnetic field components. 
             'Bf':'B_\\phi', 
             'Bq':'B_\\theta', 
             'Bx':'B_x', 
             'By':'B_y', 
             'Bz':'B_z', 
             'Ex':'E_x', 
             'Ey':'E_y', 
             'Ez':'E_z', 
             'L3S':'L^3\\widetilde{S}', 
             'S':'\\widetilde{S}', 
             'EB':'\\widetilde{E}\\widetilde{B}^*', 
             'EBp':'-\\widetilde{E}_y\\widetilde{B}^*_x', 
             'EBt':'\\widetilde{E}_x\\widetilde{B}^*_y', 
             'SpFFT':'-\\frac{L^3}{\\mu_0}\\widetilde{E}_y\\widetilde{B}^*_x', 
             'StFFT':'\\frac{L^3}{\\mu_0}\\widetilde{E}_x\\widetilde{B}^*_y', 
             'BBp':'\\widetilde{B}_z/\\widetilde{B}_x', 
             'BBt':'\\widetilde{B}_z/\\widetilde{B}_y', 
             'ImS':'|\\mathbb{I}\\mathrm{m}\\widetilde{S}|', 
             # Units. 
             'mHz':notex('mHz'),
             'mV/m':notex('\\frac{mV}{m}'),
             'mW/m^2':notex('\\frac{mW}{m^2}'),
             # Field Modifiers. 
             'imag':'\\mathbb{I}\\mathrm{m}',
             'real':'\\mathbb{R}\\mathrm{e}',
             # Axis labels. 
             'alt':notex('Altitude (km)'), 
             'B':notex('Magnetic Field (nT)'), 
             'comp':'B_z / B_x', 
             'f':notex('Frequency (mHz)'), 
             'L':notex('L'), 
             'L0':notex('L'), 
             'lat':notex('Latitude'), 
             'lat0':notex('Latitude'), 
             't':notex('Time (s)'), 
             'logU':notex('Log') + 'U' + notex(' (\\frac{GJ}{rad})'), 
             'logS':notex('Log') + '\\widetilde{S}' + notex(' (\\frac{mW}{m^2})'), 
             'X':notex('X (R_E)'), 
             'Z':notex('Z (R_E)')
            }
  return '?' if x not in texdict else texdict[x]

# #############################################################################
# ######################################################### Tuna Plotter Object
# #############################################################################

class tunaPlotter:

  # Keep track of the paths where our data is coming from. 
  paths = None
  # Remember the last few arrays we've read in to avoid duplicating our work. 
  arrays = None
  # Some runs have been longer than 300 seconds. All runs are at least 300
  # seconds, and that turns out to be a pretty good window for looking at Pc4s. 
  tmax = 300

  # ===========================================================================
  # ======================================================== Initialize Plotter
  # ===========================================================================

  def __init__(self):
    # Check if we're supposed to be saving this image or showing it. 
    if '-i' in argv:
      self.savepath = '/home/user1/mceachern/Desktop/plots/' + now() + '/'
      os.mkdir(self.savepath)
    else:
      self.savepath = None
    # Check for any path(s) from the terminal. 
    self.setPaths(*argv)
    # If no paths were given, use the default. 
    if not self.paths:
      print 'Using default data path. '
      self.setPaths('/media/My Passport/RUNS/JDRIVE_LPP_4')
    # Sometimes the plotter isn't supposed to make any plots at all. Instead,
    # its job is to go through and pickle some fresh data. 
    if 'pickle' in argv:
      self.pickle()
      exit()
    return

  # ===========================================================================
  # ================================================ Finding and Filtering Data
  # ===========================================================================

  # Given one or more paths, find all data directories, as well as the
  # parameters used by each run. 
  def setPaths(self, *args):
    # Note that self.paths isn't a list of paths to run directories -- it's a
    # dictionary, keyed by those paths, which lists the parameters used by each
    # run. We can stoll loop over path in self.paths, but this makes it easier
    # to track down the run we're looking for based on its parameters. 
    self.paths = {}
    # Increment over everything we're passed. 
    for arg in args:
      # Ignore non-paths. 
      if os.path.isdir(arg):
        for root, dirs, files in os.walk(arg):
          if 'params.in' in files:
            # Always use absolute paths. End directory paths with slashes. 
            path = os.path.abspath(root) + '/'
            self.paths[path] = self.getParams(path)
    return

  # Grab all parameters from a parameter input file. 
  def getParams(self, path):
    # Parameters are returned as a dictionary. We add some default parameters at the beginning so we don't run into any key errors while filtering runs. 
    params = {'bdrive':0, 'jdrive':0, 'inertia':-1, 'fdrive':0.016, 'azm':0, 'n1':150, 'lpp':4, 'ldrive':5}
    # The input file has one parameter per line, 'key = val'. 
    with open(path + 'params.in', 'r') as paramsfile:
      paramlines = paramsfile.readlines()
    for line in paramlines:
      key, val = [ x.strip() for x in line.split('=') ]
      params[key] = num(val)
    return params

  # Find all values for a given keyword parameter that are present in the runs
  # we're looking at. 
  def getValues(self, key):
    values = []
    # We want to be able to ask about keys that are not present. 
    for params in self.paths.values():
      values.append( params[key] if key in params else None )
    # Make sure we can safely assume the values are in ascending order. 
    return sorted( set(values) )

  # Given some keyword arguments, filter self.paths. 
  def getPath(self, **kargs):
    # Start with all the paths we have, then weed out any that don't match. 
    paths = [ p for p in self.paths ]
    for key, val in kargs.items():
      paths = [ p for p in paths if self.paths[p][key]==val ]
    # If there's anything other than exactly one match, something is wrong. 
    if len(paths)<1:
      print 'WARNING: No matching path found for ', kargs
      return None
    elif len(paths)>1:
      print 'ERROR: Multiple matching paths found for ', kargs
      exit()
    else:
      return paths[0]

  # Find the most recent run, including runs still in progress. 
  def newPath(self):
    root = '/export/scratch/users/mceachern/'
    runs = [ d for d in os.listdir(root) if os.path.isdir(root + d) ]
    # Sort by time of last modification, then return the last path. 
    return max( (os.path.getmtime(d), d) for d in runs )[1]

  # ===========================================================================
  # ============================================================== Data Pickler
  # ===========================================================================

  # Tuna outputs data as a text file full of numbers. Such files are fast to
  # create, but large to store, and slow to load. This routine goes through the
  # data, takes the time to read the values into Numpy arrays, and saves the
  # arrays as pickles. Pickle files are Python-specific, but they're compressed
  # (usually by about a factor of 3 compared to text) and they load fast (a
  # factor of 10, sometimes better, compared to text). 
  def pickle(self):
    # The Tuna Plotter object already tracked down all of the data directories,
    # either from arguments from the terminal or its internal defaults. 
    for path in self.paths:
      print '\n' + path
      # The readArray function makes a pickle whenever it reads in a dat file.
      [ readArray(f) for f in files(path, end='.dat') ]
    return

  # ===========================================================================
  # =============================================================== Data Access
  # ===========================================================================

  # This wrapper on readArray remembers the last few files we've read in, in
  # case we need them again. 
  def readArray(self, filename):
    if self.arrays is None or len(self.arrays)>20:
      self.arrays = {}
    if filename not in self.arrays:
      self.arrays[filename] = readArray(filename)
    return self.arrays[filename]

  # All arrays come in through here. It knows which fields are predominantly
  # imaginary (well, it knows how to look it up), and it knows how to combine
  # fields to get energy density, Poynting flux, etc. This is how we keep the
  # individual plot methods clean. 
  def getArray(self, path, name, real=None):
    # Check if we're looking for something that corresponds to a data file...
    if name in ('BfE', 'BfI', 'BqE', 'BqI', 'Bx', 'By', 'Bz', 'Ex', 'Ey', 
                'Ez', 'JyDrive', 'Jz', 'q', 't'):
      # We can give the real component or the imaginary component of a complex
      # field. 
      if real is True:
        arr = np.real( self.readArray(path + name + '.dat') )
      elif real is False:
        arr = np.imag( self.readArray(path + name + '.dat') )
      # If not specified, use real for poloidal components. 
      else:
        if name in ('Ex', 'By', 'Ez', 'Jz', 'BqE', 'BqI'):
          arr = np.imag( self.readArray(path + name + '.dat') )
        else:
          arr = np.real( self.readArray(path + name + '.dat') )
      # Chop off anything after tmax time steps. 
      return arr[..., :self.tmax] if name=='t' or len(arr.shape)>2 else arr
    # A few quantities get printed out with scale factors. Un-scale them. 
    # Radius in Mm (from RE). 
    elif name=='r':
      return phys.RE*self.readArray(path + 'r.dat')
    # Number density in 1/Mm^3, from 1/cm^3. 
    elif name=='n':
      return 1e24*self.readArray(path + 'n.dat')
    # Perpendicular electric constant, from units of eps0 to mF/m. 
    elif name=='epsPerp' or name=='epsp':
      return phys.eps0*self.readArray(path + 'epsPerp.dat')
    # Conductivities. Printed in S/m but we want mS/m. 
    elif name in ('sigH', 'sigP', 'sig0'):
      return 1e-3*self.readArray(path + name + '.dat')
    # Altitude in km. Note that we read r in RE and we store RE in Mm. 
    elif name=='alt':
      return 1000*(self.getArray(path, 'r') - phys.RE)
    # Normalied latitude. 
    elif name=='C':
      cosq = np.cos( self.getArray(path, 'q') )
      cosq0 = cosq[:, 0]
      return cosq/cosq0[:, None]

    if name=='comp':
      return None



    # Driving electric field in mV/m. 
    elif name=='EyDrive':
      return self.getArray(path, 'JyDrive')/self.getArray(path, 'epsPerp')
    # Perpendicular currents, computed from electric fields and conductivity. 
    elif name=='Jx':
      Ex, Ey = self.getArray(path, 'Ex', real=real), self.getArray(path, 'Ey', real=real)
      sigP, sigH = self.getArray(path, 'sigP'), self.getArray(path, 'sigH')
      return sigP[:, :, None]*Ex - sigH[:, :, None]*Ey
    elif name=='Jy':
      Ex, Ey = self.getArray(path, 'Ex', real=real), self.getArray(path, 'Ey', real=real)
      sigP, sigH = self.getArray(path, 'sigP'), self.getArray(path, 'sigH')
      return sigH[:, :, None]*Ex + sigP[:, :, None]*Ey
    # McIlwain parameter. 
    elif name=='L':
      r, q = self.getArray(path, 'r'), self.getArray(path, 'q')
      return r / ( phys.RE * np.sin(q)**2 )
    # McIlwain parameter as a 1D array. 
    elif name=='L0':
      return self.getArray(path, 'L')[:, 0]
    # Latitude in degrees, from colatitude in radians. 
    elif name=='lat':
      return 90 - self.getArray(path, 'q')*180/np.pi
    # Latitude only along the ionospheric boundary. 
    elif name=='lat0':
      return self.getArray(path, 'lat')[:, 0]
    # Differential volume for the grid, based on dipole coordinates and the
    # Jacobian determinant. 
    elif name=='dV':
      r, q = self.getArray(path, 'r'), self.getArray(path, 'q')
      # Invariant colatitude. 
      cosq0 = np.sqrt( 1 - phys.RI*np.sin(q)**2/r )
      # Dipole coordinates. 
      u1 = -phys.RI/(r*phys.RE) * np.sin(q)**2
      u3 = phys.RI**2/(r*phys.RE)**2 * np.cos(q)/cosq0
      # Dipole differentials. Rolling messes up the edges, so we zero them. 
      du1 = ( np.roll(u1, shift=1, axis=0) - np.roll(u1, shift=-1, axis=0) )/2
      du1[0, :], du1[-1, :] = 0, 0
      du3 = ( np.roll(u3, shift=1, axis=1) - np.roll(u3, shift=-1, axis=1) )/2
      du3[:, 0], du3[:, -1] = 0, 0
      # Jacobian determinant. 
      jac = (r*phys.RE)**6/phys.RI**3 * cosq0/( 1 + 3*np.cos(q)**2 )
      # The Jacobian may be negative. Make sure we return a positive volume. 
      return np.abs( du1*du3*jac )
    # Perpendicular grid spacing. This is cheating a little bit, since the
    # coordinates aren't orthogonal, but should give a decent estimate.  
    elif name=='dx0':
      return phys.RI*self.d( self.getArray(path, 'q')[:, 0] )
    # Azimuthal effective grid spacing for taking derivatives. This assumes an
    # azimuthal mode number of 1, and scales linearly. 
    elif name=='dy0':
      r, q = self.getArray(path, 'r'), self.getArray(path, 'q')
      return r[:, 0]*np.sin( q[:, 0] )
    # Differential field line length. 
    elif name=='dz':
      r, q = self.getArray(path, 'r'), self.getArray(path, 'q')
      dr = self.d(r, axis=1)
      rdq = r*self.d(q, axis=1)
      return np.sqrt( dr**2 + rdq**2 )
    # Field line length right along the ionospheric boundary. 
    elif name=='dz0':
      r, q = self.getArray(path, 'r'), self.getArray(path, 'q')
      dr = r[:, 1] - r[:, 0]
      rdq = 0.5*( r[:, 1] + r[:, 0] )*( q[:, 1] - q[:, 0] )
      return np.sqrt( dr**2 + rdq**2 )
    # Alfven bounce frequency. The axis will be set by the lines we draw. 
    elif name=='f':
      return None

    elif name=='B':
      return None


    # Toroidal Poynting flux. 
    elif name=='Stor':
      return self.getArray(path, 'Ex', real=real)*np.conj( self.getArray(path, 'By', real=real) )/phys.mu0
    # Poloidal Poynting flux. 
    elif name=='Spol':
      return -self.getArray(path, 'Ey', real=real)*np.conj( self.getArray(path, 'Bx', real=real) )/phys.mu0
    # Crosswise Poynting flux. 
    elif name=='Sx':
      return self.getArray(path, 'Ey', real=real)*np.conj( self.getArray(path, 'Bz', real=real) )/phys.mu0
    # Azimuthal Poynting flux. 
    elif name=='Sy':
      return -self.getArray(path, 'Ex', real=real)*np.conj( self.getArray(path, 'Bz', real=real) )/phys.mu0
    # Parallel Poynting flux. 
    elif name=='Sz' or name=='S':
      return self.getArray(path, 'Spol') + self.getArray(path, 'Stor')
    # Sometimes we don't actually need the array, such as when we're grabbing
    # the y axis for a line plot... so the axis will be set by line values. 
    elif name in ('logU', 'U'):
      return None
    # Poloidal magnetic field contribution to the energy density. 
    elif name=='uBx':
      return 0.5*self.getArray(path, 'Bx')**2 / phys.mu0
    # Toroidal magnetic field contribution to the energy density. 
    elif name=='uBy':
      return 0.5*self.getArray(path, 'By')**2 / phys.mu0

    # Energy in the compressional magnetic field... kinda. This is ignoring the
    # zeroth-order magnetic field. Really, this is just for computing the RMS
    # magnetic field. 
    elif name=='uBz':
      return 0.5*self.getArray(path, 'Bz')**2 / phys.mu0

    # Magnetic field contribution to the energy density. 
    elif name=='uB':
      return self.getArray(path, 'uBx') + self.getArray(path, 'uBy')
    # Toroidal electric field contribution to the energy density. 
    elif name=='uEx':
      E, epsPerp = self.getArray(path, 'Ex'), self.getArray(path, 'epsPerp')
      return 0.5*epsPerp[:, :, None]*E[:, :, :]**2
    # Poloidal electric field contribution to the energy density. 
    elif name=='uEy':
      E, epsPerp = self.getArray(path, 'Ey'), self.getArray(path, 'epsPerp')
      return 0.5*epsPerp[:, :, None]*E[:, :, :]**2
    # Magnetic field contribution to the energy density. 
    elif name=='uE':
      return self.getArray(path, 'uEx') + self.getArray(path, 'uEy')
    # Poloidal energy density. 
    elif name=='upol':
      return self.getArray(path, 'uEy') + self.getArray(path, 'uBx')
    # Toroidal energy density. 
    elif name=='utor':
      return self.getArray(path, 'uEx') + self.getArray(path, 'uBy')
    # Total energy density. 
    elif name=='u':
      return self.getArray(path, 'upol') + self.getArray(path, 'utor')
    # Integrated magnetic energy. 
    elif name=='UB':
      ux, uy = self.getArray(path, 'uBx'), self.getArray(path, 'uBy')
      dV = self.getArray(path, 'dV')
      return np.sum( np.sum( (ux + uy)*dV[:, :, None], 1), 0)
    # Integrated electric energy. 
    elif name=='UE':
      ux, uy = self.getArray(path, 'uEx'), self.getArray(path, 'uEy')
      dV = self.getArray(path, 'dV')
      return np.sum( np.sum( (ux + uy)*dV[:, :, None], 1), 0)
    # Integrated poloidal energy. 
    elif name=='Upol':
      ux, uy = self.getArray(path, 'uBx'), self.getArray(path, 'uEy')
      dV = self.getArray(path, 'dV')
      return np.sum( np.sum( (ux + uy)*dV[:, :, None], 1), 0)
    # Integrated toroidal energy. 
    elif name=='Utor':
      ux, uy = self.getArray(path, 'uEx'), self.getArray(path, 'uBy')
      dV = self.getArray(path, 'dV')
      return np.sum( np.sum( (ux + uy)*dV[:, :, None], 1), 0)

    # Integrated energy in each field component. This isn't really physical for
    # the compressional magnetic field -- it's a tool for computing the RMS. 
    elif name=='UBx':
      u, dV = self.getArray(path, 'uBx'), self.getArray(path, 'dV')
      return np.sum( np.sum( u*dV[:, :, None], 1), 0)
    elif name=='UBz':
      u, dV = self.getArray(path, 'uBz'), self.getArray(path, 'dV')
      return np.sum( np.sum( u*dV[:, :, None], 1), 0)

    # Interated volume. 
    elif name=='V':
      return np.sum( self.getArray(path, 'dV') )

    # Alfven speed. 
    elif name=='vA' or name=='va':
      return 1/np.sqrt( self.getArray(path, 'epsp')*phys.mu0 )
    # GSE X in RE. 
    elif name=='X':
      r, q = self.getArray(path, 'r'), self.getArray(path, 'q')
      return r*np.sin(q)/phys.RE
    # GSE Z in RE. 
    elif name=='Z':
      r, q = self.getArray(path, 'r'), self.getArray(path, 'q')
      return r*np.cos(q)/phys.RE
    # Keep an eye out for typos. 
    else:
      print 'ERROR: Not sure how to get ' + name
      exit()

  # ===========================================================================
  # ============================================================ Data Finagling
  # ===========================================================================

  # Helper for when we need to take a derivative. This gets the difference
  # between adjacent values (which we then have to scale by dx, etc). 
  def d(self, arr, axis=0):
    darr = ( np.roll(arr, shift=-1, axis=axis) - 
             np.roll(arr, shift=1, axis=axis) )/2
    darr[0], darr[-1] = darr[1], darr[-2]
    return darr

  # ===========================================================================
  # ====================================================== Coordinate Shorthand
  # ===========================================================================

  # This function returns a dictionary of keyword arguments meant to be plugged
  # straight into plotWindow.setParams(). 
  def getCoords(self, path, xaxis='X', yaxis='Z', lim=None):
    # The "unwrap" flag overwrites the dipole default coordinates. 
    if '-u' in argv and xaxis=='X' and yaxis=='Z':
      xaxis, yaxis = 'C', 'L'
    coords = { 'x':self.getArray(path, xaxis), 'xlabel':tex(xaxis),
             'y':self.getArray(path, yaxis), 'ylabel':tex(yaxis) }

    # Let's stop worrying about generalizability and make sure these ticks and
    # tick labels look good for the plots we need. 

    if xaxis=='t':
      coords['xlims'] = (0, 300)
      coords['xticks'] = (0, 100, 200, 300)
      coords['xticklabels'] = ('$0$', '', '', '$300$')

    if yaxis=='lat' or yaxis=='lat0':
      coords['ylims'] = (44, 72)
      coords['yticks'] = (44, 51, 58, 65, 72)
      coords['yticklabels'] = ('$44^\\circ$', '', '$58^\\circ$', '', '$72^\\circ$')

    if xaxis=='X' and yaxis=='Z':
      coords['xticks'] = (0, 2.5, 5, 7.5, 10)
      coords['xticklabels'] = ('$0$', '', '$5$', '', '$10$')
      coords['yticks'] = (-4, -2, 0, 2, 4)
      coords['yticklabels'] = ('$-4$', '', '$0$', '', '$+4$')
      coords['ylabelpad'] = -2

    # Latitude vs altitude isn't much good for plotting the whole dipole. Zoom
    # in on the ionosphere. 
    if xaxis=='lat' and yaxis=='alt':
      # Set the window range based on the latitudes seen at the northern
      # hemisphere boundary, and the altitudes we resolve at those latitudes.
      lat, alt = coords['x'], coords['y']
      xmin, xmax = np.min( lat[:, 0] ), np.max( lat[:, 0] )
      ymin = np.min(alt)
      # Allow the altitude maximum to be overwritten to zoom in. 
      ymax = np.max( np.where(lat>xmin, alt, 0) ) if lim is None else lim
      coords['xlims'], coords['ylims'] = (xmin, xmax), (ymin, ymax)
#    # The first time output is at 1s, but we want to start the axis at zero. 
#    if xaxis=='t':
#      coords['x'] = coords['x'][:self.tmax]
#      coords['xlims'] = (0, lim)
    # Dipole plots need outlines drawn on them. 
    if xaxis=='X' and yaxis=='Z':
      coords['outline'] = True
    # If we're looking at electromagnetic energy on the y axis, we want a log
    # scale, and we also need a minimum. 
    if yaxis=='U':
      coords['ylog'] = True
      coords['ylims'] = (10 if lim is None else lim, None)
    # For line plots, the y axis is specified by the data. 
    if coords['y'] is None:
      del coords['y']
    return coords

# #############################################################################
# ########################################################## Plot Window Object
# #############################################################################

# The Plot Window is a wrapper around PyPlot which handles the high-level
# commands -- subplot spacing, titles, labels, etc. It contains an array of
# Plot Cell objects, which keep track of the actual data. 

class plotWindow:

  # We keep a color axis for the color bar, a title axis, an array of header
  # axes for column labels, an array of side axes for row labels, a side header
  # axis to label the row labels, and a footer axis just in case. Data axes are
  # stored by the individual Plot Cells. Also a unit axis. 
  cax = None
  fax = None
  hax = None
  sax = None
  shax = None
  tax = None
  uax = None

  fax = None

  # The Plot Window also holds an array of Plot Cells, one for each data axis. 
  cells = None
  # Keep track of the style of color bar, if any, we'll be using. Use 'log' for
  # a log scale, 'sym' for a symmetric log scale, and 'lin' for a linear scale.
  # For no color bar, use False or None. 
  colorbar = None
  # Overwrite the default number of colors. 
  ncolors = 8
  # Overwrite the automatically-determined color bar range. 
  zmaxManual = None
  # Do we want to specify units for the color bar tick labels? 
  unit = ''


  fontfactor = 1.


  # ---------------------------------------------------------------------------
  # --------------------------------- Initialize Plot Window and Space Out Axes
  # ---------------------------------------------------------------------------

  def __init__(self, ncols=1, nrows=1, cells=None, square=False, joinlabel=None, footlabel=False, landscape=False, fontfactor=1., **kargs):
    # If initialized with an array of cells, this isn't a real Plot Window... 
    # it's a temporary object that allows the access of a slice of cells. 
    if cells is not None:
      self.cells = cells
      return
    # If we're making a real Plot Window, make sure there's nothing lingering
    # from a previous plot. 
    plt.close('all')
    # Set the font to match LaTeX. 

    self.fontfactor = fontfactor

    if not landscape:
      self.landscape = False
      rc('font', **{'family':'sans-serif', 'sans-serif':['Helvetica'], 
                    'size':str(9*self.fontfactor)})
    else:
      self.landscape = True
      rc('font', **{'family':'sans-serif', 'sans-serif':['Helvetica'], 
                    'size':str(12*self.fontfactor)})
    rc('text', usetex=True)
    rc('text.latex', preamble='\usepackage{amsmath}, \usepackage{amssymb}, ' + 
                              '\usepackage{color}')
    # The window width in inches is fixed to match the size of the page. 
    windowWidth = 5.75 if not self.landscape else 11.
    # A negative number of columns means that there should be just one column,
    # but extra "wide." For example, if asked for -3 columns, row heights are
    # set up to accommodate 3 columns, then only one cell is put on each row. 
    ancols, oncols = abs(ncols), max(1, ncols)
    # The window will be broken up into some number of equally-sized tiles.
    # That's the unit we use to specify the relative sizes of plot elements. 
    sideMargin = 40
    cellPadding = 5
    titleMargin = int(15*self.fontfactor)
    headMargin = 1 if ncols<2 and joinlabel is None else 10
    unitMargin = 10
    footMargin = int( ( 30 if footlabel is True else 20 )*self.fontfactor )
    # The size of each subplot depends on how many columns there are. The total
    # width of the subplot area (including padding) will always be the same.
    # No more than four columns are allowed. 
    cellWidth = {1:175, 2:80, 3:55, 4:40}[ancols]
    # Cells are proportioned to show a dipole plot, which is 10RE wide and 8RE
    # tall, in proper proportion. 
    cellHeight = cellWidth if square is True else 4*cellWidth/5 
    # Tally up how many tiles we need. 
    tileWidth = ancols*cellWidth + (ancols-1)*cellPadding + 2*sideMargin
    tileHeight = ( nrows*cellHeight + (nrows-1)*cellPadding + titleMargin +
                   headMargin + footMargin )
    # Set the window size in proportion with the number of tiles we need. This
    # ensures that that tiles are square. 
    windowHeight = tileHeight*windowWidth/tileWidth
    # Create the window. Tell it that we want the subplot area to go all the
    # way to the edges, then break that area up into tiles. 
    fig = plt.figure(figsize=(windowWidth, windowHeight), facecolor='white')
    fig.canvas.set_window_title('Tuna Plotter')
    tiles = gridspec.GridSpec(tileHeight, tileWidth)
    plt.subplots_adjust(bottom=0., left=0., right=1., top=1.)
    # Create a lattice of axes and use it to initialize an array of Plot Cells.
    self.cells = np.empty( (nrows, oncols), dtype=object)
    for row in range(nrows):
      top = titleMargin + headMargin + row*(cellHeight + cellPadding)
      bot = top + cellHeight
      if ncols<0:
        ax = plt.subplot( tiles[top:bot, sideMargin:-sideMargin] )
        self.cells[row, 0] = plotCell(ax)
      else:
        for col in range(ncols):
          left = sideMargin + col*(cellWidth + cellPadding)
          right = left + cellWidth
          ax = plt.subplot( tiles[top:bot, left:right] )
          self.cells[row, col] = plotCell(ax)
    # Space out the title axis. 
    self.tax = plt.subplot( tiles[:titleMargin, sideMargin:-sideMargin] )
    # Space out an array of side axes to hold row labels. 
    self.sax = np.empty( (nrows,), dtype=object)
    left, right = 0, sideMargin - 3*cellPadding
    for row in range(nrows):
      top = titleMargin + headMargin + row*(cellHeight + cellPadding)
      bot = top + cellHeight
      self.sax[row] = plt.subplot( tiles[top:bot, left:right] )
    # Space out an array of header axes on the top to hold column labels. 
    if joinlabel is True:
      self.hax = np.empty( (1,), dtype=object)
      top, bot = titleMargin, titleMargin + headMargin
      self.hax[0] = plt.subplot( tiles[top:bot, sideMargin:-sideMargin] )
    else:
      self.hax = np.empty( (ancols,), dtype=object)
      top, bot = titleMargin, titleMargin + headMargin
      for col in range(ancols):
        left = sideMargin + col*(cellWidth + cellPadding)
        right = left + cellWidth
        self.hax[col] = plt.subplot( tiles[top:bot, left:right] )
    # Side header axis, for the row label header. 
    top, bot = titleMargin, titleMargin + headMargin
    left, right = 0, sideMargin - 3*cellPadding
    self.shax = plt.subplot( tiles[top:bot, left:right] )
    # Narrow axis on the right side for the color bar. 
    top, bot = titleMargin + headMargin, -footMargin
    left, right = -sideMargin + cellPadding, -sideMargin + 3*cellPadding
    self.cax = plt.subplot( tiles[top:bot, left:right] )
    # Space out a tiny axis above the color bar to indicate units. Size it to
    # line up with the column labels. If there's only one column, and so the
    # column labels are compressed, still pretend they are sized normally. 
    top, bot = titleMargin + headMargin - unitMargin, titleMargin + headMargin
    left, right = -sideMargin + cellPadding, -sideMargin + 3*cellPadding
    self.uax = plt.subplot( tiles[top:bot, left:right] )

    # Make room for a label at the bottom. If footlabel isn't True, this will
    # probably overlap with x axis labels. 
    self.fax = plt.subplot( tiles[-15:-5, sideMargin:-sideMargin] )

    # The title, header, and side axes are for spacing text, not showing data.
    # The axes themselves need to be hidden. The colorbar axis is hidden by
    # default as well, though it may be un-hidden later. 
    self.tax.axis('off')
    self.shax.axis('off')
    self.cax.axis('off')
    self.uax.axis('off')
    self.fax.axis('off')
    [ x.axis('off') for x in self.sax ]
    [ x.axis('off') for x in self.hax ]
    # We're done setting up the axes. If we were given any other arguments, 
    # send them to the parameter handler. 
    return self.setParams(**kargs)

  # ---------------------------------------------------------------------------
  # ---------------------------------------------------- Adjust Plot Parameters
  # ---------------------------------------------------------------------------

  def setParams(self, **kargs):
    # Keyword parameters used for centering text in axes. 
    targs = {'x':0.5, 'y':0.5, 'horizontalalignment':'center', 
             'verticalalignment':'center'}
    # Address the parameters one at a time. 
    for key, val in kargs.items():
      # Keys are caps insensitive. 
      key = key.lower()
      # Accept a list of strings as column labels. 
      if key=='collabels':
        for col, label in enumerate(val):
          self.hax[col].text(s='$' + label + '$', **targs)
      # Turn on the color bar, and specify its scale. 
      elif key=='colorbar':
        self.colorbar = val
        if self.colorbar:
          self.cax.axis('on')

      # Write something in the foot label. 
      elif key=='footer':
          self.fax.text(s='$' + val + '$', **targs)

      # Overwrite the default number of colors. 
      elif key=='ncolors':
        self.ncolors = val
      # Accept a list of strings as row labels. 
      elif key=='rowlabels':
        for row, label in enumerate(val):
          self.sax[row].text(s='$' + label + '$', **targs)
      # Sometimes, we may want to label the row labels. 
      elif key=='rowlabellabel':
        self.shax.text(s='$' + val + '$', **targs)
      # By default, axis limits are common to all plots. 
      elif key=='sharelimits':
        self.sharelimits = bool(val)
      # Put a sideways label in the color bar axis. 
      elif key=='sidelabel':
        targs['horizontalalignment'] = 'left'
        self.cax.text(s='$' + val + '$', rotation='vertical', **targs)
        targs['horizontalalignment'] = 'center'
      # Accept a string as the window supertitle. 
      elif key=='title':
        fontsize = ( 12 if not self.landscape else 24 )*self.fontfactor
        self.tax.text(s='$' + val + '$', fontsize=fontsize, **targs)
      # In case we want to put units on the color bar tick labels. 
      elif key=='unit':
        self.unit = val
      # Put a little label over the color bar indicating units. 
      elif key=='unitlabel':
        self.uax.text(s='$' + val + '$', **targs)
      # Overwrite the automatically-determined color bar range. 
      elif key=='zmax':
        self.zmaxManual = val
      # Any other parameters get sent to the cells. 
      else:
        [ cell.setParams( **{key:val} ) for cell in self.cells.flatten() ]
    return

  # ---------------------------------------------------------------------------
  # ------------------------------------------------------------------ Add Data
  # ---------------------------------------------------------------------------

  # The Plot Window doesn't actually handle any data. Individual cells should
  # instead be accessed as array entries. 
  def __getitem__(self, index):
    # If we're asked for a single cell, return that cell. 
    if isinstance(index, int):
      return self.cells.flatten()[index]
    elif isinstance(index, tuple) and all( isinstance(x, int) for x in index ):
      return self.cells[index]
    # Otherwise, we were asked for a slice. In that case, return a Plot Window
    # object that has only the requested slice of cells. This allows parameters
    # to be set for that whole slice of cells without touching the rest. 
    if isinstance(index, tuple):
      cells = self.cells[index]
    else:
      self.cells.flatten()[index]
    return plotWindow(cells=cells)

  # If the window gets passed a contour, just send it along to each cell. 
  def setContour(self, *args, **kargs):
    return [ cell.setContour(*args, **kargs) for cell in self.cells.flatten() ]

  # If the window gets passed a line, just send it along to each cell. 
  def setLine(self, *args, **kargs):
    return [ cell.setLine(*args, **kargs) for cell in self.cells.flatten() ]

  # If the window gets passed a mesh, just send it along to each cell. 
  def setMesh(self, *args, **kargs):
    return [ cell.setMesh(*args, **kargs) for cell in self.cells.flatten() ]

  # If the window gets passed a bar plot, just send it along to each cell. 
  def setBars(self, *args, **kargs):
    return [ cell.setBars(*args, **kargs) for cell in self.cells.flatten() ]

  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------- Get Cell Extrema
  # ---------------------------------------------------------------------------

  # We standardize color levels and axis ranges across all cells.

  def xmax(self):
    return max( cell.xmax() for cell in self.cells.flatten() )

  def ymax(self):
    return max( cell.ymax() for cell in self.cells.flatten() )

  def zmax(self):
    return max( cell.zmax() for cell in self.cells.flatten() )

  # Looking at minima is tricky, since some of them may be None, which is
  # smaller than any number. 

  def xmin(self):
    xmn = [ cell.xmin() for cell in self.cells.flatten() ]
    return None if max(xmn) is None else min( x for x in xmn if x is not None )

  def ymin(self):
    ymn = [ cell.ymin() for cell in self.cells.flatten() ]
    return None if max(ymn) is None else min( y for y in ymn if y is not None )

  def zmin(self):
    zmn = [ cell.zmin() for cell in self.cells.flatten() ]
    return None if max(zmn) is None else min( z for z in zmn if z is not None )

  # ---------------------------------------------------------------------------
  # ------------------------------------------------------------- Render Window
  # ---------------------------------------------------------------------------

  # Once all of the contours are loaded, we can standardize the plot domain and
  # color levels. 
  def render(self, filename=None):
    # Use the most extreme x and y values to set the plot domain. Snap to
    # integers, but don't round based on tiny bits of numerical noise. 
    xmin = None if self.xmin() is None else np.round( self.xmin() )
    xmax = None if self.xmax() is None else np.round( self.xmax() )
    ymin = None if self.ymin() is None else np.round( self.ymin() )
    ymax = None if self.ymax() is None else np.round( self.ymax() )

    if np.iscomplexobj(xmin):
      print 'xmin is complex! '
    if np.iscomplexobj(xmax):
      print 'xmax is complex! '
    if np.iscomplexobj(ymin):
      print 'ymin is complex! '
    if np.iscomplexobj(ymax):
      print 'ymax is complex! '

#    xmin = np.floor( float( format(self.xmin(), '.4e') ) )
#    xmax = np.ceil( float( format(self.xmax(), '.4e') ) )
#    ymin = np.floor( float( format(self.ymin(), '.4e') ) )
#    ymax = np.ceil( float( format(self.ymax(), '.4e') ) )
    self.setParams( xlims=(xmin, xmax), ylims=(ymin, ymax) )
    # Only the leftmost cells get y axis labels and tick labels. 
    for cell in self.cells[:, 1:].flatten():
      if not cell.rightaxis:
        cell.setParams( ylabel='', yticklabels=() )
    # Only the bottom cells get x axis labela and tick labels. 
    for cell in self.cells[:-1, :].flatten():
      cell.setParams( xlabel='', xticklabels=() )
    # Use the most extreme contour value among all plots to set the color bar. 
    kargs = {'cax':self.cax, 'colorbar':self.colorbar, 'ncolors':self.ncolors, 'unit':self.unit}
    if self.zmaxManual is not None:
      colors = plotColors(zmax=self.zmaxManual, **kargs)
    else:
      colors = plotColors(zmax=self.zmax(), **kargs)
    # Send the color params to each cell. 
    [ cell.render(**colors) for cellRow in self.cells for cell in cellRow ]
    # If given a filename, save the image. 
    if filename is not None:
      # Make sure the folder exists. 
      if not os.path.exists( os.path.dirname(filename) ):
        os.makedirs( os.path.dirname(filename) )
      # Silently save the image. 
      plt.savefig(filename)
      return True
    # Otherwise, display it. 
    else:
      plt.show()
      return True

# #############################################################################
# ############################################################ Plot Cell Object
# #############################################################################

class plotCell:

  # If this cell contains a contour, we'll need to hold the spatial coordinates
  # and the data values. We also keep room for any arguments for contourf. 
  x, y, cz, mz, ckargs, mkargs = None, None, None, None, None, None
  # A plot can have any number of lines drawn on it. Those will be stored here. 
  lines = None

  bars = None


  # If we manually set the axis limits, we want to ignore the automatically-set
  # limits that come down the line later. 
  xlims, ylims = (None, None), (None, None)
  # If we're on a log scale, we need different rules for placing ticks. 
  xlog, ylog = False, False
  # Keep track if we're supposed to be tracing the outline of our domain, such
  # as if the data is dipole-shaped. Or the whole grid. 
  grid, outline = False, False
  # Cells can be small. Let's try to keep the number of ticks under control.
  nxticks, nyticks = 3, 4
  # Sometimes we want an extra axis label on the right. Make sure the window
  # doesn't delete it when it's cleaning up the non-edge ticks and labels. 
  rightaxis = False

  xtickrelax, ytickrelax = False, False

  flipx, flipy = False, False


  # ---------------------------------------------------------------------------
  # ----------------------------------------------------------- Initialize Cell
  # ---------------------------------------------------------------------------

  def __init__(self, ax):
    self.ax = ax
    return

  # ---------------------------------------------------------------------------
  # ------------------------------------------------------- Set Cell Parameters
  # ---------------------------------------------------------------------------

  def setParams(self, **kargs):
    # Scroll through the parameters one at a time. 
    for key, val in kargs.items():
      # Keys are caps insensitive. 
      key = key.lower()
      # Sometimes we want to sneak in an extra axis of labels. 
      if key=='axright' and bool(val) is True:
        self.rightaxis = True
        self.ax.yaxis.set_label_position('right')
        self.ax.yaxis.tick_right()
        self.ax.yaxis.set_ticks_position('both')
      # Draw Earth. 
      elif key=='earth':
        q = {'l':90, 'r':270, 't':0, 'b':180}[ val[0] ]
        self.ax.add_artist( Wedge( (0, 0), 1, q,       q + 180, fc='w') )
        self.ax.add_artist( Wedge( (0, 0), 1, q + 180, q + 360, fc='k') )
      # Flip an axis. 
      elif key=='flipx' and bool(val):
        self.flipx = True

      # Put some text in the corner. 
      elif key=='lcorner':
        targs = {'x':0.03, 'y':0.03, 'horizontalalignment':'left', 
                 'verticalalignment':'bottom', 'transform':self.ax.transAxes,
                 'fontsize':10}
        self.ax.text(s='$' + val + '$', **targs)

      # Put some text in the corner. 
      elif key=='rcorner':
        targs = {'x':0.97, 'y':0.03, 'horizontalalignment':'right', 
                 'verticalalignment':'bottom', 'transform':self.ax.transAxes,
                 'fontsize':10}
        self.ax.text(s='$' + val + '$', **targs)

      # Draw the grid. 
      elif key=='grid':
        self.grid = val
      # Sometimes we have to finagle with the number of ticks. 
      elif key=='nxticks':
        self.nxticks = val
      elif key=='nyticks':
        self.nyticks = val
      # Draw an outline around the plot contents. 
      elif key=='outline':
        self.outline = val
      # Add text inside the cell, along the top. If we want to do anything more
      # sophisticated with text, like control its position or rotation or
      # color or size, we'll probably need to add a setText method. 
      elif key=='text':
        targs = {'x':0.5, 'y':0.5, 'horizontalalignment':'center', 
                 'verticalalignment':'center', 'transform':self.ax.transAxes}
        self.ax.text(s='$' + val + '$', **targs)

      elif key=='toptext':
        targs = {'x':0.5, 'y':0.90, 'horizontalalignment':'center', 
                 'verticalalignment':'top', 'transform':self.ax.transAxes}
        self.ax.text(s='$' + val + '$', **targs)

      # Horizontal axis coordinate. 
      elif key=='x':
        self.x = val
      # Label the horizontal axis. 
      elif key=='xlabel':
        self.ax.set_xlabel('' if not val else '$' + val + '$')
      # Change padding between axis and label. 
      elif key=='xlabelpad':
        self.ax.xaxis.labelpad = val
      # Set horizontal axis domain. 
      elif key.startswith('xlim'):
        # If the limits are set manually, we want to ignore the automatic
        # limits that come down the line later. 
        self.xlims = ( val[0] if self.xlims[0] is None else self.xlims[0], 
                       val[1] if self.xlims[1] is None else self.xlims[1] )
      # Set log horizontal scale. 
      elif key=='xlog' and val is True:
        self.ax.set_xscale('log')
        self.xlog = True
      # Set the horizontal axis tick labels manually. 
      elif key=='xticklabels':
        self.ax.set_xticklabels(val)
        self.nxticks = None

      elif key=='xtickrelax':
        self.xtickrelax = val

      # Set the horizontal axis ticks manually. 
      elif key=='xticks':
        self.ax.set_xticks(val)
        self.nxticks = None
      # Vertical axis coordinate. 
      elif key=='y':
        self.y = val
      # Label the vertical axis. 
      elif key=='ylabel':
        self.ax.set_ylabel('' if not val else '$' + val + '$')
      # Change padding between axis and label. 
      elif key=='ylabelpad':
        self.ax.yaxis.labelpad = val
      # Set the vertical axis domain. 
      elif key.startswith('ylim'):
        # If the limits are set manually, we want to ignore the automatic
        # limits that come down the line later. 
        self.ylims = ( val[0] if self.ylims[0] is None else self.ylims[0], 
                       val[1] if self.ylims[1] is None else self.ylims[1] )
      # Set log vertical scale. 
      elif key=='ylog' and val is True:
        self.ax.set_yscale('log')
        self.ylog = True
      # Set the vertical axis tick labels manually. 
      elif key=='yticklabels':
        self.ax.set_yticklabels(val)
        self.nyticks = None

      elif key=='ytickrelax':
        self.ytickrelax = val

      # Set the vertical axis ticks manually. 
      elif key=='yticks':
        self.ax.set_yticks(val)
        self.nyticks = None
      # Report any unfamiliar parameters. 
      else:
        print 'WARNING: Unknown param ', key, ' = ', val
    return

  # ---------------------------------------------------------------------------
  # ------------------------------------------------------------- Set Cell Data
  # ---------------------------------------------------------------------------

  def setContour(self, *args, **kargs):
    # Store any keyword parameters meant for the contourf call. 
    self.ckargs = kargs
    # Accept the contour with or without its spatial coordinates. 
    if len(args)==1:
      self.cz = args[0]
    elif len(args)==3:
      self.x, self.y, self.cz = args
    # If we're passed a weird number of arguments, bail. 
    else:
      print 'ERROR: Illegal number of arguments to plotCell.setContour '
      exit()
    return

  def setLine(self, *args, **kargs):
    # Initialize line list. 
    if self.lines is None:
      self.lines = []
    # If we're given two numpy arrays, the first is the horizontal coordinate. 
    if len(args)>1 and isinstance(args[1], np.ndarray):
      self.lines.append( (args, kargs) )
      if self.x is None:
        self.x = args[0]
    # If only given one array, use self.x. 
    else:
      self.lines.append( ( (self.x,) + args, kargs ) )
    return

  def setMesh(self, *args, **kargs):
    # Store any keyword parameters meant for the contourf call. 
    self.mkargs = kargs
    # Accept the contour with or without its spatial coordinates. 
    if len(args)==1:
      self.mz = args[0]
    elif len(args)==3:
      self.x, self.y, self.mz = args
    # If we're passed a weird number of arguments, bail. 
    else:
      print 'ERROR: Illegal number of arguments to plotCell.setMesh '
      exit()
    return

  def setBars(self, *args, **kargs):
    # Initialize line list. 
    if self.bars is None:
      self.bars = []
    # If we're given two numpy arrays, the first is the horizontal coordinate. 
    if len(args)>1 and isinstance(args[1], np.ndarray):
      self.bars.append( (args, kargs) )
      # If we don't yet have a horizontal coordinate, keep this one. 
      if self.x is None:
        self.x = args[0]
    # If only given one array, use self.x. 
    else:
      self.bars.append( ( (self.x,) + args, kargs ) )
    return

  # ---------------------------------------------------------------------------
  # ------------------------------------------------------- Report Cell Extrema
  # ---------------------------------------------------------------------------

  # Cells all share a color bar (for contour plots) and axis limits (for line
  # plots). To manage that, the Plot Window asks each cell for its extrema. 

  def xmax(self):
    return None if self.x is None else np.max(self.x)

  def ymax(self):
    amax = None if self.y is None else np.max(self.y)
    bmax = None if self.bars is None else max( max( args[1] ) for args, kargs in self.bars )
    lmax = None if self.lines is None else max( max( args[1] ) for args, kargs in self.lines )
    return max(amax, bmax, lmax)

  def zmax(self):
    cmax = None if self.cz is None else np.max(self.cz)
    mmax = None if self.mz is None else np.max(self.mz)
    return max(cmax, mmax)

  # Minima are tricky, since None counts as smaller than any number. 

  def xmin(self):
    return None if self.x is None else np.min(self.x)

  def ymin(self):
    amin = None if self.y is None else np.min(self.y)
    bmin = None if self.bars is None else min( min( args[1] ) for args, kargs in self.bars )
    lmin = None if self.lines is None else min( min( args[1] ) for args, kargs in self.lines )
    nums = [ m for m in (amin, bmin, lmin) if m is not None ]
    return None if len(nums)==0 else min(nums)

  def zmin(self):
    cmin = None if self.cz is None else np.min(self.cz)
    mmin = None if self.mz is None else np.min(self.mz)
    nums = [ m for m in (cmin, mmin) if m is not None ]
    return None if len(nums)==0 else min(nums)

  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------- Render Plot Cell
  # ---------------------------------------------------------------------------

  def render(self, **colors):
    # If this cell has a contour, lay that down first. 
    if self.cz is not None:
      # Use the color params we were passed, but allow keyword arguments from
      # the contour call to overwrite them. 
      citems = [ ( key, colors[key] ) for key in ('ticks', 'levels', 'norm', 'cmap') ]
      kargs = dict( citems + self.ckargs.items() )
      self.ax.contourf(self.x, self.y, self.cz, **kargs)
    # Same for a mesh. 
    if self.mz is not None:
      citems = [ ( 'norm', colors['mnorm'] if 'mnorm' in colors else None ), 
                 ( 'cmap', colors['mcmap'] if 'mcmap' in colors else None ) ]
      kargs = dict( citems + self.mkargs.items() )
      self.ax.pcolormesh(self.x, self.y, self.mz, **kargs)

    # Draw the bars. 
    if self.bars is not None:
      [ self.ax.bar(*args, **kargs) for args, kargs in self.bars ]

    # Optionally, draw the outline of the data. 
    if self.outline and self.x is not None and self.y is not None:
      [ self.ax.plot(self.x[i, :], self.y[i, :], 'k') for i in (0, -1) ]
      [ self.ax.plot(self.x[:, k], self.y[:, k], 'k') for k in (0, -1) ]
    # Or the whole grid. 
    if self.grid and self.x is not None and self.y is not None:
      x, y = self.x, self.y
      [ self.setLine(x[i, :], y[i, :], 'k') for i in range( x.shape[0] ) ]
      [ self.setLine(x[:, j], y[:, j], 'k') for j in range( x.shape[1] ) ]

    # Draw any lines. 
    if self.lines is not None:
      [ self.ax.plot(*args, **kargs) for args, kargs in self.lines ]
    # Set axis limits. 
    self.ax.set_xlim( self.xlims if not self.flipx else self.xlims[::-1] )
    self.ax.set_ylim(self.ylims)

    # There can be a lot of cells. Try to be economical. 
    if not self.xlog:
      if self.nxticks is not None:
        self.ax.xaxis.set_major_locator( plt.MaxNLocator(self.nxticks,
                                                         integer=True) )
      if not self.xtickrelax:
        f, l = ('left', 'right') if not self.flipx else ('right', 'left')
        self.ax.xaxis.get_majorticklabels()[0].set_horizontalalignment(f)
        self.ax.xaxis.get_majorticklabels()[-1].set_horizontalalignment(l)

    if not self.ylog:
      if self.nyticks is not None:
        self.ax.yaxis.set_major_locator( plt.MaxNLocator(self.nyticks, 
                                                         integer=True) )

      if not self.ytickrelax:
        self.ax.yaxis.get_majorticklabels()[0].set_verticalalignment('bottom')
        self.ax.yaxis.get_majorticklabels()[-1].set_verticalalignment('top')
    return

# #############################################################################
# ######################################################### Plot Colors Handler
# #############################################################################

# This class figures out the color levels and ticks to be used by all of the
# contour plots. It draws the color bar, then serves as a keyword dictionary
# for the contourf calls. 

class plotColors(dict):

  # ---------------------------------------------------------------------------
  # --------------------------------------------------------- Initialize Colors
  # ---------------------------------------------------------------------------

  def __init__(self, zmax, cax, colorbar=None, ncolors=None, unit=''):
    # Some plots don't have contours. 
    if not zmax or not cax or not colorbar:
      return dict.__init__(self, {})
    # Store the data scale so that it can be hard-wired into our normalization
    # functions. 
    self.colorbar = colorbar
    self.ncolors = ncolors if ncolors is not None else 8
    self.nticks = self.ncolors - 1
    self.unit = unit
    # Assemble the keyword parameters in a temporary dictionary. We'll then use
    # the dictionary constructor to build this object based on it. 
    temp = {}
    # Determine location of contour color levels and color bar ticks. 
    if self.colorbar=='log':
      temp['ticks'], temp['levels'] = self.logTicksLevels(zmax)
      temp['norm'] = LogNorm()
    elif self.colorbar=='lg':
      temp['ticks'], temp['levels'] = self.lgTicksLevels(zmax)
      temp['norm'] = LogNorm()
    elif self.colorbar=='sym':
      temp['ticks'], temp['levels'] = self.symTicksLevels(zmax)
      temp['norm'] = Normalize()
    elif self.colorbar=='phase':
      temp['ticks'], temp['levels'] = self.phaseTicksLevels(zmax)
      temp['norm'] = Normalize()
    elif self.colorbar=='pos':
      temp['ticks'], temp['levels'] = self.posTicksLevels(zmax)
      temp['norm'] = Normalize()

    elif self.colorbar=='pct':
      temp['ticks'], temp['levels'] = self.pctTicksLevels(zmax)
      temp['norm'] = LogNorm()

    else:
      temp['ticks'], temp['levels'] = self.linTicksLevels(zmax)
      temp['norm'] = Normalize()

    # Rework the color map to match the normalization of our ticks and levels. 
    temp['cmap'] = self.getCmap()

    # Kludge something together so this works for colormesh as well as contour. 
    temp['mcmap'], temp['mnorm'] = self.getMesh( temp )

    # Draw the color bar. 
    self.setColorbar(cax, **temp)
    # Become a dictionary of color parameters to be used by the contour plots. 
    return dict.__init__(self, temp)

  # ---------------------------------------------------------------------------
  # ----------------------------------- Tick Locations and Contour Color Levels
  # ---------------------------------------------------------------------------

  def linTicksLevels(self, zmax):
    # We put zmax at the top of the top color level. Ticks go at the middle of
    # color levels, as they do with symlog plots. 
    self.zmax = zmax
    levels = np.linspace(-self.zmax, self.zmax, self.ncolors)
    ticks = 0.5*( levels[1:] + levels[:-1] )
    # Make sure that the middle tick is exactly zero. 
    ticks[ len(ticks)/2 ] = 0.
    return ticks, levels

  def phaseTicksLevels(self, zmax):
    # This setup probably isn't very useful. But it'll be a good place to start
    # if we ever want a linear-scale color bar that bottoms out at zero. It
    # also sets tick labels to be fractions of pi, which looks nice. 
    self.zmax = np.pi/2
    self.zmin = 0
    self.nticks = self.ncolors
    ticks = np.linspace(self.zmin, self.zmax, self.nticks)
    levels = np.linspace(self.zmin, self.zmax, self.ncolors)
    return ticks, levels

  # Seems to work? Don't lean too heavily... it was just thrown together. 
  def posTicksLevels(self, zmax):
    # Linear scale from 0 to zmax. Tick at every other level. Put zmax at the
    # center of the top bin, and 0 at the bottom edge of the bottom bin. 
    dz = zmax/(self.nticks - 0.5)
    self.zmax = zmax + dz/2
    levels = np.linspace(0, self.zmax, self.ncolors)
    ticks = 0.5*( levels[1:] + levels[:-1] )[::2]
    return ticks, levels

  def logTicksLevels(self, zmax):
    # Color levels are centered on ticks. The top tick is a power of ten. Each
    # subsequent tick is down by sqrt(10). 
    power = np.ceil(np.log10(zmax) - 0.25)
    # Each color spans a factor of root ten. This is in contrast to the
    # symmetric log scale, where each color was a whole order of magnitude. The
    # goal is to, for each, have the same number of colors and the same number
    # of orders of magnitude. 
    # Symetric log scale with 7 colors will have three positive powers of ten,
    # three negative powers, and zero. The log scale will just have three
    # positive powers. Anything below there will automatically show 0, though
    # it won't be marked explicitly on the color bar. 
    self.zmax = 10.**(power + 0.25)
    self.zmin = self.zmax/10**(self.nticks/2 + 0.5)
    ticks = [ 10**(power - 0.5*i) for i in range(self.nticks) ]
    logMin, logMax = np.log10(self.zmin), np.log10(self.zmax)
    levels = np.logspace(logMin, logMax, self.ncolors)
    return ticks, levels




  def pctTicksLevels(self, zmax):
    # Hard-coded to have ticks at 10%, 1%, 0.1%. Several color levels between each tick. 
    halves = np.logspace(-2, 1, self.ncolors - 1)
    self.zmin = halves[0]*np.sqrt( halves[0]/halves[1] )
    self.zmax = halves[-1]*np.sqrt(halves[-1]/halves[-2] )
    levels = np.logspace(np.log10(self.zmin), np.log10(self.zmax), self.ncolors)
    ticks = np.array( (0.01, 0.1, 1, 10) )
    return ticks, levels





  def lgTicksLevels(self, zmax):
    # Same as log, but with base 2 instead of 10. 
    power = np.ceil(np.log2(zmax) - 0.25)
    self.zmax = 2.**(power + 0.25)
    self.zmin = self.zmax/2**(self.nticks/2 + 0.5)
    ticks = [ 2**(power - 0.5*i) for i in range(self.nticks) ]
    lgMin, lgMax = np.log2(self.zmin), np.log2(self.zmax)
    levels = np.logspace(lgMin, lgMax, self.ncolors, base=2)
    return ticks, levels

  def symTicksLevels(self, zmax):
    # Ticks are located at powers of ten. Color levels are centered on ticks. 
    power = np.ceil( np.log10( zmax/np.sqrt(10.) ) )
    self.zmax = np.sqrt(10.)*10**power
    # A tick at zero, then one per order of magnitude. 
    norders = (self.nticks - 1)/2
    pticks = [ 10**(power - i) for i in range(norders) ]
    plevels = [ np.sqrt(10.)*10**(power - i) for i in range(norders + 1) ]
    # For uniform tick spacing, the log cutoff is a factor of 10 below the
    # lowest positive tick. That is, it's where the next tick would be, if we
    # had one more tick. 
    self.zmin = min(pticks)/10.
    ticks = sorted( pticks + [0] + [ -tick for tick in pticks ] )
    levels = sorted( plevels + [ -level for level in plevels ] )
    return ticks, levels

  # ---------------------------------------------------------------------------
  # ----------------------------------------------- Data Interval Normalization
  # ---------------------------------------------------------------------------

  # Map from the unit interval to the data scale via linear scale. 
  def linNorm(self, x):
    return self.zmax*(2*x - 1)

  # Map from the data scale to the unit interval via linear scale. 
  def linMron(self, x):
    return 0.5 + 0.5*x/self.zmax

  # Map from the unit interval to the data scale via linear scale. 
  def phaseNorm(self, x):
    return x*self.zmax

  # Map from the data scale to the unit interval via linear scale. 
  def phaseMron(self, x):
    return x/self.zmax

  # Map from the unit interval to the data scale via log scale. 
  def logNorm(self, x):
    return self.zmin*(self.zmax/self.zmin)**x

  # Map from the log scaled data scale to the unit interval. 
  def logMron(self, x):
    return np.log10(x/self.zmin)/np.log10(self.zmax/self.zmin)

  # Map from the unit interval to the data scale via symmetric log scale. 
  def symNorm(self, x):
    if x>0.5:
      return self.zmin*(self.zmax/self.zmin)**(2*x - 1)
    elif x<0.5:
      return -self.zmin*(self.zmax/self.zmin)**(1 - 2*x)
    else:
      return 0

  # Map from the symmetric log scaled data scale to the unit interval. 
  def symMron(self, x):
    if x>self.zmin:
      return 0.5 + 0.5*np.log10(x/self.zmin)/np.log10(self.zmax/self.zmin)
    elif x<-self.zmin:
      return 0.5 - 0.5*np.log10(-x/self.zmin)/np.log10(self.zmax/self.zmin)
    else:
      return 0.5

  # ---------------------------------------------------------------------------
  # --------------------------------------------------- Mesh Norm and Color Map
  # ---------------------------------------------------------------------------

  # This is SUPER kludgey. Sorry. No time to make it pretty while writing! 
  def getMesh(self, temp):
    clevs = np.array( temp['levels'] )
    if self.colorbar in ('lg', 'log', 'pct'):
      ulevs = np.array( [ self.logMron(c) for c in clevs ] )
    elif self.colorbar=='pos':
      ulevs = ( clevs - clevs[0] )/( clevs[-1] - clevs[0] )
    elif self.colorbar=='lin':
      ulevs = np.array( [ self.linMron(c) for c in clevs ] )
    elif self.colorbar=='sym':
      ulevs = np.array( [ self.symMron(c) for c in clevs ] )
    else:
      print 'WARNING: mesh can\'t handle that. '
    clist = [ temp['cmap'](u) for u in 0.5*( ulevs[1:] + ulevs[:-1] ) ]
    cmap = ListedColormap(clist)
    norm = BoundaryNorm(clevs, cmap.N)
    return cmap, norm

  # ---------------------------------------------------------------------------
  # ----------------------------------------------------------------- Color Map
  # ---------------------------------------------------------------------------

  # A color map is really just a handful of RGB codes defined on the unit
  # interval. To show up nicely, we need to renormalize that unit interval to
  # match the normalization of our ticks and color levels. 
  def getCmap(self):
    # Figure out the unit interval renormalization to use. 
    if self.colorbar in ('lg', 'log', 'pos', 'pct'):
      # Kinda kludgey. See setColorbar for explanation. 
      return plt.get_cmap(None)
    elif self.colorbar=='sym':
      norm = self.symNorm
    elif self.colorbar=='phase':
      # The physics machines at the U use an old version of Matplotlib. 
      # Cubehelix was added in 1.5. It can also be obtained here: 
      # https://github.com/jradavenport/cubehelix/blob/master/cubehelix.py
      return plt.get_cmap(None)
    else:
      norm = self.linNorm
    # Get a fine sampling of the color map on the unit interval. 
    N = 1000
    unitInterval = [ i/(N - 1.) for i in range(N) ]
    cmap = plt.get_cmap('seismic')
    rgb = [ cmap(u) for u in unitInterval ]
    # Renormalize the unit interval. Make sure we get the end points right. 
    newInterval = [ self.linMron( norm(u) ) for u in unitInterval ]
    newInterval[0], newInterval[-1] = 0., 1.
    # The color dict contains three channels. Each of them is a list of tuples,
    # (u, rgbLeft, rgbRight). Between u values, colors are interpolated
    # linearly. Approaching u from the right, the color should approach
    # rgbRight, and vice versa. Since our color map is smooth and
    # finely-resolved, we don't bother to distinguish.  
    red = [ (newInterval[i], rgb[i][0], rgb[i][0]) for i in range(N) ]
    grn = [ (newInterval[i], rgb[i][1], rgb[i][1]) for i in range(N) ]
    blu = [ (newInterval[i], rgb[i][2], rgb[i][2]) for i in range(N) ]
    # Return a LinearSegmentedColormap built from the color dictionary. We use
    # TONS of samples because the symmetric log normalization devotes very
    # little of the unit interval to zero... but that it the most important bin
    # to have sharply defined. 
    return LSC('myMap', {'red':red, 'green':grn, 'blue':blu}, 1000000)

  # ---------------------------------------------------------------------------
  # ------------------------------------------------------------- Set Color Bar
  # ---------------------------------------------------------------------------

  # Without SymLogNorm, we can't very well use the built-in color bar
  # functionality. Instead, we make our own: a tall, narrow contour plot. 
  def setColorbar(self, cax, **colorParams):
    # Unit interval axes. 
    X, Y = np.empty( (2, 1000) ), np.empty( (2, 1000) )
    for i in range(2):
      X[i, :] = i
      Y[i, :] = np.linspace(0, 1, 1000)
    # The contour values are just the Y axis, mapped to the data scale via
    # linear, log, or symmetric log normalizer. We'll also need the inverse
    # normalizers, since we have the tick values in the data scale, and we map
    # them to the Y axis (which is on the unit interval). And the formatters,
    # to make our ticks look pretty in LaTeX. 
    if self.colorbar=='log':
      # This is kludgey right now. Sorry. We can't use a real color bar for the
      # symmetric norm plot, since since SymLogNorm isn't defined. But we can't
      # use a renormalized color map for the log plot due to sampling
      # constraints. This is the odd case out right now. 
      norm, mron, fmtr = self.logNorm, self.logMron, self.logFormatter
      ColorbarBase(cax, boundaries=colorParams['levels'],
                   ticks=colorParams['ticks'], norm=colorParams['norm'],
                   cmap=colorParams['cmap'])
      cax.set_yticklabels( [ fmtr(t) for t in colorParams['ticks'] ] )
      return

    elif self.colorbar=='lg':
      norm, mron, fmtr = self.logNorm, self.logMron, self.lgFormatter
      ColorbarBase(cax, boundaries=colorParams['levels'],
                   ticks=colorParams['ticks'], norm=colorParams['norm'],
                   cmap=colorParams['cmap'])
      cax.set_yticklabels( [ fmtr(t) for t in colorParams['ticks'] ] )
      return

    elif self.colorbar=='pct':
      norm, mron, fmtr = self.logNorm, self.logMron, self.pctFormatter
      ColorbarBase(cax, boundaries=colorParams['levels'],
                   ticks=colorParams['ticks'], norm=colorParams['norm'],
                   cmap=colorParams['cmap'])
      cax.set_yticklabels( [ fmtr(t) for t in colorParams['ticks'] ] )
      return

    elif self.colorbar=='pos':
      fmtr = self.linFormatter
      ColorbarBase(cax, boundaries=colorParams['levels'],
                   ticks=colorParams['ticks'], norm=colorParams['norm'],
                   cmap=colorParams['cmap'])
      cax.set_yticklabels( [ fmtr(t).replace('+', '') for t in colorParams['ticks'] ] )
      return

    elif self.colorbar=='sym':
      norm, mron, fmtr = self.symNorm, self.symMron, self.symFormatter
    elif self.colorbar=='phase':
      norm, mron, fmtr = self.phaseNorm, self.phaseMron, self.phaseFormatter
    else:
      norm, mron, fmtr = self.linNorm, self.linMron, self.linFormatter
    # Draw the contour. 
    Z = np.vectorize(norm)(Y)
    cax.contourf( X, Y, Z, **colorParams)
    # Place the ticks appropriately on the unit interval (Y axis). 
    cax.set_yticks( [ mron(t) for t in colorParams['ticks'] ] )
    # Format tick names nicely. 
    cax.set_yticklabels( [ fmtr(t) for t in colorParams['ticks'] ] )
    # Put the color bar ticks on the right, get rid of the ticks on the bottom,
    # and hide the little notches in the color bar. 
    cax.yaxis.tick_right()
    cax.set_xticks( [] )
    cax.tick_params( width=0 )
    return

  # ---------------------------------------------------------------------------
  # ------------------------------------------------------ Tick Name Formatting
  # ---------------------------------------------------------------------------

  # We have to format the ticks for two reasons. First, because the color bar Y
  # axis is on the unit interval, not the data scale (and may not be normalized
  # properly). Second, because that's how we make sure to get dollar signs in
  # there so LaTeX handles the font rendering. 
  def linFormatter(self, x):
    # Zero is always zero. 
    if x==0:
      return '$0' + self.unit + '$'
    # If our numbers are around order unity, the top tick should show two
    # significant figures, and the rest should match that decimal place. 
    elif 1e-3<self.zmax<1e4:
      sign = '' if x<0 else '+'
      power = int( format(self.zmax, '.1e').split('e')[-1] )
      if power>1:
        xp = x/10.**power
        d0 = int(xp)
        d1 = int( round( 10*(xp - d0) ) )
        fx = format((d0 + 0.1*d1)*10**power, '.0f')
      else:
        digs = 1 - power
        fx = format(x, '.' + str(digs) + 'f')
      return '$' + sign + fx + self.unit + '$'
    else:
      # Cast the number in scientific notation. 
      s = format(x, '.1e').replace('e', ' \\cdot 10^{') + '}'
      # If the number is positive, throw a plus sign on there. 
      s = '+ ' + s if x>0 else s
      # Before returning, get rid of any extra digits in the exponent. 
      return '$' + s.replace('+0', '').replace('-0', '-') + self.unit + '$'

  def phaseFormatter(self, x):
    # Zero is always zero. 
    if x==0:
      return '$0' + self.unit + '$'
    else:
      # Fractions of pi. Don't put '1' in the numerator. 
      numer, denom = (x/np.pi).as_integer_ratio()
      if numer==1:
        return '${\\displaystyle \\frac{\\pi}{' + str(denom) + '}}' + self.unit + '$'
      else:
        return '${\\displaystyle \\frac{' + str(numer) + ' \\pi}{' + str(denom) + '}}' + self.unit + '$'

  def logFormatter(self, x):
    # Zero is always zero. 
    if x==0:
      return '$0$'
    # Half-power ticks don't get labels. 
    elif format(x, '.1e').startswith('3'):
      return ''
    # Otherwise, just keep the power of ten. 
    return '$ 10^{' + format(np.log10(x), '.0f') + '}' + self.unit + '$'


  def pctFormatter(self, x):
    if x == int(x):
      return '$' + str( int(x) ) + '\\%$'
    else:
      return '$' + str(x) + '\\%$'


  def lgFormatter(self, x):
    # Zero is always zero. 
    if x==0:
      return '$0$'
    # Half-power ticks don't get labels. 
    elif np.log2(x) != np.int( np.log2(x) ):
      return ''
    # Otherwise, just keep the power of ten. 
    return '$ 2^{' + format(np.log2(x), '.0f') + '}' + self.unit + '$'



  def symFormatter(self, x):
    # Zero is always zero. 
    if x==0:
      return '$0' + self.unit + '$'
    # Otherwise, just keep the sign and the power of ten. 
    power = format(np.log10( np.abs(x) ), '.0f')
    return '$ ' + ( '-' if x<0 else '+' ) + ' 10^{' + power + '}' + self.unit + '$'

# #############################################################################
# ############################################################ Helper Functions
# #############################################################################

# Turns a list of numbers (1, 2, 3) into the string '1x2x3'. 
def by(x):
  return str( x[0] ) + 'x' + by( x[1:] ) if len(x)>1 else str( x[0] )

# Convert a string to a complex or float. 
def com(x):
  if ',' not in x:
    return float(x)
  else:
    # Shave off the parentheses then split into real and imaginary parts. 
    re, im = x[1:-1].split(',')
    return (float(re) + float(im)*1j)

# Grab all files in the given directory. Remember that we always use absolute
# paths, and that directory names always end with a slash. 
def files(path=None, end=''):
  p = path if path is not None else os.getcwd()
  # Grab all files in the directory. 
  f = [ p + x for x in os.listdir(p) if os.path.isfile(p + x) ]
  # Only return the ones that end with our desired extension. 
  return sorted( x for x in f if x.endswith(end) )

# Given kargs full of lists, return a list of kargs (if we're making a series
# of images) or just one of them (if we're looking at the plot). 
def loopover(**kargs):
  lo = [ [] ]
  for key, vals in kargs.items():
    lo = [ l + [ (key, v) ] for l in lo for v in vals ]
  if '-i' not in argv:
    return [ dict( choice(lo) )  ]
  else:
    return [ dict(l) for l in lo ]

# Timestamp for labeling output. 
def now():
  return ( znt(lt().tm_year, 4) + znt(lt().tm_mon, 2) + znt(lt().tm_mday, 2) +
           '_' + znt(lt().tm_hour, 2) + znt(lt().tm_min, 2) +
           znt(lt().tm_sec, 2) )

# Turn a string into a float or integer. 
def num(x):
  return int( float(x) ) if float(x)==int( float(x) ) else float(x)

# Turns the number 3 into '003'. If given a float, truncate it. 
def znt(x, width=0):
  return str( int(x) ).zfill(width)

# Two decimal places. If it's a number bigger than one, that's two sig figs. Less than one, only one sig fig, to save space. 
def tdp(x):

#  if not isinstance(x, np.float) or not isinstance(x, np.int) or not np.isfinite(x):
#    return '?'

  if x.size > 1 or not np.isfinite(x):
    return '?'

  if x == 0:
    return '0'
  elif x < 1:
    return str( float( format(x, '.0e') ) )
  elif x < 10:
    return str( float( format(x, '.1e') ) )
  else:
    return str( int( float( format(x, '.1e') ) ) )



# Make sure we don't throw anything infinite on the plot. 
def fmask(x):
  return masked_where(np.logical_not( np.isfinite(x) ), x)

# Also leave out any zeros. 
def zmask(x, thr=0):
  return masked_where(np.abs(x) <= thr, x)



# #############################################################################
# ################################################################ Array Reader
# #############################################################################

# Read a file of values into an array. We expect the first line to give the
# array dimensions. The rest of the file should just be real or complex
# numbers, and is agnostic to whitespace and newlines. 
def readArray(filename):
  # The out prefix is just an older convention for dat files, Fortran output.
  # We ultimately want to use the Python data format, pickles. 
  name = filename[ :filename.rfind('.') ]
  datname, outname, pklname = name + '.dat', name + '.out', name + '.pkl'

  # Allow epsp.dat, but rename to epsPerp.dat. 
  if os.path.exists( datname.replace('epsPerp', 'epsp') ):
    outname = outname.replace('epsPerp.out', 'epsp.dat')

  # Allow jz.out, but rename to Jz.dat (change in capitalization). 
  outname = outname.replace('Jz', 'jz')

  # If we see a old file (.out) move it to the new convention (.dat). 
  if os.path.isfile(outname) and not os.path.exists(datname):
    os.rename(outname, datname)
    print 'Renamed ' + basename(outname) + ' to ' + basename(datname)

  # If a pickle is available, read that instead of parsing the Fortran output. 
  if os.path.isfile(pklname):
    print 'Reading ' + basename(pklname) + ' ... ',
    stdout.flush()
    # Note how long it takes to read the file. 
    start = time()
    with open(pklname, 'rb') as handle:
      inputArray = pickle.load(handle)
    print format(time() - start, '5.1f') + 's' + ' ... ' + by(inputArray.shape)
    return inputArray
  # If the pickle doesn't exist yet, parse the Fortran output. 
  elif os.path.isfile(datname):
    print 'Reading ' + basename(datname) + ' ... ',
    stdout.flush()
    # Note how long it takes to read the file. 
    start = time()
    # Grab the data as a list of strings. 
    with open(datname, 'r') as f:
      arrayLines = f.readlines()
    # The first line is the dimensions of the array. 
    dims = [ int(x) for x in arrayLines.pop(0).split() ]
    # Assemble a one-dimensional array large enough to hold all of the values.
    # (This is much faster than appending as we go.) This means figuring out if
    # we want reals or complexes. We check by looking for a comma, since
    # complex values are listed as ordered pairs. 
    if len(arrayLines)>0 and ',' in arrayLines[0]:
      dtype = np.complex
    else:
      dtype = np.float
    # Create the empty array. 
    nVals = np.prod(dims)
    vals = np.empty(nVals, dtype=dtype)
    # Now fill the array with values one at a time. Stop when it's full, or
    # when we run out of values. 
    i = 0
    for line in arrayLines:
      for val in line.split():
        # Check if the array is full. 
        if i==nVals:
          break
        # If it's not, grab the next value. 
        else:
          vals[i] = com(val)
          i = i + 1
    # Reshape and transpose the array. Fortran and Python have opposite
    # indexing conventions. 
    inputArray = np.transpose( np.reshape( vals, dims[::-1] ) )
    # Check the array dimensions. If it's not full, the run may have crashed. 
    # In that case we return only the time steps that exist. 
    actualDims = dims[:-1] + [ np.int( i/np.prod(dims[:-1]) ) ]
    if dims!=actualDims:
      inputArray = inputArray[ ..., :actualDims[-1] ]
    # Report how long this all took. 
    print format(time() - start, '5.1f') + 's'
    # Dump a pickle for next time. 
    print '\tCreating ' + basename(pklname) + ' ... ',
    stdout.flush()
    start = time()
    with open(pklname, 'wb') as handle:
      pickle.dump(inputArray, handle, protocol=-1)
    print format(time() - start, '5.1f') + 's'
    return inputArray
  # If the pickle doesn't exist and there's no Fortran output, return nothing. 
  else:
    print 'WARNING: ' + datname + ' not found. '


