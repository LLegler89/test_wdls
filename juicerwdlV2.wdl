version 1.0

workflow juicer_hic_pipeline {
    input {
        String top_dir = "/mnt/disks/local-disk/juicer/project"
        String site = "none"
        String experiment_description = "My Hi-C experiment"
        File chrom_sizes = "gs://your-bucket-name/path/to/chrom_sizes.txt"
        File reference_genome_file = "gs://your-bucket-name/path/to/reference_genome.fa"
        String output_bucket = "gs://your-bucket-name/output/"
        Array [String] fastq_files = ["gs://your-bucket-name/path/to/fastq1.fastq.gz", "gs://your-bucket-name/path/to/fastq2.fastq.gz"]
        Int additional_disk_space_gb = 100
        Int machine_mem_gb = 64
    }

  Int mem_gb        = machine_mem_gb - 1
  Int GB_of_space   = ceil((size(fastq_files, "GB") * 5) + additional_disk_space_gb)

  command <<< 
    set -euo pipefail

    # Clone into the WORKING DIRECTORY (=/cromwell_root)
    git clone https://github.com/theaidenlab/juicer.git juicer_src

    # Make & cd into your project dir (on the big disk)
    mkdir -p ~{top_dir}
    cd       ~{top_dir}

    # Link in the Juicer scripts
    ln -s ../juicer_src/CPU scripts

    # Download tools
    cd scripts/common
    wget https://hicfiles.tc4ga.com/public/juicer/juicer_tools.1.9.9_jcuda.0.8.jar
    ln -s juicer_tools.1.9.9_jcuda.0.8.jar juicer_tools.jar

    # Back to project root
    cd ~{top_dir}

    # Prepare your input dirs
    mkdir -p references fastq output

    # Soft‐link FASTQs
    for fq in ~{sep=' ' fastq_files}; do
      ln -s $fq fastq/
    done

    # Link & index reference
    ln -s ~{reference_genome_file} references/$(basename ~{reference_genome_file})
    bwa index references/$(basename ~{reference_genome_file})

    # Run Juicer
    bash scripts/juicer.sh \
      -z references/$(basename ~{reference_genome_file}) \
      -e ~{experiment_description}                   \
      -p ~{chrom_sizes}                              \
      -s ~{site}

    # Collect outputs
    ln -s ~{top_dir}/aligned aligned
  >>>

  output {
    Array[File] all_outputs = glob("aligned/*")
  }

  runtime {
    docker: "leglerl/juicydock_v2"
    memory: mem_gb + " GB"
    cpu: 16
    disks: "local-disk " + GB_of_space + " HDD"
  }
}
