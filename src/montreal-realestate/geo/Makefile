all: clean build

clean:
	rm -f montreal.json

build:
	ogr2ogr -f GeoJSON montreal.json montreal.shp
	python python/process_geodata.py
	topojson -p -o montreal.topo.json montreal.data.json
	cp montreal.topo.json ../assets/montreal.topo.json
