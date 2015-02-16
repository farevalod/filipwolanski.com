all: clean build

clean:
	rm -f montreal.data.json montreal.topo.json montreal.json

build:
	mapshaper  -p 0.3 --auto-snap --encoding iso885915 montreal.shp -f geojson -o montreal.json
	python python/process_geodata.py
	topojson -p -o montreal.topo.json montreal.data.json
	cp montreal.topo.json ../assets/montreal.topo.json
