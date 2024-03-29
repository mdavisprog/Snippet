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

#include "OctaneGUI/Controls/Canvas.h"

namespace Snippet
{
namespace Controls
{

class Node;

class Canvas : public OctaneGUI::Canvas
{
    CLASS(Snippet.Canvas);

public:
    enum class Action
    {
        None,
        MoveNodes,
    };

    Canvas(OctaneGUI::Window* Window);

    virtual std::weak_ptr<OctaneGUI::Control> GetControl(const OctaneGUI::Vector2& Point) const override;

    virtual void OnPaint(OctaneGUI::Paint& Brush) const override;
    virtual void OnMouseMove(const OctaneGUI::Vector2& Position) override;
    virtual bool OnMousePressed(const OctaneGUI::Vector2& Position, OctaneGUI::Mouse::Button Button, OctaneGUI::Mouse::Count Count) override;
    virtual void OnMouseReleased(const OctaneGUI::Vector2& Position, OctaneGUI::Mouse::Button Button) override;

private:
    Canvas& SetHovered(const std::shared_ptr<Node>& Hovered);
    Canvas& SetAction(Action Action_);
    Canvas& AddSelected(const std::shared_ptr<Node>& Node_);
    Canvas& ClearSelected();
    Canvas& MoveSelected(const OctaneGUI::Vector2& Delta);
    Canvas& Remove(const std::shared_ptr<Node>& Item);
    Canvas& RemoveSelected(const std::shared_ptr<Node>& Item);

    void PaintSelected(OctaneGUI::Paint& Brush, const std::shared_ptr<Node>& Node_) const;

    std::vector<std::shared_ptr<Node>> m_Nodes {};
    std::vector<std::weak_ptr<Node>> m_Selected {};
    std::weak_ptr<Node> m_Hovered {};
    Action m_Action { Action::None };
    OctaneGUI::Vector2 m_LastMousePos {};
};

}
}
