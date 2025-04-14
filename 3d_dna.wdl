version 1.0

workflow run_3d_dna {
  input {
    File draft_assembly_fasta         # GCS path to input contig-level FASTA
    File merged_nodups                # GCS path to Juicer output
    String? output_prefix             # Optional prefix for naming
  }

  call run3DDNA {
    input:
      draft_assembly_fasta = draft_assembly_fasta,
      merged_nodups = merged_nodups,
      output_prefix = output_prefix
  }

  output {
    File scaffolded_assembly = run3DDNA.scaffolded_assembly
    File final_assembly_fasta = run3DDNA.final_assembly_fasta
    File run_log = run3DDNA.run_log
  }
}

task run3DDNA {
  input {
    File draft_assembly_fasta
    File merged_nodups
    String? output_prefix
  }

  command <<<
    set -eux

    # Install dependencies if needed
    apt-get update && apt-get install -y git curl samtools

    # Clone the 3D-DNA pipeline
    git clone https://github.com/aidenlab/3d-dna.git
    cd 3d-dna

    # Copy inputs
    cp ~{draft_assembly_fasta} ./assembly.fasta
    cp ~{merged_nodups} ./merged_nodups.txt

    # Run the 3D-DNA pipeline
    bash run-asm-pipeline.sh \
      ./assembly.fasta \
      ./merged_nodups.txt > ../3d-dna.log 2>&1

    # Move outputs to root so WDL can find them
    cp *final.fasta ../
    cp *FINAL.assembly ../
  >>>

output {
  File final_fasta = "scaffolds_FINAL.fasta"  # Main chrom-level scaffolds
  File final_assembly = "scaffolds_FINAL.assembly"  # Juicebox-compatible assembly
  File sealed_fasta = "scaffolds.final.fasta"  # Input + misjoin correction
  File sealed_assembly = "scaffolds.final.assembly"  # Before gapped map
  
  File? final_hic = "scaffolds_FINAL.hic"  # Only if --build-gapped-map was used
  File? sealed_hic = "scaffolds.final.hic"
  File? polished_hic = "scaffolds.polished.hic"
  File? resolved_hic = "scaffolds.resolved.hic"

  Array[File]? edit_tracks = glob("*.bed")
  Array[File]? scaffold_tracks = glob("*.scaffold_track.txt")
  Array[File]? super_scaffold_tracks = glob("*.superscaf_track.txt")
  Array[File]? annotation_files = glob("*.txt")  # includes edits.for.step.*, mismatches.at.step.*, etc.

  File run_log = "../3d-dna.log"
}

  runtime {
    docker: "leglerl/3d-dna:latest"
    cpu: 16
    memory: "104G"
    disks: "local-disk 50 HDD"
  }
}
