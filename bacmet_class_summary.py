#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# FileName:  bacmet_class_summary.py
# Author:    Zhihao Xie  \(#^o^)/
# Date:      2018/5/2 16:28
# Version:   v1.0.0
# CopyRight: Copyright ©Zhihao Xie, All rights reserved.

# class summary of bacmat output table

import sys
import os
import re
from collections import OrderedDict
from numpy import unique

def main():
    if len(sys.argv) < 2:
        print("usage: python3 {} <bacmat_out_table> > output".format(sys.argv[0]))
        sys.exit(1)

    bacmat_out = os.path.abspath(sys.argv[1])
    class_sum = OrderedDict()
    with open(bacmat_out) as fh:
        for line in fh:
            if re.search(r"^\s*$|^Query", line):
                continue
            elif len(line) == 0:
                break
            else:
                fields = line.strip().split("\t")
                compounds = fields[6]
                if re.search(r'\[.*\]', compounds):
                    compounds_class = re.findall('\[class:\s?(.+?)\]', compounds)
                    compounds_class = list(unique(compounds_class))
                    if len(compounds_class) > 0:
                        for i in compounds_class:
                            class_sum.setdefault(i, 0)
                            class_sum[i] += 1
                else:
                    compounds = compounds.strip('"')
                    compounds = compounds.strip("'")
                    compounds = compounds.strip()
                    class_sum.setdefault(compounds, 0)
                    class_sum[compounds] += 1
    print("Class\tCount")
    for key in sorted(class_sum.keys()):
        print(key, class_sum[key], sep="\t")

if __name__ == '__main__':
    main()
