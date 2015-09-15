# Author: Daniel Ortiz Mart\'inez
# *- bash -*

# thot for batch systems

print_desc()
{
    echo "thot_pbs_gen_phr_model written by Daniel Ortiz"
    echo "thot_pbs_gen_phr_model is a parallelized version of phrase model estimation for pbs clusters"
    echo "type \"thot_pbs_gen_phr_model --help\" to get usage information."
}

version()
{
    echo "thot version "${version}
    echo "thot is GNU software written by Daniel Ortiz"
}

usage()
{
    echo "Usage: thot_pbs_gen_phr_model {-pr <int>}"
    echo "                {-g <string> [-pml] [-mon]"
    echo "                [-m <int> [-nospur] [-ms]]"
    echo "                [-c <float]"
    echo "                {-o <string>} [-qs <string>] [-v | -v1 | -va]"
    echo "                [-T <string>] [-sdir <string>] "
    echo "                [-debug] [--help] [--version]"
    echo ""
    echo "-pr <int>                       Number of processors."
    echo ""
    echo "-g <string>                     Name of the alignment file in GIZA format for"
    echo "                                generating a phrase model."
    echo ""
    echo "-pml                            Obtain pseudo-ml model (RF by default)."
    echo ""
    echo "-mon                            Obtain monotone model (non-monotone by default)."
    echo ""
    echo "-m <int>                        Set maximum target phrase length (target is the"
    echo "                                target language of the GIZA alignment file)."
    echo ""
    echo "-nospur                         Do not take into account the spurious words when"
    echo "                                calculating the source phrase length (source is"
    echo "                                the source language of the GIZA alignment file)."
    echo ""
    echo "-ms                             Also impose the maximum phrase-length"
    echo "                                constraint to the source phrase (source is the"
    echo "                                source language of the GIZA alignment file)."
    echo ""
    echo "-c <string>                     Remove from the translation table those pairs"
    echo "                                whose count for the source phrase is lower or"
    echo "                                equal to cutoffValue (source is the source"
    echo "                                language of the GIZA alignment file)."
    echo ""
    echo "-o <string>                     Set output files prefix name."
    echo ""
    echo "-qs <string>                    Specific options to be given to the qsub"
    echo "                                command (example: -qs \"-l pmem=1gb\")."
    echo ""
    echo "-v | -v1 | -va                  Verbose mode | more verbosity | verbose mode in"
    echo "                                Aachen alignment format"	
    echo ""
    echo "-T <string>                     Use <string> for temporaries instead of /tmp"
    echo ""
    echo "-sdir <string>                  Absolute path of a directory common to all"
    echo "                                processors. If not given, \$HOME will be used"
    echo ""
    echo "-debug                          After ending, do not delete temporary files"
    echo "                                (for debugging purposes)"
    echo ""
    echo "--help                          Display this help and exit"
    echo ""
    echo "--version                       Output version information and exit"
    echo ""
}

pipe_fail()
{
    # test if there is at least one command to exit with a non-zero status
    for pipe_status_elem in ${PIPESTATUS[*]}; do 
        if test ${pipe_status_elem} -ne 0; then 
            return 1; 
        fi 
    done
    return 0
}

exclude_readonly_vars()
{
    ${AWK} -F "=" 'BEGIN{
                         readonlyvars["BASHOPTS"]=1
                         readonlyvars["BASH_VERSINFO"]=1
                         readonlyvars["EUID"]=1
                         readonlyvars["PPID"]=1
                         readonlyvars["SHELLOPTS"]=1
                         readonlyvars["UID"]=1
                        }
                        {
                         if(!($1 in readonlyvars)) printf"%s\n",$0
                        }'
}

exclude_bashisms()
{
    $AWK '{if(index($1,"=(")==0) printf"%s\n",$0}'
}

write_functions()
{
    for f in `${AWK} '{if(index($1,"()")!=0) printf"%s\n",$1}' $0`; do
        $SED -n /^$f/,/^}/p $0
    done
}

create_script()
{
    # Init variables
    local name=$1
    local command=$2

    # Write environment variables
    set | exclude_readonly_vars | exclude_bashisms > ${name}

    # Write functions if necessary
    $GREP "()" ${name} -A1 | $GREP "{" > /dev/null || write_functions >> ${name}

    # Write PBS directives
    stream_fname=`${BASENAME} ${name}`
    echo "#PBS -o ${stream_fname}.o\${PBS_JOBID}" >> ${name}
    echo "#PBS -e ${stream_fname}.e\${PBS_JOBID}" >> ${name}
    echo "#$ -cwd" >> ${name}

    # Write command to be executed
    echo "${command}" >> ${name}

    # Give execution permission
    chmod u+x ${name}
}

