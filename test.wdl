 version 1.0
 
 workflow juicer_hic_pipeline {
     input {
            String text = "Hello World"
            String top_dir = "/cromwell_root/test"
     }
 
     call run_juicer {
         input:
            text = text,
            top_dir = top_dir
     }
 
     output {
         Array[File] all_outputs = run_juicer.all_outputs
     }
 }
 
 
 task run_juicer {
     input {
        String text
        String top_dir
     }
 
     command <<<
        mkdir -p {top_dir}/output
        echo "Creating output directory..."
        cd /cromwell_root/test/output
        echo "Creating a copy of the file..."
        echo "Hello World" > copy.txt
        echo "This is a test file." >> copy.txt
        echo "The content of the file is:" >> copy.txt
        cat copy.txt
        cp copy.txt /cromwell_root/test/output/copy2.txt
        cp copy.txt /cromwell_root/test/output/copy3.txt
        echo "The file has been copied to the output directory."
        echo "File created successfully."
    >>>
    output {
        Array[File] all_outputs = glob("/cromwell_root/test/output/*.txt")
    }
    runtime {
        docker: "ubuntu:latest"
        memory: "2 GB"
        cpu: 1
    }
 }