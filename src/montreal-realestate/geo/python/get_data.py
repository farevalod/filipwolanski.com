#!/usr/bin/env python

import urllib
import random
import urllib2
import json
import time
import re
import sqlite3
from datetime import datetime

class APIException(Exception):
    pass

def setup_db():
    conn = sqlite3.connect('properties.db')
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS properties
                 (id integer primary key, price decimal(10,2), lat decimal(3,10),
                 long decimal(3,10), address text, postal_code text,
                 building_type text, property_type text,
                 interior_size text, ownership text, date timestamp )''')
    conn.commit()
    return c, conn

def api_request_for_properties(lat, long, lat_min, long_min, lat_max, long_max):
    url = "http://beta.realtor.ca/api/Listing.svc/PropertySearch_Post"

    post_data = { "CultureId":1, "ApplicationId":1, "RecordsPerPage":1500, "MaximumResults":1500,
    "PropertyTypeId":300, "TransactionTypeId":2, "SortOrder":"A", "SortBy":1,
    "LongitudeMin":long_min, "LongitudeMax":long_max, "LatitudeMin":lat_min, "LatitudeMax":lat_max,
    "PriceMin":0, "PriceMax":0, "BedRange":"0-0", "BathRange":"0-0", "ParkingSpaceRange":"0-0",
    "viewState":"m", "Longitude":long, "Latitude":lat, "ZoomLevel":12, "CurrentPage":1,
    }
    post_data_encoded = urllib.urlencode(post_data)

    request_object = urllib2.Request(url, post_data_encoded)
    response = urllib2.urlopen(request_object)

    json_string = response.read()
    data = json.loads(json_string)
    #print get_value("Paging", data)
    res = get_value("Results", data)
    if len(res) > 900:
      print "Length of results: " + str(len(res))
    return res

def get_value(value, data, important = True):
    if value in data:
        return data[value]
    elif important:
        raise APIException(value + " not contained in api response.")
    else:
        return ""

def get_property_data(property):
    non_decimal = re.compile(r'[^\d.-]+')

    #id
    id = int(get_value("Id", property))

    building = get_value("Building", property)
    prop = get_value("Property", property)

    #price
    price = get_value("Price", prop)
    price = float(non_decimal.sub('', price))

    #lat and long
    address = get_value("Address", prop)
    addr_text = get_value("AddressText", address)
    lat = get_value("Latitude", address)
    long = get_value("Longitude", address)
    lat = float(non_decimal.sub('', lat))
    long = float(non_decimal.sub('', long))

    #postal code
    postal_code = get_value("PostalCode", property)

    #building type
    building_type = get_value("Type", building)

    #property type
    property_type = get_value("Type", prop)

    #property type
    property_ownership = get_value("OwnershipType", prop, False)

    #size
    interior_size = get_value("SizeInterior", building, False)

    return (id, price, lat, long, addr_text, postal_code, building_type, property_type, interior_size, property_ownership)


def save_data_for_tile(lat_start, long_start, delta):
    lat_end = lat_start + delta
    long_end = long_start + delta
    lat = (lat_start + lat_end) / 2
    long = (long_start + long_end) / 2
    data = api_request_for_properties(lat, long, lat_start, long_start, lat_end, long_end)
    rows = []
    for property in data:
        try:
            property_data = get_property_data(property)
        except APIException:
            pass
        else:
            property_data = property_data + ( datetime.now(),)
            rows.append( property_data)
    c.executemany('''replace into properties(id, price, lat, long, address, postal_code,
                     building_type, property_type, interior_size, ownership, date) values (?,?,?,?,?,?,?,?,?,?,?)''', rows )
    conn.commit()

def get_comprehension(start_lat, start_long, end_lat, end_long, delta):
    locations = []
    lat = [x * 0.01 for x in range(int(start_lat * 100), int((end_lat + delta)*100), int(delta * 100))]
    long = [x * -0.01 for x in range(int(-end_long * 100), int(-(start_long - delta) * 100), int(delta * 100))]
    return [(x,y) for x in lat for y in long]


c, conn = setup_db()

start_lat = 45.16
start_long = -74.27
end_lat = 45.83
end_long = -73.18
delta = 0.03

coordinates = get_comprehension(start_lat, start_long, end_lat, end_long, delta)

count = 0
length = len(coordinates)
for coord in coordinates:
    count +=1
    print "Getting ", count, " of ", length
    save_data_for_tile(coord[0], coord[1], delta)
    time.sleep(random.randint(5,15))

conn.close()

