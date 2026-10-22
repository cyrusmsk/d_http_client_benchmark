#!/usr/bin/env python

"""Plot benchmark results as horizontal stacked bars, one bar per HTTP client."""

import argparse
import json
import os
from collections import OrderedDict

import matplotlib.pyplot as plt
import numpy as np


def label_for(command):
    name = os.path.basename(str(command))
    for ext in (".py", ".swift", ".cpp", ".rs", ".go", ".cs", ".r", ".zig"):
        if name.endswith(ext):
            name = name[: -len(ext)]
    return name


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("file", help="JSON file with benchmark results")
parser.add_argument("--title", help="Plot title")
parser.add_argument("--labels", help="Comma-separated list of entries for the plot legend")
parser.add_argument("-o", "--output", help="Save image to the given filename.")
args = parser.parse_args()

with open(args.file) as f:
    payload = json.load(f)

results = payload.get("results", [])

clients = OrderedDict()
tests = OrderedDict()

for item in results:
    client = label_for(item.get("command", item.get("name", "unknown")))
    test = str(item.get("test", "test"))
    times = item.get("times", [])
    value = sum(times) / len(times) if times else 0.0

    if client not in clients:
        clients[client] = OrderedDict()
    if test not in tests:
        tests[test] = True
    clients[client][test] = clients[client].get(test, 0.0) + value

if args.labels:
    tests = OrderedDict.fromkeys(args.labels.split(","))

client_names = list(clients.keys())
test_names = list(tests.keys())

if not client_names or not test_names:
    raise SystemExit("No benchmark results found to plot.")

values = np.array(
    [[clients[client].get(test, 0.0) for test in test_names] for client in client_names]
)

fig, ax = plt.subplots(figsize=(max(8, len(test_names) * 2.0), max(4, len(client_names) * 0.45)))

left = np.zeros(len(client_names))
cmap = plt.get_cmap("tab20")
colors = [cmap(i % 20) for i in range(len(test_names))]

for i, test in enumerate(test_names):
    ax.barh(
        client_names,
        values[:, i],
        left=left,
        color=colors[i],
        label=test,
        edgecolor="black",
        linewidth=0.4,
        height=0.7,
    )
    left += values[:, i]

for y, total in zip(client_names, left):
    ax.text(total, y, f" {total:.3f}s", va="center", ha="left", fontsize=8)

if args.title:
    ax.set_title(args.title)

ax.set_xlabel("Time [s]")
ax.set_ylabel("HTTP client")
ax.grid(axis="x")
ax.set_xlim(0, left.max() * 1.15 if left.max() > 0 else 1)
ax.invert_yaxis()
ax.tick_params(axis="y", labelsize=9)
plt.xticks(rotation=45)
ax.legend(title="Test", loc="lower right", fontsize="small")
plt.tight_layout()

if args.output:
    plt.savefig(args.output)
else:
    plt.show()
