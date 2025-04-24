version 1.0

workflow juicer_hic_pipeline {
  input {
    Array[File] fastq_files
    File        reference_genome_file
    File        chrom_sizes
    String      experiment_description = "My Hi-C experiment"
    String      site               = "none"
    Int         GB_of_space    = 500
    Int         mem_gb  = 64
  }

  call run_juicer {
    input:
      fastq_files           = fastq_files,
      reference_genome_file = reference_genome_file,
      chrom_sizes           = chrom_sizes,
      experiment_description= experiment_description,
      site                  = site,
      Int         GB_of_space = GB_of_space,
      Int         mem_gb = mem_gb
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
    Array[File] fastq_files
    File        reference_genome_file
    File        chrom_sizes
    String      experiment_description
    String      site
    Int         GB_of_space
    Int         mem_gb
  }

  command <<< 
    set -euo pipefail
    # Work in the task’s own call directory:
    git clone https://github.com/theaidenlab/juicer.git juicer
    ln -s juicer/CPU scripts
    cd scripts/common
    wget https://hicfiles.tc4ga.com/public/juicer/juicer_tools.1.9.9_jcuda.0.8.jar
    ln -s juicer_tools.1.9.9_jcuda.0.8.jar juicer_tools.jar
    cd ../..
    
    mkdir -p references fastq
    
    # Soft link the FASTQ files into the fastq directory
    for fastq in ~{sep=' ' fastq_files}; do
        ln -s $fastq fastq/
    done
    
    ln -s ~{reference_genome_file} references/
    bwa index references/$(basename ~{reference_genome_file})
    bash scripts/juicer.sh \
      -D ${PWD} \
      -z references/$(basename ~{reference_genome_file}) \
      -e ~{experiment_description} \
      -p ~{chrom_sizes} \
      -s ~{site} \
      -y
  >>>

  output {
    Array[File] hic_files           = glob("*.hic")
    Array[File] log_files           = glob("*.log")
    Array[File] txt_stats           = glob("*.txt")
    Array[File] bam_files           = glob("aligned/*")
    Array[File] splits_files        = glob("splits/*")
    Array[File] intermediate_files  = glob("intermediate/*")
    File        merged_nodups       = "aligned/merged_nodups.txt"
  }


  runtime {
    docker: "leglerl/juicydock_v3"
    memory: mem_gb + " GB"
    cpu: 16
    disks: "local-disk " + GB_of_space + " HDD"
  }
}
