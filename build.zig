const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "asmjit",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
            .sanitize_c = .off,
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
        const dirs = .{ "core", "axl", "arm", "x86", "ujit" };
        const srcs = .{ core_srcs, axl_srcs, arm_srcs, x86_srcs, ujit_srcs };

        var cppflags: std.ArrayList([]const u8) = .empty;
        try cppflags.appendSlice(b.allocator, &.{
            "-std=c++20",
            "-fvisibility=hidden",
            "-fno-exceptions",
            "-fno-rtti",
            "-fno-math-errno",
            "-fno-threadsafe-statics",
            "-fno-semantic-interposition",
            "-fno-trapping-math",
            "-fno-finite-math-only",
            "-mllvm",
            "--disable-loop-idiom-all",
        });
        if (optimize != .debug)
            try cppflags.appendSlice(b.allocator, &.{
                "-fmerge-all-constants",
                "-ftree-vectorize",
            });

        inline for (dirs, srcs) |dir, src|
            lib.root_module.addCSourceFiles(.{
                .language = .cpp,
                .root = upstream_dep.path("asmjit/" ++ dir),
                .files = src,
                .flags = cppflags.items,
            });
    }

    lib.installHeadersDirectory(upstream_dep.path("asmjit"), "asmjit", .{});
    b.installArtifact(lib);
}

// asmjit/core
// Core API, backend independent except relocations
const core_srcs = &[_][]const u8{
    "arch_traits.cpp",
    "assembler.cpp",
    "builder.cpp",
    "code_holder.cpp",
    "code_writer.cpp",
    "compiler.cpp",
    "const_pool.cpp",
    "cpu_info.cpp",
    "debug_utils.cpp",
    "emit_helper.cpp",
    "emitter.cpp",
    "emitter_utils.cpp",
    "environment.cpp",
    "error.cpp",
    "error_handler.cpp",
    "formatter.cpp",
    "func.cpp",
    "func_args_context.cpp",
    "inst.cpp",
    "inst_db.cpp",
    "jit_allocator.cpp",
    "jit_runtime.cpp",
    "logger.cpp",
    "os_utils.cpp",
    "ra_local.cpp",
    "ra_pass.cpp",
    "ra_stack.cpp",
    "string.cpp",
    "target.cpp",
    "type.cpp",
    "virt_mem.cpp",
};

// asmjit/axl
// Auxiliary library, low level primitives and utilities
const axl_srcs = &[_][]const u8{
    "arena.cpp",
    "arena_bit_set.cpp",
    "arena_hash.cpp",
    "arena_vector.cpp",
};

// asmjit/arm
// ARM specific API, designed to be common for both AArch32 and AArch64
const arm_srcs = &[_][]const u8{
    "a64_assembler.cpp",
    "a64_builder.cpp",
    "a64_compiler.cpp",
    "a64_emit_helper.cpp",
    "a64_formatter.cpp",
    "a64_func.cpp",
    "a64_inst_api.cpp",
    "a64_inst_db.cpp",
    "a64_ra_pass.cpp",
    "arm_formatter.cpp",
};

// asmjit/x86
// x86 specific API, used only by x86 and x64 backends
const x86_srcs = &[_][]const u8{
    "x86_assembler.cpp",
    "x86_builder.cpp",
    "x86_compiler.cpp",
    "x86_emit_helper.cpp",
    "x86_formatter.cpp",
    "x86_func.cpp",
    "x86_inst_api.cpp",
    "x86_inst_db.cpp",
    "x86_ra_pass.cpp",
};

// asmjit/ujit
// Universal JIT API
const ujit_srcs = &[_][]const u8{
    "uni_compiler_a64.cpp",
    "uni_compiler_x86.cpp",
    "vec_const_table.cpp",
};