estimate_frag()
{
    echo "** Processing chunk ${fragm} (started at "`date`")..." >> $SDIR/log
    echo "** Processing chunk ${fragm} (started at "`date`")..." > $SDIR/${fragm}_proc.log

    $bindir/thot_gen_phr_model_mr -g $SDIR/${fragm} ${thot_pars} \
        -o $SDIR/${fragm} -pc -la "$i" -T $tmpdir 2>> $SDIR/${fragm}_proc.log || \
        { echo "Error while executing estimate_frag for $SDIR/${fragm}" >> $SDIR/log ; return 1 ; }

    # Write date to log file
    echo "Processing of chunk ${fragm} finished ("`date`")" >> $SDIR/log

    echo "" > $SDIR/qs_est_${fragm}_end
}

merge_gen_phr()
{
    echo "** Merging counts (started at "`date`")..." >> $SDIR/log
    echo "** Merging counts (started at "`date`")..." > $SDIR/merge.log

    export LC_ALL=""
    export LC_COLLATE=C
    export LC_NUMERIC=C

    # output format = -pc
    $SORT ${SORT_TMP} -t " " ${sortpars} ${mflag} $SDIR/*.ttable | ${bindir}/thot_merge_counts \
        | ${bindir}/thot_cut_ttable -c $cutoff > ${output}.ttable 2>> $SDIR/merge.log || \
        { echo "Error while executing merge_gen_phr" >> $SDIR/log ; return 1 ; }

    if [ "${estimation}" = "PML" ]; then
        cat $SDIR/*.seglentable > $tmpdir/${$}seglentable
        ${bindir}/thot_merge_seglen_counts $tmpdir/${$}seglentable > ${output}.seglentable
        rm $tmpdir/${$}seglentable
    fi
    
    # Write date to log file
    echo "Merging process finished ("`date`")" >> $SDIR/log

    echo "" > $SDIR/merge_gen_phr_end
}

launch()
{
    local file=$1
    ### qsub invocation
    if [ "${QSUB_WORKS}" = "no" ]; then
        $file &
    else
        local jid=$($QSUB ${QSUB_TERSE_OPT} ${qs_opts} $file | ${TAIL} -1)
    fi
    ###################
}

sync()
{
    # Init vars
    local files="$1"

    if [ "${QSUB_WORKS}" = "no" ]; then
        wait
        return 0
    else
        pbs_sync "$files"
    fi
}

pbs_sync()
{
    local files="$1"
    end=0
    while [ $end -ne 1 ]; do
        sleep 3
        end=1
        for f in ${files}; do
            if [ ! -f ${f}_end ]; then
                end=0
                break
            fi
        done
    done
}

pr_given=0
thot_pars=""
g_given=0
o_given=0
m_given=0
estimation="RF"
out_format=""
lex_given=0
qs_given=0
tmpdir="/tmp"
debug=""
sdir=$HOME
cutoff=0

if [ $# -eq 0 ]; then
    print_desc
    exit 1
fi

while [ $# -ne 0 ]; do
    case $1 in
        "--help") usage
            exit 0
            ;;
        "--version") version
            exit 0
            ;;
        "-pr") shift
            if [ $# -ne 0 ]; then
                num_hosts=$1
                pr_given=1
            fi
            ;;
        "-sdir") shift
            if [ $# -ne 0 ]; then
                sdir=$1                
            fi
            ;;
        "-g") shift
            if [ $# -ne 0 ]; then
                a3_file=$1
                g_given=1
            fi
            ;;
        "-mon") thot_pars="$thot_pars -mon"
            ;;
        "-pml") thot_pars="$thot_pars -pml"
            estimation="PML"
            ;;
        "-lex") shift
            lex_given=1
            if [ $# -ne 0 ]; then
                lex_pref=$1
            else
                lex_pref=""
            fi
            ;;
        "-o") shift
            if [ $# -ne 0 ]; then
                output=$1
                o_given=1
            fi
            ;;
        "-m") thot_pars="$thot_pars -m"
            shift
            if [ $# -ne 0 ]; then
                thot_pars="$thot_pars $1"
                m_given=1
            fi
            ;;
        "-c") shift
            if [ $# -ne 0 ]; then
                cutoff=$1
            fi
            ;;
        "-nospur") thot_pars="$thot_pars -nospur"
            ;;
        "-ms") thot_pars="$thot_pars -ms"
            ;;
        "-qs") shift
            if [ $# -ne 0 ]; then
                qs_opts=$1
                qs_given=1
            else
                qs_given=0
            fi
            ;;
        "-debug") debug="-debug"
                  thot_pars="$thot_pars -debug"
            ;;
        "-v") thot_pars="$thot_pars -v"
            ;;
        "-v1") thot_pars="$thot_pars -v1"
            ;;
        "-va") thot_pars="$thot_pars -va"
            ;;
        "-T") shift
            if [ $# -ne 0 ]; then
                tmpdir=$1
            else
                tmpdir="/tmp"
            fi
            thot_pars="$thot_pars -T $tmpdir"
            ;;
    esac
    shift
done

# verify parameters
if [ ${g_given} -eq 1 ]; then
    # verify that -g file exist
    if [ ${g_given} -eq 1 -a  ! -f  "${a3_file}" ];then
        echo "Error: file "$a3_file" does not exist " >&2
        exit 1
    fi
else
    echo "Error: -g parameter not given" >&2
    exit 1
fi

if [ ${o_given} -eq 0 ];then
    echo "Error: -o parameter not given" >&2
    exit 1
fi

if [ ${m_given} -eq 0 ];then
    echo "Error: -m parameter not given" >&2
    exit 1
fi

if [ ${pr_given} -eq 0 ]; then
    # invalid parameters 
    echo "Error: number of processors not given" >&2
    exit 1
fi

# parameters are ok

# create TMP directory
TMP="${tmpdir}/thot_pbs_gen_phr_model_tmp_$$"
mkdir $TMP || { echo "Error: temporary directory cannot be created " >&2 ; exit 1; }

# Set tmp dir of the sort command if possible
if test ${sortT} = "yes"; then
    SORT_TMP="-T ${tmpdir}"
else
    SORT_TMP=""
fi

# create shared directory
SDIR="${sdir}/thot_pbs_gen_phr_model_sdir_$$"
mkdir $SDIR || { echo "Error: shared directory cannot be created" >&2 ; exit 1; }
    
# remove temp directories on exit
if [ "$debug" != "-debug" ]; then
    trap "rm -rf $TMP $SDIR 2>/dev/null" EXIT
fi

# Output info about tracking script progress
echo "NOTE: see file $SDIR/log to track model estimation progress" >&2

# create log file
echo "*** Parallel process started at: " `date` > $SDIR/log
echo "">> $SDIR/log

# process the input

# fragment the input
echo "Spliting input: ${a3_file}..." >> $SDIR/log
input_size=`wc ${a3_file} 2>/dev/null | ${AWK} '{printf"%d",$(1)/3}'`
if [ ${input_size} -eq 0 ]; then
    echo "Error: input file ${a3_file} is empty"
    exit 1
fi

if [ ${input_size} -lt ${num_hosts} ]; then
    echo "Error: problem too small"
    exit 1
fi
frag_size=`expr ${input_size} / ${num_hosts}`
frag_size=`expr ${frag_size} + 1`
nlines=`expr ${frag_size} \* 3`
${SPLIT} -l ${nlines} $a3_file $SDIR/frag\_ || exit 1

# parallel estimation for each fragment
i=1
for f in `ls $SDIR/frag\_*`; do
    fragm=`${BASENAME} $f`

    create_script $SDIR/qs_est_${fragm} estimate_frag 
    launch $SDIR/qs_est_${fragm}

    i=`expr $i + 1`
    qs_est="${qs_est} $SDIR/qs_est_${fragm}"
done

### Check that all queued jobs are finished
sync "${qs_est}"

# merge counts and files
if [ $sortm = "yes" ]; then
    mflag="-m"
fi

create_script $SDIR/merge_gen_phr merge_gen_phr
launch $SDIR/merge_gen_phr
    
### Check that all queued jobs are finished
sync $SDIR/merge_gen_phr


# Copy log file
echo "">> $SDIR/log
echo "*** Parallel process finished at: " `date` >> $SDIR/log
cp $SDIR/log ${output}.genphr_log

# Generate file for error diagnosing
cat $SDIR/*_proc.log $SDIR/merge.log >> ${output}.genphr_err

# Check errors
num_err=`$GREP "Error while executing" ${output}.genphr_log | wc -l`
if [ ${num_err} -gt 0 ]; then
    prog=`$GREP "Error while executing" ${output}.genphr_log | head -1 | $AWK '{printf"%s",$4}'`
    echo "Error during the execution of thot_pbs_gen_phr_model (${prog})" >&2
    echo "File ${output}.genphr_err contains information for error diagnosing" >&2
    exit 1
fi
