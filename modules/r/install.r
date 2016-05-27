args = commandArgs(trailingOnly = TRUE)
type = args[1]
items = unlist(strsplit(args[-1], ','))

install_module = function (name) {
    # Here we assume is a fully qualified Github project name without release
    # or similar shenanigans, to keep it simple.
    # Replace with modules installer once that exists.
    if (! grepl('^[\\w\\d-]+/[\\w\\d.-]+$', name, perl = TRUE))
        stop('Invalid Github project name: ', dQuote(name))

    module_path = getOption('import.path', '.')
    on.exit(setwd(oldwd))
    oldwd = getwd()
    dir.create(module_path, showWarnings = FALSE, recursive = TRUE)
    setwd(module_path)

    # To keep dependencies slim, use command line git.
    system2('git', c('clone', sprintf('git@github.com:%s.git', name), name))
}

cran_install_package = function (name) {
    # Check if action is required before reinstalling package.
    installed = try(installed.packages()[name, ], silent = TRUE)
    if (inherits(installed, 'try-error')) {
        install = TRUE
    } else {
        available = available.packages()[name, ]
        install = compareVersion(installed['Version'], available['Version']) < 0
    }

    if (install)
        install.packages(name)
    else
        message(sprintf('Package %s up to date, skipping', dQuote(name)))
}

install_package = function (name) {
    # Assume either a CRAN or an unadorned Github package name.
    # Don’t do sanity check beyond that.
    stopifnot(length(name) == 1)

    is_cran = ! grepl('/', name)
    handler = if (is_cran) cran_install_package else devtools::install_github
    handler(name)
}

handler = switch(type,
                 module = install_module,
                 modules = install_module,
                 package = install_package,
                 packages = install_package,
                 stop(sprintf('Invalid type %s', dQuote(type))))

invisible(lapply(items, handler))
