import glob
import json
import argparse
import re

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-d", "--directory", nargs='?', default="multiple_5m",
                        help="the name of the directory")
    args = parser.parse_args()

    directory = args.directory

    minio_output_files = glob.glob("{}/*-cp-*.json".format(directory))
    k6s_output_files = glob.glob("{}/*-local-*.json".format(directory))
    for index, files in enumerate(minio_output_files):
        with open(files) as f:
            for line in f:
                speed = re.search('speed": (.*)', line)
                if speed:
                    jsonFile = open(k6s_output_files[index], 'r')
                    data = json.load(jsonFile)
                    jsonFile.close()

                    data["metrics"]["copy"] = {"speed": speed.group(1)}

                    jsonFile = open(k6s_output_files[index], 'w+')
                    jsonFile.write(json.dumps(data))
                    jsonFile.close()
