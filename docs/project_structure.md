# Project Structure

## Below is the structure of the main directories and files in the project, along with a brief description of their roles:

```text
res://
│
├── 📂 assets/                       # Static game resources and media
│   ├── 📂 UI/                       # UI assets and images
│   ├── 📂 main_menu/                # Specific assets for the main menu
│   ├── 📂 map_elements/             # Map building components (grouped by room)
│   │   ├── 📂 artRoom/
│   │   ├── 📂 cinema/
│   │   ├── 📂 dressingRoom/
│   │   ├── 📂 garden/
│   │   ├── 📂 kitchen/
│   │   ├── 📂 livingRoom/
│   │   ├── 📂 sprites/              # Individual sprite pieces (door, table, wall, window, etc.)
│   │   ├── 📂 toilet/
│   │   └── 📂 trainingRoom/
│   ├── 📂 shaders/                  # Visual effect files (shadows, lighting, materials)
│   ├── 📂 textures/                 # 2D assets, characters, and surfaces
│   └── 📂 tilesets/                 # Tilemap data used for drawing maps
│
├── 📂 autoload/                     # Global Singleton scripts running persistently in the background
│
├── 📂 common/                       # Shared utilities and configurations (constants, enums, etc.)
│
├── 📂 entities/                     # Game entities (characters, objects, tasks)
│   ├── 📂 environment_objects/      # Static decorative objects (grouped by room)
│   │   ├── 📂 art_room/
│   │   ├── 📂 cinema/
│   │   ├── 📂 dressing_room/
│   │   ├── 📂 garden/
│   │   ├── 📂 kitchen/
│   │   ├── 📂 living_room/
│   │   ├── 📂 toilet/
│   │   └── 📂 trainning_room/       
│   ├── 📂 interactable_objects/     # Objects players can interact with (clickable, usable)
│   │   ├── 📂 base/                 # Base classes/scenes for other objects to inherit
│   │   └── 📂 living_room/
│   ├── 📂 player/                   # Player character assets and logic
│   └── 📂 tasks/                    # Task system modules
│       ├── 📂 minigames/            # Minigame scenes and logic for tasks
│       └── 📂 resources/            # Task configuration data files (.tres)
│
├── 📂 scenes/                       # Primary game scenes and user interfaces
│   ├── 📂 art_room/
│   ├── 📂 cinema/
│   ├── 📂 dressing_room/
│   ├── 📂 gameplay_room/            # Main gameplay loop environment
│   ├── 📂 garden/
│   ├── 📂 kitchen/
│   ├── 📂 living_room/
│   ├── 📂 lobby_menu/               # Menu for creating or finding lobbies
│   ├── 📂 main_menu/                # Main menu interface upon starting the game
│   ├── 📂 main_room/
│   ├── 📂 master_room/
│   ├── 📂 toilet/
│   ├── 📂 training_room/
│   └── 📂 waiting_room/             # Pre-game waiting room screen
│
└── 📂 tests/                        # Internal test environments and prototyping scripts


