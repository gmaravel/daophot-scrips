#!/bin/bash
##########################################################
# INPUT parameters with THIS order:
#
# SII-4500_Data  SII-2000_Data  Image_for_skycoordinates
# (on_band)      (off band)
#
# 
#
version='1.1'
#
# 4/6/2018: First version of the script (adapting version from SMC Ha imaging, without calibration)
# 4/7/2018: Correcting sed usage at $skyinfo (when putting all information together at *wcs.cat). It was substituting the first line of data with the header (so losing that line-source), instead of just adding the header.  
##########################################################

# Initial parameters

field=$1    # input field to run with

echo "!!! Analyzing "$field

path2stilts='/home/gmaravel/Softwr/stilts/stilts'
ds9='/home/gmaravel/Softwr/ds9/ds9'

########################################
echo "--> Creating the initial catalogs"

./photanalyser.py $field/*sub.2.als

fieldID=$(echo $field | cut -f1 -d_)
exp=$(echo $field | cut -f2 -d_)
chip=$(echo $field | cut -f3 -d_)

onBand=$(echo $fieldID\_SII-4500\_$exp\_$chip.sub.2.als.info.dat)

offBand=$(echo $fieldID\_SII-2000\_$exp\_$chip.sub.2.als.info.dat)

#echo $fieldID, $chip, $exp, $onBand, $offBand
#echo $onBandAll, $offBandSel

# getting into the directory
cd $field

for afile in $onBand $offBand; do
    allfile=${afile/.sub.2.als.info.dat/.all.cat}
    selfile=${afile/.sub.2.als.info.dat/.sel.cat}
    cp $afile $allfile
    awk '$7<1.8 && $6>-0.5 && $6<0.5 {print}' $afile > $selfile 
    sed -i '1i\#star_id xpos ypos mag magerr sharpness chi2' $selfile  
done


################################
echo "--> Matching sources between the two filters"

echo "... for selected sources only"
selmatches=$(echo $field.matches.sel.cat)
onBandSel=${onBand/.sub.2.als.info.dat/.sel.cat}
offBandSel=${offBand/.sub.2.als.info.dat/.sel.cat}
$path2stilts tmatch2 ifmt1=ascii in1=$onBandSel ifmt2=ascii in2=$offBandSel ofmt=ascii out=$selmatches matcher=2d values1='xpos ypos' values2='xpos ypos' params=2 join=1and2 find=best progress=log
echo "    saving as "$selmatches

echo "... for all sources"
allmatches=$(echo $field.matches.all.cat)
onBandAll=${onBand/.sub.2.als.info.dat/.all.cat}
offBandAll=${offBand/.sub.2.als.info.dat/.all.cat}
$path2stilts tmatch2 ifmt1=ascii in1=$onBandAll ifmt2=ascii in2=$offBandAll ofmt=ascii out=$allmatches matcher=2d values1='xpos ypos' values2='xpos ypos' params=2 join=1and2 find=best progress=log
echo "    saving as "$allmatches

# replace header 
for addheader in $selmatches $allmatches; do
    sed -i '1c\#SII-4500_ID  SII-4500_x  SII-4500_y  SII-4500_mag  SII-4500_magerr  SII-4500_sharp  SII-4500_chi2  SII-2000_ID  SII-2000_x  SII-2000_y  SII-2000_mag  SII-2000_magerr  SII-2000_sharp  SII-2000_chi2  Separation(SII-4500,SII-2000)' $addheader   
done 


######################################################################
echo "--> Calculating SII excess (SII4500-SII2000) plus error and SNR"

# Notes:
# These calculations are the same used for Ha imaging in the SMC, 
# just replacing Ha and R by SII-4500 and SII-2000, respectively 
# The structure of the files is the same, so there is no need actually 
# to change anything at this part (regarding the calculations)
#
# calculations performed (from topcat notes)
#  . HaminusR = mag_1-mag_2 
#  . HaminusR_err = sqrt(pow(magerr_1,2)+pow(magerr_2,2))
# > calculate SNR (based on Zhao et al 2005, ApJS, 161, 429)
#  . G = (2.5/ln(10))*(1-pow(10,-0.4*abs(HaminusR)))/abs(HaminusR)
#  . SNR = G*abs(HaminusR)/HaminusR_err
# awk related:  
#  . log(10) is awk is equivalent to ln(10), for log with a base of 10 use: log(100)/log(10)
#  . sqrt((...)^2) quick trick for abs()
# In the case where Hamag=Rmag awk fails to calculate SNR and raises an error for dividing with 0 
# > to overcome this we add a very small value of 0.00001 to the Ha mag in the denominator of SNR
# (the added value is not that sensitive)  

for infile in $selmatches $allmatches;do
    calcs=${infile/.cat/.calcs.dat}
    if [[ "$infile" == *".sel."* ]]; then
        echo "... for selected sources";
    elif [[ "$infile" == *".all."* ]]; then
        echo "... for all sources";
    else
        echo "... not a suitable extension!(upgrade script)"
        exit
    fi

    awk 'FNR>1 { 
    if ($4==$11)
            print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15, $4-$11, sqrt($5^2+$12^2), (2.5/log(10)) * ( (1-10^(-0.4*sqrt(($4-$11)^2)))/sqrt(($4+0.00001-$11)^2)) * ( sqrt(($4-$11)^2)/sqrt($5^2+$12^2)) ;
    else
        print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15, $4-$11, sqrt($5^2+$12^2), (2.5/log(10)) * ( (1-10^(-0.4*sqrt(($4-$11)^2)))/sqrt(($4-$11)^2)) * ( sqrt(($4-$11)^2)/sqrt($5^2+$12^2)); }' $infile > $calcs 

done


##################################################
echo "--> Finding sky coordinates for all sources"
# In both filters we get stellar sources mainly so it doesn't really matter from which image we acquire the sky coordinates, so selecting 
img4ds9=$(echo $fieldID\_SII-2000\_$exp\_$chip.fits)
for initfile in $selmatches $allmatches;do 
    reg=${initfile/.cat/.reg}
    echo "... working on "$initfile
    awk '{printf "point(%s,%s) # point=diamond\n", $9,$10}' $initfile > $reg
    sed -i '1c\global color=green dashlist=8 3 width=1 font="helvetica 10 normal roman" select=1 highlite=1 dash=0 fixed=0 edit=0 move=0 delete=0 include=1 source=1 \nimage' $reg
    # and convert that to sky coordinates (in degrees) through ds9
    wcs=${reg/.reg/.wcs.reg}
#    wcssex=${reg/.reg/.wcs-sex.reg}
    $ds9 $img4ds9 -regions load $reg -regions system wcs -regions skyformat degrees -regions save $wcs -exit 
   	# degrees make it easier to work with sky cross-matching later on than sexagesimal
    echo "    > checking for incorrect pairing of sources"
    # keeping only the x/y positions (to double check that everything is fine with the initial catalog)
    awk 'FNR>2 {print $1}' $reg | sed 's/point(//g; s/,/  /g; s/)//g' > tmp1.tmp 
    # keeping RA,Dec coordinates (this is 1-1 correlation with the previous reg file
    awk 'FNR>3 {print $1}' $wcs | sed 's/point(//g; s/,/  /g; s/)//g' > tmp2.tmp

    # checking for incorrect pairs (x/y positions of a filter should match the x/y positions of first reg file)
    # else everything is dumped to this file
    calcfile=${initfile/.cat/.calcs.dat}
    paste $calcfile tmp1.tmp tmp2.tmp | awk '$9!=$19 || $10!=$20 {print}' > incorrect_pairs.tmp
    lines=($(wc -l incorrect_pairs.tmp))

    # according to the number of lines we exit or not the script
    # (0 is the number we want!)
    if (( $lines!=0 ));
    then 
        echo " "
        echo "!!! ERROR !!!"
        echo "    something went wrong with the x/y positions"
        echo "    check the incorrect_pairs.tmp file (with #"$lines" lines)"
        exit
    else
        echo "        OK, all good!"
    fi
  
    # adding RA,Dec coordinates to the file
    skyinfo=${initfile/.cat/.wcs.cat}
    paste $calcfile tmp2.tmp > $skyinfo
    sed -i '1i\#SII-4500_ID  SII-4500_x  SII-4500_y  SII-4500_mag  SII-4500_magerr  SII-4500_sharp  SII-4500_chi2  SII-2000_ID  SII-2000_x  SII-2000_y  SII-2000_mag  SII-2000_magerr  SII-2000_sharp  SII-2000_chi2  Separation(SII-4500,SII-2000)  SII_excess  SII_excess_err  SNR  RA_deg  Dec_deg' $skyinfo 
    echo "    saving as "$skyinfo 

done

# cleaning a bit
selcalcs=${selmatches/.cat/.calcs.dat}
allcalcs=${allmatches/.cat/.calcs.dat}
rm tmp1.tmp tmp2.tmp incorrect_pairs.tmp $selcalcs $allcalcs


#################################################
echo "--> Identifying best SII excess candidates"
selmatcheswcs=${selmatches/.sel.cat/.sel.wcs.cat}
candidates=${selmatches/.sel.cat/.sel.candidates.cat}

# basic statistics to determine the best candidates
#mean=$(awk 'BEGIN{s=0;}{s=s+$16;}END{print s/NR;}' $selmatcheswcs)
#err=$(awk 'BEGIN{s=0;}{s=s+$17;}END{print s/NR;}' $selmatcheswcs)
#limit=$(awk -v mn=$mean -v er=$err "BEGIN {print mn-5*er}")
#echo "    - <SII4500-SII2000>="$mean
#echo "    - <SII4500-SII2000>error="$err
#echo "    - (SII4500-SII2000)baseline="$limit
#echo "    (screening for SII excess<"$limit", and SNR>5)"
#awk -v lmt=$limit '$16<=lmt && $18>=5 {print}' $selmatcheswcs > $candidates

awk '$16<0 && $18>=5 {print}' $selmatcheswcs > $candidates


# number of candidate stars
number2=($(wc -l $candidates))
echo "    > "$number2" candidates"

sed -i '1c\#SII-4500_ID  SII-4500_x  SII-4500_y  SII-4500_mag  SII-4500_magerr  SII-4500_sharp  SII-4500_chi2  SII-2000_ID  SII-2000_x  SII-2000_y  SII-2000_mag  SII-2000_magerr  SII-2000_sharp  SII-2000_chi2  Separation(SII-4500,SII-2000)  SII_excess  SII_excess_err  SNR  RA_deg  Dec_deg' $candidates


echo "--> All SII excess candidate stars saved as "$candidates  


# make region files
candidatesreg=${candidates/.cat/.reg}
awk '{printf "point(%s,%s) # point=cross\n", $19,$20}' $candidates > $candidatesreg
sed -i '1c\global color=red dashlist=8 3 width=1 font="helvetica 10 normal roman" select=1 highlite=1 dash=0 fixed=0 edit=0 move=0 delete=0 include=1 source=1 \nfk5' $candidatesreg

cd ../

echo " "
echo "!!! All done!"
