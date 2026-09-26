if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# OpenJDK (Homebrew)
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export JAVA_HOME="/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
