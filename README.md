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
git clone https://github.com/Minish777/assfetch.git
cd assfetch
make
sudo make install
assfetch
```

## Screenshots

<img width="590" height="304" alt="изображение" src="https://github.com/user-attachments/assets/26827fc7-9454-4ea6-ad05-8f42a7615074" />
<img width="647" height="260" alt="изображение" src="https://github.com/user-attachments/assets/e1c38bdc-714a-445c-8fae-45e05eb6b31c" />
