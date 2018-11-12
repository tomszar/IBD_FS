#!/bin/bash
#This script was interactively ran in the HPC PSU infrastructure so to adjust the number of jobs submitted

#Download Genetic map and reference samples for hg 19 coordinates in scratch 
cd ~/scratch
if [ ! -f 1000GP_Phase3.tgz ]; then
	wget -q https://mathgen.stats.ox.ac.uk/impute/1000GP_Phase3.tgz
	tar -zxvf 1000GP_Phase3.tgz
	#No need to gunzip hap and legend files
fi

#Move to directory. Remember to transfer the phased haps files to this folder
cd ~/work/FS

#Load modules
module load gcc/5.3.1
module load parallel/20170522

#Download fs and extract it
wget https://people.maths.bris.ac.uk/~madjl/finestructure/fs-2.1.3.tar.gz
tar -xzvf fs-2.1.3.tar.gz
fs-2.1.3/configure
make

######Send job to convert from impute to chromopainter
#We will ask for 1 processor per chromosome with 8 gb
mkdir -p convert
for chr in {1..22}
do 
    cmdf="convert/convert_chr${chr}.pbs" 
    infile="$(echo *chr_${chr}_phased.haps)"
    outfile="$(echo *chr_${chr}_phased.haps | cut -d'.' -f1)"
    echo "#!/bin/bash" > $cmdf 
    echo "#PBS -l nodes=1:ppn=1" >> $cmdf 
    echo "#PBS -l walltime=24:00:00" >> $cmdf
    echo "#PBS -l pmem=8gb" >> $cmdf
	echo "#PBS -A open" >> $cmdf #account for resource consumption (jlt22_b_g_sc_default or open)
	echo "#PBS -j oe" >> $cmdf
	echo "" >> $cmdf
	echo "#Moving to directory" >> $cmdf
	echo "cd ~/work/FS" >> $cmdf
	echo "#convert from imputer to chromopainter format" >> $cmdf
    echo "perl fs-2.1.3/scripts/impute2chromopainter.pl ${infile} ${outfile}" >> $cmdf
    echo "#add chromosome column to 1000G genetic map downloaded from https://mathgen.stats.ox.ac.uk/impute/1000GP_Phase3.tgz" >> $cmdf
    echo "awk -v awk_chr=$chr 'NR==1{print \"chr \"\$0} NR>1{print awk_chr\" \"\$0}' ~/scratch/1000GP_Phase3/genetic_map_chr${chr}_combined_b37.txt > ~/scratch/1000GP_Phase3/genetic_map_chr${chr}_combined_b37_hapv.txt" >> $cmdf
    echo "#convert to recombfile used by fs" >> $cmdf
    echo "perl fs-2.1.3/scripts/convertrecfile.pl -M hapmap ${outfile}.phase ~/scratch/1000GP_Phase3/genetic_map_chr${chr}_combined_b37_hapv.txt recomb_chr${chr}.recombfile" >> $cmdf
done 

for chr in {1..22}
do
	qsub convert/convert_chr${chr}.pbs
done

#Create ids file
awk 'NR>2{print $2}' *chr_1_phased.sample > Merge.ids

#Now run fs, for a subset of chromosomes, to estimate parameters
infiles="$(echo *chr_{1,8,12,22}_phased.phase)"
./fs merge_fs.cp -idfile Merge.ids -phasefiles $infiles -recombfiles recomb_chr{1,8,12,22}.recombfile -hpc 1 -go
#Add ./ to the beginning of commandfile1.txt
awk '{print "./"$0}' merge_fs/commandfiles/commandfile1.txt > merge_fs/commandfiles/commandfile1.temp && mv merge_fs/commandfiles/commandfile1.temp merge_fs/commandfiles/commandfile1.txt

#Submit commandfile1.txt commands to HPC
#Divide in jobs of 120 commands per file (109 jobs)
split -d -l 120 merge_fs/commandfiles/commandfile1.txt merge_fs/commandfiles/commandfile1_split.txt -a 3

mkdir -p fsjobs
#Run the 87 jobs.
for i in {000..090}
do
	cmdf="fsjobs/fsjob_${i}.pbs"
	echo '#!/bin/bash' > $cmdf 
	echo "#PBS -l nodes=1:ppn=1" >> $cmdf 
	echo "#PBS -l walltime=48:00:00" >> $cmdf
	echo "#PBS -l pmem=16gb" >> $cmdf
	echo "#PBS -A open" >> $cmdf
	echo "#PBS -j oe" >> $cmdf
	echo "" >> $cmdf
	echo "#Moving to directory" >> $cmdf
	echo "cd ~/work/FS" >> $cmdf
	echo "" >> $cmdf
	cat merge_fs/commandfiles/commandfile1_split.txt${i} >> $cmdf
	
	qsub fsjobs/fsjob_${i}.pbs

done > fsjobs/fsjobs.log 2>&1 &
	
