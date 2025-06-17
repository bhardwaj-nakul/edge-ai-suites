# Industrial Edge Insights Vision
Industrial Edge Insights Vision is a template for users to be able to create sample applications intended for industrial use cases in the edge.
Users can refer to one of many sample built from the template as a reference.

You only need to update the install.sh to get the required artifcats downloaded, add configuration for the dlstreamer pipeline server and then provide the payload to launch pipelines.

## Get Started
### Directory structure

    application_name/
        configs/
            pipeline-server.json
        resources/
            models/
            videos/
        payload.json
        docker-compose.yml
    
    .env_app_name
    sample_list.sh
    sample_start.sh
    sample_status.sh
    sample_stop.sh

 - **configs**: directory containing dlstreamer pipeline server configuration files. To learn about it click here.

 - **resources**: directory containing artificacts such as models, videos etc. It can be populated by install script. Users can modify it as per their usecase requriements.

 - **payload.json**: A JSON array file containing one or more pipeline requests. Each JSON inside the array has two keys- `pipeline` and `payload` that refers to the pipeline it belongs to and the payload used to launch an instance of the pipeline. To learn more click here. 

 - **docker-compose.yml**: A generic, parameterized compose file that can launch a particular sample application defined in the environment variable `SAMPLE_APP`.

 - **.env_app_name**: Environment file containing application specific variables. Before starting the application, Users should rename it to `.env` for compose file to source it automatically.

 ### Script description
 
 | Shell Command         | Description                              | Parameters                    |
|-----------------------|----------------------------------------|-------------------------------|
| `./sample_start.sh`    | Runs all or specific pipeline from the config.json. <br> Optionally, run copies of payload (default 1)| `--all` (default) <br> `--pipeline` or `-p` <br> `--payload-copies` or `-n` |
| `./sample_stop.sh`     | Stops all/specific instance by id      | `--all` (default) <br> `--id` or `-i` |
| `./sample_list.sh`     | List loaded pipelines                   | *(none)*                      |
| `./sample_status.sh –i 89ab898e090a90b0c897d3ea7` | Get pipeline status of all/specific instance | `--all` (default) <br> `--id` or `-i`    |

## Sample Applications

Using the template above, several industrial recipies have been provided for users.
* Pallet Defect Detection
* Weld Porosity
* Anomaly Detection