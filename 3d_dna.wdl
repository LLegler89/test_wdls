version 1.0

workflow run_3d_dna {
  input {
    File draft_assembly_fasta         # e.g., gs://bucket/contigs.fasta
    File merged_nodups                # e.g., gs://bucket/merged_nodups.txt
    String output_prefix = "scaffolds"  # Optional prefix
  }

  call run3DDNA {
    input:
      draft_assembly_fasta = draft_assembly_fasta,
      merged_nodups = merged_nodups,
      output_prefix = output_prefix
  }

  output {
    File final_fasta = run3DDNA.final_fasta
    File final_assembly = run3DDNA.final_assembly
    File sealed_fasta = run3DDNA.sealed_fasta
    File sealed_assembly = run3DDNA.sealed_assembly
    File? final_hic = run3DDNA.final_hic
    File? sealed_hic = run3DDNA.sealed_hic
    Array[File]? scaffold_tracks = run3DDNA.scaffold_tracks
    Array[File]? super_scaffold_tracks = run3DDNA.super_scaffold_tracks
    Array[File]? annotation_files = run3DDNA.annotation_files
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

    # Clone the 3D-DNA GitHub repository
    git clone https://github.com/aidenlab/3d-dna.git
    cd 3d-dna

    # Copy inputs
    cp ~{draft_assembly_fasta} ./input.fasta
    cp ~{merged_nodups} ./merged_nodups.txt

    # Run the pipeline
    bash run-asm-pipeline.sh input.fasta merged_nodups.txt > ../3d-dna.log 2>&1

    # Move outputs up one directory so WDL can find them
    cp *.final.fasta ../
    cp *.FINAL.fasta ../
    cp *.final.assembly ../
    cp *.FINAL.assembly ../
    cp *.final.hic ../ || true
    cp *.FINAL.hic ../ || true
    cp *.scaffold_track.txt ../ || true
    cp *.superscaf_track.txt ../ || true
    cp *.bed ../ || true
    cp *.wig ../ || true
    cp edits.for.step.*.txt ../ || true
    cp mismatches.at.step.*.txt ../ || true
    cp suspect_2D.at.step.*.txt ../ || true
  >>>

  output {
    File final_fasta = "${output_prefix}.FINAL.fasta"
    File final_assembly = "${output_prefix}.FINAL.assembly"
    File sealed_fasta = "${output_prefix}.final.fasta"
    File sealed_assembly = "${output_prefix}.final.assembly"
    File? final_hic = "${output_prefix}.FINAL.hic"
    File? sealed_hic = "${output_prefix}.final.hic"
    Array[File]? scaffold_tracks = glob("*.scaffold_track.txt")
    Array[File]? super_scaffold_tracks = glob("*.superscaf_track.txt")
    Array[File]? annotation_files = glob("*.bed") + glob("*.wig") + glob("edits.for.step.*.txt") + glob("mismatches.at.step.*.txt") + glob("suspect_2D.at.step.*.txt")
    File run_log = "../3d-dna.log"
  }

  runtime {
    docker: "leglerl/3d-dna:latest"
    cpu: 16
    memory: "104G"
    disks: "local-disk 50 HDD"
  }
}
