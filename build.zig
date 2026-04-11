const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "asmjit",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        }),
    });

    const upstream_dep = b.dependency("asmjit", .{
        .target = target,
        .optimize = optimize,
    });
    lib.root_module.addIncludePath(upstream_dep.path(""));
    lib.root_module.addCMacro("ASMJIT_STATIC", "");

    // if (target.result.os.tag == .wasi)
    //     lib.root_module.addCMacro("_WASI_EMULATED_MMAN", "");

    {
        const shm_open = b.option(bool, "shm-open", "Enable the use of shm_open if supported") orelse true;
        const x86_backend = b.option(bool, "x86", "Enable x86/x64 backends") orelse true;
        const aarch64_backend = b.option(bool, "aarch64", "Enable AArch64 backend") orelse true;
        const jit = b.option(bool, "jit", "Enable JIT memory management and asmjit::JitRuntime") orelse true;
        const text = b.option(bool, "text", "Enable everything that contains text") orelse true;
        const logging = b.option(bool, "logging", "Enable asmjit::Logger and asmjit::Formatter") orelse text;
        const introspection = b.option(bool, "introspection", "Enable instruction introspection API") orelse true;
        const builder = b.option(bool, "builder", "Enable Builder functionality") orelse true;
        const stdcxx = b.option(bool, "stdcxx", "Enable stdcxx") orelse true;

        const flags = .{
            shm_open, x86_backend, aarch64_backend, jit,
            text,     logging,     introspection,   builder,
            stdcxx,
        };
        const macros = .{
            "SHM_OPEN", "X86",     "AARCH64",       "JIT",
            "TEXT",     "LOGGING", "INTROSPECTION", "BUILDER",
            "STDCXX",
        };
        inline for (flags, macros) |flag, macro|
            if (!flag)
                lib.root_module.addCMacro("ASMJIT_NO_" ++ macro, "");
    }

    {
        const dirs = .{ "core", "support", "arm", "x86", "ujit" };
        const srcs = .{ core_srcs, support_srcs, arm_srcs, x86_srcs, ujit_srcs };

        inline for (dirs, srcs) |dir, src|
            lib.root_module.addCSourceFiles(.{
                .language = .cpp,
                .root = upstream_dep.path("asmjit/" ++ dir),
                .files = src,
                .flags = &.{
                    "-fvisibility=hidden",
                    "-fno-exceptions",
                    "-fno-rtti",
                    "-fno-math-errno",
                    "-fno-threadsafe-statics",
                    "-fmerge-all-constants",
                },
            });
    }

    lib.installHeadersDirectory(upstream_dep.path("asmjit"), "asmjit", .{});
    b.installArtifact(lib);
}

// asmjit/core
// Core API, backend independent except relocations
const core_srcs = &[_][]const u8{
    "archtraits.cpp",
    "assembler.cpp",
    "builder.cpp",
    "codeholder.cpp",
    "codewriter.cpp",
    "compiler.cpp",
    "constpool.cpp",
    "cpuinfo.cpp",
    "emithelper.cpp",
    "emitter.cpp",
    "emitterutils.cpp",
    "environment.cpp",
    "errorhandler.cpp",
    "formatter.cpp",
    "func.cpp",
    "funcargscontext.cpp",
    "globals.cpp",
    "inst.cpp",
    "instdb.cpp",
    "jitallocator.cpp",
    "jitruntime.cpp",
    "logger.cpp",
    "operand.cpp",
    "osutils.cpp",
    "ralocal.cpp",
    "rapass.cpp",
    "rastack.cpp",
    "string.cpp",
    "target.cpp",
    "type.cpp",
    "virtmem.cpp",
};

// asmjit/support
// Support classes and functions
const support_srcs = &[_][]const u8{
    "arena.cpp",
    "arenabitset.cpp",
    "arenahash.cpp",
    "arenalist.cpp",
    "arenatree.cpp",
    "arenavector.cpp",
    "support.cpp",
};

// asmjit/arm
// ARM specific API, designed to be common for both AArch32 and AArch64
const arm_srcs = &[_][]const u8{
    "a64assembler.cpp",
    "a64builder.cpp",
    "a64compiler.cpp",
    "a64emithelper.cpp",
    "a64formatter.cpp",
    "a64func.cpp",
    "a64instapi.cpp",
    "a64instdb.cpp",
    "a64operand.cpp",
    "a64rapass.cpp",
    "armformatter.cpp",
};

// asmjit/x86
// x86 specific API, used only by x86 and x64 backends
const x86_srcs = &[_][]const u8{
    "x86assembler.cpp",
    "x86builder.cpp",
    "x86compiler.cpp",
    "x86emithelper.cpp",
    "x86formatter.cpp",
    "x86func.cpp",
    "x86instapi.cpp",
    "x86instdb.cpp",
    "x86operand.cpp",
    "x86rapass.cpp",
};

// asmjit/ujit
// Universal JIT API
const ujit_srcs = &[_][]const u8{
    "unicompiler_a64.cpp",
    "unicompiler_x86.cpp",
    "vecconsttable.cpp",
};
