#!/bin/bash

#This script will phase genotypes using SHAPEIT and the 1000G phase 3 as reference samples.
#Note that this script should be used in the Penn State cluster
#Remember to have your unphased genotypes in the same folder as this script, divided by chromosome in plink format
#Finally, run the following script as follows:
#chmod +x PhasingGenos.sh
#./PhasingGenos.sh > PhasingGenos.log 2>&1 &

#Getting the path to this folder
thisdir=$(pwd)

#Download Genetic map and reference samples for hg 19 coordinates in scratch 
cd ~/scratch
if [ ! -f 1000GP_Phase3.tgz ]; then
	wget -q https://mathgen.stats.ox.ac.uk/impute/1000GP_Phase3.tgz
	tar -zxvf 1000GP_Phase3.tgz
	#No need to gunzip hap and legend files
fi

#Move to phasing directory
cd $thisdir
mkdir Phased

#Download SHAPEIT static version
wget -q https://mathgen.stats.ox.ac.uk/genetics_software/shapeit/shapeit.v2.r904.glibcv2.12.linux.tar.gz
tar -zxvf shapeit.v2.r904.glibcv2.12.linux.tar.gz
mv shapeit.v2.904.2.6.32-696.18.7.el6.x86_64/bin/shapeit ${thisdir}/shapeit

#For chr 1 to 22 create the pbs script and submit it to the cluster
#We'll send this to the open queue
echo ""
echo "Sarting log output for problematic SNPs..."
for i in {1..22}
do
	echo "Starting chr${i}..."
	echo "Creating pbs file..."
	file="$(echo *chr_${i}.bed | cut -d'.' -f1)"
	#We'll create initial files to remove any problematic SNPs (strand or missing) from the phasing
	echo "#!/bin/bash
#PBS -l nodes=1:ppn=1
#PBS -l walltime=30:00
#PBS -l pmem=2gb
#PBS -A open #jlt22_b_g_sc_default or open
#PBS -j oe

#Moving to phasing directory
cd ${thisdir}

#Phasing command
./shapeit -check \
-B ${file} \
-M ~/scratch/1000GP_Phase3/genetic_map_chr${i}_combined_b37.txt \
--input-ref ~/scratch/1000GP_Phase3/1000GP_Phase3_chr${i}.hap.gz ~/scratch/1000GP_Phase3/1000GP_Phase3_chr${i}.legend.gz ~/scratch/1000GP_Phase3/1000GP_Phase3.sample \
--output-log Phased/${file}_alignments" >> Phased/alignment_chr${i}.pbs

	echo "Submitting check in chr${i}..."
	qsub Phased/alignment_chr${i}.pbs

	echo "Waiting 1s for next file...."
	sleep 1s
done

echo ""
echo "Starting proper phasing..."
sleep 10m

for i in {1..22}
do
	echo "Starting chr${i}..."
	echo "Creating pbs file..."
	file="$(echo *chr_${i}.bed | cut -d'.' -f1)"
	exclude="Phased/${file}_alignments.snp.strand.exclude"
	echo "#!/bin/bash
#PBS -l nodes=1:ppn=8
#PBS -l walltime=24:00:00
#PBS -l pmem=16gb
#PBS -A open #jlt22_b_g_sc_default or open
#PBS -j oe

#Moving to phasing directory
cd ~/work/phasing

#Phasing command
./shapeit -B ${file} \
-M ~/scratch/1000GP_Phase3/genetic_map_chr${i}_combined_b37.txt \
--input-ref ~/scratch/1000GP_Phase3/1000GP_Phase3_chr${i}.hap.gz ~/scratch/1000GP_Phase3/1000GP_Phase3_chr${i}.legend.gz ~/scratch/1000GP_Phase3/1000GP_Phase3.sample \
-O Phased/${file}_phased \
--output-log ${file}_phased.log \
--force \
-T 8 " >> Phased/phasing_chr${i}.pbs

if [ -e $exclude ]; then
	echo "$(cat Phased/phasing_chr${i}.pbs) --exclude-snp ${exclude}" > Phased/phasing_chr${i}.pbs
fi

	echo "Submitting phasing_chr${i}.pbs job..."
	qsub Phased/phasing_chr${i}.pbs

	echo "Waiting 30m for next chromosome..."
	echo ""
	sleep 30m
done
