all: prepare

prepare:
	mkdir -p /opt/fev
	chmod 777 /opt/fev
	cp -R models /opt/fev
	cp *.edn /opt/fev/

export:
	@for file in *.json; do \
		filename=$(basename "$$file"); \
		extension="$${filename##*.}"; \
		filename="$${filename%.*}"; \
		sed "1s/^/window.$$filename = /; \$$s/\$$/;/" <$$file >$${filename}.js;  \
	done
	@mv *.js ../assets

