#!/usr/bin/env python

import datetime
import json
import locale
import re
import subprocess
from html import escape

data = {}

locale.setlocale(locale.LC_TIME, "de_DE.utf8")
today_long = datetime.date.today().strftime("%d. %B %Y")

next_week = (datetime.date.today() +
             datetime.timedelta(days=5)).strftime("%Y-%m-%d")

output = subprocess.check_output(
    "khal list now " + next_week +
    ' --format "{start-time}-{end-time} {title} {repeat-symbol} {alarm-symbol}"',
    shell=True,
)
output = output.decode("utf-8")

lines = output.split("\n")
new_lines = []
for line in lines:
    clean_line = escape(line).split(" ::")[0]
    if len(clean_line) and not clean_line[0] in ["0", "1", "2"]:
        clean_line = "\n<b>" + clean_line + "</b>"
    new_lines.append(clean_line)
output = "\n".join(new_lines).strip()

# In der Leiste nur Icon + Startzeit; Titel und Agenda bleiben im Tooltip.
if today_long in output:
    event_lines = [
        line for line in output.split("\n")
        if line and not line.startswith("<b>")
    ]
    next_event = event_lines[0] if event_lines else ""
    time_match = re.match(r"^(\d{1,2}:\d{2})", next_event)
    data["text"] = " " + time_match.group(1) if time_match else ""
else:
    data["text"] = ""

data["tooltip"] = output

print(json.dumps(data))
