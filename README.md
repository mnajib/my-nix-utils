├── lib/
│   ├── my-helpers.nix              # Contains functions for scanning directories
│   └── flake-parts/
│       ├── systems.nix             # flake-parts module to generate nixosConfigurations
│       ├── homes.nix               # flake-parts module to generate homeConfigurations (optional, for standalone Home-Manager)
│       └── modules.nix             # flake-parts module to expose custom modules
