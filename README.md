# AsmJit

[AsmJit](https://asmjit.com/) on the [Zig Build System](https://ziglang.org/learn/build-system/).

## Usage

Add this package to `build.zig.zon`:

```sh
zig fetch --save git+https://github.com/KNnut/asmjit
```

And then import `asmjit` in `build.zig` with:

```zig
const asmjit_dep = b.dependency("asmjit", .{
    .target = target,
    .optimize = optimize,
});
lib.root_module.linkLibrary(asmjit_dep.artifact("asmjit"));
```
