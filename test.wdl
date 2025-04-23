version 1.0

 workflow juicer_hic_pipeline {
     input {
         String text = ""
     }
        output {
            File copy.txt = text
        }


    command <<<
        mkdir -p ~/cromwell_root/output
        cd output
        echo "Creating a copy of the file..."
        echo "Hello World" > copy.txt
        echo "This is a test file." >> copy.txt
        echo "The content of the file is:" >> copy.txt
        cat copy.txt
    >>>
    output {
        File copy.txt = "output/copy.txt"
    }
    runtime {
        docker: "ubuntu:latest"
        memory: "2 GB"
        cpu: 1
    }
