 version 1.0
 
 workflow juicer_hic_pipeline {
     input {
            String test_text 
            String top_dir = "/cromwell_root/test"
     }
 
     call run_juicer {
         input:
            test_text = test_text,
            top_dir = top_dir
     }
 
     output {
         Array[File] all_outputs = run_juicer.all_outputs
     }
 }
 
 
 task run_juicer {
     input {
        String test_text
        String top_dir
     }
 
     command <<< 
        mkdir -p ${top_dir}/output
        echo "Creating output directory..."
        cd ${top_dir}/output
        echo "Creating a copy of the file with the provided text..."
        touch copy.txt
        echo "${test_text}" > copy.txt
        echo "This is a test file." >> copy.txt
        echo "The content of the file is:" >> copy.txt
        cat copy.txt
        cp copy.txt copy2.txt
        cp copy.txt copy3.txt
        echo "The file has been copied to the output directory."
        echo "File created successfully."
    >>>
    output {
        Array[File] all_outputs = glob('${top_dir}/output/*')
    }
    runtime {
        docker: "ubuntu:latest"
        memory: "2 GB"
        cpu: 1
    }
 }
