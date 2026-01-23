OPENSCAD=openscad-nightly

t1: T1vhod.stl T1notranjost.stl T1tla.stl T1pokrov.stl

t2: T2vhod.stl T2notranjost.stl T2tla.stl T2pokrov.stl

all: t1 t2 bridge

%.stl: curved_tunnel.scad curved_tunnel.json
	$(OPENSCAD) --export-format binstl -o $@ -p curved_tunnel.json -P $* $<

clean:
	rm -rf *.stl

bridge: curved_bridge.stl

curved_bridge.stl: curved_bridge.scad
	$(OPENSCAD) --export-format binstl -o $@ $<
