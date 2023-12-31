# gcp-stream
An ETL project using GCP (Pub/Sub, Cloud Run, and Bigquery)  to stream simulated telemetry data.

## Set up

* change the variables in config_env.sh to match your project id and region
* run `source config_env.sh` to set environmet variables.
* run `gcloud config set project $GCP_PROJECT`
* run `gcloud config set run/region $GCP_REGION`
* run `cd cloud-run-app` then  `gcloud builds submit --tag gcr.io/$GCP_PROJECT/pubsub` to make the container image from the Dockerfile
* run `terraform apply` to build the infrastructure
* run `export GCP_TOPIC_ID=<output value of the topic name from terraform>` to set the pub sub topic id (we will use this to send some dummy web events to test our pipeline)
