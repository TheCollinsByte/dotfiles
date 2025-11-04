- [ ] Dev Software to be installed (Compile. Interpreters and Libraries)
    - [ ] Node/nvm (React, Angular, Vue)
    - [ ] Python
    - [ ] Rust
    - [ ] OCaml
        - Pre-Requists: 
            * Bubblewrap (bwarp)
            * rsync - use rsync and local repositories unless you install the rsync command on your system.
            * hg - use mercurial repositories unless you install the hg command on your system.
            * darcs - use darcs repositories unless you install the darcs command on your system.
    - [ ] Zig
    - [ ] Lua Interpreter
    - [ ] GoLang
    - [ ] Java (OpenJDK)
    - [ ] Gradle
    - [ ] Intellij/Android-Studion
    - [ ] Dart/Flutter
    - [ ] C/C++ Compilers

- [ ] Containerization Software's
    - [ ] Docker/Docker-Composer
    - [ ] Kubernete
    - [ ] kvm ("Type A", "Native", "Bare Metal")
    - [ ] Virtualbox ("Type B", "Hosted")
    - [ ] LXD

- [ ] Network Softwares (Troubleshooting Network Issues and packet sniffer)
    - [ ] whois
    - [ ] tcpdump
    - [ ] wireshark
    - [ ] iftop

- [ ] Software Configuration
    - [ ] curl
    - [ ] Browser (Chrome, Firefox, Suckless Browser(Surf))
    - [ ] git
    - [ ] bash
        - [ ] bash prompt
        - [ ] bash functions

- [X] submodules
    - [X] Suckless Softwares
    - [X] tmux
    - [X] Vim
    - [X] Neovim

- [ ] IRC (Internet Relay Chat)
    - [ ] weechat

- [ ] Terminal/Emulator


- [ ] Wallpaper Script
    - [ ] Wallpaper Shuffle
    - [ ] Wallpaper Slideshow

- [ ] Fonts (Nerd Font)
    - [ ] Font Awesome Icons
    - [ ] Font Formats (ttf, otf, Bitmap)
    - [ ] fc-list
    - [ ] fc-cache or fc-cache -r : updates the font config cache
    - [ ] Path (/usr/share/fonts) (~/.local/share/fonts)

- [ ] Brightness:
    * brillo
    - Up: brillo -A 40
    - Low: brillo -U 40

- [ ] Suckless Software Configurations
    - [ ] DWM
    - [ ] st
    - [ ] dmenu
    

- [ ] Intellij Plugins:
    - sequence Diagram
    - Material Icon
    - Protocol Buffer
    - IdeaVim
    - Indent Rainbow 
    - Key Promoter X 
    - Mario Progress Bar 
    - Google-Java-Format

- [ ] Color Scheme
    - gruvbox dark
    - Monokai Pro
    - Tomorrow Night

- [ ] Distro 
    - Arch Linux
        * AUR Support
    - Ubuntu 
        * snap
        * apt

- [ ] Tools
    - android-tools (adb)
    - Android SDK
    - Tree


- [ ] Functionality
    - [ ] Add dry-run mode to install.sh
      - Add --dry-run flag to preview changes

    - [ ] Improve backup strategy
      - Add option to restore from backup
      - List existing backups before creating new ones
       
    - [ ] Add validation
      - Verify symlinks after creation
      - Check if required dependencies exist before building suckless tools
      
    - [ ] Better package management
      - Create separate package lists per distro
      - Handle package name differences (e.g., fd-find vs fd)

- [ ] Documentation
  - [ ] Add comments to complex sections
    - Document the symlink creation logic
    - Explain submodule handling
     
  - [ ] Create CONTRIBUTING.md 
    - Document how to add new dotfiles
    - Explain the structure
     
  - [ ] Add troubleshooting section to README
    - Common issues and solutions
    - How to rollback changes