version 1.0

workflow juicer_hic_pipeline {
    input {
        String genome_id = "hg19"
        String top_dir = "/path/to/topDir"
        String queue = "short"
        String long_queue = "long"
        String site = "none" # Set site to "none" for datasets without restriction sites
        String experiment_description = "My Hi-C experiment"
        String stage = "chimeric"
        File chrom_sizes = "gs://your-bucket-name/path/to/chrom_sizes.txt"
        File reference_genome_file = "gs://your-bucket-name/path/to/reference_genome.fa"
        Int chunk_size = 90000000
        String juicer_scripts_directory = "/opt/juicer/scripts" # Updated path
        String juicer_tools = "/opt/juicer/scripts/common/juicer_tools.jar" # Added juicer_tools path
        String queue_time_limit = "1200"
        String long_queue_time_limit = "3600"
        Boolean include_fragments = false
        Boolean early_exit = false
        String R_end = ""
        String output_bucket = "gs://your-bucket-name/output/" # Specify Google bucket for outputs
    }

    call generate_bwa_index {
        input:
            reference_genome_file = reference_genome_file
    }

    call run_juicer {
        input:
            genome_id = genome_id,
            top_dir = top_dir,
            queue = queue,
            long_queue = long_queue,
            site = site,
            experiment_description = experiment_description,
            stage = stage,
            chrom_sizes = chrom_sizes,
            restriction_site_file = "null", # No restriction site file provided
            reference_genome_file = reference_genome_file,
            chunk_size = chunk_size,
            juicer_scripts_directory = juicer_scripts_directory,
            juicer_tools = juicer_tools, # Pass juicer_tools path
            queue_time_limit = queue_time_limit,
            long_queue_time_limit = long_queue_time_limit,
            include_fragments = include_fragments,
            early_exit = early_exit,
            R_end = R_end,
            output_bucket = output_bucket
    }
}

task generate_bwa_index {
    input {
        File reference_genome_file
    }
    command <<< 
        set -euo pipefail
        bwa index ~{reference_genome_file}
    >>>
    output {
        Array[File] bwa_index_files = glob("~{basename(reference_genome_file)}.*") # Capture all BWA index files
    }
    runtime {
        docker: "rnakato/juicer" # Match Docker image
        memory: "8G"
        cpu: 4
    }
}

task run_juicer {
    input {
        String genome_id
        String top_dir
        String queue
        String long_queue
        String site
        String experiment_description
        String stage
        File chrom_sizes
        File restriction_site_file
        File reference_genome_file
        Int chunk_size
        String juicer_scripts_directory
        String juicer_tools # Added juicer_tools input
        String queue_time_limit
        String long_queue_time_limit
        Boolean include_fragments = false
        Boolean early_exit = false
        String R_end
        String output_bucket # Google bucket for outputs
    }
    command <<< 
        set -euo pipefail
        juicer.sh \
            -g ~{genome_id} \
            -d ~{top_dir} \
            -q ~{queue} \
            -l ~{long_queue} \
            -s ~{site} \
            -a '~{experiment_description}' \
            ~{if R_end != "" then "-R " + R_end else ""} \ # Fixed condition for R_end
            -S ~{stage} \
            -p ~{chrom_sizes} \
            -y ~{restriction_site_file} \
            -z ~{reference_genome_file} \
            -C ~{chunk_size} \
            -D ~{juicer_scripts_directory} \
            -T ~{juicer_tools} \ # Use juicer_tools in the command
            -Q ~{queue_time_limit} \
            -L ~{long_queue_time_limit} \
            ~{if include_fragments then "-f" else ""} \
            ~{if early_exit then "-e" else ""}
        
        # Copy all output files to the specified Google bucket
        gsutil -m cp -r * ~{output_bucket}
    >>>
    output {
        File juicer_log = "juicer.log"
        Array[File] all_outputs = glob("*") # Capture all files in the working directory
    }
    runtime {
        docker: "rnakato/juicer" # Match Docker image
        memory: "16G"
        cpu: 8
        disks: "local-disk 500 HDD"
    }
}