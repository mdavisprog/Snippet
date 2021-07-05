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
#include "LuaHelpers.h"
#include "LuaLibs.h"
#include "LuaResult.h"
#include "LuaVMDebugger.h"
#include "OS.hpp"

#define VM_KEY "__vm"

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

	// Retrieve the LuaVM upvalue set when the lua_State was initialized.
	LuaVM *owner = LuaVM::GetVM(L);
	if (owner != nullptr)
	{
		owner->emit_signal("OnPrint", buffer);
	}

	lua_pop(L, args);

	return 0;
}

static const luaL_Reg base_overrides[] =
{
	{"print", print},
	{nullptr, nullptr}
};

void LuaVM::_register_methods()
{
	register_method((char*)"Compile", &LuaVM::Compile);
	register_method((char*)"Execute", &LuaVM::Execute);
	register_method((char*)"Call", &LuaVM::Call);
	register_method((char*)"PushArguments", &LuaVM::PushArguments);
	register_method((char*)"Reset", &LuaVM::Reset);
	register_method((char*)"Resume", &LuaVM::Resume);
	register_method((char*)"Stop", &LuaVM::Stop);
	register_method((char*)"AttachDebugger", &LuaVM::AttachDebugger);
	register_method((char*)"GetDebugger", &LuaVM::GetDebugger);
	register_signal<LuaVM>((char*)"OnPrint", "Contents", GODOT_VARIANT_TYPE_STRING);
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

LuaVM *LuaVM::GetVM(lua_State *State)
{
	if (State == nullptr)
	{
		return nullptr;
	}

	LuaVM *Result = nullptr;
	lua_getglobal(State, "_G");
	lua_getfield(State, -1, VM_KEY);
	Result = (LuaVM*)lua_touserdata(State, -1);
	lua_pop(State, 2);

	return Result;
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

Ref<LuaResult> LuaVM::Compile(String Source)
{
	Ref<LuaResult> Result = Ref<LuaResult>(LuaResult::_new());

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

Ref<LuaResult> LuaVM::Execute(String Source, String Name)
{
	Ref<LuaResult> Result = Ref<LuaResult>(LuaResult::_new());

	if (State == nullptr)
	{
		return Result;
	}

	// The coroutine is currently executing.
	if (Coroutine != nullptr)
	{
		return Result;
	}

	Shutdown = false;
	ShouldResume = false;

	// Here, we will catch any syntax errors.
	Result->Success = luaL_loadbuffer(State, Source.ascii().get_data(), Source.ascii().length(), Name.ascii().get_data()) == LUA_OK;
	if (!Result->Success)
	{
		Result->Error->Parse(lua_tostring(State, -1), LuaError::TYPE::SYNTAX);
		lua_pop(State, 1);
		return Result;
	}

	// Create a coroutine so that it can be yielded and resumed.
	Coroutine = lua_newthread(State);

	// Copy the buffer and push on to the top of the stack.
	lua_pushvalue(State, -2);

	// Copy the top value and pop it off of the main stack to the coroutine.
	lua_xmove(State, Coroutine, 1);

	int Ret = LUA_ERRRUN;
	do
	{
		Ret = lua_resume(Coroutine, nullptr, 0);
		
		while (Ret == LUA_YIELD && !ShouldResume)
		{
			OS::get_singleton()->delay_msec(100);

			if (Shutdown)
			{
				Ret = LUA_ERRRUN;
				lua_pushliteral(Coroutine, "Shutdown");
				break;
			}
		}

		ShouldResume = false;

	} while (Ret == LUA_YIELD);

	Result->Success = Ret == LUA_OK;
	if (Result->Success)
	{
		Result->Results = GetReturnValues(Coroutine);
	}
	else
	{
		Result->Error->Parse(lua_tostring(Coroutine, -1), LuaError::TYPE::RUNTIME);
		lua_pop(State, 1);
	}

	// Pop the coroutine and the loaded function object.
	lua_pop(State, 2);

	return Result;
}

Ref<LuaResult> LuaVM::Call(String FnName, Variant Args)
{
	Ref<LuaResult> Result = Ref<LuaResult>(LuaResult::_new());

	if (State == nullptr)
	{
		return Result;
	}

	int Type = lua_getglobal(State, FnName.ascii().get_data());
	if (Type != LUA_TFUNCTION)
	{
		Godot::print_error(FnName.format("Failed to find function {0}.", FnName), "LuaVM::Call", __FILE__, __LINE__);
		return Result;
	}

	LuaHelpers::PushVariant(State, Args);

	Result->Success = lua_pcall_handler(State, 1, LUA_MULTRET) == LUA_OK;
	if (Result->Success)
	{
		Result->Results = GetReturnValues(State);
	}
	else
	{
		Result->Error->Parse(lua_tostring(State, -1), LuaError::TYPE::RUNTIME);
		lua_pop(State, 1);
	}

	return Result;
}

void LuaVM::PushArguments(Array Args)
{
	if (State == nullptr)
	{
		return;
	}

	lua_getglobal(State, "_G");
	for (int I = 0; I < Args.size(); I++)
	{
		LuaHelpers::PushVariant(State, Args[I]);
		String Field = String("arg{0}").format(Array::make(I));
		lua_setfield(State, -2, Field.ascii().get_data());
	}
	lua_pop(State, 1);
}

void LuaVM::Reset()
{
	Close();
	InitState();
}

void LuaVM::Resume()
{
	ShouldResume = true;
}

void LuaVM::Stop()
{
	{
		std::lock_guard<std::mutex> Guard(ConditionLock);
		Shutdown = true;
	}

	Condition.notify_one();

	// Owning thread object must call wait_to_finish().
}

void LuaVM::AttachDebugger()
{
	if (State == nullptr)
	{
		return;
	}

	if (Debugger.is_valid())
	{
		return;
	}

	Debugger = Ref<LuaVMDebugger>(LuaVMDebugger::_new());
	Debugger->Hook(State);
}

Ref<LuaVMDebugger> LuaVM::GetDebugger() const
{
	return Debugger;
}

void LuaVM::Pause(lua_State *State, int64_t MSec)
{
	std::unique_lock<std::mutex> UL(ConditionLock);
	bool Interrupted = Condition.wait_for(UL, std::chrono::milliseconds(MSec), [this]() {return Shutdown;});
	if (Interrupted)
	{
		luaL_error(State, "Interrupted");
	}
}

bool LuaVM::InitState()
{
	if (State == nullptr)
	{
		State = lua_newstate(alloc, nullptr);
		luaL_openlibs(State);

		LuaLibs::VM = this;
		LuaLibs::Thread::Open(State);
		LuaLibs::VM = nullptr;

		lua_getglobal(State, "_G");
		lua_pushlightuserdata(State, this);
		lua_setfield(State, -2, VM_KEY);
		luaL_setfuncs(State, base_overrides, 0);
		lua_pop(State, 1);
		Shutdown = false;
		ShouldResume = false;

		Coroutine = nullptr;
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

Array LuaVM::GetReturnValues(lua_State *State) const
{
	Array Result;

	int Count = lua_gettop(State);

	for (int I = 1; I <= Count; I++)
	{
		Result.append(LuaHelpers::ToVariant(State, I));
	}

	lua_pop(State, Count);

	return Result;
}

}
