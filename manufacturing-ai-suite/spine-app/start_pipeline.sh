 #!/bin/bash

 # Default values
 SCRIPT_DIR=$(dirname $(readlink -f "$0"))
 

 usage() {
    echo "Usage: $0 [--pipeline <pipeline_name>] [--all]"
    echo "Options:"
    echo "  --all                       Run all pipelines in the config (Default)"
    echo "  -p, --pipeline <pipeline_name>  Specify the pipeline to run"
    echo "  -h, --help                  Show this help message"
 }

 # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                PIPELINE="all"
                echo "Running all pipelines in the config"
                shift
                ;;
            -p|--pipeline)
                if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                    PIPELINE="$2"
                    echo "Running pipeline: $PIPELINE"
                    shift 2
                else
                    echo "Error: --pipeline requires a non-empty argument."
                    usage
                    exit 1
                fi
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done