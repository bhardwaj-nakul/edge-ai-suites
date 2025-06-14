 #!/bin/bash

 # Default values
 SCRIPT_DIR=$(dirname $(readlink -f "$0"))
 echo "Script directory: $SCRIPT_DIR"
 PIPELINE="all"  # Default to running all pipelines

 # load environment variables from .env file if it exists
 if [[ -f "$SCRIPT_DIR/.env" ]]; then
     export $(grep -v -E '^\s*#' "$SCRIPT_DIR/.env" | sed -e 's/#.*$//' -e '/^\s*$/d' | xargs)
     echo "Environment variables loaded from $SCRIPT_DIR/.env"     
else
     echo "No .env file found in $SCRIPT_DIR"
     exit 1
 fi

 # check if SAMPLE_APP is set
 if [[ -z "$SAMPLE_APP" ]]; then
     echo "Error: SAMPLE_APP environment variable is not set."
     exit 1
else
    echo "SAMPLE_APP is set to: $SAMPLE_APP"
 fi
 # check if SAMPLE_APP directory exists
 if [[ ! -d "$SAMPLE_APP" ]]; then
     echo "Error: SAMPLE_APP directory $SAMPLE_APP does not exist."
     exit 1
 fi

load_payload() {
    # Load the payload from the specified file
    PAYLOAD_FILE="$SAMPLE_APP/payload.json"
    if [[ -f "$PAYLOAD_FILE" ]]; then
        echo "Loading payload from $PAYLOAD_FILE"
        if command -v jq &> /dev/null; then
            PAYLOAD=$(jq '.' "$PAYLOAD_FILE")
            echo "Payload loaded successfully."
        else
            echo "jq is not installed. Cannot parse JSON payload."
            exit 1
        fi
    else
        echo "No payload file found at $PAYLOAD_FILE"
        exit 1
    fi
}

launch_pipeline() {
    PIPELINE="$1"
    echo "Launching pipeline: $PIPELINE"

}
 

 usage() {
    echo "Usage: $0 [--all] [-p | --pipeline <pipeline_name>] [-h | --help]"
    echo "Options:"
    echo "  --all                           Run all pipelines in the config (Default)"
    echo "  -p, --pipeline <pipeline_name>  Specify the pipeline to run"
    echo "  -h, --help                      Show this help message"
 }


start_pipeline() {
    # check if dlstreamer-pipeline-server is running
    if ! pgrep -x "dlstreamer-pipeline-server" > /dev/null; then
        echo "Error: dlstreamer-pipeline-server is not running. Please start it first."
        # exit 1
    fi
    # no arguments provided, start all pipelines
    if [[ -z "$1" ]]; then
        echo "No pipeline specified. Starting all pipelines..."
        # Here you would add the command to start all pipelines, e.g.:
        # python run_all_pipelines.py
        return
    fi
    
    case "$1" in
        --all)
            echo "Starting all pipelines..."
            # Here you would add the command to start all pipelines, e.g.:
            # python run_all_pipelines.py
            ;;
        -p|--pipeline)
            # Check if the next argument is provided and not empty, and loop through all pipelines and launch them
            shift
            if [[ -z "$1" ]]; then
                echo "Error: --pipeline requires a non-empty argument."
                usage
                exit 1
            fi
            # If the next argument is not an option (doesn't start with - or --), start all the subsquent arg as pipelines
            while [[ $# -gt 0 && "$1" != "--" ]]; do
                if [[ -n "$1" && ! "$1" =~ ^- ]]; then
                    echo "Starting pipeline: $1"
                    launch_pipeline "$1"
                    # Here you would add the command to start the specific pipeline, e.g.:
                    # python run_pipeline.py --pipeline "$1"
                    shift
                else
                    echo "Error: Invalid argument '$1'. Expected a pipeline name."
                    usage
                    exit 1
                fi
            done            
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Starting pipeline: $1"
            # Here you would add the command to start the specific pipeline, e.g.:
            # python run_pipeline.py --pipeline "$1"
            ;;
    esac
}

load_payload
start_pipeline "$@"    
