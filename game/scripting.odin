package game

import "core:log"
import "core:testing"
import lua "vendor:lua/5.4"


LUA_SOURCE :: `
message = "find me"
`

LUA_ACTION :: `
value = 1
value = value + 1
`


@(test)
lua_test :: proc(t: ^testing.T) {
    L: ^lua.State = lua.L_newstate()
    defer lua.close(L)

    status: lua.Status = lua.L_loadstring(L, LUA_SOURCE)
    testing.expect(t, status == .OK, "Error loading source")

    call_status: i32 = lua.pcall(L, 0, 0, 0)
    testing.expect(t, lua.Status(call_status) == .OK, "Error running source")

    stack := lua.getglobal(L, "message")
    testing.expect(t, stack == i32(lua.TSTRING), "Cannot find variable")

    val := lua.tostring(L, 1)
    testing.expect(t, val == "find me", "Cannot convert stack to cstring")

    lua.settop(L, 0)
    testing.expect(t, lua.gettop(L) == 0, "Cannot clear stack")
}

@(test)
test_print :: proc(t: ^testing.T) {
    L: ^lua.State = lua.L_newstate()
    defer lua.close(L)

    lua.L_openlibs(L)

    result := lua.L_dostring(L, LUA_ACTION)
    testing.expect(t, result == 0, "Result not success.")

    stack := lua.getglobal(L, "value")
    testing.expect(t, stack == i32(lua.TNUMBER), "Cannot find variable")

    value := lua.tointeger(L, 1)
    testing.expect(t, value == 2, "Cannot convert stack to int")

    lua.settop(L, 0)
    testing.expect(t, lua.gettop(L) == 0, "Cannot clear stack")
}