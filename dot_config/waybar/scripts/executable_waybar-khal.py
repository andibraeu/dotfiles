#!/usr/bin/env python

import subprocess
import datetime
import json
import locale
from html import escape

data = {}

locale.setlocale(locale.LC_TIME, "de_DE.utf8")
today = datetime.date.today().strftime("%Y-%m-%d")
today_long = datetime.date.today().strftime("%d. %B %Y")

next_week = (datetime.date.today() +
             datetime.timedelta(days=10)).strftime("%Y-%m-%d")

output = subprocess.check_output("khal list now "+next_week+ ' --format "{start-time}-{end-time} {title} {repeat-symbol} {alarm-symbol}"', shell=True)
output = output.decode("utf-8")

lines = output.split("\n")
new_lines = []
for line in lines:
    clean_line = escape(line).split(" ::")[0]
    if len(clean_line) and not clean_line[0] in ['0', '1', '2']:
        clean_line = "\n<b>"+clean_line+"</b>"
    new_lines.append(clean_line)
output = "\n".join(new_lines).strip()

if today_long in output:
    text = output.split('\n')[1]
    next_event = (text[:40] + '..') if (len(text)) > 40 else text
    data['text'] = " " + next_event
else:
    data['text'] = ""

data['tooltip'] = output

print(json.dumps(data))
