version 1.0

workflow run_3d_dna {
  input {
    File draft_assembly_fasta         # e.g., gs://your-bucket/contigs.fasta
    File merged_nodups                # e.g., gs://your-bucket/merged_nodups.txt
    String output_prefix              # This string (e.g., "rabbit") should match the prefix used by 3D-DNA
  }

  call run3DDNA {
    input:
      draft_assembly_fasta = draft_assembly_fasta,
      merged_nodups = merged_nodups,
      output_prefix = output_prefix
  }

  output {
    # Capture all files with the pattern *FINAL.fasta and *FINAL.assembly in the output directory
    Array[File] final_fasta = run3DDNA.final_fasta
    Array[File] final_assembly = run3DDNA.final_assembly
    File run_log = run3DDNA.run_log
  }
}

task run3DDNA {
  input {
    File draft_assembly_fasta
    File merged_nodups
    String output_prefix
  }

  command <<<
    set -eux

    # Create and enter an output directory for pipeline results.
    mkdir -p output

    # Copy the input files to the local working directory.
    cp ~{draft_assembly_fasta} assembly.fasta
    cp ~{merged_nodups} merged_nodups.txt

    # Clone the 3D-DNA repository (since our Docker does not include it).
    git clone https://github.com/aidenlab/3d-dna.git
    cd 3d-dna

    # Run the full 3D-DNA pipeline; the script will run sealing, merging, and finalizing.
    bash run-asm-pipeline.sh assembly.fasta merged_nodups.txt > ../output/3d-dna.log 2>&1

    # According to the pipeline, after finalizing the output files should be named with the output prefix.
    # For example, if output_prefix is "rabbit", we expect "rabbit.FINAL.fasta" and "rabbit.FINAL.assembly".
    cp ${output_prefix}.FINAL.fasta ../output/ || true
    cp ${output_prefix}.FINAL.assembly ../output/ || true
  >>>

  output {
    # Collect all FASTA files ending with FINAL.fasta from the output directory.
    Array[File] final_fasta = glob("output/*FINAL.fasta")
    # Collect all assembly files ending with FINAL.assembly.
    Array[File] final_assembly = glob("output/*FINAL.assembly")
    File run_log = "output/3d-dna.log"
  }

  runtime {
    docker: "leglerl/3d-dna:latest"
    cpu: 16
    memory: "104G"
    disks: "local-disk 50 HDD"
  }
}
