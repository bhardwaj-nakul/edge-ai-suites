 #!/bin/bash
# This script is used to start pipelines in the dlstreamer-pipeline-server
# ------------------------------------------------------------------
	# 1. Check if DLSPS server is reachable- status API
	# 2. Check if payload.json(json array) exists
	# 	a. If yes, loads them as a json array, as pipeline, payloads map
	# 3. Based on argument, start all or pipeline(s)
	# 	a. starting a pipeline
	# 		i. fetch the payload(s) from the loaded pipeline-payload map
    #         ii. call POST command to DLSPS with this payload
# ------------------------------------------------------------------


 # Default values
 SCRIPT_DIR=$(dirname $(readlink -f "$0"))
 echo "Script directory: $SCRIPT_DIR"
 PIPELINE_ROOT="user_defined_pipelines"  # Default root directory for pipelines
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
    echo "Running sample app: $SAMPLE_APP"
 fi
 # check if SAMPLE_APP directory exists
 if [[ ! -d "$SAMPLE_APP" ]]; then
     echo "Error: SAMPLE_APP directory $SAMPLE_APP does not exist."
     exit 1
 fi

load_payload() {
    # Load all pipelines payload
    PAYLOAD_FILE="$SAMPLE_APP/payload.json"
    if [[ -f "$PAYLOAD_FILE" ]]; then
        echo "Loading payload from $PAYLOAD_FILE"
        if command -v jq &> /dev/null; then
            PAYLOAD=$(jq '.' "$PAYLOAD_FILE")
            # find the list of pipelines in the payload
            ALL_PIPELINES_IN_PAYLOAD=$(echo "$PAYLOAD" | jq 'group_by(.pipeline) | map({pipeline: .[0].pipeline, payloads: map(.payload)})')
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

post_payload() {
    local PIPELINE="$1"
    local PAYLOAD="$2"
    # Post the payload to the REST server
    echo "Posting payload to REST server at http://$HOST_IP:$REST_SERVER_PORT/pipelines/$PIPELINE_ROOT/$PIPELINE"
    # Use curl to post the payload
    response=$(curl -s -w "\n%{http_code}" http://$HOST_IP:$REST_SERVER_PORT/pipelines/$PIPELINE_ROOT/$PIPELINE -X POST -H "Content-Type: application/json" -d "$PAYLOAD" )
    
    # Split response and status
    body=$(echo "$response" | sed '$d')
    status=$(echo "$response" | tail -n1)
    if [[ "$status" -ne 200 ]]; then
        echo "Error: Failed to post payload for pipeline '$PIPELINE'. HTTP Status Code: $status"
        echo "Response body: $body"
        exit 1
    else
        echo "Payload for pipeline '$PIPELINE' posted successfully. Response: $body"
    fi
}    
    

fetch_payload_and_post() {
    local PIPELINE="$1"
    # Extract the payload for the specific pipeline
    # echo $ALL_PIPELINES_IN_PAYLOAD
    echo "Extracting payload for pipeline: $PIPELINE"

    # check if there are any payloads for the pipeline
    payload_count=$(echo "$ALL_PIPELINES_IN_PAYLOAD" | jq --arg name "$PIPELINE" '[.[] | select(.pipeline == $name) | .payloads[]] | length')

    if [[ "$payload_count" -eq 0 ]]; then
        echo "No payloads found for pipeline: $PIPELINE"
        exit 1
    else
        echo "Found $payload_count payload(s) for pipeline: $PIPELINE"
        # fetch payloads for the pipeline and run each
        echo "$ALL_PIPELINES_IN_PAYLOAD" | jq -c --arg PIPELINE "$PIPELINE" '.[] | select(.pipeline == $PIPELINE) | .payloads[]' | while read -r payload; do
            # Use jq to format the payload            
            echo "Payload for pipeline '$PIPELINE' $payload"
            post_payload "$PIPELINE" "$payload"
        # Use curl to post the payload
        done
    fi

}

launch_pipeline() {
    PIPELINE="$1"
    echo "Launching pipeline: $PIPELINE"
    fetch_payload_and_post "$PIPELINE"
    

}
 

 usage() {
    echo "Usage: $0 [--all] [-p | --pipeline <pipeline_name>] [-h | --help]"
    echo "Options:"
    echo "  --all                           Run all pipelines in the config (Default)"
    echo "  -p, --pipeline <pipeline_name>  Specify the pipeline to run"
    echo "  -h, --help                      Show this help message"
 }


start_piplines(){
    # no argument-> starts all pipelines from ALL_PIPELINES_IN_PAYLOAD
    # sequence of pipeline(s)-> starts the specified pipeline(s)
    
    # If no arguments are provided, start all pipelines
    if [[ -z "$1" ]]; then
        echo "No pipelines specified. Starting all pipelines..."
        for pipeline in $(echo "$ALL_PIPELINES_IN_PAYLOAD" | jq -r '.[].pipeline'); do
            launch_pipeline "$pipeline"
        done
        return
    fi
    # If the next argument is not an option (doesn't start with - or --), start all the subsquent arg as pipelines
    while [[ $# -gt 0 && "$1" != "--" ]]; do
        if [[ -n "$1" && ! "$1" =~ ^- ]]; then
            echo "Starting pipeline: $1"
            launch_pipeline "$1"
            # check for a id as response from POST curl with a timeout
            shift
        else
            echo "Error: Invalid argument '$1'. Expected a pipeline name."
            usage
            exit 1
        fi
    done  

}

get_status(){
    response=$(curl -s -w "\n%{http_code}" http://$HOST_IP:$REST_SERVER_PORT/pipelines/status)
    # Split response and status
    body=$(echo "$response" | sed '$d')
    status=$(echo "$response" | tail -n1)
    # echo $status
    # Check if the status is 200 OK
    echo "Checking status of dlstreamer-pipeline-server..."
    if [[ "$status" -ne 200 ]]; then
        echo "Error: Failed to get status of dlstreamer-pipeline-server. HTTP Status Code: $status"
        exit 1
    else
        echo "Server reachable. HTTP Status Code: $status"
    fi
}

main() {
    # check if dlstreamer-pipeline-server is running
    get_status
    # load the payload
    load_payload

    # no arguments provided, start all pipelines
    if [[ -z "$1" ]]; then
        echo "No pipeline specified. Starting all pipelines..."
        start_piplines
        return  
    fi
    
    case "$1" in
        --all)
            echo "Starting all pipelines..."
            start_piplines "$@"            
            ;;
        -p|--pipeline)
            # Check if the next argument is provided and not empty, and loop through all pipelines and launch them
            shift
            if [[ -z "$1" ]]; then
                echo "Error: --pipeline requires a non-empty argument."
                usage
                exit 1            
            else
                start_piplines "$@"
            fi            
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: Invalid option '$1'."
            usage
            exit 1
            ;;
    esac
}


main "$@"