import glob
import json
import re

if __name__ == "__main__":

    minio_output_files = glob.glob("*-cp-*.json")
    k6s_output_files = glob.glob("*-local-*.json")
    for index, files in enumerate(minio_output_files):
        with open(files) as f:
            for line in f:
                speed = re.search('speed": (.*)', line)
                if speed:
                    jsonFile = open(k6s_output_files[index], 'r')
                    data = json.load(jsonFile)
                    jsonFile.close()

                    data["metrics"]["copy"] = {"speed": float(speed.group(1))}

                    jsonFile = open(k6s_output_files[index], 'w+')
                    jsonFile.write(json.dumps(data))
                    jsonFile.close()
