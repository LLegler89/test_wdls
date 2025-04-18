version 1.0
 
 workflow juicer_hic_pipeline {
     input {
         String top_dir = "/mnt/disks/local-disk/juicer/project"
         String site = "none"
         String experiment_description = "My Hi-C experiment"
         File chrom_sizes = "gs://your-bucket-name/path/to/chrom_sizes.txt"
         File reference_genome_file = "gs://your-bucket-name/path/to/reference_genome.fa"
         String output_bucket = "gs://your-bucket-name/output/"
         Array [File] fastq_files = ["gs://your-bucket-name/path/to/fastq1.fastq.gz", "gs://your-bucket-name/path/to/fastq2.fastq.gz"]
         Int additional_disk_space_gb = 100
         Int machine_mem_gb = 64
     }
 
     call run_juicer {
         input:
             top_dir = top_dir,
             site = site,
             experiment_description = experiment_description,
             chrom_sizes = chrom_sizes,
             reference_genome_file = reference_genome_file,
             output_bucket = output_bucket,
             fastq_files = fastq_files,
             additional_disk_space_gb = additional_disk_space_gb,
             machine_mem_gb = machine_mem_gb
     }
 
     output {
         Array[File] all_outputs = run_juicer.all_outputs
     }
 }
 
 
 task run_juicer {
     input {
         String top_dir
         String experiment_description
         File chrom_sizes
         File reference_genome_file
         String output_bucket
         Array[File] fastq_files
         String site = "none"
         Int additional_disk_space_gb
         Int machine_mem_gb
     }
 
     Int mem_gb = machine_mem_gb -1
     Int GB_of_space = ceil((size(fastq_files,"GB") * 5) + additional_disk_space_gb)
 
     command <<<
         set -euo pipefail
 
         # Clone the Juicer repository
         git clone https://github.com/theaidenlab/juicer.git ~/juicer
 
         # Create and move into project directory
         mkdir -p ~{top_dir}
         cd ~{top_dir}
 
         ln -s ~/juicer/CPU scripts
         cd scripts/common
         wget https://hicfiles.tc4ga.com/public/juicer/juicer_tools.1.9.9_jcuda.0.8.jar
         ln -s juicer_tools.1.9.9_jcuda.0.8.jar juicer_tools.jar
         cd ~{top_dir}
 
         # Create required directories for reference and fastq files
         mkdir -p ~{top_dir}/references
         mkdir -p ~{top_dir}/fastq
         mkdir -p ~/output
         # Soft link the FASTQ files into the fastq directory
         for fastq in ~{sep=' ' fastq_files}; do
             ln -s $fastq fastq/
         done
 
         # Copy reference genome and build index
         ln -s ~{reference_genome_file} references
         bwa index references/$(basename ~{reference_genome_file})
 
         # Run the Juicer pipeline
         bash ~{top_dir}/scripts/juicer.sh \
             -z references/$(basename ~{reference_genome_file}) \
             -e ~{experiment_description} \
             -p ~{chrom_sizes} \
             -s ~{site}
 
         
         ln -s ~{top_dir}/aligned ~/aligned
     >>>
     output {
         Array[File] all_outputs = glob("/opt/juicer/project/aligned/*") # Use relative path
         Array[File] all_outputs = glob("aligned/*") # Use relative path
     }
 
     runtime {
         docker: "leglerl/juicydock_v2"
         memory: mem_gb + " GB"
         cpu: 16
         disks: "local-disk " + GB_of_space + " HDD"
     }
