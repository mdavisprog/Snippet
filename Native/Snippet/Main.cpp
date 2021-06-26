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

#include "Lua/LuaError.h"
#include "Lua/LuaStackTrace.h"
#include "Lua/LuaStackTraceElement.h"
#include "Lua/LuaResult.h"
#include "Lua/LuaVM.h"

extern "C" void GDN_EXPORT snippet_gdnative_init(godot_gdnative_init_options *Options)
{
	godot::Godot::gdnative_init(Options);
}

extern "C" void GDN_EXPORT snippet_gdnative_terminate(godot_gdnative_terminate_options *Options)
{
	godot::Godot::gdnative_terminate(Options);
}

extern "C" void GDN_EXPORT snippet_nativescript_init(void *Handle)
{
	godot::Godot::nativescript_init(Handle);

	godot::register_class<godot::LuaError>();
	godot::register_class<godot::LuaStackTrace>();
	godot::register_class<godot::LuaStackTraceElement>();
	godot::register_class<godot::LuaResult>();
	godot::register_class<godot::LuaVM>();
}
