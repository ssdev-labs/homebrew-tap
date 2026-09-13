cask "notype" do
  version "2.0.1"
  sha256 "78b55d5c99001b45d8f9ce297037e246c25779894c5076c0126cd4412e93972a"

  url "https://github.com/yahuo/NoType/releases/download/v#{version}/NoType-#{version}-macOS.dmg"
  name "NoType"
  desc "Menu bar dictation, translation and realtime voice assistant"
  homepage "https://github.com/yahuo/NoType"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "NoType.app"

  caveats <<~EOS
    This build uses Apple Development signing and is not notarized.
    If macOS blocks its first launch, allow NoType in System Settings > Privacy & Security.

    Codex features require a local Codex login. Allow microphone and accessibility access;
    Neo wake word detection also requires speech recognition permission.
  EOS
end
