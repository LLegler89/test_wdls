version 1.0

 workflow juicer_hic_pipeline {
     input {
         String text = ""
     }
        output {
            File text
        }


    command <<<
        mkdir -p ~/cromwell_root/test/output
        echo "Creating output directory..."
        cd ~/cromwell_root/test/output
        echo "Creating a copy of the file..."
        echo "Hello World" > copy.txt
        echo "This is a test file." >> copy.txt
        echo "The content of the file is:" >> copy.txt
        cat copy.txt
        tt = copy.txt
        echo "File created successfully."
    >>>
    output {
        File text = glob("cromwell_root/test/output/*.txt")[0]
    }
    runtime {
        docker: "ubuntu:latest"
        memory: "2 GB"
        cpu: 1
    }
