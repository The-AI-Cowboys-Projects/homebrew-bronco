class Bronco < Formula
  include Language::Python::Virtualenv

  desc "Agentic local-AI creative assistant — runs against Ollama"
  homepage "https://github.com/The-AI-Cowboys-Projects/Bronco"
  # HTTPS + git strategy — Homebrew cannot use raw git@ SSH strings in ``url``.
  # Private clones still work if GitHub credentials / SSH helper are configured for HTTPS.
  url "https://github.com/The-AI-Cowboys-Projects/Bronco.git",
      using:    :git,
      tag:      "v0.3.0",
      revision: "01c55ee2555066b838793ca85f32773f78a39456"
  license "MIT"
  head "https://github.com/The-AI-Cowboys-Projects/Bronco.git",
       branch: "main",
       using:  :git

  # Runtime requirements:
  #   * python@3.12 — Bronco's pyproject pins ``requires-python = ">=3.12"``.
  #   * ollama     — Bronco's only LLM provider; chat fails without it.
  #   * ffmpeg     — required by the deterministic video / audio agents
  #                  (imageio-ffmpeg + diffusers' export_to_video pipeline).
  depends_on "ffmpeg"
  depends_on "ollama"
  depends_on "python@3.12"

  def install
    # We deliberately don't enumerate every transitive resource as its own
    # ``resource "..." do ... end`` block. Bronco pulls torch / diffusers
    # transitively via the optional extras users may add later, so the
    # exhaustive resource manifest would balloon to hundreds of lines and
    # rot fast. Instead we let pip resolve everything inside Bronco's
    # private virtualenv, which is the same dependency graph CI exercises
    # on every PR.
    virtualenv_create(libexec, "python3.12")

    # Install Bronco itself with the ``[web]`` extra so ``bronco-web``
    # works out of the box. Heavy ML extras (image / video / audio /
    # memory) are documented in the caveats — they pull torch+diffusers
    # which is multiple GB and not appropriate as a default for everyone.
    #
    # Do not use {Virtualenv#pip_install}: it applies Homebrew
    # ``std_pip_args`` (includes ``--no-deps``). This formula intentionally
    # lets pip resolve the full graph from PyPI instead of hundreds of
    # ``resource`` blocks — so we call brewed ``python3.12 -m pip`` targeting
    # the venv (the venv is created ``--without-pip``, so there is no
    # ``libexec/bin/pip`` yet).
    cd buildpath do
      system Formula["python@3.12"].opt_bin/"python3.12", "-m", "pip",
             "--python=#{libexec}/bin/python",
             "install", "-v", "--no-cache-dir", ".[web]"
    end

    # Symlink the entry-point scripts (bronco, bronco-web, bronco-models)
    # into the brew prefix's ``bin``.
    bin.install_symlink Dir[libexec/"bin/bronco*"]
  end

  def caveats
    <<~EOS
      Bronco core + web UI installed. Run:
        bronco --init                     # generate ~/.bronco/config.toml
        ollama serve &                    # in another terminal
        ollama pull bronco-creative-v1    # default chat model
        bronco-web --port 8888            # then open http://localhost:8888

      Optional extras add weight (each pulls torch / diffusers / chromadb)
      (venv has no pip script — use brewed Python’s pip module):
        #{Formula["python@3.12"].opt_bin}/python3.12 -m pip --python=#{libexec}/bin/python install 'imaginairy>=15.0.0'                            # [image]
        #{Formula["python@3.12"].opt_bin}/python3.12 -m pip --python=#{libexec}/bin/python install 'diffusers>=0.34.0' 'imageio-ffmpeg>=0.5.0'     # [video]
        #{Formula["python@3.12"].opt_bin}/python3.12 -m pip --python=#{libexec}/bin/python install 'transformers>=4.45.0,<4.60.0' 'sentencepiece' # [audio]
        #{Formula["python@3.12"].opt_bin}/python3.12 -m pip --python=#{libexec}/bin/python install 'mempalace>=3.3.2'                              # [memory]

      Apple Silicon: add this to your shell rc so unsupported MPS
      operations fall back to CPU instead of erroring:
        export PYTORCH_ENABLE_MPS_FALLBACK=1

      Fine-tuning new models is NOT supported on Mac (bitsandbytes is
      CUDA-only). Inference works; training requires a CUDA host.
    EOS
  end

  test do
    # ``bronco --help`` exits 0 and prints the typer help banner. We don't
    # spin up a model in tests — that'd require Ollama running with a
    # pulled checkpoint, which isn't appropriate for ``brew test``.
    output = shell_output("#{bin}/bronco --help 2>&1")
    assert_match "Bronco", output
  end
end
