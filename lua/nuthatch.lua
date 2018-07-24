#!/usr/bin/env cgilua.cgi

package.path = package.path .. ';/home/nuthatch/Nuthatch/lib/Shared/?.lua'
package.path = package.path .. ';/home/nuthatch/Nuthatch/lib/Client/?.lua'
local client = require "clientdispatch"
client.execute()
