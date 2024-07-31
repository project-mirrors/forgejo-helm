.PHONY: prepare-environment
prepare-environment:
	pnpm install

.PHONY: readme
readme: prepare-environment
	pnpm readme:parameters
	pnpm readme:lint

.PHONY: unittests
unittests:
	helm unittest --strict -f 'unittests/**/*.yaml' ./

.PHONY: helm
update-helm-dependencies:
	helm dependency update
  