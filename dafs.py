from minio import Minio
import json
import subprocess
import requests
import yaml
import concurrent.futures
from urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)


def getImages():
    with open(r'config.yaml') as config:
        config_obj = yaml.load(config, Loader=yaml.FullLoader)
        return(config_obj['payload']['images'])


def getMinioClient(location):
    backend = location + 'Backend'
    with open(r'config.yaml') as config:
        config_obj = yaml.load(config, Loader=yaml.FullLoader)

        service_ip = config_obj[backend]['service_ip']
        service_port = config_obj[backend]['service_port']
        access_key = config_obj[backend]['access_key']
        secret_key = config_obj[backend]['secret_key']

        endpoint_str = "{}:{}".format(service_ip, service_port)
        minioClient = Minio(endpoint=endpoint_str,
                            access_key=access_key,
                            secret_key=secret_key,
                            secure=False)
        return minioClient


def getPlayload(location, images):
    backend = location + 'Backend'
    with open(r'config.yaml') as config:
        config_obj = yaml.load(config, Loader=yaml.FullLoader)

        service_ip = config_obj[backend]['service_ip']
        service_port = config_obj[backend]['service_port']
        access_key = config_obj[backend]['access_key']
        secret_key = config_obj[backend]['secret_key']

        payload = {
            "service_ip": service_ip,
            "service_port": service_port,
            "access_key": access_key,
            "secret_key": secret_key,
            "images": images
        }

        return json.dumps(payload)


def checkLocal(images):
    mc = getMinioClient('local')
    missing = []
    for i in images:
        try:
            stat = mc.stat_object('openwhisk', i)
        except Exception as e:
            if str(e).__contains__("NoSuchKey"):
                missing.append(i)
    missingStr = '|'.join(missing)
    return missingStr


def getClusterIP():
    with open(r'config.yaml') as config:
        config_obj = yaml.load(config, Loader=yaml.FullLoader)
        return(config_obj['clusters'][0]['openwhisk'])


def callFunction(location, images):
    url = "https://{}:31001/api/v1/namespaces/guest/actions/minio?blocking=true&result=true".format(
        getClusterIP())
    headers = {"Authorization": "Basic MjNiYzQ2YjEtNzFmNi00ZWQ1LThjNTQtODE2YWE0ZjhjNTAyOjEyM3pPM3haQ0xyTU42djJCS0sxZFhZRnBYbFBrY2NPRnFtMTJDZEFzTWdSVTRWck5aOWx5R1ZDR3VNREdJd1A=",
               "Content-Type": "application/json"}

    payload = getPlayload(location, images)
    resp = requests.post(url,
                         headers=headers,
                         verify=False,
                         data=payload)
    return resp.json()


def checkDocker():
    return subprocess.check_output("docker ps --format {{.Names}} --filter name=^/copying-images-123$", shell=True).decode()


def copyImages(missing_images):
    f = open("config.yaml", "r")
    config_obj = yaml.load(f, Loader=yaml.FullLoader)

    local_service_ip = config_obj['localBackend']['service_ip']
    local_service_port = config_obj['localBackend']['service_port']
    local_access_key = config_obj['localBackend']['access_key']
    local_secret_key = config_obj['localBackend']['secret_key']

    remote_service_ip = config_obj['remoteBackend']['service_ip']
    remote_service_port = config_obj['remoteBackend']['service_port']
    remote_access_key = config_obj['remoteBackend']['access_key']
    remote_secret_key = config_obj['remoteBackend']['secret_key']

    subprocess.Popen(
        "docker run --rm --name copying-images-123 --entrypoint=\"\" --network host minio/mc sh -c \"mc -q config host add local http://{}:{} {} {} > /dev/null; mc -q config host add remote http://{}:{} {} {} > /dev/null; mc -q find remote/openwhisk --regex \\\"{}\\\" --exec \\\"mc -q cp {{}} local/openwhisk\\\"\" >> /dev/null".format(
            local_service_ip, local_service_port, local_access_key, local_secret_key,
            remote_service_ip, remote_service_port, remote_access_key, remote_secret_key,
            missing_images),
        shell=True,
        stdin=None, stdout=None, stderr=None, close_fds=True)


def main():
    images = getImages()
    missing_images = checkLocal(images)

    if not missing_images:
        print('Local: ', callFunction('local', images))
    else:
        executor = concurrent.futures.ThreadPoolExecutor(max_workers=1)
        t1 = executor.submit(callFunction, 'remote', images)
        print('Remote: ', t1.result())
        if not checkDocker():
            print('Copying images...')
            copyImages(missing_images)


if __name__ == "__main__":
    main()
