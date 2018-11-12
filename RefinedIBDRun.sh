#!/bin/bash

#This script will download RefineIBD software and run it using all .haps files in the directory,
#containing phased genotypes.
#First, the script will convert haps/sample files devided by chromosome from ShapeIt to vcf files
#Remember to have this script as well as the genotype files you want to analyze in the same folder
#To run it in background and output to a log file do the following:
#chmod +x RefinedIBDRun.sh
#./RefinedIBDRun.sh > RefinedIBDRun.log 2>&1 &

thisdir=$(pwd)
#Download RefineIBD
wget http://faculty.washington.edu/browning/refined-ibd/refined-ibd.12Jul18.a0b.jar
#Download SHAPEIT static version (to convert haps/sample files to vcf)
wget -q https://mathgen.stats.ox.ac.uk/genetics_software/shapeit/shapeit.v2.r904.glibcv2.12.linux.tar.gz
tar -zxvf shapeit.v2.r904.glibcv2.12.linux.tar.gz
mv shapeit.v2.904.2.6.32-696.18.7.el6.x86_64/bin/shapeit ${thisdir}/shapeit

#Download Genetic map for hg 19 (GRCh37) coordinates in scratch 
cd ~/scratch
if [ ! -f plink.GRCh37.map.zip ]; then
    wget http://bochet.gcc.biostat.washington.edu/beagle/genetic_maps/plink.GRCh37.map.zip
   	unzip plink.GRCh37.map.zip
fi

cd $thisdir
#Convert haps/sample files to vcf using shapeit
#Creating job files for each hap file
for file in *.haps
do
	filename="$(echo $file | cut -d'.' -f1)"

	echo "#!/bin/bash
#PBS -l nodes=1:ppn=1
#PBS -l walltime=10:00:00
#PBS -l pmem=8gb
#PBS -A open #jlt22_b_g_sc_default or open
#PBS -j oe

#Moving to directory
cd ${thisdir}

#Converting from .haps to .vcf
./shapeit -convert \
--input-haps $filename \
--output-vcf ${filename}.vcf" >> Convert_${file}.pbs

	qsub Convert_${file}.pbs

done

#Sleeping 5 minutes to wait for the jobs to complete
sleep 5m

#Run RefinedIBD for each chromosome
for i in {1..22}
do
	#Getting file names ready
	file="$(echo *chr_${i}_*.vcf)"
	mapfile="$(echo ~/scratch/plink.chr${i}.*.map)"
	outfile="$(echo *chr_${i}_*.vcf | cut -d'.' -f1)"
	refined="$(echo refined-ibd*.jar)"

	echo "#!/bin/bash
#PBS -l nodes=1:ppn=1
#PBS -l walltime=24:00:00
#PBS -l pmem=16gb
#PBS -A open #jlt22_b_g_sc_default or open
#PBS -j oe

#Moving to directory
cd ${thisdir}

#Runnning refinedibd
java -jar ${refined} gt=${file} map=${mapfile} out=${outfile}" >> RefinedIBD_job${i}.pbs

	qsub RefinedIBD_job${i}.pbs

done
