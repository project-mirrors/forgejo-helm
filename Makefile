.PHONY: prepare-environment
prepare-environment:
	pnpm install

.PHONY: readme
readme: prepare-environment
	pnpm readme:parameters
	pnpm readme:lint

.PHONY: schema
schema: prepare-environment
	pnpm schema

.PHONY: schema-check
schema-check: prepare-environment
	pnpm schema:check

.PHONY: unittests
unittests:
	helm unittest --strict -f 'unittests/**/*.yaml' ./

.PHONY: helm
update-helm-dependencies:
	helm dependency update
  