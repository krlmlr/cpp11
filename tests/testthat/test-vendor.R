describe("cpp_vendor", {
  it("errors if cpp11 is not installed", {
    pkg <- local_package()
    mockery::stub(cpp_vendor, "system.file", "")
    expect_error(
      cpp_vendor(pkg_path(pkg)),
      "cpp11 is not installed"
    )
  })

  it("errors if cpp11 is already vendored", {
    pkg <- local_package()
    cpp_vendor(pkg_path(pkg))

    expect_error(
      cpp_vendor(pkg_path(pkg)),
      "already exists"
    )
  })

  it("vendors into subdir", {
    pkg <- local_package()
    p <- pkg_path(pkg)

    cpp_vendor(p, subdir = "src")

    expect_true(file.exists(file.path(p, "src", "cpp11.hpp")))
    expect_true(file.exists(file.path(p, "src", "cpp11", "declarations.hpp")))
    expect_false(dir.exists(file.path(p, "inst", "include", "cpp11")))
  })

  it("errors on a misnamed argument", {
    pkg <- local_package()
    expect_error(
      cpp_vendor(pkg_path(pkg), subdirectory = "src"),
      "must be empty"
    )
  })

  it("vendors cpp11", {
    pkg <- local_package()
    p <- pkg_path(pkg)

    cpp_vendor(pkg_path(pkg))

    expect_true(dir.exists(file.path(p, "inst", "include", "cpp11")))
    expect_true(file.exists(file.path(p, "inst", "include", "cpp11.hpp")))
    expect_true(file.exists(file.path(
      p,
      "inst",
      "include",
      "cpp11",
      "declarations.hpp"
    )))
  })
})
