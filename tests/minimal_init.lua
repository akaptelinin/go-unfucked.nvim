package.path = package.path .. ";./tests/deps/nvim-test-core/lua/?.lua"
package.path = package.path .. ";./tests/deps/nvim-test-core/lua/?/init.lua"
package.path = package.path .. ";./lua/?.lua"
package.path = package.path .. ";./lua/?/init.lua"

require("nvim-test-core")
require("go-unfucked")
