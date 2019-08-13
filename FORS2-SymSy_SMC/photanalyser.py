#!/usr/bin/python
# v3 17/10/2017: version for FORS camera, eg. removing ZP+color terms
# v2 23/04/2015: adding output for selected chi2 sources, and ZP+color term as obtained through the manual for the CTIO data, currently the .mag option is not working since the "system parameters" are commented out 
# v1 30/06/2014: info output with more details and organized for later use

# TODO insert mag sharpness, chi2 selection and limit if wanted...else print the whole sample!

import os, sys, glob
from math import sqrt
from matplotlib import pyplot as plt

# FILE SELECTION
if len(sys.argv)==1:
    print 'No arguments given!!\nRun as: ./daophot.py filename.ext\n  -- .ext can be: .als / .mag\n  -- list of multiple files accepted\n  -- wildcard * accepted!'
    sys.exit() 
arg = sys.argv[1:]

showPlots=False


for infile in arg:
    print " Working on", infile

    if infile[-4:]=='.als':
        fext = 'als'
    elif infile[-4:]=='.mag':
        fext = 'mag'
    else:    
        print "Filename should be something.als or something.mag"
        raise SystemExit

    # OUTPUT FILES
    b = open(infile+'.dropped.reg','w')    # dropped sources (due to big errors)
    g = open(infile+'.sources.reg','w')    # identified sources
    d = open(infile+'.info.dat','w')       # data info (csv file)
    # region headers 
    b.write('global color=red dashlist=8 3 width=1 font="helvetica 10 normal roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=0 delete=1 include=1 source=1\nphysical\n')
    g.write('global color=green dashlist=8 3 width=1 font="helvetica 10 normal roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=0 delete=1 include=1 source=1\nphysical\n')
    d.write('#star_id  xpos  ypos  mag  magerr  sharpness  chi2\n')


    sef = open(infile+'.selected.reg','w')  # selected sources
    sef.write('global color=red dashlist=8 3 width=1 font="helvetica 10 normal roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=0 delete=1 include=1 source=1\nphysical\n')
    
    # LISTS -- for plotting
    amag = []        # magnitudes
    amag_err = []        # magnitude errors
    amag_dif = []         # log(snr?)
    amag_relerr = []    # relative magnitude errors
    astar_id = []        # star ids (number from phot source list
    aflux = []        # flux (in counts / defined as sum-area*msky)
    asnr = []        # snr
    axpos = []        # x pixel value
    aypos = []        # y pixel value
    asharp = []        # sharpness (from daophot)
    achi = []        # chi2 fit
    anitr = []
    askypxcnt = []        # sky's counts per pixel ratio (msky)
    atotpxcnt = []        # total area's counts (sum/area, where sum=star+sky counts and area=total pixels)
    cnt = 0            # counter (for sources with large magnitude errors)

    # PROCESSING OF .als FILE
    if fext == 'als':
        fals = open(infile,'r')
        alslns = fals.readlines()
        fals.close
#        print alslns[0]
#        print alslns[44]    # first line after comments

     
        for i in range(44,len(alslns),2):
            line0 = alslns[i].split()
            star_id = line0[0]
            xpos = float(line0[1])
            ypos = float(line0[2])

            mag = float(line0[3]) 

            # adding ZP and color correction!!
#           mag = float(line0[3])+0.631+0.032*1.536

            magerr = float(line0[4])
            nitr = line0[6]
            line1 = alslns[i+1].split()
            sharp = float(line1[0])
            chi = float(line1[1])
            
            if chi>=0.5 and chi<=1.5 and sharp>-0.5 and sharp<0.5:
#            if mag>=18.1 and mag<=18.8:
#                print star_id, chi, sharp
                sef.write('point('+str(xpos)+','+str(ypos)+') # point=diamond\n')
            
#            print star_id, xpos, ypos, mag, magerr
            d.write(str(star_id)+'  '+str(xpos)+'  '+str(ypos)+'  '+str(mag)+'  '+str(magerr)+'  '+str(sharp)+'  '+str(chi)+'\n')
#            if float(sharp)>-0.5 and sharp<0.5 and float(chi)<1.5: # and magerr<1:
            if magerr<99:
                amag.append(mag)
                amag_err.append(magerr)
                amag_dif.append(mag-magerr)
                amag_relerr.append(magerr/mag) # relative error (DX/X)
                astar_id.append(star_id)
                asharp.append(sharp)
                axpos.append(xpos)
                aypos.append(ypos)
                achi.append(chi)
                anitr.append(nitr)        
                g.write('point('+str(xpos)+','+str(ypos)+') # point=diamond\n')
            else:
#                print star_id, magerr, xpos, ypos
                cnt+=1
                b.write('point('+str(xpos)+','+str(ypos)+') # point=x\n')    # text={'+star_id+'}        

    # PROCESSING OF .mag FILE
    if fext == 'mag':
        fmag = open(infile,'r')
        maglns = fmag.readlines()
        fmag.close
