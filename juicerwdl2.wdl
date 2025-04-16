version 1.0

workflow juicer_hic_pipeline {
    input {
        String top_dir = "/opt/juicer/project"
        String site = "none"
        String experiment_description = "My Hi-C experiment"
        File chrom_sizes = "gs://your-bucket-name/path/to/chrom_sizes.txt"
        File reference_genome_file = "gs://your-bucket-name/path/to/reference_genome.fa"
        String output_bucket = "gs://your-bucket-name/output/"
        Array[File] fastq_files
    }

    call run_juicer {
        input:
            top_dir = top_dir,
            site = site,
            experiment_description = experiment_description,
            chrom_sizes = chrom_sizes,
            reference_genome_file = reference_genome_file,
            output_bucket = output_bucket,
            fastq_files = fastq_files
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
    }
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
        # Copy FASTQ files into the fastq directory
        for fastq in ~{sep=' ' fastq_files}; do
            mv $fastq ~{top_dir}/fastq/
        done

        # Copy reference genome and build index
        mv ~{reference_genome_file} ~{top_dir}/references/
        bwa index references/$(basename ~{reference_genome_file})

        # Run the Juicer pipeline
        bash ~{top_dir}/scripts/juicer.sh \
            -z references/$(basename ~{reference_genome_file}) \
            -e ~{experiment_description} \
            -p ~{chrom_sizes} \
            -s ~{site}

        # Validate that the aligned directory exists and contains files
        if [ -d "aligned" ] && [ "$(ls -A aligned)" ]; then
            gsutil -m cp -r ~{top_dir}/aligned ~{output_bucket}
            cp -r ~{top_dir}/aligned/* ~/output/
        else
            echo "Aligned directory is missing or empty. Aborting."
            exit 1
        fi
    >>>
    output {
        Array[File] all_outputs = glob("output/*") # Use relative path
    }
    runtime {
        docker: "rnakato/juicer"
        memory: "64G"
        cpu: 16
        disks: "local-disk 2000 HDD"
    }
}
