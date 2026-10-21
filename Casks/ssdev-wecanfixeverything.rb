cask "ssdev-wecanfixeverything" do
  version "0.11.0"
  sha256 "de2a02f8dfc5683b48483a76b5ece8a0f609fe644a8a0d5bc9a8b814a77bb298"

  url "https://github.com/ssdev-labs/homebrew-tap/releases/download/ssdev-wecanfixeverything-v#{version}/ssdev-wecanfixanything-macos-universal.dmg"
  name "SSDEV 临时协助"
  desc "Temporary, scoped remote troubleshooting channel"
  homepage "https://github.com/ssdev-labs/homebrew-tap"

  livecheck do
    skip "Auto-generated on release."
  end

  depends_on macos: :ventura

  app "WeCanFixEverything.app"
  binary "#{appdir}/WeCanFixEverything.app/Contents/Resources/bin/ssdev-wecanfixeverything-cli"

  caveats <<~EOS
    This build is ad-hoc signed. If macOS blocks its first launch, remove the
    quarantine attribute from this app only, then open it:

      sudo /usr/bin/xattr -dr com.apple.quarantine "/Applications/WeCanFixEverything.app"
      open "/Applications/WeCanFixEverything.app"
  EOS
end
