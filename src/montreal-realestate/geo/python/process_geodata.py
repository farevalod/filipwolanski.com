#!/usr/local/bin/python

import sys
import json
import sqlite3

from shapely.geometry import shape, Point

# load GeoJSON file containing sectors
with open('montreal.json', 'r') as f:
    js = json.load(f)


js['features'] = [x for x in js['features'] if x['geometry'] != None]
# create an array of polygons for each sector
polygons = []
for feature in js['features']:
    feature['properties']['data_points'] = 0
    feature['properties']['avg_price'] = 0
    feature['properties']['pp_foot'] = 0
    feature['properties']['pp_foot_data_points'] = 0
    polygons.append(shape(feature['geometry']))

# connect to the database
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
            if row['interior_size']:
                size, unit = row['interior_size'].split(" ")
                if unit == "sqft":
                    size = float(size)
                elif unit == "m2":
                    size = float(size)*10.7639
                else:
                    print "Invalid unit found: ", unit
                    sys.exit(1)
                js['features'][idx]['properties']['pp_foot']+= float(row['price']/size)
                js['features'][idx]['properties']['pp_foot_data_points']+= 1
            js['features'][idx]['properties']['data_points']+=1
            js['features'][idx]['properties']['avg_price']+= float(row['price'])
            break

for feature in js['features']:
    p = feature['properties']
    if p['data_points'] > 0:
        feature['properties']['avg_price'] = p['avg_price']/p['data_points']
    if p['pp_foot'] > 0:
        feature['properties']['pp_foot'] = p['pp_foot']/p['pp_foot_data_points']

with open('montreal.data.json', 'w') as f:
    f.write(json.dumps(js))
