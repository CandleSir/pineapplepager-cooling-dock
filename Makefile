PY := python3 -I
SCAD := openscad
VARIANTS := 60x15 60x25 40x10 40x20
FN := 64

DOCKS := $(VARIANTS:%=stl/dock-%.stl)
FILTERS := $(foreach s,40 60,stl/filter-grid-$(s).stl stl/filter-cap-$(s).stl)
GAUGES := stl/fan-gauge-40.stl stl/fan-gauge-60.stl
SEAT := stl/coupon.stl stl/gasket.stl stl/fit-gauge.stl
STLS := $(DOCKS) $(FILTERS) $(GAUGES) $(SEAT)
PNGS := $(foreach v,$(VARIANTS),previews/front-$(v).png previews/rear-$(v).png previews/section-$(v).png)

# 60x25 -> -D fan_size=60 -D fan_t=25
fan = -D fan_size=$(word 1,$(subst x, ,$(1))) -D fan_t=$(word 2,$(subst x, ,$(1)))
# fan gauges use the thicker fan of each size
GAUGE_T_40 := 20
GAUGE_T_60 := 25

.PHONY: all test stl previews clean
all: test stl previews

test:
	$(PY) tests/check.py

stl: $(STLS)
previews: $(PNGS)

SRC := $(wildcard src/*.scad)
OUT = @mkdir -p $(@D); $(SCAD) -o $@ -D '$$fn=$(FN)'

stl/dock-%.stl: $(SRC)
	$(OUT) -D 'part="dock"' $(call fan,$*) src/dock.scad
stl/filter-grid-%.stl: $(SRC)
	$(OUT) -D 'part="filter-grid"' -D fan_size=$* src/dock.scad
stl/filter-cap-%.stl: $(SRC)
	$(OUT) -D 'part="filter-cap"' -D fan_size=$* src/dock.scad
stl/fan-gauge-%.stl: $(SRC)
	$(OUT) -D 'part="fan-gauge"' -D fan_size=$* -D fan_t=$(GAUGE_T_$*) src/dock.scad
stl/coupon.stl: $(SRC)
	$(OUT) -D 'part="coupon"' src/dock.scad
stl/gasket.stl: $(SRC)
	$(OUT) -D 'part="gasket"' src/dock.scad
stl/fit-gauge.stl: $(SRC)
	$(OUT) -D 'part="gauge"' src/dock.scad

PREVIEW = @mkdir -p previews; $(SCAD) -o $@ $(call fan,$*) --viewall --autocenter --imgsize=1200,900
previews/front-%.png: $(SRC) tools/preview.scad
	$(PREVIEW) -D 'view="front"' --camera=0,0,0,60,0,-30,0 tools/preview.scad
previews/rear-%.png: $(SRC) tools/preview.scad
	$(PREVIEW) -D 'view="rear"' --camera=0,0,0,50,0,150,0 tools/preview.scad
previews/section-%.png: $(SRC) tools/preview.scad
	$(PREVIEW) -D 'view="section"' --camera=0,0,0,0,0,0,0 --projection=o tools/preview.scad

clean:
	rm -rf stl previews
