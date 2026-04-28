# homebrew-bronco

Homebrew tap for [Bronco](https://github.com/The-AI-Cowboys-Projects/Bronco) — agentic local-AI creative assistant.

> **Private upstream.** The Bronco source repo is private. This tap pulls source over SSH using your existing GitHub SSH key, so installation only works if your GitHub account has been granted access to the upstream repo.
>
> Verify access first:
>
> ```bash
> git ls-remote git@github.com:The-AI-Cowboys-Projects/Bronco.git HEAD
> ```
>
> If that returns commits, you're set. If it 404s or auth-fails, request access before running the install commands below.

## Install

```bash
# 1. Add the Bronco tap and install
brew tap The-AI-Cowboys-Projects/bronco
brew install bronco

# 3. Start Ollama in the background and pull the default chat model
ollama serve &
ollama pull bronco-creative-v1

# 4. Recommended on Apple Silicon — adds the line to your shell rc
echo 'export PYTORCH_ENABLE_MPS_FALLBACK=1' >> ~/.zshrc
source ~/.zshrc

# 5. Generate config and read the platform-aware next steps
bronco --init

# 6. Launch the web UI
bronco-web --port 8888
```

Open <http://localhost:8888> in your browser.

## Optional extras

The base install includes the web UI but not the heavy ML stacks. Add only what you'll actually use — each pulls multiple GB of dependencies.

```bash
# Locate Bronco's private Homebrew-managed virtualenv
PIP=$(brew --prefix bronco)/libexec/bin/pip

$PIP install 'imaginairy>=15.0.0'                            # image generation (SDXL/FLUX)
$PIP install 'diffusers>=0.34.0' 'imageio-ffmpeg>=0.5.0'     # video generation (Wan2.1)
$PIP install 'transformers>=4.45.0,<4.60.0' 'sentencepiece'  # audio generation (Bark + MusicGen)
$PIP install 'mempalace>=3.3.2'                              # cross-session memory
```

Bronco picks extras up automatically on next render — no `bronco-web` restart required.

## What works on Mac

| Workload | Apple Silicon | Intel Mac |
|---|---|---|
| Text agents (chat, document, marketing, design) | ✓ | ✓ |
| Image generation | ✓ via MPS | ✗ unusably slow |
| Video generation (Wan2.1 1.3B) | ✓ via MPS, ~10-20 min per 5 s clip | ✗ |
| Video generation (Wan2.1 14B) | ✓ M3 Max / M2 Ultra only | ✗ |
| Audio generation | ✓ via MPS | ✗ unusably slow |
| Fine-tuning new models | ✗ — `bitsandbytes` is CUDA-only | ✗ |

## Updating

```bash
brew update && brew upgrade bronco
```

The tap pins to a specific Bronco release tag; updates land when the formula bumps. For bleeding edge, `brew install --HEAD bronco` builds against `main` (not recommended for day-to-day; expect occasional breakage).

## Verifying the install

The tap ships an end-to-end smoke-test script. Run it after install (or after a `brew upgrade`):

```bash
bash "$(brew --repo The-AI-Cowboys-Projects/bronco)/scripts/verify-tap.sh"
```

Exits non-zero with a tagged log line on the first failed step.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `brew install bronco` fails with `Permission denied (publickey)` | No SSH access to the private upstream | Verify with the `git ls-remote` command at the top; request access if needed |
| `bronco-web` starts but chat hangs | Ollama not running | `ollama serve &` in another terminal |
| `bronco-web` returns "model not found" | Default model not pulled | `ollama pull bronco-creative-v1` |
| Video / audio agent crashes with an MPS error | `PYTORCH_ENABLE_MPS_FALLBACK` not set | Re-export it in the shell that's running `bronco-web`, or restart the shell after editing `.zshrc` |
| Want to start clean | — | `brew uninstall bronco && brew untap The-AI-Cowboys-Projects/bronco`, then re-run the install |

## Reporting issues

- **Tap or formula problems** (install fails, formula bug): file in this repo.
- **Bronco runtime bugs** (chat output wrong, agent crashes): [Bronco/issues](https://github.com/The-AI-Cowboys-Projects/Bronco/issues).
