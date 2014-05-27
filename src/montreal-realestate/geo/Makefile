all: clean build

clean:
	rm -f montreal.data.json montreal.topo.json montreal.json

build:
	#ogr2ogr -f GeoJSON  montreal.encoded.json montreal.shp
	mapshaper  -p 0.3 --auto-snap --encoding iso885915 montreal.shp -f geojson -o montreal.json
	#iconv -f ISO-8859-15 -t utf-8 montreal.encoded.json > montreal.json
	#rm montreal.encoded.json
	python python/process_geodata.py
	topojson -p -o montreal.topo.json montreal.data.json
	cp montreal.topo.json ../assets/montreal.topo.json
