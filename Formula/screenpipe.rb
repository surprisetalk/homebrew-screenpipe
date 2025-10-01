class Screenpipe < Formula
  desc "Library to build personalized AI powered by what you've seen, said, or heard"
  homepage "https://github.com/mediar-ai/screenpipe"
  version "0.2.74"
  license "MIT"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/mediar-ai/screenpipe/releases/download/v#{version}/screenpipe-#{version}-aarch64-apple-darwin.tar.gz"
      sha256 "27d4e6d529621c3be212a3cba48c3a0fbe04ad5270cd7c6eb4ba21feb121c4dc"
    else
      url "https://github.com/mediar-ai/screenpipe/releases/download/v#{version}/screenpipe-#{version}-x86_64-apple-darwin.tar.gz"
      sha256 "b4142246ddc0b30ebfb085042644dab56032e6288f40c5136c0e2e6a7a2b6f2f"
    end
  elsif OS.linux?
    if Hardware::CPU.intel?
      url "https://github.com/mediar-ai/screenpipe/releases/download/v#{version}/screenpipe-#{version}-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "d2d95ea2ec82779fbc661f1b7feffcccfdfaaa6717d821a4dbcf23583620b770"
    else
      odie "Linux ARM is not supported yet"
    end
  end

  depends_on "ffmpeg"
  depends_on "oven-sh/bun/bun" => :recommended
  
  depends_on macos: :sonoma if OS.mac?
  
  on_linux do
    depends_on "alsa-lib"
  end

  def install
    # Debug: print current directory and contents
    ohai "Current directory:", Dir.pwd
    ohai "Directory contents:", Dir.glob("**/*").join("\n")

    bin.install "bin/screenpipe"

    if Dir.exist?("screenpipe-vision")
      if OS.mac?
        lib.install Dir["screenpipe-vision/lib/*.dylib"]
      elsif OS.linux?
        lib.install Dir["screenpipe-vision/lib/*.so"]
      end
    end

    if OS.mac?
      system "xattr", "-r", "-d", "com.apple.quarantine", bin/"screenpipe" rescue nil
      system "xattr", "-r", "-d", "com.apple.quarantine", lib if lib.exist? rescue nil
    end
  end

  def post_install
    (var/"screenpipe").mkpath
  end

  def caveats
    s = <<~EOS
      Screenpipe has been installed! 🚀
      
      To get started:
      1. Run: screenpipe
      2. On macOS, you'll need to grant permissions for:
         - Screen Recording (System Preferences > Privacy & Security > Screen Recording)
         - Microphone (System Preferences > Privacy & Security > Microphone)
      
      Configuration directory: ~/.screenpipe
      Logs directory: ~/.screenpipe
      
      For more information:
      - Documentation: https://docs.screenpi.pe
      - Discord: https://discord.gg/dU9EBuw7Uq
    EOS

    if OS.mac? && MacOS.version >= :ventura
      s += <<~EOS

        Note: On macOS Ventura and later, you may need to explicitly allow
        the application in System Settings after the first run.
      EOS
    end

    s
  end

  service do
    run [opt_bin/"screenpipe"]
    keep_alive true
    log_path var/"log/screenpipe.log"
    error_log_path var/"log/screenpipe.error.log"
    environment_variables HOME: var/"screenpipe"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/screenpipe --version")
    
    # Test that the binary can at least start (with disabled features for CI)
    output = shell_output("#{bin}/screenpipe --help 2>&1")
    assert_match "screenpipe", output
  end
end
