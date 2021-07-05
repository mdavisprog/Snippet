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

#include "LuaHelpers.h"
#include "LuaVM.h"
#include "RegEx.hpp"
#include "RegExMatch.hpp"

namespace godot
{

static PoolIntArray GetLineNumbers(lua_State *State, lua_Debug *Ar)
{
	PoolIntArray Result;

	if (State == nullptr)
	{
		return Result;
	}

	if (lua_getinfo(State, "L", Ar) == 0)
	{
		return Result;
	}

	// Check if the top element is a table.
	if (lua_istable(State, -1))
	{
		// This is a table where the line numbers are the indices of the source. The values don't have any meaning.
		lua_pushnil(State);
		while (lua_next(State, -2) != 0)
		{
			Variant Key;

			// Cannot use lua_isstring here as the function will return true for values that can be converted to a string.
			if (lua_type(State, -2) == LUA_TSTRING)
			{
				Key = lua_tostring(State, -2);
			}
			else if (lua_type(State, -2) == LUA_TNUMBER)
			{
				Key = (int)lua_tointeger(State, -2);
			}

			Result.append(Key);

			// Pop the value and leave the key for the next iteration.
			lua_pop(State, 1);
		}

		// Pop the table off of the stack.
		lua_pop(State, 1);
	}

	return Result;
}

static PoolStringArray GetLines(lua_Debug *Ar)
{
	PoolStringArray Result;

	if (Ar == nullptr)
	{
		return Result;
	}

	// The 'source' field should be in the format '@[name]:[source]', so will look for the first ':' character and split.
	// TODO: Find alternative to capturing the source of a function. Might be related to the 'what' field being 'main'.
	String Name;
	String Source = Ar->source;

	String Token = "@";
	if (Source.begins_with(Token))
	{
		// Extract just the source.
		const int Index = Source.find(":");
		if (Index != -1)
		{
			Name = Source.substr(1, Index - 1);
			Source = Source.right(Index + 1);
		}

		// Split into lines.
		Ref<RegEx> Expr = Ref<RegEx>(RegEx::_new());

		// The below expression will include the newline character as we want to capture empty lines as well.
		// These newline characters will be removed when adding to the array.
		Expr->compile("(.*)\n");

		Array Matches = Expr->search_all(Source);
		int End = 0;
		for (int I = 0; I < Matches.size(); I++)
		{
			Ref<RegExMatch> Match = Matches[I];
			Result.append(Match->get_string().trim_suffix("\n"));
			End = Match->get_end();
		}

		// Grab the last remaining line at the end of the buffer.
		if (End < Source.length())
		{
			Result.append(Source.substr(End, Source.length() - End));
		}
	}

	return Result;
}

void LuaVMDebugger::OnHook(lua_State *State, lua_Debug *Ar)
{
	// Fills in the fields for Ar.
	if (lua_getinfo(State, "nSltu", Ar) == 0)
	{
		return;
	}

	if (Ar->currentline > 0 && Ar->event == LUA_HOOKLINE)
	{
		LuaVM *VM = LuaVM::GetVM(State);
		if (VM != nullptr)
		{
			Array Breakpoints = VM->GetDebugger()->GetBreakpoints();
			// Lines are indexed at 0.
			int Index = Ar->currentline - 1;
			
			// If we hit a breakpoint, grab all needed data.
			if (Breakpoints.has(Index))
			{
				// Grab all valid local variables.
				VM->GetDebugger()->ClearVariables();
				const char *Name = nullptr;
				int I = 1;
				do
				{
					// Pushes the value on to the stack if a local is found at the given index.
					Name = lua_getlocal(State, Ar, I++);
					if (Name != nullptr)
					{
						String Temp = Name;
						String Token = "(";
						if (!Temp.begins_with(Token))
						{
							VM->GetDebugger()->SetVariable(Temp, LuaHelpers::ToVariant(State, -1));
						}

						// Pop the value from the stack.
						lua_pop(State, 1);
					}

				} while (Name != nullptr);

				// Grab all declared global variables.
				lua_getglobal(State, "_G");
				lua_pushnil(State);
				while (lua_next(State, -2) != 0)
				{
					// Retrieve the key and make sure to not change the type in-place.
					String Key;
					int Type = lua_type(State, -2);
					if (Type == LUA_TNUMBER)
					{
						Key = (float)lua_tonumber(State, -2);
					}
					else
					{
						Key = lua_tostring(State, -2);
					}

					// For now, we are only interested in basic types.
					Variant Value;
					switch (lua_type(State, -1))
					{
						case LUA_TBOOLEAN: { Value = lua_toboolean(State, -1) == 1; }
						case LUA_TSTRING: { Value = lua_tostring(State, -1); }
						case LUA_TNUMBER:
						{
							if (lua_isinteger(State, -1))
							{
								Value = (int)lua_tointeger(State, -1);
							}
							else
							{
								Value = lua_tonumber(State, -1);
							}
						} break;
						default: break;
					}

					if (Value.get_type() != Variant::Type::NIL)
					{
						if (Key != "_VERSION")
						{
							VM->GetDebugger()->SetVariable(Key, Value);
						}
					}

					lua_pop(State, 1);
				}

				// Pop the global table.
				lua_pop(State, 1);

				VM->GetDebugger()->emit_signal("OnBreak", Index);
				lua_yield(State, 0);
				return;
			}
		}
	}
}

void LuaVMDebugger::_register_methods()
{
	register_method((char*)"SetBreakpoints", &LuaVMDebugger::SetBreakpoints);
	register_method((char*)"GetVariables", &LuaVMDebugger::GetVariables);
	register_signal<LuaVMDebugger>((char*)"OnBreak", "Line", GODOT_VARIANT_TYPE_INT);
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

void LuaVMDebugger::SetBreakpoints(Array InBreakpoints)
{
	Breakpoints = InBreakpoints;
}

Dictionary LuaVMDebugger::GetVariables() const
{
	return Variables;
}

Array LuaVMDebugger::GetBreakpoints() const
{
	return Breakpoints;
}

void LuaVMDebugger::SetVariable(String Name, Variant Value)
{
	Variables[Name] = Value;
}

void LuaVMDebugger::ClearVariables()
{
	Variables.clear();
}

void LuaVMDebugger::Hook(lua_State *State)
{
	if (State == nullptr)
	{
		return;
	}

	lua_sethook(State, OnHook, LUA_MASKCALL | LUA_MASKLINE | LUA_MASKRET, 0);
}

void LuaVMDebugger::Unhook(lua_State *State)
{
	if (State == nullptr)
	{
		return;
	}

	lua_sethook(State, nullptr, 0, 0);
}

}
