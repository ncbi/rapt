#!/usr/bin/env python3

import sys
import json
import random
import libcloud
from libcloud.compute.types import Provider
from libcloud.compute.providers import get_driver
from libcloud.common.google import ResourceNotFoundError, \
     GoogleBaseError, QuotaExceededError, ResourceExistsError, ResourceInUseError
from libcloud.common.types import LibcloudError
from pprint import pprint

class gcp_control:

    def __init__(self, auth):
        compute_engine = get_driver(Provider.GCE)
        self.project = auth["project_id"]
        self.service_account = auth["client_email"]
        self.driver = compute_engine(self.service_account,
                                     key=auth['private_key'],
                                     project=self.project)

    def list_images(self, filters=[]):
        images = self.driver.list_images(ex_project=self.project)
        images[:] = [ x for x in images if x.name.startswith("rapt") ]
        for f in filters:
            images[:] = [ x for x in images if (f in x.name) ]
        images.sort(key=lambda x: x.name, reverse=True)
        return images

    def list_instances(self):
        pprint(self.driver.list_nodes())

    def get_latest_image(self, branch="release"):
        image = (gcp.list_images(filters=[branch])[0]).name
        return image
            
    def get_metadata(self, name):
        startup_script = open("rapt_startup.py", "r").read()
        metadata = {
            'items': [
                {
                    'key': 'accession',
                    'value': "SAMN13012271-rid8503733"
                },
                {
                    'key': 'input',
                    'value': "gs://rapt_input/SAMN13012271-rid8503733.asnt"
                },
                {
                    'key': 'output',
                    'value' : f"gs://rapt_results/SAMN13012271-rid8503733-{name}.tgz"
                },
                {
                    'key': 'taxid',
                    'value': "440524"
                },
                {
                    'key': 'taxgroup',
                    'value' : "2"
                },
                {
                    'key': 'blast_cache',
                    'value' : "gs://rapt_cache"
                },
                {
                    'key': 'debug',
                    'value': False
                },
                {
                    'key': 'startup-script',
                    'value': startup_script
                }
            ]
        }
        #metadata['items'].pop() # remove startup script for debugging 
        return metadata

    def get_random_zone(self):
        zones = [ zone for zone in self.driver.zone_list if
                      ( zone.name.startswith("us-") or zone.name.startswith("northamerica") ) ]
        #pprint(zones)
        return random.choice(zones)
    
    def launch_image(self,
                     node_name,
                     zone,
                     image_name,
                     machine_type,
                     disk_type,
                     preemptible=True
                    ):
        print(f"Launching a {machine_type} instance based on {image_name}, in zone {zone.name}")

        scopes = [ "https://www.googleapis.com/auth/cloud-platform" ]
        metadata=self.get_metadata(node_name)
        
        try:
            node = self.driver.create_node(node_name,
                                      machine_type,
                                      image_name,
                                      location=zone,
                                      ex_metadata=metadata,
                                      ex_disk_type=disk_type,
                                      ex_on_host_maintenance='TERMINATE',
                                      ex_automatic_restart=False,
                                      ex_preemptible=preemptible,
                                      ex_service_accounts=[{'email': self.service_account,
                                                            'scopes': scopes}])
        except QuotaExceededError:
            return 500, "Quota exceeded", None
        except ResourceExistsError:
            return 500, "Resource exists", None
        except ResourceInUseError:
            return 500, "Resource in use", None
        except GoogleBaseError as error:
            return 500, error["message"], None
        except LibcloudError as error:
            return 500, error["message"] if "message" in error else str(error), None
        return 200, "Success", node
            
            
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <instance_name>")
        sys.exit(0)

    authfile = "rapt_auth.json"
    machine_type = "n1-standard-8"
    disk_type = "pd-standard"

    with open(authfile) as f:
        auth = json.load(f)

    gcp = gcp_control(auth)

    zone = gcp.get_random_zone()
    image_name=gcp.get_latest_image()
    with open('rapt_settings.json') as jf:
        recs = json.load(jf)

    for rec in recs:
        print(rec)
    sys.exit(0)
    r = gcp.launch_image(sys.argv[1], zone, image_name,
                         machine_type, disk_type)
    print(r)
