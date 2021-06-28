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

#include "LuaLibs.h"

#include "Godot.hpp"
#include "LuaVM.h"
#include "OS.hpp"

namespace LuaLibs
{
    godot::LuaVM *VM = nullptr;

    namespace Thread
    {
        int Sleep(lua_State *State)
        {
            int64_t Duration = 0;

            int Count = lua_gettop(State);
            if (Count > 0)
            {
                Duration = (int64_t)lua_tointeger(State, 1);
            }

            godot::LuaVM *LocalVM = godot::LuaVM::GetVM(State);
            if (LocalVM != nullptr)
            {
                LocalVM->Pause(State, Duration);
            }

            return 0;
        }

        static const luaL_Reg Funcs[] =
        {
            {"sleep", Sleep},
            {nullptr, nullptr}
        };

        int OpenLib(lua_State *State)
        {
            luaL_newlibtable(State, Funcs);
            lua_pushlightuserdata(State, VM);
            luaL_setfuncs(State, Funcs, 1);
            return 1;
        }

        void Open(lua_State *State)
        {
            luaL_requiref(State, "thread", OpenLib, 1);
            lua_pop(State, 1);
        }
    }
}
