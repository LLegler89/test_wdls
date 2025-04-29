version 1.0

workflow juicer_hic_pipeline {
  input {
    Array[File] fastq_files
    File        reference_genome_file
    String      experiment_description = "My Hi-C experiment"
    String      site               = "none"
    Int         Extra_disk_space    = 500
    Int         mem_gb  = 64
    Int         threads = 16
    String      genome_id = "my genome ID"
    String      output_bucket
  }

  call run_juicer {
    input:
      fastq_files           = fastq_files,
      reference_genome_file = reference_genome_file,
      experiment_description= experiment_description,
      site                  = site,
      Extra_disk_space      = Extra_disk_space,
      mem_gb                = mem_gb,
      threads               = threads,
      genome_id             = genome_id,
      output_bucket         = output_bucket
  }

  output {
    Array[File] hic_files     = run_juicer.hic_files
    Array[File] log_files     = run_juicer.log_files
    File        merged_nodups = run_juicer.merged_nodups
  }
}

task run_juicer {
  input {
    Array[File] fastq_files
    File        reference_genome_file
    String      experiment_description
    String      site
    Int         Extra_disk_space
    Int         mem_gb
    Int         threads
    String      genome_id
    String      output_bucket
  }
  Int GB_of_space = ceil(size(fastq_files, "GB") * 5) + Extra_disk_space

  command <<<
    set -euo pipefail

    # Set Java memory options dynamically
    export _JAVA_OPTIONS="-Xmx~{mem_gb}g -Xms~{mem_gb}g"

    # Clone Juicer and setup environment
    git clone https://github.com/theaidenlab/juicer.git juicer
    ln -s juicer/CPU scripts

    cd scripts/common
    wget https://hicfiles.tc4ga.com/public/juicer/juicer_tools.1.9.9_jcuda.0.8.jar
    ln -s juicer_tools.1.9.9_jcuda.0.8.jar juicer_tools.jar
    cd ../..

    mkdir -p references fastq

    # Soft link the FASTQ files into the fastq directory
    for fastq in ~{sep=' ' fastq_files}; do
        ln -s "$fastq" fastq/
    done

    ln -s ~{reference_genome_file} references/

    # Index the reference genome
    bwa index references/$(basename ~{reference_genome_file})

    # Run Juicer
    bash scripts/juicer.sh \
      -D ${PWD} \
      -z references/$(basename ~{reference_genome_file}) \
      -e ~{experiment_description} \
      -p  assembly \
      -s ~{site} \
      -t ~{threads} \
      -g ~{genome_id} \
      -y

  >>>

  output {
    Array[File] hic_files     = glob("*.hic")
    Array[File] log_files     = glob("*.log")
    File        merged_nodups = "aligned/merged_nodups.txt"
  }

  runtime {
    docker: "leglerl/juicydock_v3"
    memory: mem_gb + " GB"
    cpu: 16
    disks: "local-disk " + GB_of_space + " HDD"
  }
}
