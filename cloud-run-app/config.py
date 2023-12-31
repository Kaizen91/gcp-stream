import os

project_id = os.environ["GCP_PROJECT"]
location = os.environ["GCP_REGION"]
bq_dataset = 'ecommerce_sink'
bq_table = 'cloud_run'
