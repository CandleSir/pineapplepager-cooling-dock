PY := python3 -I

.PHONY: test
test:
	$(PY) tests/check.py
