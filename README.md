# daophot-scrips
A collection of PyRAF/DAOPHOT scripts.
To run these you need a working installation of [IRAF](http://ds9.si.edu/site/Home.html) and [PyRAF](http://www.stsci.edu/institute/software_hardware/pyraf), [ds9](http://ds9.si.edu/site/Home.html) and the [stilts library](http://www.star.bris.ac.uk/~mbt/stilts/). 

## FORS2-SymSy_SMC
Analysis of FORS2 data to identify Symbiotic Systems in the Small Magellanic Cloud.

* __calc_psigma.py__: a simple calculator of the predicted value for the standard deviation of the sky base don the data - use to test the measured values of sky's standard deviation and median value
* __example_fits__: a directory with some images to test/run the daophot process
* __daoproc.py__: the "manual" mode to run the daophot process - insert manually the necessary parameters (see the editable block for parameters) and take where the ds9 resides
* __run_daoproc_auto.py__: the "auto" mode to run daophot for single and multiple files - for each image the script creates a temporary daoproc file (tmp_daoproc.py) with the necessary daophot parameters derived from the FIELD.notes, that runs and organizes the results to appropriate directories (again, take care to properly set the path to ds9) 
* __FIELD.notes__: a simple ascii file with various information on the observed fields, including the parameters used by daophot (this is filled manually by the user prio to daophot runs)
* __photanalyser.py__: the script reads the daophot product files (\*als,\*mag) and converts them to ascii catalogs of the sources - if `showPlots = True` then the scrip can produce a number of plots to check the quality of the results 
* __reduce_field.sh__: the scripts combines the daophot products of the two bands ('on' and 'off) per field/exposure time/chip (for FORS2) into the final catalogs, by doing the following steps:
  - convert daophot products to some initial catalogs - this step uses the script photanalyser.py 
  - perform an initial selection of sources based on their chi2 (<1.8) and sharpness (|sharp|<0.5)
  - match the sources between the two bands
  - calculate the (SII) excess, error, and SNR
  - convert (x,y) pixel positions to (RA,Dec) sky coordinates
  - identify best candidates based on their SII excess (<0) and their SNR (>5)
  
  Note: take care to properly set the paths to ds9 and stilts libray
* __reduce_field_outout.notes__: this file describes the results/products of reduce_field.sh script
