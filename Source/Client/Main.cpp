#include "Frontend.h"
#include "OctaneGUI/OctaneGUI.h"

#include <cstdio>

int main(int argc, char** argv)
{
    (void)argc;
    (void)argv;

    const char* Json = R"({
    "Theme": "Resources/Themes/Dark.json",
    "Windows": {
        "Main": {"Title": "Snippet", "Width": 1280, "Height": 720,
            "MenuBar": {},
            "Body": {"Controls": []}
        }
    }
})";

    OctaneGUI::Application Application;
    Frontend::Initialize(Application);

    std::unordered_map<std::string, OctaneGUI::ControlList> Controls;
    Application.Initialize(Json, Controls);

    return Application.Run();
}
