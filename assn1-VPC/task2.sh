#!/bin/bash

#Part1

#Create a VPC
gcloud compute --project=pe-training networks create varun-pe-task2 --mode=custom

#Create a subnet
gcloud compute --project=pe-training networks subnets create subnet1 \
--network=varun-pe-task2 \
--region=us-east1 \
--range=10.0.1.0/24

#Create another subnet
gcloud compute --project=pe-training networks subnets create subnet2 \
--network=varun-pe-task2 \
--region=us-central1 \
--range=10.0.2.0/24

#Part2

#Create a firewall rule to allow SSH
gcloud compute firewall-rules create demo-vpc-allow-ssh \
--allow tcp:22 \
--network varun-pe-task2

#Create a firewall rule to allow all traffic access within the VPC
gcloud compute firewall-rules create demo-vpc-allow-internal-network \
--allow tcp:1-65535,udp:1-65535,icmp \
--source-ranges 10.0.0.0/16 \
--network varun-pe-task2

#Create a NAT gateway
gcloud compute instances create nat-gateway --network varun-pe-task2 \
	--can-ip-forward \
    --zone us-central1-a \
	--subnet subnet2 \
    --image-family debian-8 \
    --image-project debian-cloud \
    --tags nat-instance \
	--metadata startup-script="sudo sysctl -w net.ipv4.ip_forward=1 \n sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE"

#Create a private instance
gcloud compute instances create example-instance --network varun-pe-task2 \
	--no-address \
    --zone us-east1-b \
    --image-family debian-8 \
    --subnet subnet1 \
    --image-project debian-cloud \
    --tags private-instance \
	
#Create an internet route for private instances to go through the NAT gateway	
gcloud compute routes create varun-pe-private-internet-route --network varun-pe-task2 \
    --destination-range 0.0.0.0/0 \
    --next-hop-instance nat-gateway \
    --next-hop-instance-zone us-central1-a \
    --tags private-instance --priority 800
