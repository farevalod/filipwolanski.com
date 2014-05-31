#!/usr/local/bin/python

import sys
import json
import sqlite3
from shapely.geometry import shape, Point
from time import time
from functools import partial

process_items = ['data_points', 'price', 'pp_foot', 'pp_foot_points']
process_types = ['house', 'town', 'condo']
additional_items = ['DAUID', "CSDNAME", 'area']

def initialize_data(data):
    for item in process_items:
        for type in process_types:
            data[item + "_" + type] = 0

def compute_interior_size(row, data, type):
    if row['interior_size']:
        size, unit = row['interior_size'].split(" ")
        if unit == "sqft":
            size = float(size)
        elif unit == "m2":
            size = float(size)*10.7639
        else:
            print "Invalid unit found: ", unit
            sys.exit(1)
        data['pp_foot_' + type] = float(row['price']/size)
        data['pp_foot_points_' + type] = 1

def get_type(building):
    return {
        'Apartment': 'condo',
        'House': 'house',
        'Mobile Home': 'house',
    }.get(building, 'town')

def process_row(polygons,row):
    data = {}
    point = Point(float(row['long']), float(row['lat']))
    for idx,polygon in enumerate(polygons):
        if point.within(polygon):
            data['idx'] = idx
            type = get_type(row['building_type'])
            compute_interior_size(row, data, type)
            data['data_points' + "_" + type] = 1
            data['price' + "_" + type] = float(row['price'])
            return data
    return False

def create_polygons(js):
    js['features'] = [x for x in js['features'] if x['geometry'] != None]
    # create an array of polygons for each sector
    polygons = []
    for feature in js['features']:
        initialize_data(feature['properties'])
        poly = shape(feature['geometry'])
        polygons.append(poly)
        feature['properties']['area'] = poly.area*111.12*111.12
    return polygons

def compute_attributes(polygons, c):
    # get the total properties to process
    c.execute("select count(*) from properties")
    total = c.fetchone()
    data = []
    count = 0
    percent = 0.0

    for row in c.execute("SELECT * FROM properties"):
        count+= 1
        if round((float(count)/int(total[0]))*100) != percent:
            percent = round(float(count)/int(total[0])*100)
            done_str = str(int(percent)) + "% done."
            sys.stdout.write('\r%s' % done_str)
            sys.stdout.flush()
        d = process_row(polygons, row)
        if d:
            data.append(d)
    return data

def merge_attributes(js, data):
    for d in data:
        for item in process_items:
            for type in process_types:
                itemType = item + "_" + type
                if itemType in d:
                    js['features'][d['idx']]['properties'][itemType]+= d[itemType]
                js['features'][d['idx']]['properties']['processed'] = True
    js['features'] = [x for x in js['features'] if 'processed' in x['properties']]

def trim_attributes(js):
    items = additional_items
    for item in process_items:
        for type in process_types:
            items.append(item + "_" + type)

    for feature in js['features']:
        p = feature['properties'].copy()
        for i in p:
            if i not in items:
                del feature['properties'][i]

# connect to the database
conn = sqlite3.connect('properties.db')
conn.row_factory = sqlite3.Row
c = conn.cursor()

# load GeoJSON file containing sectors
with open('montreal.json', 'r') as f:
    js = json.load(f)

polygons = create_polygons(js)
data = compute_attributes(polygons, c)
merge_attributes(js, data)
trim_attributes(js)

# write out the processed file
with open('montreal.data.json', 'w') as f:
    f.write(json.dumps(js))
