clean:
	rm -rf _output
	rm -rf .up
	rm -rf ~/.up/cache

build:
	up project build

render: render-step-1 render-step-2

render-step-1:
	up composition render --xrd=apis/accounts/definition.yaml apis/accounts/composition.yaml examples/accounts/example.yaml

render-step-2:
	up composition render --xrd=apis/accounts/definition.yaml apis/accounts/composition.yaml examples/accounts/example.yaml --observed-resources=examples/observed-resources/example/steps/1/

test:
	up test run tests/test*

validate:
	up composition render --xrd=apis/accounts/definition.yaml apis/accounts/composition.yaml examples/accounts/example.yaml --observed-resources=examples/observed-resources/example/steps/1/ --include-full-xr --quiet | crossplane beta validate apis/accounts -

validate-examples:
	crossplane beta validate apis/accounts examples/accounts

publish:
	@if [ -z "$(tag)" ]; then echo "Error: tag is not set. Usage: make publish tag=<version>"; exit 1; fi
	up project build --push --tag $(tag)

generate-definitions:
	up xrd generate examples/accounts/example.yaml

generate-function:
	up function generate --language=go-templating render apis/accounts/composition.yaml

e2e:
	up test run tests/e2etest* --e2e