#Second batch
for i in {090..179}
do
	cmdf="fsjobs/fsjob_${i}.pbs"
	echo '#!/bin/bash' > $cmdf 
	echo "#PBS -l nodes=1:ppn=1" >> $cmdf 
	echo "#PBS -l walltime=100:00:00" >> $cmdf
	echo "#PBS -l pmem=8gb" >> $cmdf
	echo "#PBS -A jlt22_b_g_sc_default" >> $cmdf
	echo "#PBS -j oe" >> $cmdf
	echo "" >> $cmdf
	echo "#Moving to directory" >> $cmdf
	echo "cd ~/work/FS" >> $cmdf
	echo "" >> $cmdf
	cat merge_fs/commandfiles/commandfile1_split.txt${i} >> $cmdf
	
	qsub fsjobs/fsjob_${i}.pbs

done > fsjobs/fsjobs.log 2>&1 &

#Third batch
for i in {180..269}
do
	cmdf="fsjobs/fsjob_${i}.pbs"
	echo '#!/bin/bash' > $cmdf 
	echo "#PBS -l nodes=1:ppn=1" >> $cmdf 
	echo "#PBS -l walltime=100:00:00" >> $cmdf
	echo "#PBS -l pmem=8gb" >> $cmdf
	echo "#PBS -A jlt22_b_g_sc_default" >> $cmdf
	echo "#PBS -j oe" >> $cmdf
	echo "" >> $cmdf
	echo "#Moving to directory" >> $cmdf
	echo "cd ~/work/FS" >> $cmdf
	echo "" >> $cmdf
	cat merge_fs/commandfiles/commandfile1_split.txt${i} >> $cmdf
	
	qsub fsjobs/fsjob_${i}.pbs

done > fsjobs/fsjobs.log 2>&1 &

#Fourth batch
for i in {270..326}
do
	cmdf="fsjobs/fsjob_${i}.pbs"
	echo '#!/bin/bash' > $cmdf 
	echo "#PBS -l nodes=1:ppn=1" >> $cmdf 
	echo "#PBS -l walltime=100:00:00" >> $cmdf
	echo "#PBS -l pmem=8gb" >> $cmdf
	echo "#PBS -A jlt22_b_g_sc_default" >> $cmdf
	echo "#PBS -j oe" >> $cmdf
	echo "" >> $cmdf
	echo "#Moving to directory" >> $cmdf
	echo "cd ~/work/FS" >> $cmdf
	echo "" >> $cmdf
	cat merge_fs/commandfiles/commandfile1_split.txt${i} >> $cmdf
	
	qsub fsjobs/fsjob_${i}.pbs

done > fsjobs/fsjobs.log 2>&1 &

#Once the jobs are done, resume the analysis with
./fs merge_fs.cp -go
#An error will appear to run the second stage and a commandfile2.txt file will be created

#Add ./ to the beginning of commandfile2.txt
awk '{print "./"$0}' merge_fs/commandfiles/commandfile2.txt > merge_fs/commandfiles/commandfile2.temp && mv merge_fs/commandfiles/commandfile2.temp merge_fs/commandfiles/commandfile2.txt

#Submit commandfile2.txt commands to HPC
#Divide in jobs of 200 commands per file (326 jobs)
split -d -l 200 merge_fs/commandfiles/commandfile2.txt merge_fs/commandfiles/commandfile2_split.txt -a 3

