
## Nextflow vs Galaxy 

<br>

**Workflow Differences**

|             | Galaxy | Nextflow |
| ----------- | ------ | -------- |
| Smallest unit of execution (task)     | Tool       | Process |
| Subworkflows      | Yes       | Yes |
| Conditional execution | Limited | Full |  

<br>

**Supplying Data to Tasks**

|             | Galaxy | Nextflow |
| ----------- | ------ | -------- |
| Dynamic data | Source -> Sink | Channels |
| Hardcoded parameters | Yes | Yes |
| Global parameters | No | Yes |

<br>

Discuss:

- Nextflow Channels vs Source -> Sink
- Nextflow's Global Params Object


<br>

## Downloading a nf-core Workflow

What you see on the nf-core website is just a snapshot of the main functionality of the workflow (and maybe a nice visualisation). 

Documentation lies - we need the actual software which is executed. 

We need to download the nf-core workflow, then look at the structure locally.

Downloading nf-core workflow

```
# install nf-core
pip install --upgrade nf-core

# download specific tool / workflow
nf-core download taxprofiler
```

<br>

## Structure of nf-core Workflows

Once downloaded, let's look at the workflow files. 

Look at the new directory created during download. 

For us, it has this structure: 

```
nf-core-taxprofiler_1.0.1/
├── 1_0_1
└── configs
```

The `1_0_1/` folder holds version 1.0.1 of taxprofiler. 

Look inside this folder to view top-level workflow files and folers.

```
tree -L 1 nf-core-taxprofiler_1.0.1/1_0_1
```

Should print the following:
```
├── CHANGELOG.md             
├── CITATIONS.md            
├── CODE_OF_CONDUCT.md      
├── README.md           
├── LICENSE
├── assets                  
├── bin
├── conf                        # extended inputs for premade run profiles
├── docs
├── lib
├── main.nf                     # main entry point
├── modules                     # nextflow processes (same as galaxy tools)
├── modules.json
├── nextflow.config             # default inputs
├── nextflow_schema.json
├── pyproject.toml
├── subworkflows                # subworkflows used by this workflow
└── workflows                   # main workflow
```

`nextflow.config`
- Contains the default workflow inputs
- Can use these to help test our Galaxy Workflow

`conf/` 
- Contains extra inputs for specific premade run profiles
- nf-core workflows will always have a 'test' profile 
- Can use these to help test our Galaxy Workflow

`subworkflows/` 
- Subworkflows used in main workflow. 
- Will create a galaxy workflow per file in this directory. 

`modules/`
- Stores all nextflow processes
- `nf-core/` processes, and `local/` processes specific to this workflow. 
- nextflow process == galaxy tool 

<br>

## Nextflow Processes 

Each piece of software gets a folder in `modules/`. 

```
modules
├── local
│   ├── kraken2_standard_report.nf
│   ├── krona_cleanup.nf
│   └── samplesheet_check.nf
└── nf-core
    ├── adapterremoval
    ├── bbmap
    ├── bowtie2
    ├── bracken
    ├── cat
    ├── centrifuge
    ├── custom
    ├── diamond
    ├── falco
    ├── fastp
    ├── fastqc
    ├── filtlong
    ├── gunzip
    ├── kaiju
    ├── kraken2
    ├── krakentools
    ├── krakenuniq
    ├── krona
    ├── malt
    ├── megan
    ├── metaphlan3
    ├── minimap2
    ├── motus
    ├── multiqc
    ├── porechop
    ├── prinseqplusplus
    ├── samtools
    ├── taxpasta
    └── untar
```

The actual nextflow processes are files inside these folders, and have the extension `.nf`.

Some folders contain a single nextflow process as a `main.nf` file.<br>
These are generally tools with only a single command / run mode. 

Other folders contain multiple processes in subfolders. <br>
These are generally for software which have multiple different run commands. 

For example, see the tree below: 

```
modules
├── local
│   ├── kraken2_standard_report.nf
│   ├── krona_cleanup.nf
│   └── samplesheet_check.nf
└── nf-core
    ├── adapterremoval
    │   ├── main.nf
    │   └── meta.yml
    ├── bbmap
    │   └── bbduk
    │       ├── main.nf
    │       └── meta.yml
    ├── bowtie2
    │   ├── align
    │   │   ├── main.nf
    │   │   └── meta.yml
    │   └── build
    │       ├── main.nf
    │       └── meta.yml
    ├── bracken
    │   ├── bracken
    │   │   ├── main.nf
    │   │   └── meta.yml
    │   └── combinebrackenoutputs
    │       ├── main.nf
    │       └── meta.yml
    ...
```

