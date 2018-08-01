#!/bin/bash

#Create a pub/sub topic
gcloud pubsub topics create varun-pe-topic

#Create and deploy a cloud function
gcloud beta functions deploy varun-pe-cloud-function --region us-central1 \
--runtime python37 \
--trigger-resource varun-pe-topic \
--trigger-event google.pubsub.topic.publish \
--source gs://varun-pe-source/function-source.zip
	
	