#remove previous jobs
rm fsjobs/*

#Make sets of 89 jobs. Make sure to look for when most of the jobs end, so you can upload the next batch
#It seems that in this stage, each individual takes less than 10 minutes
for i in {000..089}
do
	cmdf="fsjobs/fsjob_${i}.pbs"
	echo '#!/bin/bash' > $cmdf 
	echo "#PBS -l nodes=1:ppn=1" >> $cmdf 
	echo "#PBS -l walltime=100:00:00" >> $cmdf
	echo "#PBS -l pmem=8gb" >> $cmdf
	echo "#PBS -A jlt22_b_g_sc_default" >> $cmdf
	echo "#PBS -j oe" >> $cmdf
	echo "" >> $cmdf
	echo "#Moving to directory" >> $cmdf
	echo "cd ~/work/FS" >> $cmdf
	echo "" >> $cmdf
	cat merge_fs/commandfiles/commandfile2_split.txt${i} >> $cmdf
	
	qsub fsjobs/fsjob_${i}.pbs

done > fsjobs/fsjobs.log 2>&1 &

#Second batch
for i in {090..179}
do
	cmdf="fsjobs/fsjob_${i}.pbs"
	echo '#!/bin/bash' > $cmdf 
	echo "#PBS -l nodes=1:ppn=1" >> $cmdf 
	echo "#PBS -l walltime=100:00:00" >> $cmdf
	echo "#PBS -l pmem=8gb" >> $cmdf
	echo "#PBS -A jlt22_b_g_sc_default" >> $cmdf
	echo "#PBS -j oe" >> $cmdf
	echo "" >> $cmdf
	echo "#Moving to directory" >> $cmdf
	echo "cd ~/work/FS" >> $cmdf
	echo "" >> $cmdf
	cat merge_fs/commandfiles/commandfile2_split.txt${i} >> $cmdf
	
	qsub fsjobs/fsjob_${i}.pbs

done > fsjobs/fsjobs.log 2>&1 &

#Third batch
for i in {180..269}
do
	cmdf="fsjobs/fsjob_${i}.pbs"
	echo '#!/bin/bash' > $cmdf 
	echo "#PBS -l nodes=1:ppn=1" >> $cmdf 
	echo "#PBS -l walltime=100:00:00" >> $cmdf
	echo "#PBS -l pmem=8gb" >> $cmdf
	echo "#PBS -A jlt22_b_g_sc_default" >> $cmdf
	echo "#PBS -j oe" >> $cmdf
	echo "" >> $cmdf
	echo "#Moving to directory" >> $cmdf
	echo "cd ~/work/FS" >> $cmdf
	echo "" >> $cmdf
	cat merge_fs/commandfiles/commandfile2_split.txt${i} >> $cmdf
	
	qsub fsjobs/fsjob_${i}.pbs

done > fsjobs/fsjobs.log 2>&1 &

#Fourth batch
for i in {270..326}
do
	cmdf="fsjobs/fsjob_${i}.pbs"
	echo '#!/bin/bash' > $cmdf 
	echo "#PBS -l nodes=1:ppn=1" >> $cmdf 
	echo "#PBS -l walltime=100:00:00" >> $cmdf
	echo "#PBS -l pmem=8gb" >> $cmdf
	echo "#PBS -A jlt22_b_g_sc_default" >> $cmdf
	echo "#PBS -j oe" >> $cmdf
	echo "" >> $cmdf
	echo "#Moving to directory" >> $cmdf
	echo "cd ~/work/FS" >> $cmdf
	echo "" >> $cmdf
	cat merge_fs/commandfiles/commandfile2_split.txt${i} >> $cmdf
	
	qsub fsjobs/fsjob_${i}.pbs

done > fsjobs/fsjobs.log 2>&1 &


#Once the jobs are done, resume the analysis with
./fs merge_fs.cp -go
#Now we will run the stage 3 
cmdf="fsjobs/fsjob_stage3.pbs"
echo '#!/bin/bash' > $cmdf 
echo "#PBS -l nodes=1:ppn=1" >> $cmdf 
echo "#PBS -l walltime=500:00:00" >> $cmdf
echo "#PBS -l pmem=64gb" >> $cmdf
echo "#PBS -A jlt22_b_g_sc_default" >> $cmdf
echo "#PBS -j oe" >> $cmdf
echo "" >> $cmdf
echo "#Moving to directory" >> $cmdf
echo "cd ~/work/FS" >> $cmdf
echo "" >> $cmdf
echo "./fs merge_fs.cp -s34args:'-X -Y' -makes3 -dos3 -combines3 -go" >> $cmdf
	
qsub fsjobs/fsjob_stage3.pbs

#Once the jobs are done, resume the analysis with
./fs merge_fs.cp -go
#Add ./ to the beginning of commandfile4.txt
awk '{print "./"$0}' merge_fs/commandfiles/commandfile4.txt > merge_fs/commandfiles/commandfile4.temp && mv merge_fs/commandfiles/commandfile4.temp merge_fs/commandfiles/commandfile4.txt
#Now we will run the stage 4
cmdf="fsjobs/fsjob_stage4.pbs"
echo '#!/bin/bash' > $cmdf 
echo "#PBS -l nodes=1:ppn=1" >> $cmdf 
echo "#PBS -l walltime=420:00:00" >> $cmdf
echo "#PBS -l pmem=64gb" >> $cmdf
echo "#PBS -A jlt22_b_g_sc_default" >> $cmdf
echo "#PBS -j oe" >> $cmdf
echo "" >> $cmdf
echo "#Moving to directory" >> $cmdf
echo "cd ~/work/FS" >> $cmdf
echo "" >> $cmdf
cat merge_fs/commandfiles/commandfile4.txt >> $cmdf

qsub fsjobs/fsjob_stage4.pbs

#All is done!


#####TESTING MEMORY######
##Test speed per ind in relation to memory
mkdir -p fsjobs
mem=2
for i in {1..6}
do
	cmdf="fsjobs/fsjob_${i}.pbs"
	echo '#!/bin/bash' > $cmdf 
	echo "#PBS -l nodes=1:ppn=1" >> $cmdf 
	echo "#PBS -l walltime=48:00:00" >> $cmdf
	echo "#PBS -l pmem=${mem}gb" >> $cmdf
	echo "#PBS -A open" >> $cmdf # account for resource consumption (jlt22_b_g_sc_default)
	echo "#PBS -j oe" >> $cmdf
	echo "" >> $cmdf
	echo "#Moving to directory" >> $cmdf
	echo "cd ~/work/FS" >> $cmdf
	echo "" >> $cmdf
	sed "${i}q;d" merge500k_fs/commandfiles/commandfile1.txt >> $cmdf
	mem=$(( $mem * 2 ))

	qsub fsjobs/fsjob_${i}.pbs
done