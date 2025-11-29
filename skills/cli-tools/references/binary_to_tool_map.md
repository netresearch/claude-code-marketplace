# Binary to Tool Mapping

When a "command not found" error occurs, use this mapping to find the correct catalog entry.

## Direct Mappings (binary_name differs from catalog name)

| Binary | Catalog Entry | Notes |
|--------|---------------|-------|
| `rg` | `ripgrep` | ripgrep search tool |
| `ansible` | `ansible-core` | Ansible automation |
| `docker` | `compose` | Docker Compose (not Docker daemon) |
| `file-rename` | `prename` | Perl rename utility |
| `python3` | `python` | Python interpreter |
| `rustc` | `rust` | Rust compiler (install via rustup) |

## Common Aliases (same catalog name, common confusion)

| Command | Catalog Entry | Install Method |
|---------|---------------|----------------|
| `fd` | `fd` | fd-find on Debian/Ubuntu |
| `bat` | `bat` | batcat on Debian/Ubuntu |
| `fdfind` | `fd` | Debian alias for fd |
| `batcat` | `bat` | Debian alias for bat |
| `cargo` | `rust` | Install rust to get cargo |
| `node` | `node` | Via nvm preferred |
| `npm` | `npm` | Comes with node |
| `pip3` | `pip` | Python package manager |
| `pip` | `pip` | Python package manager |

## Lookup Algorithm

```
1. Check if binary name exists in catalog/*.json directly
2. Check binary_to_tool_map for alias
3. Check common variations:
   - tool3 → tool (e.g., python3 → python)
   - toolcat → tool (e.g., batcat → bat)
   - toolfind → tool (e.g., fdfind → fd)
4. If not found, search catalog descriptions
```

## Package Manager Binaries

These tools come from installing their parent:

| Binary | Install Via |
|--------|-------------|
| `cargo`, `rustc`, `rustup` | `rust` |
| `go`, `gofmt` | `go` |
| `node`, `npm`, `npx` | `node` |
| `python3`, `pip3` | `python` |
| `ruby`, `gem`, `irb` | `ruby` |
| `php`, `php-cli` | `php` |
| `composer` | `composer` (requires php) |
