version 1.0

workflow run_3d_dna {
  input {
    File draft_assembly_fasta         # Input contig-level FASTA (e.g., gs://your-bucket/contigs.fasta)
    File merged_nodups                # Juicer output file (e.g., gs://your-bucket/merged_nodups.txt)
    String output_prefix              # The genome ID or prefix to be used (e.g., "rabbit")
  }

  call run3DDNA {
    input:
      draft_assembly_fasta = draft_assembly_fasta,
      merged_nodups = merged_nodups,
      output_prefix = output_prefix
  }

  output {
    # Capture all FASTA files with either uppercase or lowercase "final"
    Array[File] final_fasta = run3DDNA.final_fasta
    Array[File] final_assembly = run3DDNA.final_assembly
    File scaffolded_assembly = run3DDNA.scaffolded_assembly
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

    # Install dependencies 
    apt-get update && apt-get install -y git curl samtools

    # Create and enter an output directory.
    mkdir -p output

    # Copy input files into working directory.
    cp ~{draft_assembly_fasta} assembly.fasta
    cp ~{merged_nodups} merged_nodups.txt

    # Clone the 3D-DNA GitHub repository.
    git clone https://github.com/aidenlab/3d-dna.git
    cd 3d-dna

    # Run the 3D-DNA pipeline.
    bash run-asm-pipeline.sh assembly.fasta merged_nodups.txt > ../output/3d-dna.log 2>&1

    # Ensure the log file exists (if not, create an empty file) so delocalization does not fail.
    [[ -f ../output/3d-dna.log ]] || touch ../output/3d-dna.log

    # Copy output files into the output folder.
    # According to the 3D-DNA pipeline, final scaffold files are produced with the prefix defined by output_prefix.
    # We try both uppercase and lowercase "final".
    cp ${output_prefix}.FINAL.fasta ../output/ || true
    cp ${output_prefix}.final.fasta ../output/ || true
    cp ${output_prefix}.FINAL.assembly ../output/ || true
    cp ${output_prefix}.final.assembly ../output/ || true

    # Also, if the pipeline creates a scaffolds file (e.g., scaffolds_FINAL.assembly), copy it.
    cp scaffolds_FINAL.assembly ../output/ 2>/dev/null || true
  >>>

  output {
    # Use glob to catch files regardless of whether "FINAL" is uppercase or lowercase.
    Array[File] final_fasta = glob("output/*[Ff]inal.fasta")
    Array[File] final_assembly = glob("output/*[Ff]inal.assembly")
    File scaffolded_assembly = "output/scaffolds_FINAL.assembly"
    File run_log = "output/3d-dna.log"
  }

  runtime {
    docker: "leglerl/3d-dna:latest"
    cpu: 16
    memory: "104G"
    disks: "local-disk 1000 HDD"
  }
}
