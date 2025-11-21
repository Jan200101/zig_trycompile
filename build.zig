const std = @import("std");

const Build = std.Build;
const Step = Build.Step;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    test_compiles_zig(b, target, optimize);
    test_compiles_c(b, target, optimize);
    test_linking(b, target, optimize);
}

fn test_compiles_zig(b: *Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const zig_sources = [_][]const u8{
        "src/good.zig",
        "src/bad.zig",
    };

    for (zig_sources) |source| {
        const lib = b.addLibrary(.{
            .name = "test_compiles zig",
            .root_module = b.createModule(.{
                .root_source_file = b.path(source),
                .target = target,
                .optimize = optimize,
                .imports = &.{},
            }),
        });

        const did_make = make(b, lib);

        if (did_make) {
            std.debug.print("test_compiles_zig {s}: success\n", .{source});
        } else {
            std.debug.print("test_compiles_zig {s}: failure\n", .{source});
        }
    }
}

fn test_compiles_c(b: *Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const c_sources = [_][]const u8{
        "src/good.c",
        "src/bad.c",
    };

    for (c_sources) |source| {
        const lib = b.addLibrary(.{
            .name = "test_compiles_c",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });

        lib.addCSourceFiles(.{
            .files = &.{
                source,
            },
        });

        const did_make = make(b, lib);

        if (did_make) {
            std.debug.print("test_compiles_c {s}: success\n", .{source});
        } else {
            std.debug.print("test_compiles_c {s}: failure\n", .{source});
        }
    }
}

fn test_linking(b: *Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const test_syslibs = [_][]const u8{
        "libcurl",
        "sdl3",
        "invalid",
    };

    for (test_syslibs) |syslib| {
        const lib = b.addLibrary(.{
            .name = "try_make zig",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/good.zig"),
                .target = target,
                .optimize = optimize,
                .imports = &.{},
            }),
        });
        lib.linkSystemLibrary2(syslib, .{
            .needed = true,
        });

        const did_make = make(b, lib);

        if (did_make) {
            std.debug.print("test_linking {s}: success\n", .{syslib});
        } else {
            std.debug.print("test_linking {s}: failure\n", .{syslib});
        }
    }
}

fn make(b: *Build, artifact: *Step.Compile) bool {
    const allocator = b.allocator;

    var thread_pool: std.Thread.Pool = undefined;
    thread_pool.init(.{
        .allocator = allocator,
        .n_jobs = 1,
    }) catch return false;
    defer thread_pool.deinit();

    artifact.step.make(.{
        .progress_node = .none,
        .thread_pool = &thread_pool,
        .watch = false,
        .web_server = null,
        .gpa = allocator,
    }) catch {
        return false;
    };

    return true;
}
