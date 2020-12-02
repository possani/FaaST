import glob
import json
import argparse
import re
from os import system, remove

filename_prefix = ""
factor = 1
unity = "ms"
function = ""
metric = ""
submetric = ""
case = "single"
tests = ["local", "lrz", "remote"]
durations = ["1m"]
filepath = ""


def aggregate_results(be_files):
    result = 0.0
    values = []

    if not be_files:
        return result

    for be_file in be_files:
        with open(be_file) as f:
            data = json.load(f)
            values.append(data["metrics"][metric][submetric])

    if submetric == "max":
        result = max(values)
    elif submetric == "min":
        result = min(values)
    else:
        result = float(sum(values)/len(values))

    return result


def get_files(test, duration):
    files = glob.glob(
        "**/*{}-{}-{}-{}-summary.json".format(function, test, duration, case),recursive=True)
    files = sorted(files)
    return files


def create_dat():
    f = open("{}.dat".format(filename_prefix), "w")
    f.write("Durations\t{}".format('\t'.join(tests)))

    for duration in durations:
        f.write("\n{}".format(duration))
        for test in tests:
            test_files = get_files(test,duration)
            if not test_files:
                continue
            result = aggregate_results(test_files)
            f.write("\t{}".format(result/factor))

    f.close()


def create_gpi():
    f = open("{}.gpi".format(filename_prefix), "w")
    f.write("set terminal pngcairo size 960,540 enhanced font 'Verdana,10'")
    f.write("\nset title \"Duration Comparison \"")
    f.write("\nset output '{}.png'".format(filename_prefix))
    f.write("\nset style data histogram")
    f.write("\nset style fill solid 1.0 border -1")
    f.write("\nset ylabel '{} ({})'".format(metric.replace("_", "\_"), unity))
    f.write("\nset yrange [0:*]")
    f.write("\nplot '{}.dat' using 2:xtic(1) title col".format(
        filename_prefix))
    n_tests = len(tests)
    if n_tests > 1:
        col = 3
        for t in tests[1:]:
            f.write(", \\")
            f.write("\n'' using {}:xtic(1) title col".format(col))
            col+=1
    f.close()


def create_graph():
    system('gnuplot {}.gpi'.format(
        filename_prefix.replace("(", "\(").replace(")", "\)")))


def delete_all():
    for ext in ["dat", "gpi", "png"]:
        for f in glob.glob("*.{}".format(ext)):
            remove(f)


def delete_in():
    for ext in ["dat", "gpi", "png"]:
        for f in glob.glob("{}/*.{}".format(filepath, ext)):
            remove(f)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-f", "--function", nargs='?', default="minio",
                        help="the name of the function")
    parser.add_argument("-m", "--metric", nargs='?', default="http_req_duration",
                        help="k6 metric to be used")
    parser.add_argument("-sm", "--submetric", nargs='?', default="avg",
                        help="k6 aggregation type")
    parser.add_argument("--durations", nargs='?', default="1m",
                        help="select the duration")
    parser.add_argument("-c", "--case", nargs='?', default="single",
                        help="select the case")
    parser.add_argument("--delete-in", nargs='?', default="",
                        help="delete gpi, dat, and png generated files")
    parser.add_argument("-D","--delete-all", help="delete all gpi, dat, and png generated files in the current directory",
                        action="store_true")
    parser.add_argument("-s", "--seconds", help="display the time in seconds",
                        action="store_true")
    parser.add_argument("-t", "--tests", nargs='?', default="local,lrz,remote",
                        help="type of the test: local, local-cp, etc.")
    args = parser.parse_args()

    function = args.function
    metric = args.metric
    submetric = args.submetric

    filename_prefix = "{}-{}-{}".format(function, metric, submetric)

    if args.delete_all:
        delete_all()

    elif args.delete_in:
        filepath = args.delete_in
        delete_in()

    else:
        if args.tests:
            tests = []
            if ',' in args.tests:
                for t in args.tests.split(','):
                    tests.append(t)
            else:
                tests = [args.tests]

        if args.case:
            case = args.case

        if args.durations:
            durations = []
            if ',' in args.durations:
                for d in args.durations.split(','):
                    durations.append(d)
            else:
                durations = [args.durations]

        if args.seconds and args.metric != "iterations":
            factor = 1000
            unity = "s"

        create_dat()
        create_gpi()
        create_graph()
