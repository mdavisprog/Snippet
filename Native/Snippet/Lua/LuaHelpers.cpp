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

#include "LuaHelpers.h"

namespace LuaHelpers
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

	void Print(lua_Debug *Ar)
	{
		if (Ar == nullptr)
		{
			return;
		}

		godot::Godot::print("{0}", EventName(Ar->event));
		godot::Godot::print("   name: {0}", Ar->name);
		godot::Godot::print("   namewhat: {0}", Ar->namewhat);
		godot::Godot::print("   what: {0}", Ar->what);
		godot::Godot::print("   line: {0} {1} {2}", Ar->currentline, Ar->linedefined, Ar->lastlinedefined);
		godot::Godot::print("   nups: {0} nparams: {1}", Ar->nups, Ar->nparams);
		godot::Godot::print("   short_src: {0}", Ar->short_src);
		godot::Godot::print("   source: {0}", Ar->source);
	}

	void PushVariant(lua_State *State, godot::Variant Arg)
	{
		switch (Arg.get_type())
		{
			case godot::Variant::BOOL: lua_pushboolean(State, (bool)Arg == true ? 1 : 0); break;
			case godot::Variant::INT: lua_pushinteger(State, (int)Arg); break;
			case godot::Variant::REAL: lua_pushnumber(State, (float)Arg); break;
			case godot::Variant::STRING:
			{
				godot::String Data = Arg;
				lua_pushstring(State, Data.ascii().get_data());
			} break;
			case godot::Variant::ARRAY:
			{
				godot::Array Data = Arg;
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
				godot::Godot::print("Unhandled Variant in PushVariant: {0}", Arg.get_type());
				lua_pushnil(State);
			} break;
		}
	}

	godot::Variant ToVariant(lua_State *State, int Index)
	{
		godot::Variant Result;

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
					Result = (int)lua_tointeger(State, Index);
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
				godot::Array Table;

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

			default: break;
		}

		return Result;
	}

	void PrintStack(lua_State *State)
	{
		if (State == nullptr)
		{
			godot::Godot::print("Invalid state.");
			return;
		}

		int Size = lua_gettop(State);
		godot::Godot::print("Stack size: {0}", Size);
		for (int I = Size; I > 0; --I)
		{
			godot::Variant Item = ToVariant(State, I);

			if (Item.get_type() == godot::Variant::ARRAY)
			{
				// Printing arrays has been a challenge with GDNative across MSVC and clang-apple.
				// Attempting to use format specifiers directly into the Array variant would only index an
				// element instead of just indexing the whole array, even through it isn't the first item in the list.
				// Due to errors with conversions between Variant and other types on other platforms, a PoolStringArray
				// is used as an intermediary to dump the contents of the array. Could probably update
				// the constructor to allow for this. Will need to investigate further.
				godot::Array Args = Item;
				godot::PoolStringArray Pool(Args);
				Item = Pool;
			}

			godot::Godot::print("   {0}: {1}", I, Item);
		}
	}
}
