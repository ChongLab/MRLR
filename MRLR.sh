#!/usr/bin/bash
#
usage() { echo "Usage: $0 -f <Father_vcf> -m <Mother_vcf> -c <Child_vcf> [-oablrs]" 1>&2; 
	echo "  -f   father vcf file from longranger output" 1>&2;
	echo "  -m   mother vcf file from longranger output" 1>&2;
	echo "  -c   child vcf file from longranger output" 1>&2;
	echo "------------optional--------";
	echo "  -o   output file profix; default='trio'" 1>&2;
	echo "  -a   min arm length (kb); default=20" 1>&2;
	echo "  -b   min supporting barcode; default=4" 1>&2;
	echo "  -l   min block length (kb); default=500" 1>&2;
	echo "  -p   max breakpoint region length(kb); default=100" 1>&2;
	echo "  -s   min SNV number; default=20" 1>&2;
	exit 1; }

while getopts ":f:m:c:o:a:b:l:p:s:" option; do
    case "${option}" in
	f)
            father=`readlink -f ${OPTARG}`
            ;;
        m)
            mother=`readlink -f ${OPTARG}`
            ;;
        c)
            child=`readlink -f ${OPTARG}`
            ;;
        o)
            Sample=${OPTARG}
            ;;
	a)
            a=${OPTARG}
            ;;
	b)
            b=${OPTARG}
            ;;
	l)
            l=${OPTARG}
            ;;
        p)
            p=${OPTARG}
            ;;
        s)
            s=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if  [[ -z "${father}" || -z "${mother}" || -z "${child}" ]] ; then
        usage
fi
if [ -z "${Sample}" ] ; then
        Sample="trio"
fi
if [ -z "${a}" ] ; then
	a=20
fi
if [ -z "${b}" ] ; then
	b=4
fi
if [ -z "${l}" ] ; then
	l=500
fi
if [ -z "${p}" ] ; then
	p=100
fi
if [ -z $s ] ; then
	s=20
fi

if [ -d ${Sample} ]; then
        echo -e "Folder exists; Use a different name\n" && exit 1; else
        mkdir ${Sample} && cd ${Sample}
fi

echo -e "\n\nThis is the pipeline for identification of meiotic recombination events using trio samples of 10x genomics longranger vcf outputs\n\nWe assume the script directory and Bedtools were added in path environment\n\n"
echo "Program starts!"
echo "collect haplotype information"

1st_haplotype.pl $father $mother  $child > 1st_${Sample}_haplo
sort -k1,1 -k2,2n 1st_${Sample}_haplo >1st_${Sample}_haplo_sort
1st_haplotype_mask.pl 1st_${Sample}_haplo_sort >1st_${Sample}_haplo_sort_mask
1st_haplotype_mutation_rm.pl 1st_${Sample}_haplo_sort_mask >1st_${Sample}_haplo_mutation_rm

echo "first round: phase child genome"
1st_haplotype_filter.pl 1st_${Sample}_haplo_mutation_rm >1st_${Sample}_haplo_filter
1st_child_barcode.pl 1st_${Sample}_haplo_filter >1st_${Sample}_C_barcode
perl -lane '$len=$F[2]-$F[1];if($len>=9999){print "$F[0]\t$F[1]\t$F[2]\t$len"}' 1st_${Sample}_C_barcode >1st_${Sample}_C_barcode.10k

1st_haplotype_group_filter.pl 1st_${Sample}_haplo_filter F >1st_${Sample}_F_C_haplo
1st_parent_child_match.pl 1st_${Sample}_F_C_haplo 1st_${Sample}_C_barcode.10k >1st_${Sample}_F_C_match
1st_parent_child_match_split.pl 1st_${Sample}_F_C_match >1st_${Sample}_F_C_match_split
1st_split_sum.pl 1st_${Sample}_F_C_match_split >1st_${Sample}_F_C_split_sum

1st_haplotype_group_filter.pl 1st_${Sample}_haplo_filter M >1st_${Sample}_M_C_haplo
1st_parent_child_match.pl 1st_${Sample}_M_C_haplo 1st_${Sample}_C_barcode.10k >1st_${Sample}_M_C_match
1st_parent_child_match_split.pl 1st_${Sample}_M_C_match >1st_${Sample}_M_C_match_split
1st_split_sum.pl 1st_${Sample}_M_C_match_split >1st_${Sample}_M_C_split_sum

