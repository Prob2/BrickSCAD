OPENSCAD=openscad-nightly

all: T1vhod.stl T1notranjost.stl T1tla.stl T1pokrov.stl T2vhod.stl T2notranjost.stl T2tla.stl

%.stl: curved_tunnel.scad curved_tunnel.json
	$(OPENSCAD) --export-format binstl -o $@ -p curved_tunnel.json -P $* $<

clean:
	rm -rf *.stl
