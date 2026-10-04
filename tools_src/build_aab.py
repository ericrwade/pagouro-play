"""Build the Google Play bundle: build/pagouro-jigsaw.aab, signed with the RELEASE (upload) key.

The keystore and its password live outside every repo, beside the minisign key:
    %USERPROFILE%\\.ssh\\pagouro-jigsaw-release.keystore
    %USERPROFILE%\\.ssh\\pagouro-jigsaw-release.password.txt
They reach Godot only through environment variables for this one run, so nothing secret is written into the project.
Gradle (which the bundle format needs) keeps its downloads in tools/gradle-home, not in the user profile.

    python tools_src/build_aab.py [--install-template]
"""
import os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
KEYDIR = os.path.join(os.path.expanduser("~"), ".ssh")
KS = os.path.join(KEYDIR, "pagouro-jigsaw-release.keystore")
PW = os.path.join(KEYDIR, "pagouro-jigsaw-release.password.txt")
GODOT = os.path.join(ROOT, "tools", "godot-export", "Godot_v4.7.2-stable_win64_console.exe")

env = dict(os.environ)
env["GODOT_ANDROID_KEYSTORE_RELEASE_PATH"] = KS
env["GODOT_ANDROID_KEYSTORE_RELEASE_USER"] = "pagouro-jigsaw"
env["GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD"] = open(PW, encoding="ascii").read().strip()
env["GRADLE_USER_HOME"] = os.path.join(ROOT, "tools", "gradle-home")
env["JAVA_HOME"] = os.path.join(ROOT, "tools", "jdk17")
env["GRADLE_OPTS"] = "-Dorg.gradle.daemon=false"  # a daemon left running holds Godot's output open and the export never returns
cmd = [GODOT, "--headless", "--path", os.path.join(ROOT, "jigsaw")]
if "--install-template" in sys.argv:
    cmd.append("--install-android-build-template")
cmd += ["--export-release", "Android Play", os.path.join(ROOT, "build", "pagouro-jigsaw.aab")]
r = subprocess.run(cmd, env=env, capture_output=True, text=True, errors="replace")
out = (r.stdout + r.stderr).replace(env["GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD"], "<password>")
lines = [l for l in out.splitlines() if l.strip()]
print("\n".join(lines[-40:]))
aab = os.path.join(ROOT, "build", "pagouro-jigsaw.aab")
print("exit", r.returncode, "| aab", os.path.getsize(aab) if os.path.exists(aab) else "missing")
