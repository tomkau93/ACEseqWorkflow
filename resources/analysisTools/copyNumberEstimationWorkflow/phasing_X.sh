#!/bin/bash

# Copyright (c) 2017 The ACEseq workflow developers.
# Distributed under the MIT License (license terms are at https://www.github.com/eilslabs/ACEseqWorkflow/LICENSE.txt).

if [[ ${isNoControlWorkflow} == false ]]; then
    source ${TOOL_ANALYZE_BAM_HEADER}
    getRefGenomeAndChrPrefixFromHeader ${FILE_CONTROL_BAM} # Sets CHR_PREFIX and REFERENCE_GENOME
fi

CHR_NAME=X
CHR_NR=${CHR_PREFIX}${CHR_NAME}

#DEFINE FILENAMES
UNPHASED="${FILE_UNPHASED_PRE}${CHR_NAME}.${FILE_VCF_SUF}"
UNPHASED_TWOSAMPLES="${FILE_UNPHASED_PRE}${CHR_NAME}_2samples.${FILE_VCF_SUF}"
PHASED_TWOSAMPLES="${FILE_PHASED_GENOTYPE}${CHR_NAME}_2samples"
tmpphased=${FILENAME_PHASED_GENOTYPES}_tmp #These two files should have 23 as chromosomes name rather than 'X'
tmphaploblocks=${FILENAME_HAPLOBLOCK_GROUPS}_tmp


#check for patient sex and exit if male
if grep -Pv 'female|klinefelter'  "${FILENAME_SEX}"
 then
   echo "Patient $PID is male."
   echo " " >"${FILENAME_HAPLOBLOCK_GROUPS}"
   echo "#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	sample_control_${PID}"  >"${FILENAME_PHASED_GENOTYPES}"
   exit 0
 fi

if [[ ${isNoControlWorkflow} == false ]]
then

        ${SAMTOOLS_BINARY} mpileup ${CNV_MPILEUP_OPTS} -u \
        	    -f "${REFERENCE_GENOME}" \
        	    -r ${CHR_NR} \
        	    "${FILE_CONTROL_BAM}" \
        	    | \
        	    ${BCFTOOLS_BINARY} view ${BCFTOOLS_OPTS} - \
        	    > "${UNPHASED}"
        
        if [[ "$?" != 0 ]]
        then
        	echo "Non zero exit status for mpileup in phasing_X.sh"
        	exit 2
        fi
fi

echo -n > "${UNPHASED_TWOSAMPLES}"
echo -n > "${tmpPhased}"
echo -n > "${tmpHaploblocks}"

${PYTHON_BINARY} "${TOOL_BEAGLE_CREATE_FAKE_SAMPLES}" \
    --in_file "${UNPHASED}" \
    --out_file "${UNPHASED_TWOSAMPLES}"

if [[ "$?" != 0 ]]
then
    echo "Non zero exit status while creating 2nd sample in vcf-file in phasing_X.sh" >> /dev/stderr
	exit 2
fi

#create sample_g file
echo "ID_1 ID_2 missing sex" > "${FILE_SAMPLE_G}"
echo "0 0 0 D" >> "${FILE_SAMPLE_G}"
echo "${PID} ${PID} 0 2" >> "${FILE_SAMPLE_G}"

${JAVA_BINARY} \
    -jar ${TOOL_BEAGLE} \
    gt="${UNPHASED_TWOSAMPLES}" \
    ref="${BEAGLE_REFERENCE_FILE_X}" \
    out="${PHASED_TWOSAMPLES}" \
    map="${BEAGLE_GENETIC_MAP_X}" \
    impute=false \
    seed=25041988

if [[ "$?" != 0 ]]
then
    echo "Non zero exit status while phasing with Beagle in phasing_X.sh" >> /dev/stderr
    exit 2
fi

${PYTHON_BINARY} "${TOOL_BEAGLE_EMBED_HAPLOTYPES_VCF}" \
    --hap_file "${PHASED_TWOSAMPLES}.vcf.gz" \
    --vcf_file "${UNPHASED}" \
    --out_file  "${tmpPhased}"


if [[ "$?" != 0 ]]
then
    echo "Non zero exit status while embedding haplotypes in phasing_X.sh" >> /dev/stderr
	exit 2
fi

${PYTHON_BINARY} "${TOOL_GROUP_HAPLOTYPES}" \
	--infile "${tmpphased}" \
	--out "${tmphaploblocks}" \
	--minHT ${minHT}
	
if [[ "$?" != 0 ]]
then
	echo "Non zero exit status while grouping haplotypes in phasing_X.sh"
	exit 2
fi

mv ${tmpphased} ${FILENAME_PHASED_GENOTYPES}
mv ${tmphaploblocks} ${FILENAME_HAPLOBLOCK_GROUPS}