In the structure above
- The `adapterremoval` software only has a single .nf process (`main.nf`).
- The `bowtie2` software has two subfolders: 
    - one for `bowtie2-build`
    - one for normal `bowtie2` alignment


<br>


## Checking Tools

First, we need to check whether the Galaxy Server we will run on has all the required tools. 

For each process, we want to check if the Galaxy server has a corresponding tool.

To do this, we need to know:
- The name of the software executed in the process
- The version of that software
- The subcommand if relevant. 

<br>

**Listing all processes**

The first thing to do is list the nextflow processes in the workflow. 

You can use the following bash script to do this:

```
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
```

For nf-core/taxprofiler, there are 45 processes. 

<br>

**Getting software tool names and versions**

For each process, we will need to check the software tool, its version, and the command if relevant. 

The process name usually indicates the software. 

We can get further information in the process definition itself.

We will use the `FASTQC` process as an example. 


```
# modules/nf-core/fastqc/main.nf

process FASTQC {
    ...

    conda "bioconda::fastqc=0.11.9"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastqc:0.11.9--0' :
        'quay.io/biocontainers/fastqc:0.11.9--0' }"

    input:
    ...

    output:
    ...

    script:
    
    ...
    
    """

    ...

    fastqc $args --threads $task.cpus $renamed_files
    
    ...
    
    """
}

```

In the above, some sections have been masked for simplicity. 

We can look at the `conda` and `container` directives (seen at the top) to get more information about the actual software. These both supply information for the software and version required to run this process. 

We can look at the `script:` section to see the actual CLI command which will run.

By reading the example above:
- The software is `fastqc` version `0.11.9`
- The main command is `fastqc`

This is enough information. We are looking for the `FASTQC` Galaxy Tool, and the version should be as close to `0.11.9` as possible. 

On Galaxy Australia, the version doesn't match, but it will be fine.  


<br>

**Repeating the above for all processes**

If doing this properly, we would do the above for each process. 

We would probably make a list of processes which don't have an equivalent tool installed on the Galaxy Server. 

For those that don't, we would first see if they can be ignored (conditional execution). 

For those that are mandatory but not installed on the galaxy server, we could try to find a substitute.  

If no substitute, the workflow cannot be run on the Galaxy server. 

We will continue on here, demonstrating this while focusing on a single subworkflow. 

<br>

## Focusing on a Single Subworkflow 

For this section, we will be looking at `nf-core-taxprofiler_1.0.1/1_0_1/subworkflows/local/longread_preprocessing.nf`

Basic subworkflow structure

```
workflow SUBWORKFLOW_NAME {

    take:           # inputs
    input1

    main:           # tasks to execute
    tool1()
    tool2()
    etc..

    emit:           # outputs
    output1

}
```

For `longread_preprocessing.nf`, this is the structure:

```
workflow LONGREAD_PREPROCESSING {

    take:
    reads
    
    main:
    ch_versions      = Channel.empty()
    ch_multiqc_files = Channel.empty()

    ...

    emit:
    reads    = ch_processed_reads   // channel: [ val(meta), [ reads ] ]
    versions = ch_versions          // channel: [ versions.yml ]
    mqc      = ch_multiqc_files
```

NOTE: Explain the above. 


