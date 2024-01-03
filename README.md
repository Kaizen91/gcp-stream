# gcp-stream
An ETL project using GCP (Pub/Sub, Cloud Run, and Bigquery)  to stream simulated telemetry data.

## Architecture

This pipeline starts with a pub/sub topic and push subsricption which pushes messages to an application running on a Docker container in cloud run which performs a simple transformation.  A set up like this is good for when you need to stream data, and only perform simple transformations eg data standardization, or deriving a column.  It is not suitable for more complicated transformations involving multiple rows or aggregations.

![Data flow diagram](https://github.com/Kaizen91/gcp-stream/blob/main/images/dataflow-gcp-stream-cloud-run.png)

## Requirements

* Google Cloud Command Line Interface [link](https://cloud.google.com/sdk/docs/install)
* Terraform [link](https://developer.hashicorp.com/terraform/install)
* Set up a free GCP account.  You will need a credit card, but it will not be billed unless you opt into the non free tier. [link](https://cloud.google.com/free?hl=en)


## Set up

* create a project
* enable the cloud run api
* change the variables in config_env.sh to match your project id and region
* run `source config_env.sh` to set environmet variables.
* run `gcloud config set project $GCP_PROJECT`
* run `gcloud config set run/region $GCP_REGION`
* run `cd cloud-run-app` then  `gcloud builds submit --tag gcr.io/$GCP_PROJECT/pubsub` to make the container image from the Dockerfile
* run `cd ..` to return to the working directory
* run `terraform apply` to build the infrastructure
* run `export GCP_TOPIC_ID=<output value of the topic name from terraform>` to set the pub sub topic id (we will use this to send some dummy web events to test our pipeline)

## Simulate Telemetry Data

* run `python venv venv` to create a virtual environment
* run `source venv/bin/activate` to set your python version
* run `pip install -r requirments.txt` to install required packages
* run `simulate_events.py`

## Outcome

* You should now be able to go to Bigquery and see a table that has been populated by telemetry data, with an additional weekday field which has been derived from the datetime of the event.

## Shutdown 

* run `terraform destroy` to destroy the infrastructure
* run `deactivate` to leave the python virtual environment

## Supporting links

* [Documentation on using Cloud Run with Pub/Sub](https://cloud.google.com/run/docs/tutorials/pubsub?skip_cache=true#run_pubsub_server-python)
* [article that inspired this build](https://cloud.google.com/blog/products/data-analytics/building-streaming-data-pipelines)
