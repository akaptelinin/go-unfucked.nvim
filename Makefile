deps:
	mkdir -p tests/deps
	git clone --depth 1 https://github.com/akaptelinin/nvim-test-core tests/deps/nvim-test-core 2>/dev/null || (cd tests/deps/nvim-test-core && git pull)

test: deps
	busted tests/

.PHONY: test deps
