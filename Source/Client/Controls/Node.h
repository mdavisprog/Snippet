/**

MIT License

Copyright (c) 2022-2023 Mitchell Davis <mdavisprog@gmail.com>

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

#include "OctaneGUI/Controls/HorizontalContainer.h"
#include "OctaneGUI/Controls/Text.h"

namespace OctaneGUI
{
class Text;
class TextInput;
}

namespace Snippet
{
namespace Controls
{

class Node : public OctaneGUI::Container
{
    CLASS(Snippet.Node)

public:
    Node(OctaneGUI::Window* Window);

    Node& SetName(const char32_t* Name);
    Node& EditName();
    const char32_t* Name() const;

private:
    class Header : public OctaneGUI::HorizontalContainer
    {
    public:
        Header(OctaneGUI::Window* Window);

        Header& Set(const char32_t* Value);
        Header& Edit();
        const char32_t* Value() const;

        virtual void Update() override;
    
    private:
        class Label : public OctaneGUI::Text
        {
        public:
            Label(OctaneGUI::Window* Window);

            Label& SetOnEdit(OctaneGUI::OnControlSignature&& Fn);

            virtual bool OnMousePressed(const OctaneGUI::Vector2& Position, OctaneGUI::Mouse::Button Button, OctaneGUI::Mouse::Count Count) override;

        private:
            OctaneGUI::OnControlSignature m_OnEdit { nullptr };
        };

        Header& FinishEdit();

        std::shared_ptr<Label> m_Label { nullptr };
        std::shared_ptr<OctaneGUI::TextInput> m_Input { nullptr };
    };

    void Resize();

    std::shared_ptr<Header> m_Header { nullptr };
};

}
}
