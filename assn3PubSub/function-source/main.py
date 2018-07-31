import base64
import json
import os
import googleapiclient.discovery
import subprocess
    
def create_instance(compute, project, zone, name,obj_path):
    image_response = compute.images().getFromFamily(project='debian-cloud', family='debian-8').execute()
    source_disk_image = image_response['selfLink']
    machine_type = "zones/%s/machineTypes/n1-standard-1" % zone
    #make a configuration JSON
    print("inside")
    config_json = {
        "name" : name,
        "machineType" : machine_type,
        "disks" : [
            {
                "boot" : True,
                "autoDelete" : True,
                "initializeParams" : {
                    "sourceImage" : source_disk_image,
                }
            }
        ],
        "networkInterfaces":[{
            "network":"global/networks/default",
              "accessConfigs":[{"type":"ONE_TO_ONE_NAT","name":"External NAT"}]
        }],
          "serviceAccounts" : [{
            "email" : "default",
            "scopes" : [
                'https://www.googleapis.com/auth/devstorage.read_write',
                'https://www.googleapis.com/auth/logging.write'
            ]
        }],
        "metadata" : {
        "items" : [
            {
            "key" : "startup-script",
            "value" : "#!/bin/bash\n gsutil cp %s gs://varun-pe-destination \n" % obj_path
            }]}
    }
    print(" instance created.....")
    return compute.instances().insert(project=project,zone=zone,body=config_json).execute()

def delete_instance(compute, project, zone, name):
    print("deleting....")
    return compute.instances().delete(project=project,zone=zone,instance=name).execute()

def wait_for_operation(compute, project, zone, create_response_name):
    print('Waiting for operation to finish...')
    while True:
        result = compute.zoneOperations().get(project=project,zone=zone,operation=create_response_name).execute()
        if result['status'] == 'DONE':
            return 0
        if 'error' in result:
            raise Exception(result['error'])
            return result
        
def hello_pubsub(event, context):
    """Triggered from a message on a Cloud Pub/Sub topic.
    Args:
         event (dict): Event payload.
         context (google.cloud.functions.Context): Metadata for the event.
    """
    pubsub_message = base64.b64decode(event['data']).decode('utf-8')
    #res_json = event.data
    pubsub_json = json.loads(pubsub_message)
    machine_size = pubsub_json["instance_size"]
    instance_name = pubsub_json["instance_name"]
    obj_path = pubsub_json["object_path"]
    compute = googleapiclient.discovery.build('compute', 'v1') #use gcloud credentials
    project = "pe-training"
    zone = "us-central1-c" #lowa
    create_response = create_instance(compute, project, zone, instance_name,obj_path)
    print("created...")
    wait_for_operation(compute, project, zone, create_response['name'])
    print("Copied")
    delete_instance(compute, project, zone, instance_name)
    print("deleted")