#!/usr/local/bin/python

import sys
import json
import sqlite3

from shapely.geometry import shape, Point

# load GeoJSON file containing sectors
with open('montreal.json', 'r') as f:
    js = json.load(f)

polygons = []
for idx, feature in enumerate(js['features']):
    feature['properties']['data_points'] = 0
    polygons.append(shape(feature['geometry']))

conn = sqlite3.connect('properties.db')
conn.row_factory = sqlite3.Row
c = conn.cursor()

c.execute("select count(*) from properties")
total = c.fetchone()
count = 0
percent = 0.0
for row in c.execute("SELECT * FROM properties"):
    count+= 1
    if round((float(count)/int(total[0]))*100) != percent:
        percent = round(float(count)/int(total[0])*100)
        done_str = str(int(percent)) + "% done."
        sys.stdout.write('\r%s' % done_str)
        sys.stdout.flush()
    point = Point(float(row['long']), float(row['lat']))
    for idx,polygon in enumerate(polygons):
        if point.within(polygon):
            js['features'][idx]['properties']['data_points']+=1

with open('montreal.data.json', 'w') as f:
    f.write(json.dumps(js))
