import json
import datetime
import subprocess
import requests
import yaml
import logging
from urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)

# Global variables
log = logging.getLogger('root')
FORMAT = "[ %(asctime)s %(levelname)s %(funcName)15s() ] %(message)s"
logging.basicConfig(format=FORMAT, level=logging.INFO,
                    datefmt="%Y-%m-%d %H:%M:%S")


class Cluster:
    def __init__(self, watcher, openwhisk):
        self.watcher = watcher
        self.openwhisk = openwhisk


def getAction():
    with open(r'config.yaml') as config:
        config_obj = yaml.load(config, Loader=yaml.FullLoader)
        return(config_obj['function'])


def getClusters():
    with open(r'config.yaml') as config:
        config_obj = yaml.load(config, Loader=yaml.FullLoader)
        return(config_obj['clusters'])


# def getClusters():
#     clusters = subprocess.check_output(
#         "ls ansible/from_remote/",
#         shell=True,
#     ).decode().split()
#     log.info("Clusters: ".format(clusters))
#     return clusters


# def getPods():
#     for cluster in getClusters():
#         pods = subprocess.check_output(
#             "export KUBECONFIG=ansible/from_remote/{}/etc/kubernetes/admin.conf; kubectl get pods".format(
#                 cluster),
#             shell=True,
#         ).decode()
#         print(pods)


def getSmallestAvg():
    action = getAction()
    smallest = 999999999
    cluster = None

    for c in getClusters():
        url = "http://{}?action={}".format(c["watcher"], action)
        resp = requests.get(url)
        data = resp.json()
        if float(data["avg"]) < smallest:
            smallest = float(data["avg"])
            cluster = c

    return cluster


def getPlayload():
    with open(r'config.yaml') as config:
        config_obj = yaml.load(config, Loader=yaml.FullLoader)
        return json.dumps(config_obj['payload'])


def callFunction(cluster, action):
    url = "https://{}:31001/api/v1/namespaces/guest/actions/{}?blocking=true&result=true".format(
        cluster["openwhisk"],
        action)
    headers = {"Authorization": "Basic MjNiYzQ2YjEtNzFmNi00ZWQ1LThjNTQtODE2YWE0ZjhjNTAyOjEyM3pPM3haQ0xyTU42djJCS0sxZFhZRnBYbFBrY2NPRnFtMTJDZEFzTWdSVTRWck5aOWx5R1ZDR3VNREdJd1A=",
               "Content-Type": "application/json"}

    payload = getPlayload()
    resp = requests.post(url,
                         headers=headers,
                         verify=False,
                         data=payload)
    return resp.json()


def main():
    cluster = getSmallestAvg()
    resp = callFunction(cluster, getAction())
    log.info({"Cluster": cluster["name"], "Response": resp})


if __name__ == "__main__":
    main()
