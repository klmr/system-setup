#'r args = commandArgs(trailingOnly = TRUE)
#'r type = args[1]
#'r items = unlist(strsplit(args[-1], ','))
#'r 
#'r install_module = function (name) {
#'r     # Here we assume is a fully qualified Github project name without release
#'r     # or similar shenanigans, to keep it simple.
#'r     # Replace with modules installer once that exists.
#'r     if (! grepl('^[\\w\\d-]+/[\\w\\d.-]+$', name, perl = TRUE))
#'r         stop('Invalid Github project name: ', dQuote(name))
#'r 
#'r     module_path = getOption('import.path', '.')
#'r     on.exit(setwd(oldwd))
#'r     oldwd = getwd()
#'r     dir.create(module_path, showWarnings = FALSE, recursive = TRUE)
#'r     setwd(module_path)
#'r 
#'r     # To keep dependencies slim, use command line git.
#'r     system2('git', c('clone', sprintf('git@github.com:%s.git', name), name))
#'r }
#'r 
#'r cran_install_package = function (name) {
#'r     # Check if action is required before reinstalling package.
#'r     installed = try(installed.packages()[name, ], silent = TRUE)
#'r     if (inherits(installed, 'try-error')) {
#'r         install = TRUE
#'r     } else {
#'r         available = available.packages()[name, ]
#'r         install = compareVersion(installed['Version'], available['Version']) < 0
#'r     }
#'r 
#'r     if (install)
#'r         install.packages(name)
#'r     else
#'r         message(sprintf('Package %s up to date, skipping', dQuote(name)))
#'r }
#'r 
#'r install_package = function (name) {
#'r     # Assume either a CRAN or an unadorned Github package name.
#'r     # Don’t do sanity check beyond that.
#'r     stopifnot(length(name) == 1)
#'r 
#'r     is_cran = ! grepl('/', name)
#'r     handler = if (is_cran) cran_install_package else devtools::install_github
#'r     handler(name)
#'r }
#'r 
#'r handler = switch(type,
#'r                  module = install_module,
#'r                  modules = install_module,
#'r                  package = install_package,
#'r                  packages = install_package,
#'r                  stop(sprintf('Invalid type %s', dQuote(type))))
#'r 
#'r invisible(lapply(items, handler))

install-r() {
	local type="$1"
	shift
	local IFS=','
	local items="$*"
	Rscript <(grep "^#'r " "$scriptpath/$0" | sed "s/#'r //") "$type" "$items"
}
