#!/usr/bin/env cgilua.cgi

package.path = package.path .. ';/home/nuthatch/Nuthatch/lib/Shared/?.lua'
package.path = package.path .. ';/home/nuthatch/Nuthatch/lib/API/?.lua'
local api = require "apidispatch"
api.execute()
