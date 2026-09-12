#' Vendor the cpp11 dependency
#'
#' Vendoring is the act of making your own copy of the 3rd party packages your
#' project is using. It is often used in the go language community.
#'
#' This function vendors cpp11 into your package by copying the cpp11
#' headers into the `inst/include` folder of your package and adding
#' 'cpp11 version: XYZ' to the top of the files, where XYZ is the version of
#' cpp11 currently installed on your machine.
#'
#' Pass `subdir` to vendor somewhere else. A package that does not want the
#' headers installed can keep them under `src/`, which leaves nothing of cpp11
#' in the installed package; the generated `src/cpp11.cpp` reaches them by a
#' path relative to `src/`, so only that package's own `PKG_CPPFLAGS` needs to
#' know where they are.
#'
#' If you choose to vendor the headers you should _remove_ `LinkingTo:
#' cpp11` from your DESCRIPTION.
#'
#' **Note**: vendoring places the responsibility of updating the code on
#' **you**. Bugfixes and new features in cpp11 will not be available for your
#' code until you run `cpp_vendor()` again.
#'
#' @inheritParams cpp_register
#' @param ... These dots are for future extensions and must be empty.
#' @param subdir The directory below `path` to vendor into, as a path relative
#'   to `path`. Defaults to `inst/include`, which installs the headers.
#' @param date The date recorded in the `vendored on:` header of each vendored
#'   file. Defaults to the current date; pass a fixed date to make vendoring
#'   reproducible.
#' @param overwrite If `TRUE`, an existing vendored copy is removed first
#'   instead of raising an error.
#' @return The file path to the vendored code (invisibly).
#' @export
#' @examples
#' # create a new directory
#' dir <- tempfile()
#' dir.create(dir)
#'
#' # vendor the cpp11 headers into the directory
#' cpp_vendor(dir)
#'
#' list.files(file.path(dir, "inst", "include", "cpp11"))
#'
#' # cleanup
#' unlink(dir, recursive = TRUE)
cpp_vendor <- function(
  path = ".",
  ...,
  subdir = file.path("inst", "include"),
  date = Sys.Date(),
  overwrite = FALSE
) {
  check_dots_empty(...)

  new <- file.path(path, subdir, "cpp11")

  if (dir.exists(new)) {
    if (overwrite) {
      unlink(new, recursive = TRUE)
    } else {
      stop(
        "'",
        new,
        "' already exists\n * run unlink('",
        new,
        "', recursive = TRUE)",
        call. = FALSE
      )
    }
  }

  dir.create(new, recursive = TRUE, showWarnings = FALSE)

  current <- system.file("include", "cpp11", package = "cpp11")
  if (!nzchar(current)) {
    stop("cpp11 is not installed", call. = FALSE)
  }

  cpp11_version <- utils::packageVersion("cpp11")

  cpp11_header <- sprintf(
    "// cpp11 version: %s\n// vendored on: %s",
    cpp11_version,
    as.Date(date)
  )

  files <- list.files(current, full.names = TRUE)

  writeLines(
    c(
      cpp11_header,
      readLines(system.file("include", "cpp11.hpp", package = "cpp11"))
    ),
    file.path(dirname(new), "cpp11.hpp")
  )

  for (f in files) {
    writeLines(c(cpp11_header, readLines(f)), file.path(new, basename(f)))
  }

  invisible(new)
}

# `cpp_vendor()` takes its options after `...`, so they must be named. Anything
# reaching the dots is a misspelling or a positional argument, and silently
# ignoring it would vendor to the wrong place. rlang has `check_dots_empty()`;
# cpp11 depends on nothing, so this is the base equivalent.
check_dots_empty <- function(...) {
  dots <- list(...)
  if (length(dots) == 0) {
    return(invisible())
  }

  named <- names(dots)
  named <- named[nzchar(named)]

  stop(
    "`...` must be empty.\n",
    if (length(named) > 0) {
      paste0(" * Unexpected argument: `", named[[1]], "`")
    } else {
      " * Arguments after `path` must be named."
    },
    call. = FALSE
  )
}
