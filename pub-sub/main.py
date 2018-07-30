import base64
import json
import argparse
import os
import time
import googleapiclient.discovery
from six.moves import input

#Create a an instance
def createInstance(compute, project, zone, instance_name, sourceBucket, destBucket):
    #Image
    image_response = compute.images().getFromFamily(
        				project='debian-cloud', family='debian-8').execute()
    source_disk_image = image_response['selfLink']

    #Machine Configuration
    machine_type = "zones/%s/machineTypes/n1-standard-1" % zone
    startup_script = "#!/bin/bash\ngsutil cp %s %s \n" % (sourceBucket,destBucket)
    config = {
        'name': instacne_name,
        'machineType': machine_type,
        #BootDisk
        'disks': [
            {
                'boot': True,
                'autoDelete': True,
                'initializeParams': {
                    'sourceImage': source_disk_image,
                }
            }
        ],
        #Network Interfaces
        'networkInterfaces': [{
            'network': 'global/networks/default',
            'accessConfigs': [
                {'type': 'ONE_TO_ONE_NAT', 'name': 'External NAT'}
            ]
        }],
        #Permissions
        'serviceAccounts': [{
            'email': 'default',
            'scopes': [
                'https://www.googleapis.com/auth/devstorage.read_write',
                'https://www.googleapis.com/auth/logging.write'
            ]
        }],
        # Metadata
        'metadata': {
            'items': [{
                # Startup script is automatically executed by the
                # instance upon startup.
                'key': 'startup-script',
                'value': startup_script
            }, {
                'key': 'sourceBucket',
                'value': sourceBucket
            }, {
                'key': 'bucketFrom',
                'value': bucketFrom
            }]
        }
    }
    return compute.instances().insert(
        project=project,
        zone=zone,
        body=config).execute()

#Delete an Instance
def deleteInstance(compute, project, zone, instance_name):
    return compute.instances().delete(
        project=project,
        zone=zone,
		instance=instance_name).execute()

#Wait condition
def wait_for_completion(compute, project, zone, operation):
    print('Waiting for operation to finish...')
    while True:
        result = compute.zoneOperations().get(
            project=project,
            zone=zone,
            operation=operation).execute()

        if result['status'] == 'DONE':
            print("Operation Complete")
            if 'error' in result:
                raise Exception(result['error'])
            return result
       	time.sleep(1)

#Main Function
def hello_pubsub(event, context):
    """Triggered from a message on a Cloud Pub/Sub topic.
    Args:
         event (dict): Event payload.
         context (google.cloud.functions.Context): Metadata for the event.
    """
    pubsub_message = base64.b64decode(event['data']).decode('utf-8')
    #res_json = event.data
    pubsub_json = json.loads(pubsub_message)
    compute = googleapiclient.discovery.build('compute', 'v1')
    project = pubsub_json['project']
    zone = pubsub_json['zone']
    instance_name = pubsub_json['instance_name']
    sourceBucket = pubsub_json['sourceBucket']
    destBucket = pubsub_json['destBucket']
    print('Creating an Instance')
    operation = createInstance(compute, project, zone, instance_name, sourceBucket, destBucket)
    wait_for_completion(compute, project, zone, operation['name'])
    print('The object has been copied')
    operation = deleteInstance(compute, project, zone, instance_name)
    wait_for_completion(compute, project, zone, operation['name'])
    print('The instance is deleted') 
    return "The required object has been copied"