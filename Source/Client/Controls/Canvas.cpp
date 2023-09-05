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

#include "Canvas.h"
#include "Document.h"
#include "Node.h"
#include "OctaneGUI/OctaneGUI.h"

namespace Snippet
{
namespace Controls
{

Canvas::Canvas(OctaneGUI::Window* Window)
    : OctaneGUI::Canvas(Window)
{
    SetOnCreateContextMenu([this](OctaneGUI::Control&, const std::shared_ptr<OctaneGUI::Menu>& ContextMenu) -> void
        {
            if (m_Hovered.expired())
            {
                ContextMenu->AddItem("New Snippet", [this]() -> void
                    {
                        const std::shared_ptr<Node> Node_ = Scrollable()->AddControl<Node>();
                        Node_
                            ->EditName()
                            .SetPosition(GetWindow()->GetMousePosition());
                        
                        m_Nodes.push_back(Node_);
                    });
            }
            else
            {
                ContextMenu
                    ->AddItem("Rename", [this]() -> void
                        {
                            m_Hovered.lock()->EditName();
                        })
                    .AddItem("Delete", [this]() -> void
                        {
                            Remove(m_Hovered.lock());
                        });
            }
        });

    Interaction()->SetAlwaysFocus(true);
}

std::weak_ptr<OctaneGUI::Control> Canvas::GetControl(const OctaneGUI::Vector2&) const
{
    return Interaction();
}

void Canvas::OnPaint(OctaneGUI::Paint& Brush) const
{
    OctaneGUI::Canvas::OnPaint(Brush);

    PaintSelected(Brush, m_Hovered.lock());

    for (const std::weak_ptr<Node>& Selected : m_Selected)
    {
        PaintSelected(Brush, Selected.lock());
    }
}

void Canvas::OnMouseMove(const OctaneGUI::Vector2& Position)
{
    OctaneGUI::Canvas::OnMouseMove(Position);

    const OctaneGUI::Vector2 Delta { Position - m_LastMousePos };
    m_LastMousePos = Position;

    switch (m_Action)
    {
    case Action::MoveNodes:
    {
        MoveSelected(Delta);
    }
    break;

    case Action::None:
    {
        if (GetAction() == OctaneGUI::Canvas::Action::None)
        {
            std::shared_ptr<Node> Hovered { nullptr };

            for (const std::shared_ptr<Node>& Node_ : m_Nodes)
            {
                if (Node_->Contains(Position))
                {
                    Hovered = Node_;
                }
            }

            SetHovered(Hovered);
        }
    }
    break;

    default: break;
    }
}

bool Canvas::OnMousePressed(const OctaneGUI::Vector2& Position, OctaneGUI::Mouse::Button Button, OctaneGUI::Mouse::Count Count)
{
    const bool Result { OctaneGUI::Canvas::OnMousePressed(Position, Button, Count) };

    switch (Button)
    {
    case OctaneGUI::Mouse::Button::Left:
    {
        ClearSelected();

        const std::shared_ptr<Node> Hovered { m_Hovered.lock() };
        if (Count == OctaneGUI::Mouse::Count::Single)
        {
            if (Hovered != nullptr)
            {
                SetAction(Action::MoveNodes);
                AddSelected(m_Hovered.lock());
                OctaneGUI::Canvas::SetAction(OctaneGUI::Canvas::Action::None);
            }
            else
            {
                SetAction(Action::None);
            }
        }
        else if (Count == OctaneGUI::Mouse::Count::Double)
        {
            SetAction(Action::None);
            OctaneGUI::Canvas::SetAction(OctaneGUI::Canvas::Action::None);
            Document::Open(GetWindow()->App(), m_Hovered.lock());
        }
    }
    break;

    default: break;
    }

    return Result;
}

void Canvas::OnMouseReleased(const OctaneGUI::Vector2& Position, OctaneGUI::Mouse::Button Button)
{
    OctaneGUI::Canvas::OnMouseReleased(Position, Button);
    SetAction(Action::None);
}

Canvas& Canvas::SetHovered(const std::shared_ptr<Node>& Hovered)
{
    const std::shared_ptr<Node> Previous { m_Hovered.lock() };

    if (Hovered != Previous)
    {
        m_Hovered = Hovered;
        Invalidate();
    }

    return *this;
}

Canvas& Canvas::SetAction(Canvas::Action Action)
{
    if (m_Action != Action)
    {
        m_Action = Action;
    }

    return *this;
}

Canvas& Canvas::AddSelected(const std::shared_ptr<Node>& Node_)
{
    if (Node_ == nullptr)
    {
        return *this;
    }

    bool Found { false };

    for (const std::weak_ptr<Node>& Item : m_Selected)
    {
        if (Item.lock() == Node_)
        {
            Found = true;
            break;
        }
    }

    if (!Found)
    {
        m_Selected.push_back(Node_);
        Invalidate();
    }

    return *this;
}

Canvas& Canvas::ClearSelected()
{
    m_Selected.clear();
    Invalidate();
    return *this;
}

Canvas& Canvas::MoveSelected(const OctaneGUI::Vector2& Delta)
{
    if (m_Selected.empty())
    {
        return *this;
    }

    for (std::vector<std::weak_ptr<Node>>::iterator It = m_Selected.begin(); It != m_Selected.end();)
    {
        const std::shared_ptr<Node> Node_ { (*It).lock() };

        if (Node_ != nullptr)
        {
            const OctaneGUI::Vector2 NodePos { Node_->GetPosition() };
            Node_->SetPosition(NodePos + Delta);
            ++It;
        }
        else
        {
            It = m_Selected.erase(It);
        }
    }

    Invalidate();

    return *this;
}

Canvas& Canvas::Remove(const std::shared_ptr<Node>& Item)
{
    for (std::vector<std::shared_ptr<Node>>::iterator It { m_Nodes.begin() }; It != m_Nodes.end(); ++It)
    {
        if ((*It) == Item)
        {
            m_Nodes.erase(It);
            break;
        }
    }

    Scrollable()->RemoveControl(Item);
    Document::Close(GetWindow()->App(), Item);

    return RemoveSelected(Item);
}

Canvas& Canvas::RemoveSelected(const std::shared_ptr<Node>& Item)
{
    for (std::vector<std::weak_ptr<Node>>::iterator It { m_Selected.begin() }; It != m_Selected.end(); ++It)
    {
        const std::shared_ptr<Node> Node_ { (*It).lock() };

        if (Node_ == Item)
        {
            m_Selected.erase(It);
            break;
        }
    }

    return *this;
}

void Canvas::PaintSelected(OctaneGUI::Paint& Brush, const std::shared_ptr<Node>& Node_) const
{
    if (Node_ == nullptr)
    {
        return;
    }

    Brush.RectangleOutline(Node_->GetAbsoluteBounds(), {255, 255, 0, 255}, 2.0f);
}

}
}
