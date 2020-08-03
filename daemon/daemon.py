import json
import datetime
import subprocess
import requests
import os
import logging
import threading
import time
from urllib.parse import urlparse
from http.server import BaseHTTPRequestHandler, HTTPServer
from kubernetes import client, config
from urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)


class Function:
    def __init__(self, name, avg):
        self.name = name
        self.avg = avg

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__,
                          sort_keys=True, indent=4)


# Global variables
log = logging.getLogger('root')
FORMAT = "[ %(asctime)s %(levelname)s %(funcName)15s() ] %(message)s"
logging.basicConfig(format=FORMAT,
                    level=logging.INFO,
                    datefmt="%Y-%m-%d %H:%M:%S")
functions = []


class Server(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()

        query = urlparse(self.path).query
        if query:
            query_components = dict(qc.split("=") for qc in query.split("&"))
            action = query_components["action"]

            if action:
                for f in functions:
                    if f.name == action:
                        self.wfile.write(f.toJSON().encode())
                        break
                else:
                    self.send_error(
                        404, "Function: {} not found".format(action))
                return

        self.wfile.write(json.dumps([f.__dict__ for f in functions]).encode())


def getFunctionNames():
    url = "https://{}:31001/api/v1/namespaces/guest/actions".format(
        os.environ['SERVER_IP'])
    headers = {"Authorization": "Basic MjNiYzQ2YjEtNzFmNi00ZWQ1LThjNTQtODE2YWE0ZjhjNTAyOjEyM3pPM3haQ0xyTU42djJCS0sxZFhZRnBYbFBrY2NPRnFtMTJDZEFzTWdSVTRWck5aOWx5R1ZDR3VNREdJd1A=",
               "Content-Type": "application/json"}

    resp = requests.get(url, headers=headers, verify=False)
    data = resp.json()

    names = []
    for i in range(len(data)):
        names.append(data[i]['name'])

    return names


def k8s_load_config():
    k8s_config_file = os.environ.get('KUBECONFIG')
    if k8s_config_file:
        config.load_kube_config(config_file=k8s_config_file)
        log.info("Configured using load_kube_config()")
    else:
        try:
            config.load_incluster_config()
            log.info("Configured using load_incluster_config()")
        except config.ConfigException:
            raise Exception("Could not configure k8s client")


def getURL(action):
    # K8s client
    v1 = client.CoreV1Api()

    # URL variables
    svc = v1.read_namespaced_service("owdev-prometheus-server", "openwhisk")
    start = datetime.datetime.utcnow() + datetime.timedelta(minutes=-15)
    start_timestamp = str(start.isoformat()) + 'Z'
    end_timestamp = str(datetime.datetime.utcnow().isoformat()) + 'Z'

    query = "rate(openwhisk_action_duration_seconds_sum{namespace=\"guest\",action=\"" + action + \
        "\"}[1m])/rate(openwhisk_action_duration_seconds_count{namespace=\"guest\",action=\"" + action + \
        "\"}[1m])>0"

    # GET response
    url = "http://{}:9090/api/v1/query_range?query={}&start={}&end={}&step=10".format(
        svc.spec.cluster_ip, query, start_timestamp, end_timestamp)
    log.info("URL: {}".format(url))
    return url


def updateConfigMap():
    names = getFunctionNames()
    if not names:
        log.info("No functions found")
        return

    for name in names:
        log.info("Updating function {}".format(name))
        url = getURL(name)
        resp = requests.get(url)
        data = resp.json()

        if len(data['data']['result']) == 0:
            log.info("Function {} doesn't have data in the interval".format(name))
            for f in functions:
                if f.name == name:
                    break
            else:
                log.info("Function {} was never called".format(name))
                func = Function(name, 0.0)
                functions.append(func)
            continue

        values = data['data']['result'][0]['values']

        # Compute average
        avg = 0.0
        for i in range(len(values)):
            avg += float(values[i][1])

        avg_ms = avg/len(values)*1000

        for f in functions:
            if f.name == name:
                f.avg = avg_ms
                log.info(f.toJSON())
                break
        else:
            func = Function(name, avg_ms)
            functions.append(func)
            log.info(func.toJSON())
        log.info("Function: {}, new value: {:.2f} s".format(name, avg_ms/1000))


def scheduler():
    while True:
        updateConfigMap()
        time.sleep(60)


def main():
    # Init Kubernetes
    k8s_load_config()

    # Start scheduler
    t = threading.Thread(target=scheduler)
    t.start()

    # Start WebServer
    webServer = HTTPServer(("0.0.0.0", 8080), Server)
    log.info("Server started http://0.0.0.0:8080")

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
    log.info("Server stopped")


if __name__ == "__main__":
    main()
