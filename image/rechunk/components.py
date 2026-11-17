#!/usr/bin/env python3
"""Component policy, executed on stdin by Python inside the final rootfs."""
import glob
import fnmatch
import json
import os
import re
import stat
import subprocess


def tag(component, interval, path):
    # RPM file lists can contain absent %ghost paths.
    try:
        mode = os.lstat(path).st_mode
    except FileNotFoundError:
        return False
    # Linux does not support user.* xattrs on symlinks. A component set on
    # their dedicated parent directory still applies through inheritance.
    if not (stat.S_ISREG(mode) or stat.S_ISDIR(mode)):
        return False
    os.setxattr(path, "user.component", component.encode(), follow_symlinks=False)
    os.setxattr(path, "user.update-interval", interval.encode(), follow_symlinks=False)
    return True


def mark(component, interval, patterns):
    for pattern in patterns:
        for path in sorted(glob.glob(pattern)):
            tag(component, interval, path)


def is_mutable(path):
    while True:
        try:
            if os.getxattr(path, "user.component", follow_symlinks=False) == b"mutable":
                return True
        except OSError:
            pass
        if path == "/":
            return False
        path = os.path.dirname(path)


def mark_packages(groups):
    listing = subprocess.check_output(
        ["rpm", "-qa", "--qf", "[%{=NAME}\t%{FILENAMES}\n]"],
        text=True, env={**os.environ, "LC_ALL": "C"},
    )
    records = [line.split("\t", 1) for line in listing.splitlines() if "\t" in line]
    assigned = {}
    for component, rule in groups.items():
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*", component) or component == "mutable":
            raise ValueError(f"invalid or reserved package component name: {component}")
        interval = rule["update_interval"]
        mark(component, interval, rule.get("paths", []))
        for package, path in records:
            if not any(fnmatch.fnmatchcase(package, pattern) for pattern in rule["packages"]):
                continue
            # Canonicalize directory aliases (/lib64, /bin), keeping the leaf
            # intact so symlinks can be skipped rather than dereferenced.
            path = os.path.join(os.path.realpath(os.path.dirname(path)), os.path.basename(path))
            try:
                info = os.lstat(path)
            except FileNotFoundError:
                continue
            # Shared directories must never claim files from unrelated RPMs.
            if not stat.S_ISREG(info.st_mode) or is_mutable(path):
                continue
            inode = (info.st_dev, info.st_ino)
            previous = assigned.setdefault(inode, component)
            if previous != component:
                raise ValueError(f"package groups overlap at {path}: {previous}, {component}")
            tag(component, interval, path)


mark("mutable", "daily", [
    "/usr/lib/sysimage/rpm", "/var/lib/dnf", "/var/cache",
    "/usr/lib/fontconfig/cache", "/etc/ld.so.cache",
    "/usr/share/glib-2.0/schemas/gschemas.compiled",
    "/usr/share/icons/*/icon-theme.cache", "/usr/share/mime/mime.cache",
])
mark_packages(json.loads(os.environ["PACKAGE_GROUPS_JSON"]))
mark("tool-cmake", "monthly", ["/usr/local/cmake-*"])
mark("tool-rustup", "quarterly", ["/usr/local/cargo", "/usr/local/rustup"])
mark("tool-bazelisk", "monthly", ["/usr/local/bin/bazelisk", "/usr/local/bin/bazel"])
mark("tool-uv", "weekly", ["/usr/local/bin/uv", "/usr/local/bin/uvx"])
mark("tool-sccache", "monthly", ["/usr/local/bin/sccache"])
mark("tool-meson", "monthly", [
    "/usr/local/lib*/python*/site-packages/mesonbuild",
    "/usr/local/lib*/python*/site-packages/meson-*.dist-info",
    "/usr/local/bin/meson", "/usr/local/share/man/man1/meson.1",
    "/usr/local/share/polkit-1/actions/com.mesonbuild.install.policy",
])
mark("tool-ninja", "quarterly", [
    "/usr/local/lib*/python*/site-packages/ninja",
    "/usr/local/lib*/python*/site-packages/ninja-*.dist-info",
    "/usr/local/bin/ninja",
])
