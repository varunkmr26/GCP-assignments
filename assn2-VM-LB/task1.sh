#!/bin/bash
#Create an instance template
gcloud beta compute --project=pe-training instance-templates create varun-pe-it \
--machine-type=n1-standard-1 \
--network=projects/pe-training/global/networks/default \
--network-tier=PREMIUM \
--service-account=912623308461-compute@developer.gserviceaccount.com \
--image=debian-9-stretch-v20180716 \
--image-project=debian-cloud \
--boot-disk-size=10GB \
--boot-disk-type=pd-standard

#Create an instance group
gcloud compute --project "pe-training" instance-groups managed create "varun-pe-ig" \
--base-instance-name "varun-pe-ig" \
--template "varun-pe-it" \
--size "1" \
--zone "us-east1-b"

#Attach autoscaling to the instance group
gcloud compute --project "pe-training" instance-groups managed set-autoscaling "varun-pe-ig" \
--zone "us-east1-b" \
--cool-down-period "60" \
--max-num-replicas "10" \
--min-num-replicas "1" \
--target-cpu-utilization "0.6"

#Create a healthcheck
gcloud compute --project "pe-training" http-health-checks create "varun-pe-hc" \
--port "80" \
--request-path "/" \
--check-interval "5" \
--timeout "5" \
--unhealthy-threshold "2" \
--healthy-threshold "2"

#Create a named port for backend service
gcloud compute --project "pe-training" instance-groups set-named-ports varun-pe-ig \
--named-ports http-port:80 \
--zone us-east1-b

#Create a backend service
gcloud compute --project "pe-training" backend-services create varun-pe-backend \
--http-health-checks varun-pe-hc \
--port-name http-port \
--protocol HTTP \
--global

#Attach backend service to the instance group
gcloud compute --project "pe-training" backend-services add-backend varun-pe-backend \
--instance-group varun-pe-ig \
--balancing-mode RATE \
--max-rate-per-instance 10 \
--instance-group-zone us-east1-b \
--global

#Create a static IP address
gcloud compute addresses create varun-pe-address --global --ip-version IPV4

#Creating a URL Map/Load Balancer
gcloud compute url-maps create varun-pe-lb \
--default-service "varun-pe-backend"

#creating target proxies
gcloud compute target-http-proxies create varun-http-proxy \
--url-map varun-pe-lb

#now we need to attach an external IP to our load balancer
gcloud compute forwarding-rules create cdm-http-cr-rule \
--address varun-pe-address \
--ports 80 \
--target-http-proxy varun-http-proxy \
--global