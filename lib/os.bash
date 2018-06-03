os-architecture() {
  case "$(uname -m)" in
    "x86_64") echo "x64";;
    "x86") echo "ia32";;
  esac
}

os-platform() {
  case "$(uname -s)" in
      Linux)  echo "linux";;
      Darwin) echo "macos";;
  esac
}