#        print maglns[0]
#        print maglns[75]    # first line after comments


        for i in range(75,len(maglns),5):
            line0 = maglns[i].split()
            imgname = line0[0].split('.')[0]
            star_id = line0[3].split(imgname)[0]    # for big numbers ID and coordsfilename field mix
            line1 = maglns[i+1].split()
            xpos = line1[0]
            ypos = line1[1]
            line2 = maglns[i+2].split()
            msky = float(line2[0])
            nsky = float(line2[3])
            line4 = maglns[i+4].split()
            summ = float(line4[1])
            area = float(line4[2])
            flux = float(line4[3])
            mag = line4[4]
            magerr = line4[5]
#            print star_id, magerr
            if mag!='INDEF' and magerr!='INDEF':
#                d.write(str(star_id)+'  '+str(xpos)+'  '+str(ypos)+'  '+str(mag)+'  '+str(magerr)+'  '+str(sharp)+'  '+str(sharp)+'\n')
                if float(magerr)<=1: #max(magerr):
                    amag.append(float(mag))
                    amag_err.append(float(magerr))
                    amag_relerr.append(float(magerr)/float(mag)) # relative error (DX/X)
                    astar_id.append(star_id)
                    aflux.append(flux)
                    askypxcnt.append(msky)
                    atotpxcnt.append(summ/area)
                    axpos.append(float(xpos))
                    aypos.append(float(ypos))
                    asnr.append(flux*gain/sqrt( flux*gain + area*(msky*gain + nd*texp + nr**2) )) 
                    g.write('point('+str(xpos)+','+str(ypos)+') # point=diamond\n')
                else:
#                    print "  star",star_id,"("+xpos+","+ypos+")","has large error (",magerr,")" 
                    b.write('point('+str(xpos)+','+str(ypos)+') # point=x\n')            
                    cnt+=1
#        print line0
#        print line1
#        print line4
#        print star_id, xpos, ypos, mag, magerr

    b.close()
    g.close()
    d.close()

    sef.close()

    # percentage of stars with large mag error removed
    remper = round(100.*cnt/(len(amag)+cnt),5)

    
    # PLOTTING
    fig = plt.figure(figsize=(16,8))

    p1 = plt.subplot(231)
    p1.plot(amag,amag_err, 'k.', ms=0.5)
    p1.set_ylabel('mag error')
    p1.set_xlabel('mag')

    p2 = plt.subplot(232)
    p2.hist(amag, bins=500)
    p2.set_ylabel('sources')
    p2.set_xlabel('mag')
    
    p3 = plt.subplot(233)
    p3.hist(amag_err,bins=500 , range=[0,0.6], normed=False)
    p3.set_ylabel('sources')
    p3.set_xlabel('mag error')
#    p3.set_yscale('log')

    if fext == 'mag':
        fig.suptitle(infile+'\nUsing:'+str(len(amag))+', Removing (mag_err>1):'+str(cnt)[:6]+' ('+str("{0:.2f}".format(remper))+'%)')
    
        p4 = plt.subplot(234)
        p4.hist(asnr, bins=500, range=[0,100])    #(asnr)/2.
        p4.set_ylabel('sources')
        p4.set_xlabel('SNR')
    
        p5 = plt.subplot(235)
        p5.hist(askypxcnt,bins=500 , histtype='step', color='b', range=[0,1000], label='background')
        p5.hist(atotpxcnt,bins=500 , histtype='step', color='r', range=[0,1000], label='sources')
        # atotpxcnt is the total count/pixel value of the area over which photometry is performed, and as such     we get an average value f this ratio - this coule be retrieved from the flux (defined as sum-area*msky, but it seems to be less clear).
        #ax[0,2].hist(aflux,bins=500 , histtype='step', color='g', range=[0,1000], label='flux-stars')
        p5.set_ylabel('sources')
        p5.set_xlabel('counts/pixel')
        p5.legend()
    elif fext == 'als':
        fig.suptitle(infile+'\nStars found: '+str(len(amag))+' ('+str(cnt)+' stars rejected due to criteria)')
    
        p4 = plt.subplot(234)
        p4.hist(achi, bins=200, color='k', range=[0,5])
        p4.set_ylabel('sources')
        p4.set_xlabel('chi2 fit')
    
#        p5 = plt.subplot(235)
#        p5.hist(asharp, bins=500, range=[-25,25])
#        p5.set_ylabel('sources')
#        p5.set_xlabel('sharpness')

        p5 = plt.subplot(235)
        p5.plot(amag, achi, 'k.')
        p5.set_ylabel('chi2 fit')
        p5.set_xlabel('mag')
        p5.axhline(y=1,ls='--', c='red')

        p6 = plt.subplot(236)
        p6.plot(achi,amag_dif,'k.')
        p6.set_ylabel('mag-mag_err')
        p6.set_xlabel('chi2 fit')

    else:
        print "nothing to print ? weird...check what you have inserted!"
    
#    plt.savefig(infile+'.png', bbox_inches=0)

    if showPlots==True:
	plt.show()
    else:
	continue
    

print "\nEveyrhing you asked was achieved, me Lord!"
