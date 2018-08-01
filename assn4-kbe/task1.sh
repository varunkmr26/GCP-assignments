#Build a container
gcloud beta container --project "pe-training" clusters create "varun-pe-cluster" \
--zone "us-central1-a" \
--username "admin" \
--cluster-version "1.9.7-gke.3" \
--machine-type "n1-standard-1" \
--image-type "COS" \
--disk-type "pd-standard" \
--disk-size "100" \
--node-labels name=varun,project=training \
--num-nodes "1" \
--network "default" \
--subnetwork "default" \
--enable-autoscaling --min-nodes "1" --max-nodes "3"

#Get credentials to connect to the cluster
gcloud container clusters get-credentials varun-pe-cluster \
--zone us-central1-a \
--project pe-training

#Run a hello world image
kubectl run hello-server --image gcr.io/google-samples/hello-app:1.0 --port 8080

#Deploy the image and expose to port 3000
kubectl expose deployment hello-server --type LoadBalancer --port 3000 --target-port 8080

#Get the details of the server
watch kubectl get service hello-server