PY := python3 -I
SCAD := openscad
SIZES := 80 92 120
PARTS := dock coupon gasket
FN := 64

STLS := $(foreach p,$(PARTS),$(foreach s,$(SIZES),stl/$(p)-$(s).stl))
PNGS := $(foreach s,$(SIZES),previews/front-$(s).png previews/rear-$(s).png previews/section-$(s).png)

.PHONY: all test stl previews clean
all: test stl previews

test:
	$(PY) tests/check.py

stl: $(STLS)
previews: $(PNGS)

SRC := $(wildcard src/*.scad)

stl/%.stl: $(SRC)
	@mkdir -p stl
	$(SCAD) -o $@ -D 'part="$(word 1,$(subst -, ,$*))"' -D fan_size=$(word 2,$(subst -, ,$*)) -D '$$fn=$(FN)' src/dock.scad

previews/front-%.png: $(SRC) tools/preview.scad
	@mkdir -p previews
	$(SCAD) -o $@ -D fan_size=$* -D 'view="front"' --camera=0,0,0,60,0,-30,0 --viewall --autocenter --imgsize=1200,900 tools/preview.scad
previews/rear-%.png: $(SRC) tools/preview.scad
	@mkdir -p previews
	$(SCAD) -o $@ -D fan_size=$* -D 'view="rear"' --camera=0,0,0,50,0,150,0 --viewall --autocenter --imgsize=1200,900 tools/preview.scad
previews/section-%.png: $(SRC) tools/preview.scad
	@mkdir -p previews
	$(SCAD) -o $@ -D fan_size=$* -D 'view="section"' --camera=0,0,0,0,0,0,0 --viewall --autocenter --projection=o --imgsize=1200,900 tools/preview.scad

clean:
	rm -rf stl previews
