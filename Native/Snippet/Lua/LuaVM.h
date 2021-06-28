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

#pragma once

#include "Godot.hpp"
#include "Reference.hpp"
#include "lua.hpp"
#include "Mutex.hpp"

#include <mutex>
#include <condition_variable>

namespace godot
{

class LuaResult;

class LuaVM : public Reference
{
	GODOT_CLASS(LuaVM, Reference)

private:
	lua_State *State;

	std::mutex ConditionLock;
	std::condition_variable Condition;
	bool Shutdown;

public:
	static void _register_methods();
	static void *alloc(void *ud, void *ptr, size_t osize, size_t nsize);
	static int handle_error(lua_State *L);
	static int lua_pcall_handler(lua_State *L, int nargs, int nresults);
	static LuaVM *GetVM(lua_State *State);

	LuaVM();
	~LuaVM();

	void _init();
	Ref<LuaResult> Compile(String Source);
	Ref<LuaResult> Execute(String Source);
	Ref<LuaResult> Call(String FnName, Variant Args);
	void PushArguments(Array Args);
	void Reset();
	void Stop();

	// Native only
	void Pause(lua_State *State, int64_t MSec);

private:
	bool InitState();
	void Close();
	Array GetReturnValues(lua_State *State) const;
};

}
