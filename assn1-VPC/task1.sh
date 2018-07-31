#!/bin/bash
#Create the VPC
gcloud compute --project=pe-training networks create varun-pe-task1 --mode=auto

#Create the firewall
gcloud compute --project=pe-training firewall-rules create varun-pe-firewall \
--direction=INGRESS \
--priority=1000 \
--network=varun-pe-task-1 \
--action=ALLOW \
--rules=tcp:22 \
--source-ranges=59.152.52.0/22