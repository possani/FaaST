import glob
import json
import argparse
from os import system, remove

filename_prefix = ""
factor = 1
unity = "ms"
function = ""
metric = ""
submetric = ""
cluster = "cloud"
split = False


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


def create_dat(cluster):
    backend = ["aws", "lrz", "local"]

    f = open("{}-{}.dat".format(filename_prefix, cluster), "w")
    f.write("# {}".format(cluster))
    f.write("\n# scenario\t{}".format(submetric))

    for be in backend:
        be_files = glob.glob("{}-{}-*-{}.json".format(function, be, cluster))
        if not be_files:
            continue
        result = aggregate_results(be_files)
        f.write("\n{}\t{}".format(be.upper(), result/factor))

    f.close()


def create_dat_per_be():
    backend = ["aws", "lrz", "local"]

    for be in backend:

        be_files = glob.glob("{}-{}-*-{}.json".format(function, be, cluster))
        if not be_files:
            continue

        f = open("{}-{}.dat".format(filename_prefix, be), "w")
        f.write("# {} {}".format(cluster, be))
        f.write("\n# scenario\t{}".format(submetric))

        run = 1
        for be_file in be_files:
            with open(be_file) as be_f:
                data = json.load(be_f)
                value = data["metrics"][metric][submetric]
                f.write("\n{}\t{}".format(run, value/factor))
            run += 1
        f.close()


def create_gpi():
    f = open("{}.gpi".format(filename_prefix), "w")
    f.write("set terminal pngcairo size 960,540 enhanced font 'Verdana,10'")
    if split:
        f.write("\nset title '{}'".format(cluster))
    else:
        f.write("\nset title '{}'".format(function))
    f.write("\nset output '{}.png'".format(filename_prefix))
    # f.write("\nset yrange [0:10]")
    f.write("\nset ylabel '{} ({})'".format(metric.replace("_", "\_"), unity))
    f.write("\nset style line 1 linecolor rgb '#0060ad' linetype 1 linewidth 2 pointtype 7 pointsize 1.5")
    f.write("\nset style line 2 linecolor rgb '#dd181f' linetype 1 linewidth 2 pointtype 5 pointsize 1.5")
    if split:
        f.write("\nplot '{}-lrz.dat' using 2: xtic(1) with linespoints linestyle 1 title 'LRZ', \\".format(filename_prefix))
        f.write(
            "\n'{}-local.dat' using 2: xtic(1) with linespoints linestyle 2 title 'LOCAL'".format(filename_prefix))
    else:
        f.write("\nset style fill solid")
        # f.write("\nset boxwidth 0.5")
        f.write("\nplot '{}-edge.dat' using 2: xtic(1) with histogram linestyle 1 title 'Edge', \\".format(filename_prefix))
        f.write(
            "\n'{}-cloud.dat' using 2: xtic(1) with histogram linestyle 2 title 'Cloud'".format(filename_prefix))
    f.close()


def create_graph():
    system('gnuplot {}.gpi'.format(
        filename_prefix.replace("(", "\(").replace(")", "\)")))


def delete_all():
    for ext in ["dat", "gpi", "png"]:
        for f in glob.glob("*.{}".format(ext)):
            remove(f)


def delete():
    for ext in ["dat", "gpi", "png"]:
        for f in glob.glob("{}*.{}".format(filename_prefix, ext)):
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
    parser.add_argument("-c", "--cluster", nargs='?', default="cloud",
                        help="select the cluster when splitting the runs")
    parser.add_argument("-d", "--delete", help="delete gpi and dat generated files",
                        action="store_true")
    parser.add_argument("--delete-all", help="delete all gpi and dat generated files",
                        action="store_true")
    parser.add_argument("-s", "--seconds", help="display the time in seconds",
                        action="store_true")
    parser.add_argument("--split", help="display every single run for a given cluster",
                        action="store_true")
    args = parser.parse_args()

    function = args.function
    metric = args.metric
    submetric = args.submetric

    filename_prefix = "{}-{}-{}".format(function, metric, submetric)

    if args.delete_all:
        delete_all()

    elif args.delete:
        delete()

    else:
        if args.seconds and args.metric != "iterations":
            factor = 1000
            unity = "s"

        if args.split:
            split = True
            cluster = args.cluster
            create_dat_per_be()
        else:
            create_dat("cloud")
            create_dat("edge")

        create_gpi()
        create_graph()
