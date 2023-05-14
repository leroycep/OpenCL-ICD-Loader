const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const icd_config_header = b.addConfigHeader(.{
        .style = .{ .cmake = .{ .path = "loader/icd_cmake_config.h.in" } },
    }, .{
        .HAVE_SECURE_GETENV = null,
        .HAVE___SECURE_GETENV = null,
    });

    const opencl_headers = b.dependency("OpenCL-Headers", .{
        .target = target,
        .optimize = optimize,
    });

    const opencl = b.addStaticLibrary(.{
        .name = "OpenCL",
        .target = target,
        .optimize = optimize,
    });
    opencl.c_std = .C99;
    opencl.addConfigHeader(icd_config_header);
    opencl.linkLibrary(opencl_headers.artifact("OpenCL"));

    opencl.defineCMacro("CL_TARGET_OPENCL_VERSION", b.option([]const u8, "target-version", "Set the target opencl version (default: 300)") orelse "300");
    opencl.defineCMacro("CL_NO_NON_ICD_DISPATCH_EXTENSION_PROTOTYPES", null);
    opencl.defineCMacro("OPENCL_ICD_LOADER_VERSION_MAJOR", "3");
    opencl.defineCMacro("OPENCL_ICD_LOADER_VERSION_MINOR", "0");
    opencl.defineCMacro("OPENCL_ICD_LOADER_VERSION_REV", "6");

    opencl.addCSourceFiles(&.{
        "loader/icd.c",
        "loader/icd.h",
        "loader/icd_version.h",
        "loader/icd_dispatch.c",
        "loader/icd_dispatch.h",
        "loader/icd_dispatch_generated.c",
        "loader/icd_envvars.h",
        "loader/icd_platform.h",
    }, &.{});
    opencl.addIncludePath("loader");

    if (target.isWindows()) {
        opencl.addCSourceFiles(&.{
            "loader/windows/adapter.h",
            "loader/windows/icd_windows.c",
            "loader/windows/icd_windows.h",
            "loader/windows/icd_windows_dxgk.c",
            "loader/windows/icd_windows_dxgk.h",
            "loader/windows/icd_windows_envvars.c",
            "loader/windows/icd_windows_hkr.c",
            "loader/windows/icd_windows_hkr.h",
            "loader/windows/icd_windows_apppackage.c",
            "loader/windows/icd_windows_apppackage.h",
            "loader/windows/OpenCL.rc",
        }, &.{});
    } else {
        opencl.addCSourceFiles(&.{
            "loader/linux/icd_linux.c",
            "loader/linux/icd_linux_envvars.c",
            // "loader/linux/icd_exports.map",
        }, &.{});
    }

    opencl.linkLibC();
    opencl.linkLibCpp();
    b.installArtifact(opencl);
}
