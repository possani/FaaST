import sys
import glob
import json
import argparse


def create_dat(cluster, function, metric, submetric):
    aws_files = glob.glob("aws-*{}*.json".format(cluster))
    lrz_files = glob.glob("lrz-*{}*.json".format(cluster))
    local_files = glob.glob("local-*{}*.json".format(cluster))
    aws = lrz = local = 0.0

    for aws_file in aws_files:
        with open(aws_file) as f:
            data = json.load(f)
            aws = data["metrics"][metric][submetric]

    for lrz_file in lrz_files:
        with open(lrz_file) as f:
            data = json.load(f)
            lrz = data["metrics"][metric][submetric]

    for local_file in local_files:
        with open(local_file) as f:
            data = json.load(f)
            local = data["metrics"][metric][submetric]

    f = open("{}-{}.dat".format(function, cluster), "w")
    f.write("# {}".format(cluster))
    f.write("\n# scenario\t{}".format(submetric))
    f.write("\nAWS\t{}".format(aws))
    f.write("\nLRZ\t{}".format(lrz))
    f.write("\nLOCALHOST\t{}".format(local))
    f.close()


def create_gpi(function, metric):
    f = open("{}-{}.gpi".format(function, metric), "w")
    f.write("set terminal pngcairo size 960,540 enhanced font 'Verdana,10'")
    f.write("\nset title '{} - {}'".format(function, metric.replace("_", "\_")))
    f.write("\nset output '{}-{}.png'".format(function, metric))
    f.write("\nset yrange [0:10]")
    f.write("\nset ylabel '{} (ms)'".format(metric))
    f.write("\nset style line 1 linecolor rgb '#0060ad' linetype 1 linewidth 2 pointtype 7 pointsize 1.5")
    f.write("\nset style line 2 linecolor rgb '#dd181f' linetype 1 linewidth 2 pointtype 5 pointsize 1.5")
    f.write("\nplot '{}-edge.dat' using 2: xtic(1) with linespoints linestyle 1 title 'Edge', \\".format(function))
    f.write(
        "\n'{}-cloud.dat' using 2: xtic(1) with linespoints linestyle 2 title 'Cloud'".format(function))
    f.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("function", nargs='?', default="minio",
                        help="the name of the function")
    parser.add_argument("metric", nargs='?', default="http_req_duration",
                        help="k6 metric to be used")
    parser.add_argument("submetric", nargs='?', default="avg",
                        help="k6 aggregation type")
    args = parser.parse_args()
    create_dat("cloud", args.function, args.metric, args.submetric)
    create_dat("edge", args.function, args.metric, args.submetric)
    create_gpi(args.function, args.metric)
