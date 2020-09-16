import glob
import json
import re

if __name__ == "__main__":

    transferred = 0
    speed = 0.0

    # Get files
    minio_output_files = glob.glob("*-cp-*-migration.json")
    k6s_output_files = glob.glob("*-cp-*-summary.json")

    # Sort lists
    minio_output_files = sorted(minio_output_files)
    k6s_output_files = sorted(k6s_output_files)

    for index, files in enumerate(minio_output_files):
        with open(files) as f:
            for line in f:

                match_transferred = re.search('transferred": (.*),', line)
                if match_transferred:
                    transferred = int(match_transferred.group(1))

                match_speed = re.search('speed": (.*)', line)
                if match_speed:
                    speed = float(match_speed.group(1))

                if transferred and speed:
                    jsonFile = open(k6s_output_files[index], 'r')
                    data = json.load(jsonFile)
                    jsonFile.close()

                    data["metrics"]["copy"] = {"time": transferred/speed}

                    jsonFile = open(k6s_output_files[index], 'w+')
                    jsonFile.write(json.dumps(data))
                    jsonFile.close()
