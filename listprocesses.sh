
DIRECTORY="nf-core-taxprofiler_1.0.1/1_0_1/modules"
PROCESSES=()

for f in $(find $DIRECTORY -name '*.nf')
do 
    pname=$(head -n1 $f | grep -oP '(?<=process )([a-zA-Z0-9]+[_a-zA-Z0-9]*)' || echo $f)
    PROCESSES+=($pname)
done

SORTED=($(printf '%s\n' "${PROCESSES[@]}"|sort))
NUM_PROCESSES=${#SORTED[@]}
echo "Number of processes: $NUM_PROCESSES"
for (( i=0; i<${NUM_PROCESSES}; i++ ))
do 
    echo "- ${SORTED[$i]}"
done


