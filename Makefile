# Execute the "targets" in this file with `make <target>` e.g., `make test`.

# You can also run multiple in sequence, e.g. `make clean lint test serve-coverage-report`

clean:
	bash run.sh clean

install:
	bash run.sh install

lint:
	bash run.sh lint

lint-ci:
	bash run.sh lint:ci

test:
	bash run.sh run-tests

test-parallel:
	bash run.sh run-tests:parallel
	
serve-coverage-report:
	bash run.sh serve-coverage-report

help:
	bash run.sh help

generate-project:
	bash run.sh generate-project
