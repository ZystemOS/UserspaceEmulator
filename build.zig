const std = @import("std");
const CrossTarget = std.zig.CrossTarget;

const x86_32 = CrossTarget{
    .cpu_arch = .i386,
};

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{.whitelist = &[_]CrossTarget{ x86_32 }, .default_target = x86_32});

    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("UserspaceEmulator", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const samples = &[_][]const u8{ "sample1", "sample2", "sample3" };

    inline for (samples) |sample| {
        const sample_obj = b.addObject(sample, "src/" ++ sample ++ ".zig");
        sample_obj.setTarget(target);
        sample_obj.setBuildMode(.Debug);
        sample_obj.setOutputDir("sample_bin");
        exe.step.dependOn(&sample_obj.step);
    }

    const test_step = b.step("test", "Run tests");
    const unit_tests = b.addTest("src/main.zig");
    unit_tests.setTarget(target);
    test_step.dependOn(&unit_tests.step);

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
