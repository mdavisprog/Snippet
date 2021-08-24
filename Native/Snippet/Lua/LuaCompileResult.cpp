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

#include "LuaCompileResult.h"
#include "LuaError.h"
#include "LuaHelpers.h"

namespace godot
{

void LuaCompileResult::_register_methods()
{
	register_method("GetError", &LuaCompileResult::GetError);

	register_property<LuaCompileResult, bool>("Success", &LuaCompileResult::SetSuccess, &LuaCompileResult::IsSuccess, false);
	register_property<LuaCompileResult, Dictionary>("Symbols", &LuaCompileResult::SetSymbols, &LuaCompileResult::GetSymbols, Dictionary());
	register_property<LuaCompileResult, PoolStringArray>("FunctionCalls", &LuaCompileResult::SetFunctionCalls, &LuaCompileResult::GetFunctionCalls, PoolStringArray());
}

LuaCompileResult::LuaCompileResult()
{
}

LuaCompileResult::~LuaCompileResult()
{
}

void LuaCompileResult::_init()
{
	Success = false;
	Symbols = Dictionary();
	FunctionCalls = PoolStringArray();
	Error = Ref<LuaError>(LuaError::_new());
}

void LuaCompileResult::ParseSymbols(lua_State *State)
{
	if (State == nullptr)
	{
		return;
	}

	lua_pushglobaltable(State);
	Symbols = LuaHelpers::ParseSymbols(State);
	lua_pop(State, 1);
}

void LuaCompileResult::SetSuccess(bool InSuccess)
{
	Success = InSuccess;
}

bool LuaCompileResult::IsSuccess() const
{
	return Success;
}

Ref<LuaError> LuaCompileResult::GetError() const
{
	return Error;
}

void LuaCompileResult::SetSymbols(Dictionary InSymbols)
{
	// Do nothing.
}

Dictionary LuaCompileResult::GetSymbols() const
{
	return Symbols;
}

void LuaCompileResult::SetFunctionCalls(PoolStringArray InFunctionCalls)
{
	FunctionCalls = InFunctionCalls;
}

PoolStringArray LuaCompileResult::GetFunctionCalls() const
{
	return FunctionCalls;
}

}
