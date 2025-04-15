workflow run_asm_pipeline {
    input {
        String input_fasta_gs  // Google bucket path for input_fasta
        String input_mnd_gs    // Google bucket path for input_mnd
        String mode = "haploid"
        Int input_size = 15000
        Int rounds = 2
        String stage = ""
        Boolean early_exit = false
        Boolean fast_start = false
        Boolean sort_output = false
        Boolean build_gapped_map = false
    }

    call run_pipeline {
        input:
            input_fasta_gs = input_fasta_gs,
            input_mnd_gs = input_mnd_gs,
            mode = mode,
            input_size = input_size,
            rounds = rounds,
            stage = stage,
            early_exit = early_exit,
            fast_start = fast_start,
            sort_output = sort_output,
            build_gapped_map = build_gapped_map
    }

    output {
        File final_fasta = run_pipeline.final_fasta
        File final_assembly = run_pipeline.final_assembly
        File final_hic = run_pipeline.final_hic
    }
}

task run_pipeline {
    input {
        String input_fasta_gs
        String input_mnd_gs
        String mode
        Int input_size
        Int rounds
        String stage
        Boolean early_exit
        Boolean fast_start
        Boolean sort_output
        Boolean build_gapped_map
    }

    command {
        set -e

        # Pull input files from Google bucket
        echo "Downloading input files from Google bucket..."
        gsutil cp ${input_fasta_gs} input.fasta
        gsutil cp ${input_mnd_gs} input.mnd
        # Install dependencies
        apt-get update && apt-get install -y git curl samtools
        # Clone the 3D-DNA pipeline repository
        echo "Cloning 3D-DNA pipeline repository..."
        git clone https://github.com/aidenlab/3d-dna.git

        # Run the pipeline
        echo "Running the pipeline..."
        bash 3d-dna/run-asm-pipeline.sh \
            --mode ${mode} \
            --input ${input_size} \
            --rounds ${rounds} \
            --stage ${stage} \
            ${if early_exit then "-e" else ""} \
            ${if fast_start then "-f" else ""} \
            ${if sort_output then "--sort-output" else ""} \
            ${if build_gapped_map then "--build-gapped-map" else ""} \
            input.fasta input.mnd
    }

    output {
        File final_fasta = "final.fasta"
        File final_assembly = "final.assembly"
        File final_hic = "final.hic"
    }

    runtime {
        docker: "leglerl/3d-dna:latest"
        memory: "104G"
        cpu: 16
        disks: "local-disk 500 SSD"
    }
}