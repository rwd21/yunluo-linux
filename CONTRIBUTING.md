# Contributing to Yunluo Linux

Thank you for your interest in contributing to Yunluo Linux! This project aims to bring native Arch Linux to the Xiaomi Redmi Pad.

## How to Contribute

### 1. Reporting Issues

- Use GitHub Issues for bug reports and feature requests
- Search existing issues before creating new ones
- Include detailed information:
  - Device model and variant (RAM/storage)
  - Kernel version
  - Steps to reproduce
  - Expected vs actual behavior
  - Logs (dmesg, Xorg.log, etc.)

### 2. Development

Areas where we need help:

#### High Priority
- **Kernel Development**: Device tree configuration, driver patches
- **Hardware Support**: Display, touchscreen, WiFi, audio drivers
- **Testing**: Installing and testing on real devices
- **Documentation**: Improving guides, adding tutorials

#### Medium Priority
- **Build System**: Improving automation scripts
- **Desktop Environment**: Touch-friendly configurations
- **Power Management**: Battery optimization

#### Low Priority
- **Camera Support**: V4L2 drivers
- **Advanced Features**: GPU acceleration optimization

### 3. Code Contributions

1. **Fork** the repository
2. **Create a branch** for your feature:
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Make your changes**:
   - Follow existing code style
   - Test thoroughly on real hardware if possible
   - Add documentation for new features
4. **Commit** with clear messages:
   ```bash
   git commit -m "Add support for feature X"
   ```
5. **Push** to your fork:
   ```bash
   git push origin feature/amazing-feature
   ```
6. **Open a Pull Request**:
   - Describe what you changed and why
   - Reference any related issues
   - Include testing details

### 4. Documentation

- Fix typos and improve clarity
- Add screenshots where helpful
- Translate documentation (future)
- Create video tutorials (appreciated!)

### 5. Testing

Help test on real devices:
- Report hardware compatibility
- Test different installation methods
- Benchmark performance
- Document issues and solutions

## Development Setup

### Prerequisites

```bash
# Arch Linux
sudo pacman -S base-devel git android-tools aarch64-linux-gnu-gcc

# Debian/Ubuntu
sudo apt install build-essential git adb fastboot gcc-aarch64-linux-gnu
```

### Building

```bash
git clone https://github.com/rwd21/yunluo-linux.git
cd yunluo-linux
make info          # Check build environment
make all-build     # Build everything
```

See [BUILDING.md](BUILDING.md) for detailed instructions.

## Code Style

### Shell Scripts
- Use bash for scripts
- Include shebang: `#!/bin/bash`
- Set strict mode: `set -e`
- Add comments for complex logic
- Use meaningful variable names

### C/Kernel Code
- Follow Linux kernel coding style
- Run `checkpatch.pl` on patches
- Keep changes minimal and focused

### Documentation
- Use Markdown format
- Clear, concise language
- Include code examples
- Add table of contents for long docs

## Commit Message Guidelines

Good commit messages help others understand changes:

```
Short summary (50 chars or less)

More detailed explanation if needed. Wrap at 72 characters.
Explain what and why, not how.

- Bullet points are okay
- Use present tense ("Add feature" not "Added feature")
- Reference issues: "Fixes #123" or "Related to #456"
```

Examples:
```
Add WiFi driver support for MT6789

Implement basic WiFi connectivity using mt76 driver.
Includes firmware loading and NetworkManager integration.

Fixes #42
```

## Testing Guidelines

Before submitting:

1. **Test on real hardware** if possible
2. **Check for regressions**: Ensure existing features still work
3. **Document testing**: What you tested and results
4. **Include logs**: For any issues encountered

## Communication

- **GitHub Issues**: Bug reports, feature requests
- **Pull Requests**: Code changes, discussions
- **Discussions**: General questions, ideas

## Code of Conduct

Be respectful and constructive:
- Welcome newcomers
- Help others learn
- Give credit where due
- Accept feedback gracefully
- Focus on the project goals

## Legal

- Contributions are licensed under GPL-3.0
- Only submit code you have rights to
- Respect firmware licenses
- Do not include proprietary code

## Recognition

Contributors will be:
- Listed in project credits
- Mentioned in release notes
- Appreciated by the community!

## Questions?

Feel free to:
- Open a discussion on GitHub
- Ask in an issue (tag with "question")
- Reference this guide in PRs

## Resources

- [BUILDING.md](BUILDING.md) - Build instructions
- [INSTALLATION.md](INSTALLATION.md) - Installation guide
- [HARDWARE.md](HARDWARE.md) - Hardware support status
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
- [Linux Kernel Documentation](https://www.kernel.org/doc/)
- [Arch Linux ARM](https://archlinuxarm.org/)

---

Thank you for contributing to Yunluo Linux! 🎉
