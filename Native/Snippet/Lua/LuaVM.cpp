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
#include "LuaLibs.h"
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

	// Retrieve the LuaVM upvalue set when the lua_State was initialized.
	int i = lua_upvalueindex(1);
	LuaVM *owner = (LuaVM*)lua_touserdata(L, i);
	if (owner != nullptr)
	{
		owner->AppendBuffer(buffer);
	}

	lua_pop(L, args);

	return 0;
}

static const luaL_Reg base_overrides[] =
{
	{"print", print},
	{nullptr, nullptr}
};

static void PushVariant(lua_State *State, const Variant &Arg)
{
	switch (Arg.get_type())
	{
	case Variant::BOOL: lua_pushboolean(State, (bool)Arg == true ? 1 : 0); break;
	case Variant::INT: lua_pushinteger(State, (int)Arg); break;
	case Variant::REAL: lua_pushnumber(State, (float)Arg); break;
	case Variant::STRING:
		{
			String Data = Arg;
			lua_pushstring(State, Data.ascii().get_data());
		} break;
	case Variant::ARRAY:
		{
			Array Data = Arg;
			lua_newtable(State);
			for (int I = 0; I < Data.size(); I++)
			{
				lua_pushinteger(State, I + 1);
				PushVariant(State, Data[I]);
				lua_settable(State, -3);
			}
		} break;
	default:
		{
			Godot::print("Unhandled Variant: {0}", Arg.get_type());
			lua_pushnil(State);
		} break;
	}
}

static Variant ToVariant(lua_State *State, int Index)
{
	Variant Result;

	switch (lua_type(State, Index))
	{
	case LUA_TBOOLEAN:
		{
			Result = lua_toboolean(State, Index) == 1 ? true : false;
		} break;

	case LUA_TNUMBER:
		{
			if (lua_isinteger(State, Index))
			{
				Result = lua_tointeger(State, Index);
			}
			else
			{
				Result = lua_tonumber(State, Index);
			}
		} break;

	case LUA_TSTRING:
		{
			Result = lua_tostring(State, Index);
		} break;

	case LUA_TTABLE:
		{
			Array Table;

			lua_pushnil(State);
			while (lua_next(State, -2) != 0)
			{
				// Grab the value which should be at the top of the stack.
				Table.append(ToVariant(State, -1));

				// Pop the value. The key should be the only thing left on the stack for the next iteration.
				lua_pop(State, 1);
			}

			Result = Table;
		} break;

	case LUA_TFUNCTION:
		{
			Result = "Function";
		} break;

	default:
		{
			Godot::print("Unhandled Lua type: {0}", lua_type(State, Index));
		} break;
	}

	return Result;
}

static void PrintStack(lua_State *State)
{
	if (State == nullptr)
	{
		Godot::print("Invalid state.");
		return;
	}

	int Size = lua_gettop(State);
	Godot::print("Stack size: {0}", Size);
	for (int I = Size; I > 0; --I)
	{
		Variant Item = ToVariant(State, I);

		if (Item.get_type() == Variant::ARRAY)
		{
			// Printing arrays has been a challenge with GDNative across MSVC and clang-apple.
			// Attempting to use format specifiers directly into the Array variant would only index an
			// element instead of just indexing the whole array, even through it isn't the first item in the list.
			// Due to errors with conversions between Variant and other types on other platforms, a PoolStringArray
			// is used as an intermediary to dump the contents of the array. Could probably update
			// the constructor to allow for this. Will need to investigate further.
			Array Args = Item;
			PoolStringArray Pool(Args);
			Item = Pool;
		}

		Godot::print("   {0}: {1}", I, Item);
	}
}

void LuaVM::_register_methods()
{
	register_method("_process", &LuaVM::_process);
	register_method("Compile", &LuaVM::Compile);
	register_method("Execute", &LuaVM::Execute);
	register_method("Call", &LuaVM::Call);
	register_method("PushArguments", &LuaVM::PushArguments);
	register_method("Reset", &LuaVM::Reset);
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

LuaVM::LuaVM()
	: State(nullptr)
{
}

LuaVM::~LuaVM()
{
	Close();
	Lock = nullptr;
}

void LuaVM::_init()
{
	InitState();
}

void LuaVM::_process(float Delta)
{
	if (!Buffer.empty())
	{
		if (Lock->try_lock() == Error::OK)
		{
			emit_signal((char*)"OnPrint", Buffer);
			Buffer = "";
			Lock->unlock();
		}
	}
}

Ref<LuaResult> LuaVM::Compile(const String &Source)
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

Ref<LuaResult> LuaVM::Execute(const String &Source)
{
	Ref<LuaResult> Result = Ref<LuaResult>(LuaResult::_new());

	if (State == nullptr)
	{
		return Result;
	}

	Buffer = "";

	// Here, we will catch any syntax errors.
	Result->Success = luaL_loadstring(State, Source.ascii().get_data()) == LUA_OK;
	if (!Result->Success)
	{
		Result->Error->Parse(lua_tostring(State, -1), LuaError::TYPE::SYNTAX);
		lua_pop(State, 1);
		return Result;
	}

	Result->Success = lua_pcall_handler(State, 0, LUA_MULTRET) == LUA_OK;
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

Ref<LuaResult> LuaVM::Call(const String &FnName, Variant Args)
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

	PushVariant(State, Args);

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

void LuaVM::PushArguments(const Array &Args)
{
	if (State == nullptr)
	{
		return;
	}

	lua_getglobal(State, "_G");
	for (int I = 0; I < Args.size(); I++)
	{
		PushVariant(State, Args[I]);
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

void LuaVM::AppendBuffer(const String &InBuffer)
{
	Lock->lock();
	Buffer = Buffer + InBuffer + "\n";
	Lock->unlock();
}

bool LuaVM::InitState()
{
	if (State == nullptr)
	{
		State = lua_newstate(alloc, nullptr);
		luaL_openlibs(State);
		LuaLibs::Thread::Open(State);

		lua_getglobal(State, "_G");
		// Set an upvalue for this lua_State to refer back to the owning VM object.
		lua_pushlightuserdata(State, this);
		luaL_setfuncs(State, base_overrides, 1);
		lua_pop(State, 1);
	}

	if (!Lock.is_valid())
	{
		Lock = Ref<Mutex>(Mutex::_new());
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
		Result.append(ToVariant(State, I));
	}

	lua_pop(State, Count);

	return Result;
}

}
