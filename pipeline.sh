#!/bin/bash

# ==== USER CONFIGURABLE PATHS ====
PROJECTS_DIR="/path/to/projects"
EXTERNAL_DRIVE="/path/to/external/drive"
FASTQC_DIR="/path/to/FastQC"
TRIM_DIR="/path/to/Trim"
STAR_DIR="/path/to/STAR/bin"
GENOME_INDEX="/path/to/genome/index"
GTF_FILE="/path/to/annotation.gtf"


echo Enter project name
	read varname
echo

echo Enter name of folder in external drive with raw data
	read var2
echo

create_project()
{
	cd "$PROJECTS_DIR"
	mkdir "$varname"
	echo A directory named $varname has been created
}

create_project

create_subdirectories()
{
	cd "$PROJECTS_DIR/$varname"
	mkdir raw
	mkdir output
	cd "$PROJECTS_DIR/$varname/output"
	mkdir qc
	mkdir qc_trim
	mkdir align
	mkdir trimmed
	mkdir counts
	echo
	echo Sub-directories have been created
}
create_subdirectories

fastqc()
{
	cp -R "$EXTERNAL_DRIVE/$var2" "$PROJECTS_DIR/$varname/raw"
	echo
	echo Files have been copied to raw
	echo
	
	while true; do
	    read -p "Do you want to run FastQC " yn
	    case $yn in
		[Yy]* ) 
		cd "$FASTQC_DIR";
		./fastqc -t 24 "$PROJECTS_DIR/$varname/raw/$var2"/*.gz -o "$PROJECTS_DIR/$varname/output/qc"; 
		break;;
		[Nn]* ) exit;;
	    esac
	done
	echo
	echo FastQC results can be found in "$PROJECTS_DIR/$varname/output/qc"
	echo
}
fastqc

cd "$PROJECTS_DIR/$varname/raw/$var2"          
for FILE in $(ls "$PROJECTS_DIR/$varname/raw/$var2")
do
echo $FILE >> "$PROJECTS_DIR/$varname/raw/$var2/files.txt";
done

cd "$PROJECTS_DIR/$varname/raw/$var2"
sed -r 's/.{16}$//' files.txt > list.txt #removing _001.fastq.gz
uniq list.txt > samples.txt
echo The list of samples is given below:
cat samples.txt
readarray myarray < samples.txt
rm files.txt
rm list.txt
input="$PROJECTS_DIR/$varname/raw/$var2/samples.txt"

trim()
{
	echo Running trimming
	echo
	echo Enter number of threads
	read thread
	echo Enter threshold for leading
	read leading
	echo Enter threshold for trailing
	read trailing
	echo Enter value for headcrop
	read hc
	echo Enter value for minlen
	read ml

	while read -r sample
	do
	cd "$PROJECTS_DIR/$varname/output/trimmed"
	mkdir "$sample"
	echo Running FastQC for $sample
	echo
	cd "$TRIM_DIR"

java -jar trimmomatic-0.36.jar PE -threads $thread -phred33 \
"$PROJECTS_DIR/$varname/raw/$var2/${sample}_R1_001.fastq.gz" \
"$PROJECTS_DIR/$varname/raw/$var2/${sample}_R2_001.fastq.gz" \
"$PROJECTS_DIR/$varname/output/trimmed/$sample/o${sample}_R1_paired.fastq.gz" \
"$PROJECTS_DIR/$varname/output/trimmed/$sample/o${sample}_R1_unpaired.fastq.gz" \
"$PROJECTS_DIR/$varname/output/trimmed/$sample/o${sample}_R2_paired.fastq.gz" \
"$PROJECTS_DIR/$varname/output/trimmed/$sample/o${sample}_R2_unpaired.fastq.gz" \
ILLUMINACLIP:TruSeq3-PE.fa:2:30:10:keepBothReads \
LEADING:$leading TRAILING:$trailing HEADCROP:$hc MINLEN:$ml;
	done < "$input"
	echo
	echo Trimming results can be found in "$PROJECTS_DIR/$varname/output/trimmed"
}
trim

qc_trim()
{
	echo Do you want to proceed with FastQC for trimmed files?
	read yn

	while read -r sample
	do
	cd "$PROJECTS_DIR/$varname/output/qc_trim"
	mkdir "$sample"
	echo
	echo Running FastQC for trimmed $sample
	echo

	cd "$FASTQC_DIR"
	./fastqc -t 24 "$PROJECTS_DIR/$varname/output/trimmed/$sample"/*.gz -o "$PROJECTS_DIR/$varname/output/qc_trim/$sample";

	done < "$input"

	echo
	echo FastQC results can be found in "$PROJECTS_DIR/$varname/output/qc_trim"
	echo
}
qc_trim

align()
{
	echo Do you want to proceed with alignment?
	read yn
	echo
	echo Running alignment

	while read -r sample
	do
	cd "$PROJECTS_DIR/$varname/output/align"
	mkdir "$sample";
	cd "$PROJECTS_DIR/$varname/output/trimmed/$sample"
	gunzip o${sample}_R1_paired.fastq.gz
	gunzip o${sample}_R2_paired.fastq.gz 
	echo
	echo Running Alignment for $sample
	echo

	cd "$STAR_DIR"
./STAR --runThreadN 4 \
--genomeDir "$GENOME_INDEX" \
--readFilesIn "$PROJECTS_DIR/$varname/output/trimmed/$sample/o${sample}_R1_paired.fastq" \
             "$PROJECTS_DIR/$varname/output/trimmed/$sample/o${sample}_R2_paired.fastq" \
--outFilterIntronMotifs RemoveNoncanonical \
--outFileNamePrefix "$PROJECTS_DIR/$varname/output/align/$sample/$sample" \
--outSAMtype BAM SortedByCoordinate

	done < "$input"
	echo
	echo Alignment results can be found in "$PROJECTS_DIR/$varname/output/align"
	echo
}
align

counts()
{
	echo Do you want to proceed with FastQC for trimmed files?
	read yn

	echo Generating counts
	while read -r sample
	do
featureCounts -T 4 -p -s 0 -a "$GTF_FILE" \
  -o "$PROJECTS_DIR/$varname/output/align/$sample/$sample.txt" \
  "$PROJECTS_DIR/$varname/output/align/$sample"/*.bam;
	echo cleaning
	cut -f1,7 "$PROJECTS_DIR/$varname/output/align/$sample/$sample.txt" > "$PROJECTS_DIR/$varname/output/align/$sample/$sample.Rmatrix.txt"
	cd "$PROJECTS_DIR/$varname/output/align/$sample"

	sed '1,1d' "$sample.Rmatrix.txt" > "$PROJECTS_DIR/$varname/output/counts/$sample.txt"
	done < "$input"
	echo
	echo Counts results can be found in "$PROJECTS_DIR/$varname/output/counts"
	echo
}
counts
