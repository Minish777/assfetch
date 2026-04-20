# assfetch

![Language](https://img.shields.io/badge/asm-x86__64-red)
![License](https://img.shields.io/badge/license-MIT-blue)

Fast and minimal system fetch written in x86_64 assembly. No libc, no bloat, just pure syscalls.

## Features
- **Binary size**: < 2 KB
- **Speed**: Instant execution
- **Theming**: Gruvbox-friendly colors
- **Dynamic**: Parses `/proc/cpuinfo` and `sysinfo` manually

## Build & Install
Requires `nasm`, `make` and `binutils`.

```bash
git clone [https://github.com/your-username/assfetch.git](https://github.com/your-username/assfetch.git)
cd assfetch
make
sudo make install
assfetch