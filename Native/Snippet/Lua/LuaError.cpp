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

#include "LuaError.h"

#include <vector>

namespace godot
{

void LuaError::_register_methods()
{
	register_method("IsSyntax", &LuaError::IsSyntax);
	register_method("IsRuntime", &LuaError::IsRuntime);

	register_property<LuaError, int>("Line", &LuaError::Line, 1);
	register_property<LuaError, String>("Message", &LuaError::Message, "");
	register_property<LuaError, String>("Descriptor", &LuaError::Descriptor, "");
}

LuaError::LuaError()
{
}

LuaError::~LuaError()
{
}

void LuaError::_init()
{
	Line = 1;
	Message = "";
	Descriptor = "";

	// PRIVATE
	Type = TYPE::SYNTAX;
}

bool LuaError::IsSyntax() const
{
	return Type == TYPE::SYNTAX;
}

bool LuaError::IsRuntime() const
{
	return Type == TYPE::RUNTIME;
}

void LuaError::Parse(const String &Contents, TYPE InType)
{
	Message = Contents;
	Type = InType;

	if (Type == TYPE::SYNTAX)
	{
		PoolStringArray Tokens = Contents.split(":", false);

		// Should expect something like this:
		// [type Contents]:Line:Message

		static auto Pop = [](PoolStringArray &Stack)
		{
			String Result = "";

			if (Stack.size() > 0)
			{
				Result = String(Stack[0]);
				Stack.remove(0);
			}

			return Result;
		};

		Descriptor = Pop(Tokens);
		Line = Pop(Tokens).to_int();
		Message = Pop(Tokens);
	}
	else
	{
		// TODO: Need to split error message and parse stack trace.
	}
}

}
