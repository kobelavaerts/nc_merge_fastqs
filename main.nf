#!/usrb/bin/env nextflow

include { MERGE_FASTQS } from './modules/merge_fastqs/main.nf'
include { CREATE_ARCHIVE } from './modules/create_archive/main.nf'


workflow {
    // input_ch = Channel.fromFilePairs( params.input )
    input_ch = Channel.fromPath( params.input, checkIfExists: true )
    .map { 
        file ->
        def sample_id = file.getName().split(/_S\d+_L00\d|_UMI_S\d+_L00\d/)[0]
        tuple([id: sample_id], file)
    }
    .dump(tag: 'orig input ch')


    only_I1_ch = input_ch
    .filter { meta, fastq ->
        fastq.name ==~ /.*_L00\d_I1_001.*\.fastq\.gz/
    }
    .dump(tag: 'only I1')


    lane_info_ch = only_I1_ch
    .map { meta, fastq ->
        def fname = fastq.name
        def lane = fname.tokenize('_').find { it.startsWith('L00') }
        def new_meta = meta + [lane: lane]
        tuple(new_meta, fastq)
    }
    .dump(tag: 'lane_info')


    grouped_ch = lane_info_ch
    .groupTuple()
    .dump(tag: 'grouped')


    sorted_ch = grouped_ch
    .map { meta, fastq_files ->
        def sorted_files = fastq_files.sort { file -> 
            file.name.contains("UMI") ? 1 : 0
        }
        tuple(meta, sorted_files[0], sorted_files[1])
    }
    .dump(tag: 'sorted')


    prefix_included_ch = sorted_ch
    .map { meta, i1fast1, umifastq ->
        def prefix = i1fast1.name
        def new_meta = meta + [prefix: prefix]
        tuple(new_meta, i1fast1, umifastq)
    }
    .dump(tag: 'prefix_included')

    MERGE_FASTQS( prefix_included_ch )


    no_I1_ch = input_ch
    .filter { meta, fastq ->
        !(fastq.name ==~ /.*_L00\d_I1_001.*\.fastq\.gz/)
    }
    .dump(tag: 'no I1')


    no_I1_combined_with_processed_I1_ch = no_I1_ch
    .flatMap { meta, fastqs -> fastqs}
    .mix( MERGE_FASTQS.out.flatMap { meta, fastqs -> fastqs} )
    .collect()
    .dump(tag: 'no_I1_combined_with_processed_I1')

    create_archive_input_ch = no_I1_combined_with_processed_I1_ch
    .map { fastq_files -> tuple( params.project, fastq_files ) }
    .dump(tag: 'create_archive_input')


    CREATE_ARCHIVE( create_archive_input_ch )

}