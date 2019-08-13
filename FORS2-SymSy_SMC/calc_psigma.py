#!/usr/bin/python

""" A simple test of the expected/predicted standard deviation of
the sky (psigma) based on the median sky level, effective gain and
readout noise of the data with the observed standard deviation of the
sly background as measured from the data (sigma_sky). 
These two should reasonably agree
[From Davis L. E. 1994, "A reference Guide to the IRAF/DAOPHOT Package"] """

#######################
# EDIT here:          #
median_sky = 155.13
sigma_sky = 9.5
                        
gain = 0.8             
readnoise = 3.6     # chip1 = 2.7, chip2 = 3.6 [for FORS2]

exposures = 3          
#######################


import numpy as np

effective_gain = exposures * gain
effective_readnoise = np.sqrt(exposures) * readnoise

print "- effective gain:", effective_gain
print "- effective read noise:", effective_readnoise

psigma = np.sqrt( (median_sky/effective_gain) + (effective_readnoise/effective_gain)**2 )

print "--> is it psigma ~ sigma sky ?"
print "  psigma:", psigma
print "  sigma sky:", sigma_sky

diff = ( (sigma_sky-psigma)/sigma_sky ) * 100

print "  difference (%):", diff
