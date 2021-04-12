const std = @import("std");
const CrossTarget = std.zig.CrossTarget;

const x86_32 = CrossTarget{
    .cpu_arch = .i386,
};

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{.whitelist = &[_]CrossTarget{ x86_32 }, .default_target = x86_32});

    const mode = b.standardReleaseOptions();

    const sample = b.addObject("sample1", "src/sample1.zig");
    sample.setTarget(target);
    sample.setBuildMode(.Debug);
    sample.setOutputDir("src");

    const sample = b.addObject("sample2", "src/sample2.zig");
    sample.setTarget(target);
    sample.setBuildMode(.Debug);
    sample.setOutputDir("src");

    const exe = b.addExecutable("UserspaceEmulator", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    exe.step.dependOn(&sample.step);

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
