# homebrew-bronco

Homebrew tap for [Bronco](https://github.com/The-AI-Cowboys-Projects/Bronco) — agentic local-AI creative assistant.

## Install

```bash
brew tap The-AI-Cowboys-Projects/bronco
brew install bronco
```

The formula installs Bronco plus the `[web]` extra (FastAPI/uvicorn) into a private Homebrew-managed virtualenv. The `bronco` and `bronco-web` commands land on your `PATH`.

## After install

```bash
bronco --init                     # generate ~/.bronco/config.toml
ollama serve &                    # in another terminal
ollama pull bronco-creative-v1    # default chat model
bronco-web --port 8888            # then open http://localhost:8888
```

The `bronco --init` command prints platform-specific next steps — on Apple Silicon you'll see the recommended `PYTORCH_ENABLE_MPS_FALLBACK=1` env var; on Intel Macs you'll see a CPU-only warning.

## Optional extras

The base install is intentionally lean. Heavy ML extras pull `torch` / `diffusers` / `chromadb` (multiple GB each) and aren't appropriate for everyone:

```bash
# Find your homebrew bronco virtualenv prefix
PIP=$(brew --prefix bronco)/libexec/bin/pip

$PIP install 'imaginairy>=15.0.0'                                # [image] — SDXL/FLUX via imaginAIry
$PIP install 'diffusers>=0.34.0' 'imageio-ffmpeg>=0.5.0'         # [video] — Wan2.1
$PIP install 'transformers>=4.45.0,<4.60.0' 'sentencepiece'      # [audio] — Bark + MusicGen
$PIP install 'mempalace>=3.3.2'                                  # [memory] — cross-session memory
```

After installing extras, Bronco picks them up automatically — no restart of `bronco-web` required (it inspects the renderer's import surface lazily).

## Updating

```bash
brew update
brew upgrade bronco
```

The tap fetches new tagged releases from [The-AI-Cowboys-Projects/Bronco/releases](https://github.com/The-AI-Cowboys-Projects/Bronco/releases). Bronco is **not** published to PyPI — Homebrew is the only managed install path.

## Hardware compatibility

| Extra | Apple Silicon | Intel Mac | Linux | Notes |
|---|:-:|:-:|:-:|---|
| `[web]` | ✓ | ✓ | ✓ | FastAPI + uvicorn, no GPU needed |
| `[image]` | ✓ MPS | ✗ slow | ✓ | imaginAIry handles SDXL on MPS |
| `[video]` | ✓ MPS (fp16) | ✗ unusable | ✓ CUDA | Wan2.1 1.3B fits on M3 Pro+; 14B needs M3 Max / M2 Ultra / DGX |
| `[audio]` | ✓ MPS | ✗ slow | ✓ | Bark TTS + MusicGen |
| `[memory]` | ✓ | ✓ | ✓ | MemPalace + ChromaDB |
| Fine-tuning | ✗ | ✗ | ✓ CUDA | `bitsandbytes` is CUDA-only |

## Reporting issues

For tap or formula issues: file in this repo.
For Bronco bugs: file in [The-AI-Cowboys-Projects/Bronco/issues](https://github.com/The-AI-Cowboys-Projects/Bronco/issues).
