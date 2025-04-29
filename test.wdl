version 1.0

workflow juicer_hic_pipeline {
  input {
    String test_text
    String bucket_location
  }

  call run_juicer {
    input:
      test_text = test_text,
      bucket_location = bucket_location
  }

  output {
    Array[File] hic_files        = run_juicer.hic_files
    Array[File] log_files        = run_juicer.log_files
    Array[File] txt_stats        = run_juicer.txt_stats
    Array[File] bam_files        = run_juicer.bam_files
    Array[File] splits_files     = run_juicer.splits_files
    Array[File] intermediate_files = run_juicer.intermediate_files
    File        merged_nodups    = run_juicer.merged_nodups
  }
}

task run_juicer {
  input {
    String test_text
    String bucket_location
  }

  command <<< 
    set -euo pipefail

    echo "Simulating Juicer file structure..."

    mkdir -p aligned splits intermediate
    ls
    # Create fake files in each relevant folder
    echo "~{test_text}" > test.hic
    echo "~{test_text}" > run.log
    echo "~{test_text}" > summary.txt
    echo "~{test_text}" > aligned/test_1.bam
    echo "~{test_text}" > aligned/test_2.bam
    echo "~{test_text}" > aligned/merged_nodups.txt
    echo "~{test_text}" > splits/dummy_split.txt
    echo "~{test_text}" > intermediate/dummy_intermediate.txt

    gsutil cp -r aligned "~{bucket_location}"

  >>>

  output {
    Array[File] hic_files           = glob("*.hic")
    Array[File] log_files           = glob("*.log")
    Array[File] txt_stats           = glob("*.txt")
    Array[File] bam_files           = glob("aligned/*.bam")
    Array[File] splits_files        = glob("splits/*")
    Array[File] intermediate_files  = glob("intermediate/*")
    File        merged_nodups       = "aligned/merged_nodups.txt"
  }

  runtime {
    docker: "leglerl/juicydock_v3"
    memory: "1 GB"
    cpu: 1
  }
}
