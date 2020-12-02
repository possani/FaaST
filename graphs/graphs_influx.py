import glob
import json
import argparse
import os
import requests
import re


def get_files(filter, duration, case):
    files = glob.glob("**/*{}-{}-{}-summary.json".format(filter, duration, case))
    files = sorted(files)
    return files


def get_timestamps(duration, file):
    duration_sec = int(duration[:-1]) * 60
    margin_sec = 3
    remove_path = file.split("/")[1]
    start = int(remove_path.split("-")[0])
    end = start + duration_sec
    return {"start": start, "end": end}


def query_data(duration, file, p90, group_by):
    timestamps = get_timestamps(duration, file)
    if p90:
        q = 'SELECT percentile("value", 90) FROM /^http_req_duration$/ WHERE time >= {}s and time <= {}s and value > 0 GROUP BY time({}) fill(0)'.format(
            timestamps.get("start"), timestamps.get("end"), group_by)
    else:
        q = 'SELECT sum("value") FROM "http_reqs" WHERE time >= {}s and time <= {}s GROUP BY time({}) fill(0)'.format(
            timestamps.get("start"), timestamps.get("end"), group_by)
    url = "http://{}:31002/query?db=db&q={}&epoch=s".format(
        os.environ.get('LOCAL'), q)
    headers = {"Authorization": "Basic YWRtaW46YWRtaW4="}

    resp = requests.get(url, headers=headers, verify=False)
    data = resp.json()
    return data

def has_data(data):
    return "series" in data["results"][0]

def extract_values(data):
    raw_values = data["results"][0]["series"][0]["values"]
    values = []
    for v in raw_values:
        values.append(v[1])
    return values


def accumulate_values(values):
    cumulative = []
    cumulative.append(values[0])
    for i, v in enumerate(values):
        if not i:
            continue
        cumulative.append(v+cumulative[i-1])
    return cumulative


def create_dat(file, cumulative):
    filename = re.sub('^.*?/', '', file)
    filename = re.sub('^[0-9\-]+', '', filename)
    filename = re.sub('-summary.json', '', filename)
    f = open("{}.dat".format(filename), "w")
    f.write("# {}".format(filename))
    for i, v in enumerate(cumulative):
        f.write("\n{} {}".format(i, v))
    f.close()


def get_line_title(title, duration, case):
    title = re.sub('\.dat$', '', title)
    title = re.sub('-{}$'.format(case), '', title)
    title = re.sub('-{}$'.format(duration), '', title)
    title = re.sub('^minio-', '', title)
    return title


def create_gpi(duration, case):
    f = open("cumulative-{}-{}.gpi".format(duration, case), "w")
    f.write("set terminal pngcairo size 960,540 enhanced font 'Verdana,10'")
    f.write("\nset title 'Cumulative - {} - {}'".format(duration, case))
    f.write("\nset output 'cumulative-{}-{}.png'".format(duration, case))
    f.write("\nset ylabel 'Requests'")
    files = glob.glob("*-{}-{}.dat".format(duration, case))
    n_files = len(files)
    for i in range(n_files):

        if not i:
            f.write("\nplot ")
        else:
            f.write("\n, ")

        new_title = get_line_title(files[i], duration, case)
        f.write("'{}' using 1: 2 with lines title '{}'".format(
            files[i], new_title))

        if i != n_files-1:
            f.write(" \\")
    f.close()


def create_p90_gpi(duration):
    files = glob.glob("*-{}-*.dat".format(duration))
    n_files = len(files)
    for i in range(n_files):
        f = open("{}.gpi".format(files[i][:-4]), "w")
        f.write("set terminal pngcairo size 960,540 enhanced font 'Verdana,10'")
        f.write(
            "\nset title 'P(90) - http\_request\_duration (ms) - {}'".format(files[i], duration))
        f.write("\nset output '{}.png'".format(files[i][:-4]))
        f.write("\nplot '{}' using 1: 2 with lines title '{}' \\".format(
            files[i], files[i][:-4]))
        f.close()


def create_graphs(duration):
    files = glob.glob("*{}*.gpi".format(duration))
    for f in files:
        os.system('gnuplot {}'.format(f))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("--duration", nargs='?', default="5m",
                        help="the duration of the benchmark")
    parser.add_argument("--filter", nargs='?', default="",
                        help="filter to select specific files")
    parser.add_argument("--group-by", nargs='?', default="1s",
                        help="the duration to group the amount of requests by")
    parser.add_argument("--case", nargs='?', default="*",
                        help="the case selected to generate the graph")
    parser.add_argument("--p90", help="query http_req_duration p(90)",
                        action="store_true")
    args = parser.parse_args()

    p90 = False
    duration = args.duration
    group_by = args.group_by
    case = args.case
    filter = args.filter

    if args.p90:
        p90 = True

    files = get_files(filter, duration, case)
    for f in files:
        data = query_data(duration, f, p90, group_by)
        if not has_data(data):
            continue
        values = extract_values(data)
        if not p90:
            values = accumulate_values(values)
        create_dat(f, values)

    if p90:
        create_p90_gpi(duration)
    else:
        create_gpi(duration, case)
    create_graphs(duration)
