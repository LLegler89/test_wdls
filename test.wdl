version 1.2

workflow juicer_hic_pipeline {
  input {
    String test_text
  }

  call run_juicer {
    input:
      test_text = test_text
  }

  output {
    Array[File] hic_files        = glob("*.hic")
    Array[File] log_files        = glob("*.log")
    Array[File] txt_stats        = glob("*.txt")
    Array[File] bam_files        = glob("aligned/*.bam")
    Directory splits_dir         = "splits"
    Directory intermediate_dir   = "intermediate"
    Directory aligned_dir        = "aligned"
    File      merged_nodups      = "aligned/merged_nodups.txt"
  }
}

task run_juicer {
  input {
    String test_text
  }

  command <<< 
    set -euo pipefail

    echo "Simulating Juicer file structure..."

    mkdir -p aligned splits intermediate

    # Create fake files in each relevant folder
    echo "${test_text}" > test.hic
    echo "${test_text}" > run.log
    echo "${test_text}" > summary.txt
    echo "${test_text}" > aligned/test_1.bam
    echo "${test_text}" > aligned/test_2.bam
    echo "${test_text}" > aligned/merged_nodups.txt
    echo "${test_text}" > splits/dummy_split.txt
    echo "${test_text}" > intermediate/dummy_intermediate.txt
  >>>

  output {
    Array[File] hic_files        = glob("*.hic")
    Array[File] log_files        = glob("*.log")
    Array[File] txt_stats        = glob("*.txt")
    Array[File] bam_files        = glob("aligned/*.bam")
    Directory splits_dir         = "splits"
    Directory intermediate_dir   = "intermediate"
    Directory aligned_dir        = "aligned"
    File      merged_nodups      = "aligned/merged_nodups.txt"
  }

  runtime {
    docker: "ubuntu:latest"
    memory: "1 GB"
    cpu: 1
  }
}