echo "first round: reshuffle child genome"
bedtools window -a 1st_${Sample}_F_C_split_sum -b 1st_${Sample}_M_C_split_sum -w 0 >1st_${Sample}_split_merge
1st_split_merge_sum.pl 1st_${Sample}_split_merge >1st_${Sample}_split_merge_sum
1st_merge_sum_stat.pl 1st_${Sample}_split_merge_sum >1st_${Sample}_split_merge_sum_stat
2nd_haplotype_shuffle.pl 1st_${Sample}_split_merge_sum_stat 1st_${Sample}_haplo_filter >2nd_${Sample}_haplo_shuffle

echo "second round: detect meiotic recombination in father"
1st_haplotype_group_filter.pl 2nd_${Sample}_haplo_shuffle F >2nd_${Sample}_F_C_haplo
2nd_parent_child_phase_block.pl 2nd_${Sample}_F_C_haplo >2nd_${Sample}_F_C_block
perl -lane 'print if $F[3]>10000' 2nd_${Sample}_F_C_block >2nd_${Sample}_F_C_block.10k
2nd_parent_child_match.pl 2nd_${Sample}_F_C_haplo 2nd_${Sample}_F_C_block.10k >2nd_${Sample}_F_C_match
2nd_match_sum.pl 2nd_${Sample}_F_C_match >2nd_${Sample}_F_C_match_sum
2nd_match_sum_stat.pl 2nd_${Sample}_F_C_match_sum >2nd_${Sample}_F_C_match_sum_stat

2nd_HR.pl 2nd_${Sample}_F_C_match_sum_stat >2nd_${Sample}_F_C_HR
2nd_HR_test.pl 2nd_${Sample}_F_C_HR $father >2nd_${Sample}_F_C_HR_test_F
2nd_HR_test.pl 2nd_${Sample}_F_C_HR $child >2nd_${Sample}_F_C_HR_test_C
2nd_test_sum.pl 2nd_${Sample}_F_C_HR_test_F 2nd_${Sample}_F_C_HR_test_C >2nd_${Sample}_F_C_HR_test_sum

echo "second round: detect meiotic recombination in mother"
1st_haplotype_group_filter.pl 2nd_${Sample}_haplo_shuffle M >2nd_${Sample}_M_C_haplo
2nd_parent_child_phase_block.pl 2nd_${Sample}_M_C_haplo >2nd_${Sample}_M_C_block
perl -lane 'print if $F[3]>10000' 2nd_${Sample}_M_C_block >2nd_${Sample}_M_C_block.10k
2nd_parent_child_match.pl 2nd_${Sample}_M_C_haplo 2nd_${Sample}_M_C_block.10k >2nd_${Sample}_M_C_match
2nd_match_sum.pl 2nd_${Sample}_M_C_match >2nd_${Sample}_M_C_match_sum
2nd_match_sum_stat.pl 2nd_${Sample}_M_C_match_sum >2nd_${Sample}_M_C_match_sum_stat

2nd_HR.pl 2nd_${Sample}_M_C_match_sum_stat >2nd_${Sample}_M_C_HR
2nd_HR_test.pl 2nd_${Sample}_M_C_HR $mother >2nd_${Sample}_M_C_HR_test_M
2nd_HR_test.pl 2nd_${Sample}_M_C_HR $child >2nd_${Sample}_M_C_HR_test_C
2nd_test_sum.pl 2nd_${Sample}_M_C_HR_test_M 2nd_${Sample}_M_C_HR_test_C >2nd_${Sample}_M_C_HR_test_sum

2nd_parameter.pl ${a} ${b} ${l} ${p} ${s} 2nd_${Sample}_F_C_HR_test_sum |sort -k1,1 -k2,2n >final_${Sample}_F_C_sum
2nd_parameter.pl ${a} ${b} ${l} ${p} ${s} 2nd_${Sample}_M_C_HR_test_sum |sort -k1,1 -k2,2n >final_${Sample}_M_C_sum
2nd_vcf.pl 2nd_${Sample}_haplo_shuffle > final_${Sample}_child.vcf

mkdir tmp.files |mv 1st* tmp.files | mv 2nd* tmp.files

echo -e "finished\n\n\n"
