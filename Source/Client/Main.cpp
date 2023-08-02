#include "Frontend.h"
#include "OctaneGUI/OctaneGUI.h"

#include <cstdio>

int main(int argc, char** argv)
{
    const char* Json = R"({
    "Theme": "Resources/Themes/Dark.json",
    "Windows": {
        "Main": {"Title": "Snippet", "Width": 1280, "Height": 720,
            "MenuBar": {"Items": [
                {"Text": "File", "ID": "File", "Items": [
                    {"Text": "Quit", "ID": "Quit"}
                ]}
            ]},
            "Body": {"Controls": []}
        }
    }
})";

    OctaneGUI::Application Application;
    Frontend::Initialize(Application);

    std::unordered_map<std::string, OctaneGUI::ControlList> Controls;
    Application
        .SetCommandLine(argc, argv)
        .Initialize(Json, Controls);
    
    Controls["Main"].To<OctaneGUI::MenuItem>("File.Quit")->SetOnPressed([&](const OctaneGUI::TextSelectable&) -> void
        {
            Application.Quit();
        });

    return Application.Run();
}