Process imports are import from the `'modules/'`` directory
```
include { FASTQC as FASTQC_PROCESSED } from '../../modules/nf-core/fastqc/main'
include { FALCO as FALCO_PROCESSED   } from '../../modules/nf-core/falco/main'
include { PORECHOP_PORECHOP          } from '../../modules/nf-core/porechop/porechop/main'
include { FILTLONG                   } from '../../modules/nf-core/filtlong/main'
```

The imports tell you which process / subworkflows are used by this subworkflow. 

We can see that FASTQC, FALCO, PORECHOP, and FILTLONG are used. 

First, check if there are Galaxy tools available for these processes. 

(All except FALCO are available.)

Let's look at how FALCO is used to see if we can do a work-around. 

```
workflow LONGREAD_PREPROCESSING {
    ...

    if (params.preprocessing_qc_tool == 'fastqc') {
        FASTQC_PROCESSED ( ch_processed_reads )
        ch_versions = ch_versions.mix( FASTQC_PROCESSED.out.versions )
        ch_multiqc_files = ch_multiqc_files.mix( FASTQC_PROCESSED.out.zip )

    } else if (params.preprocessing_qc_tool == 'falco') {
        FALCO_PROCESSED ( ch_processed_reads )
        ch_versions = ch_versions.mix( FALCO_PROCESSED.out.versions )
        ch_multiqc_files = ch_multiqc_files.mix( FALCO_PROCESSED.out.txt )
    }
    
    ...
```

Nextflow has conditional execution. 

A common pattern is:

```
if (condition) {

} else if (condition) {

} else {

}

```

We see that the global `params.preprocessing_qc_tool` variable  controls whether to use FASTQC or FALCO for read QC. 

Galaxy has FASTQC installed, so we can just use this instead. 


<br>

## Designing our Subworkflow in Galaxy 

From the section above, we know our subworkflow has the following: 

- Inputs: reads [fastq]
- Tools: Filtlong, FastQC, Porechop
- Outputs: reads [fastq], multiqc report [zipfile]

<br>

Create a new Galaxy Workflow in the workflow editor. 

1. Create a new Galaxy Workflow called `"nfcore_taxprofiler_longread_preprocessing"`
2. Add an input dataset for the reads. 
3. Add all tools to the workflow. 

<br>

Now we have the basic entities, we need to know the order of execution. 

Open `nf-core-taxprofiler_1.0.1/1_0_1/subworkflows/local/longread_preprocessing.nf`. 

Explain the conditional logic. 

Below is the stripped down subworkflow with the route we can take. 

```
workflow LONGREAD_PREPROCESSING {
    take:
    reads

main:
    ch_versions      = Channel.empty()
    ch_multiqc_files = Channel.empty()

    ...

    PORECHOP_PORECHOP ( reads )
    ch_clipped_reads = PORECHOP_PORECHOP.out.reads
        .map { meta, reads -> [ meta + [single_end: 1], reads ] }

    ch_processed_reads = FILTLONG ( ch_clipped_reads.map { meta, reads -> [ meta, [], reads ] } ).reads

    ch_versions = ch_versions.mix(PORECHOP_PORECHOP.out.versions.first())
    ch_versions = ch_versions.mix(FILTLONG.out.versions.first())
    ch_multiqc_files = ch_multiqc_files.mix( PORECHOP_PORECHOP.out.log )
    ch_multiqc_files = ch_multiqc_files.mix( FILTLONG.out.log )

    FASTQC_PROCESSED ( ch_processed_reads )
    ch_versions = ch_versions.mix( FASTQC_PROCESSED.out.versions )
    ch_multiqc_files = ch_multiqc_files.mix( FASTQC_PROCESSED.out.zip )

    emit:
    reads    = ch_processed_reads   // channel: [ val(meta), [ reads ] ]
    versions = ch_versions          // channel: [ versions.yml ]
    mqc      = ch_multiqc_files
}

```

Explain how a process is called. 
- `PORECHOP_PORECHOP ( reads )`

<br>

> NOTE:
> 
> nf-core modules generally have both a `main.nf` and `meta.yml` file.
> 
> - The `main.nf` is the process definition. 
> - The `meta.yml` describes the software, description, inputs and output of the process.  
> 
> `meta.yml` can be very helpful to tell us the inputs and outputs of a process. 
> 
> Open `nf-core-taxprofiler_1.0.1/1_0_1/modules/nf-core/fastqc/meta.yml` to view this information. 

<br>

Explain the connections. 
- `FILTLONG.out`

Explain the channels. 
-  `FASTQC_PROCESSED ( ch_processed_reads )`
- `ch_versions`
- `ch_multiqc_files`

Explain `.mix()`
- https://training.nextflow.io/basic_training/operators/

<br>

Order is `PORECHOP_PORECHOP -> FILTLONG -> FASTQC`

(`FASTQC` aliased to `FASTQC_PROCESSED`)

<br>

## Testing our Galaxy Subworkflow

Show how to trace the test data back to params. 











