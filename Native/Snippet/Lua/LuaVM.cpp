/**

MIT License

Copyright (c) 2021 Mitchell Davis <mdavisprog@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#include "LuaVM.h"

#include "LuaError.h"
#include "LuaResult.h"

namespace godot
{

static int print(lua_State *L)
{
	int args = lua_gettop(L);

	String buffer;

	// Remember that Lua indices start at 1.
	for (int i = 1; i <= args; i++)
	{
		buffer += lua_tostring(L, i);
	}

	Godot::print(buffer);

	return 0;
}

static const luaL_Reg base_overrides[] =
{
	{"print", print},
	{nullptr, nullptr}
};

void LuaVM::_register_methods()
{
	register_method("Compile", &LuaVM::Compile);
	register_method("Execute", &LuaVM::Execute);
	register_method("Reset", &LuaVM::Reset);
}

void *LuaVM::alloc(void *ud, void *ptr, size_t osize, size_t nsize)
{
	return api->godot_realloc(ptr, nsize);
}

int LuaVM::handle_error(lua_State *L)
{
	// The code below is taken from db_traceback.

	int arg = 0;
	lua_State *L1 = L;
	if (lua_isthread(L, 1))
	{
		arg = 1;
		L1 = lua_tothread(L, 1);
	}

	const char *msg = lua_tostring(L, arg + 1);
	if (msg == nullptr && !lua_isnoneornil(L, arg + 1))
	{
		lua_pushvalue(L, arg + 1);
	}
	else
	{
		int level = (int)luaL_optinteger(L, arg + 2, (L == L1) ? 1 : 0);
		luaL_traceback(L, L1, msg, level);
	}

	return 1;
}

int LuaVM::lua_pcall_handler(lua_State *L, int nargs, int nresults)
{
	int msgh = lua_gettop(L) - nargs;
	lua_pushcfunction(L, LuaVM::handle_error);
	lua_insert(L, msgh);
	int ret = lua_pcall(L, nargs, nresults, msgh);
	lua_remove(L, msgh);
	return ret;
}

LuaVM::LuaVM()
	: State(nullptr)
{
}

LuaVM::~LuaVM()
{
	Close();
}

void LuaVM::_init()
{
	InitState();
}

Ref<LuaResult> LuaVM::Compile(const String &Source)
{
	LuaResult *Result = LuaResult::_new();

	if (State == nullptr)
	{
		return Result;
	}

	Result->Success = luaL_loadstring(State, Source.ascii().get_data()) == LUA_OK;
	if (!Result->Success)
	{
		Result->Error->Parse(lua_tostring(State, -1), LuaError::TYPE::SYNTAX);
	}

	// Clean the stack.
	lua_pop(State, 1);

	return Result;
}

Ref<LuaResult> LuaVM::Execute(const String &Source)
{
	Ref<LuaResult> Result = Ref<LuaResult>(LuaResult::_new());

	if (State == nullptr)
	{
		return Result;
	}

	// Here, we will catch any syntax errors.
	Result->Success = luaL_loadstring(State, Source.ascii().get_data()) == LUA_OK;
	if (!Result->Success)
	{
		Result->Error->Parse(lua_tostring(State, -1), LuaError::TYPE::SYNTAX);
		lua_pop(State, 1);
		return Result;
	}

	Result->Success = lua_pcall_handler(State, 0, LUA_MULTRET) == LUA_OK;
	if (!Result->Success)
	{
		Result->Error->Parse(lua_tostring(State, -1), LuaError::TYPE::RUNTIME);
		lua_pop(State, 1);
	}
	else
	{
		// TODO: Retrieve return values.
	}

	return Result;
}

void LuaVM::Reset()
{
	Close();
	InitState();
}

bool LuaVM::InitState()
{
	if (State == nullptr)
	{
		State = lua_newstate(alloc, nullptr);
		luaL_openlibs(State);

		lua_getglobal(State, "_G");
		luaL_setfuncs(State, base_overrides, 0);
		lua_pop(State, 1);
	}

	return State != nullptr;
}

void LuaVM::Close()
{
	if (State != nullptr)
	{
		lua_close(State);
		State = nullptr;
	}
}

}
