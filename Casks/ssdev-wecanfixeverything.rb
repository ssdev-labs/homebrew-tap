cask "ssdev-wecanfixeverything" do
  version "0.7.0"
  sha256 "a815a228911f2f15fcd6d4de191b1ae9a84312dcdf381b7a08dd80ffd4041b02"

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
