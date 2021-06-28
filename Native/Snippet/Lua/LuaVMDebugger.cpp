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

#include "LuaVMDebugger.h"
#include "LuaVM.h"

namespace godot
{

const char *EventName(int Event)
{
	switch (Event)
	{
		case LUA_HOOKCALL: return "Call";
		case LUA_HOOKTAILCALL: return "TailCall";
		case LUA_HOOKCOUNT: return "Count";
		case LUA_HOOKLINE: return "Line";
		case LUA_HOOKRET: return "Return";
		default: break;
	}

	return "";
}

static void Print(lua_Debug *Ar)
{
	if (Ar == nullptr)
	{
		return;
	}

	Godot::print("{0}", EventName(Ar->event));
	Godot::print("   name: {0}", Ar->name);
	Godot::print("   namewhat: {0}", Ar->namewhat);
	Godot::print("   what: {0}", Ar->what);
	Godot::print("   line: {0} {1} {2}", Ar->currentline, Ar->linedefined, Ar->lastlinedefined);
	Godot::print("   nups: {0} nparams: {1}", Ar->nups, Ar->nparams);
}

void LuaVMDebugger::hook(lua_State *State, lua_Debug *Ar)
{
	if (lua_getinfo(State, "nSltu", Ar) == 0)
	{
		return;
	}
}

void LuaVMDebugger::_register_methods()
{
}

LuaVMDebugger::LuaVMDebugger()
{
}

LuaVMDebugger::~LuaVMDebugger()
{
}

void LuaVMDebugger::_init()
{
}

void LuaVMDebugger::Hook(lua_State *State)
{
	if (State == nullptr)
	{
		return;
	}

	lua_sethook(State, hook, LUA_MASKCALL | LUA_MASKLINE | LUA_MASKRET, 0);
}

void LuaVMDebugger::Unhook(lua_State *State)
{
	if (State == nullptr)
	{
		return;
	}

	lua_sethook(State, hook, 0, 0);
}

}
