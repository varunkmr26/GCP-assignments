#!/bin/bash

#Create a bucket
gsutil mb gs://varun-pe-bucket

#Set a lifecyle rule
gsutil lifecycle set rule.json gs://varun-pe-bucket

#Display the lifecycle rule
gsutil lifecycle get gs://varun-pe-bucket