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

#include "LuaStackTrace.h"
#include "LuaStackTraceElement.h"
#include <vector>

namespace godot
{

static String Pop(PoolStringArray &Stack)
{
	String Result = "";

	if (Stack.size() > 0)
	{
		Result = String(Stack[0]);
		Stack.remove(0);
	}

	return Result;
}

void LuaError::_register_methods()
{
	register_method("IsSyntax", &LuaError::IsSyntax);
	register_method("IsRuntime", &LuaError::IsRuntime);
	register_method("GetStackTrace", &LuaError::GetStackTrace);
	register_method("GetTop", &LuaError::GetTop);

	register_property<LuaError, String>("Contents", &LuaError::Contents, "");
}

LuaError::LuaError()
{
}

LuaError::~LuaError()
{
}

void LuaError::_init()
{
	Type = TYPE::SYNTAX;
	StackTrace = Ref<LuaStackTrace>(LuaStackTrace::_new());
	Contents = "";
}

bool LuaError::IsSyntax() const
{
	return Type == TYPE::SYNTAX;
}

bool LuaError::IsRuntime() const
{
	return Type == TYPE::RUNTIME;
}

Ref<LuaStackTrace> LuaError::GetStackTrace() const
{
	return StackTrace;
}

Ref<LuaStackTraceElement> LuaError::GetTop() const
{
	return StackTrace->Top();
}

void LuaError::Parse(const String &InContents, TYPE InType)
{
	Contents = InContents;
	Type = InType;
	StackTrace->Clear();

	if (Type == TYPE::SYNTAX)
	{
		// Should expect something like this:
		// [type Contents]:Line:Message

		// Syntax errors generally shouldn't be described as a call stack.
		Ref<LuaStackTraceElement> Element = CreateElement(Contents);
		if (Element != nullptr)
		{
			StackTrace->Push(Element);
		}
	}
	else
	{
		PoolStringArray Lines = Contents.split("\n", false);

		for (int I = 0; I < Lines.size(); I++)
		{
			const String &Line = Lines[I];
			if (Line == "stack traceback:")
			{
				continue;
			}

			Ref<LuaStackTraceElement> Element = CreateElement(Line);
			if (Element != nullptr)
			{
				// Stack is unwound from top most first so elements need to be pushed onto the internal stack
				// in reverse order.
				StackTrace->PushFront(Element);
			}
		}
	}
}

Ref<LuaStackTraceElement> LuaError::CreateElement(const String &Line) const
{
	if (Line.empty())
	{
		return nullptr;
	}

	PoolStringArray Tokens = Line.split(":", false);
	Ref<LuaStackTraceElement> Element = Ref<LuaStackTraceElement>(LuaStackTraceElement::_new());
	Element->Descriptor = Pop(Tokens);
	Element->Line = Pop(Tokens).to_int();
	Element->Message = Pop(Tokens);
	return Element;
}

}
