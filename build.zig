const std = @import("std");

const Build = std.Build;
const Step = Build.Step;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zig_sources = [_][]const u8{
        "src/good.zig",
        "src/bad.zig",
    };

    for (zig_sources) |source| {
        const lib = b.addLibrary(.{
            .name = "try_make zig",
            .root_module = b.createModule(.{
                .root_source_file = b.path(source),
                .target = target,
                .optimize = optimize,
                .imports = &.{},
            }),
        });

        const did_make = make(b, lib);

        if (did_make) {
            std.debug.print("{s}: success\n", .{source});
        } else {
            std.debug.print("{s} failure\n", .{source});
        }
    }

    const c_sources = [_][]const u8{
        "src/good.c",
        "src/bad.c",
    };

    for (c_sources) |source| {
        const lib = b.addLibrary(.{
            .name = "try_make c",
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
            std.debug.print("{s}: success\n", .{source});
        } else {
            std.debug.print("{s}: failure\n", .{source});
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
