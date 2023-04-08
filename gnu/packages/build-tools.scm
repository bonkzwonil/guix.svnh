;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2017, 2018 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2017 Corentin Bocquillon <corentin@nybble.fr>
;;; Copyright © 2017–2021 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2018 Fis Trivial <ybbs.daans@hotmail.com>
;;; Copyright © 2018 Tomáš Čech <sleep_walker@gnu.org>
;;; Copyright © 2018, 2020 Marius Bakke <mbakke@fastmail.com>
;;; Copyright © 2018 Alex Vong <alexvong1995@gmail.com>
;;; Copyright © 2019, 2020 Brett Gilio <brettg@gnu.org>
;;; Copyright © 2019 Jonathan Brielmaier <jonathan.brielmaier@web.de>
;;; Copyright © 2020 Liliana Marie Prikler <liliana.prikler@gmail.com>
;;; Copyright © 2020 Yuval Kogman <nothingmuch@woobling.org>
;;; Copyright © 2020 Jakub Kądziołka <kuba@kadziolka.net>
;;; Copyright © 2020 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2021 qblade <qblade@protonmail.com>
;;; Copyright © 2021 Maxim Cournoyer <maxim.cournoyer@gmail.com>
;;; Copyright © 2022 Juliana Sims <jtsims@protonmail.com>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages build-tools)
  #:use-module (ice-9 optargs)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix utils)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system copy)
  #:use-module (guix modules)
  #:use-module (gnu packages)
  #:use-module (gnu packages adns)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages check)
  #:use-module (gnu packages code)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages cpp)
  #:use-module (gnu packages cppi)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages lisp)
  #:use-module (gnu packages logging)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages ninja)
  #:use-module (gnu packages package-management)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages pretty-print)
  #:use-module (gnu packages protobuf)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-crypto)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages regex)
  #:use-module (gnu packages rpc)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages unicode)
  #:use-module (gnu packages version-control)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system python))

(define-public bam
  (package
    (name "bam")
    (version "0.5.1")
    (source (origin
              ;; do not use auto-generated tarballs
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/matricks/bam")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "13br735ig7lygvzyfd15fc2rdygrqm503j6xj5xkrl1r7w2wipq6"))))
    (build-system gnu-build-system)
    (arguments
     `(#:make-flags `(,(string-append "CC=" ,(cc-for-target))
                      ,(string-append "INSTALL_PREFIX="
                                      (assoc-ref %outputs "out")))
       #:test-target "test"
       #:phases
       (modify-phases %standard-phases
         (delete 'configure))))
    (native-inputs
     `(("python" ,python-2)))
    (inputs
     (list lua))
    (home-page "https://matricks.github.io/bam/")
    (synopsis "Fast and flexible build system")
    (description "Bam is a fast and flexible build system.  Bam uses Lua to
describe the build process.  It takes its inspiration for the script files
from scons.  While scons focuses on being 100% correct when building, bam
makes a few sacrifices to acquire fast full and incremental build times.")
    (license license:bsd-3)))

(define-public bear
  (package
    (name "bear")
    (version "3.0.20")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/rizsotto/Bear")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0k89ccp9vz3x71w3r2wfpng9b8s0rxp4qr0ch9q32wq6y1ik847j"))))
    (build-system cmake-build-system)
    (arguments
     `(#:phases (modify-phases %standard-phases
                  (add-after 'unpack 'disable-TEST_BEFORE_INSTALL
                    (lambda _
                      (substitute* "CMakeLists.txt"
                        ;; Delete the matching line—and comment out the next.
                        ((".*TEST_(BEFORE_INSTALL|COMMAND).*") "#"))))
                  (add-before 'check 'set-build-environment
                    (lambda _
                      (setenv "CC" "gcc")))
                  (replace 'check
                    ;; TODO: Test configuration is incomplete.
                    (lambda* (#:key tests? #:allow-other-keys)
                      (when tests?
                        (invoke "ctest")))))))
    (inputs
     `(("c-ares" ,c-ares)
       ("fmt" ,fmt-8)
       ("grpc" ,grpc)
       ("json-modern-cxx" ,json-modern-cxx)
       ("protobuf" ,protobuf)
       ("python" ,python-wrapper)
       ("re2" ,re2)
       ("spdlog" ,spdlog-1.10)))
    (native-inputs
     `(("abseil-cpp" ,abseil-cpp)
       ("googletest" ,googletest)
       ("openssl" ,openssl)
       ("pkg-config" ,pkg-config)
       ("python-lit" ,python-lit)
       ("zlib" ,zlib)))
    (home-page "https://github.com/rizsotto/Bear")
    (synopsis "Tool for generating a compilation database")
    (description "A JSON compilation database is used in the Clang project to
provide information on how a given compilation unit is processed.  With this,
it is easy to re-run the compilation with alternate programs.  Bear is used to
generate such a compilation database.")
    (license license:gpl3+)))

(define-public bmake
  (package
    (name "bmake")
    (version "20211212")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://www.crufty.net/ftp/pub/sjg/bmake-" version ".tar.gz"))
       (sha256
        (base32 "17lywks7fy5538vwyyvbvxcq5mgnd5si7f2qgw85sgqj7mdr4xdd"))))
    (build-system gnu-build-system)
    (inputs
     (list bash-minimal))
    (native-inputs
     (list coreutils))
    (arguments
     `(#:tests? #f                      ; test during build
       #:phases
       (modify-phases %standard-phases
         (add-after 'configure 'fix-test ; fix from nixpkgs
           (lambda _
             (substitute* "unit-tests/unexport-env.mk"
               (("PATH=\t/bin:/usr/bin:/sbin:/usr/sbin")
                "PATH := ${PATH}"))))
         (add-after 'configure 'remove-fail-tests
           (lambda _
             (substitute* "unit-tests/Makefile"
               (("cmd-interrupt") "")
               (("varmod-localtime") "")))))
       #:configure-flags
       (list
        (string-append
         "--with-defshell=" (assoc-ref %build-inputs "bash") "/bin/bash")
        (string-append
         "--with-default-sys-path=" (assoc-ref %outputs "out") "/share/mk"))
       #:make-flags
       (list "INSTALL=install"))) ;; use coreutils install
    (home-page "http://www.crufty.net/help/sjg/bmake.htm")
    (synopsis "BSD's make")
    (description
     "bmake is a program designed to simplify the maintenance of other
programs.  Its input is a list of specifications as to the files upon which
programs and other files depend.")
    (license license:bsd-3)))

(define-public gn
  (let ((commit "1c4151ff5c1d6fbf7fa800b8d4bb34d3abc03a41")
        (revision "2072"))            ;as returned by `git describe`, used below
    (package
      (name "gn")
      (version (git-version "0.0" revision commit))
      (home-page "https://gn.googlesource.com/gn")
      (source (origin
                (method git-fetch)
                (uri (git-reference (url home-page) (commit commit)))
                (sha256
                 (base32
                  "02621c9nqpr4pwcapy31x36l5kbyd0vdgd0wdaxj5p8hrxk67d6b"))
                (file-name (git-file-name name version))))
      (build-system gnu-build-system)
      (arguments
       (list #:phases
             #~(modify-phases %standard-phases
                 (add-before 'configure 'set-build-environment
                   (lambda _
                     (setenv "CC" "gcc")
                     (setenv "CXX" "g++")
                     (setenv "AR" "ar")))
                 (replace 'configure
                   (lambda _
                     (invoke "python" "build/gen.py"
                             "--no-last-commit-position")))
                 (add-after 'configure 'create-last-commit-position
                   (lambda _
                     ;; Mimic GenerateLastCommitPosition from gen.py.
                     (call-with-output-file "out/last_commit_position.h"
                       (lambda (port)
                         (format port
                                 "// Generated by Guix.

#ifndef OUT_LAST_COMMIT_POSITION_H_
#define OUT_LAST_COMMIT_POSITION_H_

#define LAST_COMMIT_POSITION_NUM ~a
#define LAST_COMMIT_POSITION \"~a (~a)\"

#endif  // OUT_LAST_COMMIT_POSITION_H_
"
                                 #$revision #$revision
                                 #$(string-take commit 12))))))
                 (replace 'build
                   (lambda _
                     (invoke "ninja" "-C" "out" "gn"
                             "-j" (number->string (parallel-job-count)))))
                 (replace 'check
                   (lambda* (#:key tests? #:allow-other-keys)
                     (if tests?
                         (begin
                           (invoke "ninja" "-C" "out" "gn_unittests"
                                   "-j" (number->string (parallel-job-count)))
                           (invoke "./out/gn_unittests"))
                         (format #t "test suite not run~%"))))
                 (replace 'install
                   (lambda _
                     (install-file "out/gn" (string-append #$output "/bin")))))))
      (native-inputs
       (list ninja python-wrapper))
      (synopsis "Generate Ninja build files")
      (description
       "GN is a tool that collects information about a project from @file{.gn}
files and generates build instructions for the Ninja build system.")
      ;; GN is distributed as BSD-3, but bundles some files from ICU using the
      ;; X11 license.
      (license (list license:bsd-3 license:x11)))))

(define-public meson-0.63
  (package
    (name "meson")
    (version "0.63.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/mesonbuild/meson/"
                                  "releases/download/" version  "/meson-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "1gwba75z47m2hv3w08gw8sgqgbknjr7rj1qwr510bgknxwbjy8hn"))))
    (build-system python-build-system)
    (arguments
     `(;; FIXME: Tests require many additional inputs and patching many
       ;; hard-coded file system locations in "run_unittests.py".
       #:tests? #f
       #:phases (modify-phases %standard-phases
                  ;; Meson calls the various executables in out/bin through the
                  ;; Python interpreter, so we cannot use the shell wrapper.
                  (replace 'wrap
                    (lambda* (#:key outputs inputs #:allow-other-keys)
                      (let ((python-version
                             (python-version (assoc-ref inputs "python")))
                            (output (assoc-ref outputs "out")))
                        (substitute* (string-append output "/bin/meson")
                          (("# EASY-INSTALL-ENTRY-SCRIPT")
                           (format #f "\
import sys
sys.path.insert(0, '~a/lib/python~a/site-packages')
# EASY-INSTALL-ENTRY-SCRIPT"
                                   output python-version)))))))))
    (inputs (list python-wrapper ninja))
    (home-page "https://mesonbuild.com/")
    (synopsis "Build system designed to be fast and user-friendly")
    (description
     "The Meson build system is focused on user-friendliness and speed.
It can compile code written in C, C++, Fortran, Java, Rust, and other
languages.  Meson provides features comparable to those of the
Autoconf/Automake/make combo.  Build specifications, also known as @dfn{Meson
files}, are written in a custom domain-specific language (@dfn{DSL}) that
resembles Python.")
    (license license:asl2.0)))

(define-public meson-0.60
  (package
    (inherit meson-0.63)
    (version "0.60.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/mesonbuild/meson/"
                                  "releases/download/" version  "/meson-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "13mrrizg4vl6n5k7fz6amyafnn3i097dcarr552qc0ca6nlmzjl7"))
              (patches (search-patches
                        "meson-allow-dirs-outside-of-prefix.patch"))))))

;;; This older Meson variant is kept for now for gtkmm and others that may
;;; have problems with 0.60.
(define-public meson-0.59
  (package
    (inherit meson-0.60)
    (version "0.59.4")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/mesonbuild/meson/"
                                  "releases/download/" version  "/meson-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "117cm8794h291lca1wljz1pwnzidgbvrpg3mw3np6ksma368hyd7"))
              (patches (search-patches
                        "meson-allow-dirs-outside-of-prefix.patch"))))))

(define-public meson meson-0.63)

(define-public meson-python
  (package
    (name "meson-python")
    (version "0.8.1")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "meson_python" version))
              (sha256
               (base32
                "0k2yn0iws1n184sdznzmfw4xgbqgq5cn02hpc7m0xdaxryj1ybs4"))))
    (build-system python-build-system)
    (arguments
     (list #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'avoid-ninja-dependency
                 (lambda _
                   ;; Avoid dependency on the "ninja" PyPI distribution,
                   ;; which is a meta-package that simply downloads and
                   ;; installs ninja from the web ...
                   (substitute* "pyproject.toml"
                     (("'ninja',")
                      ""))))
               (replace 'build
                 (lambda _
                   ;; ZIP does not support timestamps before 1980.
                   (setenv "SOURCE_DATE_EPOCH" "315532800")
                   (invoke "python" "-m" "build" "--wheel" "--no-isolation" ".")))
               (replace 'install
                 (lambda _
                   (let ((whl (car (find-files "dist" "\\.whl$"))))
                     (invoke "pip" "--no-cache-dir" "--no-input"
                             "install" "--no-deps" "--prefix" #$output whl))))
               (replace 'check
                 (lambda* (#:key tests? #:allow-other-keys)
                   (when tests?
                     (invoke "pytest" "-vv" "tests" "-k"
                             (string-append
                              "not "
                              ;; These tests require a git checkout.
                              (string-join '("test_contents_unstaged"
                                             "test_no_pep621"
                                             "test_pep621"
                                             "test_dynamic_version"
                                             "test_contents"
                                             "test_contents_subdirs")
                                           " and not ")))))))))
    (propagated-inputs
     (list meson
           ninja
           ;; XXX: python-meson forcefully sets the RUNPATH of binaries
           ;; for vendoring purposes, and uses PatchELF for that(!).  This
           ;; functionality is not useful in Guix, but removing this
           ;; dependency is tricky.  There is discussion upstream about making
           ;; it optional, but for now we'll just carry it:
           ;; https://github.com/FFY00/meson-python/issues/125
           patchelf
           python-colorama
           python-pyproject-metadata
           python-tomli
           python-wheel))
    (native-inputs
     (list python-pypa-build
           python-wheel

           ;; For tests.
           pkg-config
           python-gitpython
           python-pytest
           python-pytest-mock))
    (home-page "https://github.com/FFY00/mesonpy")
    (synopsis "Meson-based build backend for Python")
    (description
     "meson-python is a PEP 517 build backend for Meson projects.")
    (license license:expat)))

(define-public premake4
  (package
    (name "premake")
    (version "4.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/premake/Premake/"
                                  version "/premake-" version "-src.zip"))
              (sha256
               (base32
                "1017rd0wsjfyq2jvpjjhpszaa7kmig6q1nimw76qx3cjz2868lrn"))))
    (build-system gnu-build-system)
    (native-inputs
     (list unzip)) ; for unpacking the source
    (arguments
     `(#:make-flags (list (string-append "CC=" ,(cc-for-target)))
       #:tests? #f ; No test suite
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (add-after 'unpack 'enter-source
           (lambda _ (chdir "build/gmake.unix") #t))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (install-file "../../bin/release/premake4"
                           (string-append (assoc-ref outputs "out") "/bin"))
             #t)))))
    (synopsis "Portable software build tool")
    (description "@code{premake4} is a command line utility that reads a
scripted definition of a software project and outputs @file{Makefile}s or
other lower-level build files.")
    (home-page "https://premake.github.io")
    (license license:bsd-3)))

(define-public premake5
  (package
    (inherit premake4)
    (version "5.0.0-alpha15")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/premake/premake-core/"
                                  "releases/download/v" version
                                  "/premake-" version "-src.zip"))
              (sha256
               (base32
                "0lyxfyqxyhjqsb3kmx1fyrxinb26i68hb7w7rg8lajczrgkmc3w8"))))
    (arguments
     (substitute-keyword-arguments (package-arguments premake4)
       ((#:phases phases)
        `(modify-phases ,phases
           (replace 'enter-source
             (lambda _ (chdir "build/gmake2.unix") #t))
           (replace 'install
             (lambda* (#:key outputs #:allow-other-keys)
               (install-file "../../bin/release/premake5"
                             (string-append (assoc-ref outputs "out") "/bin"))
               #t))))))
    (description "@code{premake5} is a command line utility that reads a
scripted definition of a software project and outputs @file{Makefile}s or
other lower-level build files.")))

(define-public scons
  (package
    (name "scons")
    (version "4.4.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/SCons/scons")
                    (commit version)))
              (file-name (git-file-name name version))
              (patches (search-patches "scons-test-environment.patch"))
              (sha256
               (base32
                "1czswx1fj2j48rspkrvarkr43k0vii9rsmz054c9yby1dq362fgr"))))
    (build-system python-build-system)
    (arguments
     (list
      #:modules (append %python-build-system-modules
                        '((ice-9 ftw) (srfi srfi-26)))
      #:phases
      #~(modify-phases (@ (guix build python-build-system) %standard-phases)
          (add-after 'unpack 'adjust-hard-coded-paths
            (lambda _
              (substitute* "SCons/Script/Main.py"
                (("/usr/share/scons")
                 (string-append #$output "/share/scons")))))
          (add-before 'build 'bootstrap
            (lambda _
              ;; XXX: Otherwise setup.py bdist_wheel fails.
              (setenv "PYTHONPATH" (getenv "GUIX_PYTHONPATH"))
              (invoke "python" "scripts/scons.py")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "python" "runtest.py" "--all" "--unit-only"))))
          (add-after 'install 'move-manuals
            (lambda _
              ;; XXX: For some reason manuals get installed to the top-level
              ;; #$output directory.
              (with-directory-excursion #$output
                (let ((man1 (string-append #$output "/share/man/man1"))
                      (stray-manuals (scandir "."
                                              (cut string-suffix? ".1" <>))))
                  (mkdir-p man1)
                  (for-each (lambda (manual)
                              (link manual (string-append man1 "/" manual))
                              (delete-file manual))
                            stray-manuals))))))))
    (native-inputs
     ;; TODO: Add 'fop' when available in Guix to generate manuals.
     (list python-wheel
           ;;For tests.
           python-psutil))
    (home-page "https://scons.org/")
    (synopsis "Software construction tool written in Python")
    (description
     "SCons is a software construction tool.  Think of SCons as an improved,
cross-platform substitute for the classic Make utility with integrated
functionality similar to autoconf/automake and compiler caches such as ccache.
In short, SCons is an easier, more reliable and faster way to build
software.")
    (license license:x11)))

(define-public scons-3
  (package
    (inherit scons)
    (version "3.0.4")
    (source (origin
             (method git-fetch)
             (uri (git-reference
                   (url "https://github.com/SCons/scons")
                   (commit version)))
             (file-name (git-file-name "scons" version))
             (sha256
              (base32
               "1xy8jrwz87y589ihcld4hv7wn122sjbz914xn8h50ww77wbhk8hn"))))
    (arguments
     `(#:use-setuptools? #f                ; still relies on distutils
       #:tests? #f                         ; no 'python setup.py test' command
       #:phases
       (modify-phases %standard-phases
         (add-before 'build 'bootstrap
           (lambda _
             (substitute* "src/engine/SCons/compat/__init__.py"
               (("sys.modules\\[new\\] = imp.load_module\\(old, \\*imp.find_module\\(old\\)\\)")
                "sys.modules[new] = __import__(old)"))
             (substitute* "src/engine/SCons/Platform/__init__.py"
               (("mod = imp.load_module\\(full_name, file, path, desc\\)")
                "mod = __import__(full_name)"))
             (invoke "python" "bootstrap.py" "build/scons" "DEVELOPER=guix")
             (chdir "build/scons")
             #t)))))
    (native-inputs '())))

(define-public scons-python2
  (package
    (inherit (package-with-python2 scons-3))
    (name "scons-python2")))

(define-public tup
  (package
    (name "tup")
    (version "0.7.9")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://gittup.org/tup/releases/tup-v"
                                  version ".tar.gz"))
              (sha256
               (base32
                "0gnd2598xqgwihdkfkx7qn0q6p4n7npam1fy83mp7s04zwj99syc"))
              (patches (search-patches "tup-unbundle-dependencies.patch"))
              (modules '((guix build utils)))
              (snippet
               '(begin
                  ;; NOTE: Tup uses a slightly modified Lua, so it cannot be
                  ;; unbundled.  See: src/lula/tup-lua.patch
                  (delete-file-recursively "src/pcre")
                  (delete-file-recursively "src/sqlite3")
                  #t))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         ;; There is a bootstrap script, but it doesn't do what you think - it
         ;; builds tup.
         (delete 'bootstrap)
         (replace 'configure
           (lambda _
             (substitute* "src/tup/link.sh"
               (("`git describe`") ,version))
             (with-output-to-file "tup.config"
               (lambda _
                 (format #t "CONFIG_TUP_USE_SYSTEM_SQLITE=y~%")))
             #t))
         (delete 'check)
         (replace 'build
           (lambda _
             ;; Based on bootstrap-nofuse.sh, but with a detour to patch-shebang.
             (invoke "./build.sh")
             (invoke "./build/tup" "init")
             (invoke "./build/tup" "generate" "--verbose" "build-nofuse.sh")
             (patch-shebang "build-nofuse.sh")
             (invoke "./build-nofuse.sh")))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((outdir (assoc-ref outputs "out"))
                    (ftdetect (string-append outdir
                                             "/share/vim/vimfiles/ftdetect")))
               (install-file "tup" (string-append outdir "/bin"))
               (install-file "tup.1" (string-append outdir "/share/man/man1"))
               (install-file "contrib/syntax/tup.vim"
                             (string-append outdir "/share/vim/vimfiles/syntax"))
               (mkdir-p ftdetect)
               (with-output-to-file (string-append ftdetect "/tup.vim")
                 (lambda _
                   (display "au BufNewFile,BufRead Tupfile,*.tup setf tup")))
               #t))))))
    (inputs
     (list fuse pcre
           `(,pcre "bin") ; pcre-config
           sqlite))
    (native-inputs
     (list pkg-config))
    (home-page "https://gittup.org/tup/")
    (synopsis "Fast build system that's hard to get wrong")
    (description "Tup is a generic build system based on a directed acyclic
graphs of commands to be executed.  Tup instruments your build to detect the
exact dependencies of the commands, allowing you to take advantage of ideal
parallelism during incremental builds, and detecting any situations where
a build worked by accident.")
    (license license:gpl2)))

(define-public osc
  (package
    (name "osc")
    (version "0.172.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/openSUSE/osc")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1sqdnkka3c6b6hwnrmlwrgy7w62cp8raq8mph9pgd2lydzzbvwlp"))))
    (build-system python-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'install 'fix-filename
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((bin (string-append (assoc-ref outputs "out") "/bin/")))
               ;; Main osc tool is renamed in spec file, not setup.py, let's
               ;; do that too.
               (rename-file
                (string-append bin "osc-wrapper.py")
                (string-append bin "osc"))
               #t))))))
    (native-inputs
     (list python-chardet))
    (inputs
     (list python-m2crypto python-pycurl rpm))                   ; for python-rpm
    (home-page "https://github.com/openSUSE/osc")
    (synopsis "Open Build Service command line tool")
    (description "@command{osc} is a command line interface to the Open Build
Service.  It allows you to checkout, commit, perform reviews etc.  The vast
majority of the OBS functionality is available via commands and the rest can
be reached via direct API calls.")
    (license license:gpl2+)))

(define-public compiledb
  (package
    (name "compiledb")
    (version "0.10.1")
    (source
      (origin
        (method url-fetch)
        (uri (pypi-uri "compiledb" version))
        (sha256
          (base32 "0vlngsdxfakyl8b7rnvn8h3l216lhbrrydr04yhy6kd03zflgfq6"))))
    (build-system python-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'no-compat-shim-dependency
           ;; shutilwhich is only needed for python 3.3 and earlier
           (lambda _
             (substitute* "setup.py" (("^ *'shutilwhich'\n") ""))
             (substitute* "compiledb/compiler.py" (("shutilwhich") "shutil")))))))
    (propagated-inputs
      (list python-bashlex python-click))
    (native-inputs
      (list python-pytest))
    (home-page
      "https://github.com/nickdiego/compiledb")
    (synopsis
      "Generate Clang JSON Compilation Database files for make-based build systems")
    (description
     "@code{compiledb} provides a @code{make} python wrapper script which,
besides executing the make build command, updates the JSON compilation
database file corresponding to that build, resulting in a command-line
interface similar to Bear.")
    (license license:gpl3)))

(define-public build
  (package
    (name "build")
    (version "0.3.10")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://www.codesynthesis.com/download/"
                           "build/" (version-major+minor version)
                           "/build-" version ".tar.bz2"))
       (sha256
        (base32 "1lx5rpnmsbip43zpp0a57sl5rm7pjb0y6i2si6rfglfp4p9d3z76"))))
    (build-system gnu-build-system)
    (arguments
     `(#:make-flags (list (string-append "install_prefix=" %output))
       #:tests? #f
       #:phases (modify-phases %standard-phases
                  (delete 'build)
                  (delete 'configure))))
    (home-page "https://www.codesynthesis.com/projects/build/")
    (synopsis "Massively-parallel build system implemented on top of GNU make")
    (description "Build is a massively-parallel software build system
implemented on top of GNU Make, designed with the following tasks in mind:
@itemize
@item configuration
@item building
@item testing
@item installation
@end itemize
Build has features such as:
@itemize
@item Position-independent makefiles.
@item Non-recursive multi-makefile include-based structure.
@item Leaf makefiles are full-fledged GNU makefiles, not just variable definitions.
@item Complete dependency graph.
@item Inter-project dependency tracking.
@item Extensible language/compiler framework.
@end itemize")
    (license license:gpl2+)))

(define-public genie
  (let ((commit "b139103697bbb62db895e4cc7bfe202bcff4ff25")
        (revision "0"))
    (package
      (name "genie")
      (version (git-version "1167" revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/bkaradzic/genie")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "16plshzkyjjzpfcxnwjskrs7i4gg0qn92h2k0rbfl4a79fgmwvwv"))))
      (build-system gnu-build-system)
      (arguments
       (list #:phases #~(modify-phases %standard-phases
                          (delete 'configure)
                          (replace 'install
                            (lambda _
                              (install-file "bin/linux/genie"
                                            (string-append #$output "/bin")))))
             #:tests? #f)) ;no tests
      (home-page "https://github.com/bkaradzic/genie")
      (synopsis "Project generator")
      (description
       "GENie generates projects from Lua scripts, making it easy to apply the
same settings to multiple projects.  It supports generating projects using GNU
Makefiles, JSON Compilation Database, and experimentally Ninja.")
      (license license:bsd-3))))

(define*-public (gnulib-checkout #:key
                                 version
                                 (revision "1")
                                 commit
                                 hash)
  "Return as a package the exact gnulib checkout."
  (package
    (name "gnulib")
    (version (git-version version revision commit))
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://git.savannah.gnu.org/git/gnulib.git/")
             (commit commit)))
       (file-name (git-file-name name version))
       (sha256 hash)
       (snippet
        (with-imported-modules (source-module-closure '((guix build utils)))
          #~(begin
              (use-modules (guix build utils)
                           (ice-9 ftw)
                           (ice-9 rdelim))
              ;; .c, .h and .gperf files whose first line is /* DO NOT EDIT!
              ;; GENERATED AUTOMATICALLY! */ are generated automatically based
              ;; on the unicode database. Since we replace the unicode
              ;; database with our own, we need to regenerate them. So, they
              ;; are removed from the source. They are sprinkled all over the
              ;; place unfortunately, so we can’t exclude whole directories.
              (let ((generated-automatically?
                     (lambda (filename . unused)
                       (and (or (string-suffix? ".c" filename)
                                (string-suffix? ".h" filename)
                                (string-suffix? ".gperf" filename))
                            (call-with-input-file filename
                              (lambda (port)
                                (let ((first-line (read-line port)))
                                  (equal?
                                   first-line
                                   "/* DO NOT EDIT! GENERATED AUTOMATICALLY! */"))))))))
                (for-each delete-file (find-files (getcwd) generated-automatically?)))
              ;; Other files are copied from UCD.
              (for-each delete-file
                        '("tests/unigbrk/GraphemeBreakTest.txt"
                          "tests/uninorm/NormalizationTest.txt"
                          "tests/uniname/UnicodeData.txt"
                          "tests/uniname/NameAliases.txt"
                          ;; FIXME: tests/uniname/HangulSyllableNames.txt
                          ;; seems like a UCD file but it is not distributed
                          ;; with UCD.
                          "tests/uniwbrk/WordBreakTest.txt")))))))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~'(("./gnulib-tool" "bin/")
          ("." "src/gnulib" #:exclude-regexp ("\\.git.*")))
      #:modules '((ice-9 match)
                  (guix build utils)
                  (guix build copy-build-system)
                  ((guix build gnu-build-system) #:prefix gnu:))
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'install 'check
            (assoc-ref gnu:%standard-phases 'check))
          (add-before 'check 'fix-tests
            (lambda _
              (substitute* "Makefile"
                (("-f maint.mk syntax-check")
                 "_gl-Makefile=yes -f maint.mk syntax-check"))
              (invoke "git" "init")
              (invoke "git" "config" "user.name" "Guix")
              (invoke "git" "config" "user.email" "guix@localhost")
              (invoke "git" "add" ".")
              ;; Syntax checks are only run against committed files.
              (invoke "git" "commit" "-m" "Prepare for tests.")))
          (add-before 'check 'disable-failing-tests
            (lambda _
              (substitute* "cfg.mk"
                (("local-checks-to-skip =")
                 ;; sc_copyright_check fails because the fake commit date may
                 ;; be later than the copyright year.
                 "local-checks-to-skip = \\
  sc_Wundef_boolean \\
  sc_copyright_check \\
  sc_file_system \\
  sc_indent \\
  sc_keep_gnulib_texi_files_mostly_ascii \\
  sc_prohibit_assert_without_use \\
  sc_prohibit_close_stream_without_use \\
  sc_prohibit_defined_have_decl_tests \\
  sc_prohibit_doubled_word \\
  sc_prohibit_empty_lines_at_EOF \\
  sc_prohibit_intprops_without_use \\
  sc_prohibit_openat_without_use \\
  sc_prohibit_test_minus_ao \\
  sc_unportable_grep_q"))
              (substitute* "Makefile"
                (("sc_check_(sym_list|copyright)" rule)
                 (string-append "disabled_check_" rule))
                (("sc_cpp_indent_check")
                 "disabled_cpp_indent_check")
                (("sc_prefer_ac_check_funcs_once")
                 "disabled_prefer_ac_check_funcs_once")
                (("sc_prohibit_(AC_LIBOBJ_in_m4|leading_TABs)" rule)
                 (string-append "disabled_prohibit_" rule)))))
          (add-before 'check 'regenerate-unicode
            (lambda* (#:key inputs #:allow-other-keys)
              (define (find-ucd-file name)
                (search-input-file inputs (string-append "share/ucd/" name)))
              (define (find-ucd-files . names)
                (map find-ucd-file names))
              (with-directory-excursion "lib"
                ;; See the compile-command buffer-local variable in
                ;; lib/gen-uni-tables.c
                (invoke "gcc" "-O" "-Wall" "gen-uni-tables.c"
                        "-Iunictype" "-o" "gen-uni-tables")
                (apply invoke
                       "./gen-uni-tables"
                       (append
                        (find-ucd-files "UnicodeData.txt"
                                        "PropList.txt"
                                        "DerivedCoreProperties.txt"
                                        "emoji/emoji-data.txt"
                                        "ArabicShaping.txt"
                                        "Scripts.txt"
                                        "Blocks.txt")
                        (list
                         #$(origin
                             (method url-fetch)
                             (uri (string-append
                                   "https://www.unicode.org/Public/"
                                   "3.0-Update1/PropList-3.0.1.txt"))
                             (sha256
                              (base32
                               "0k6wyijyzdl5g3nibcwfm898kfydx1pqaz28v7fdvnzdvd5fz7lh"))))
                        (find-ucd-files "EastAsianWidth.txt"
                                        "LineBreak.txt"
                                        "auxiliary/WordBreakProperty.txt"
                                        "auxiliary/GraphemeBreakProperty.txt"
                                        "CompositionExclusions.txt"
                                        "SpecialCasing.txt"
                                        "CaseFolding.txt")
                         (list #$(package-version (this-package-native-input "ucd")))))
                (invoke "clisp" "-C" "uniname/gen-uninames.lisp"
                        (find-ucd-file "UnicodeData.txt")
                        "uniname/uninames.h"
                        (find-ucd-file "NameAliases.txt"))
                (for-each
                 (match-lambda
                  ((ucd-file . directory)
                   (copy-file (find-ucd-file ucd-file)
                              (string-append "../tests/" directory "/"
                                             (basename ucd-file)))))
                 '(("NameAliases.txt" . "uniname")
                   ("UnicodeData.txt" . "uniname")
                   ("NormalizationTest.txt" . "uninorm")
                   ("auxiliary/GraphemeBreakTest.txt" . "unigbrk")
                   ("auxiliary/WordBreakTest.txt" . "uniwbrk")))
                (delete-file "gen-uni-tables"))))
          (add-after 'install 'restore-shebangs
            (lambda _
              (substitute* (find-files
                            (string-append #$output "/src/gnulib")
                            (lambda (fname stat)
                              (and (not (string-suffix? "/lib/javaversion.class" fname))
                                   (not (string-suffix? ".mo" fname)))))
                (("^#! ?(.*)/bin/sh" _ prefix)
                 "#!/bin/sh")
                (("^#! ?(.*)/bin/python3" _ prefix)
                 "#!/usr/bin/env python3")
                (("^#! ?(.*)/bin/([a-zA-Z0-9-]+)" _ prefix program)
                 (string-append "#!/usr/bin/" program))))))))
    (inputs
     (list bash-minimal))                         ;shebang for gnulib-tool
    (native-inputs
     (list
      bash-minimal python perl clisp
      ;; Unicode data:
      ucd-next
      ;; Programs for the tests:
      cppi indent git-minimal/pinned autoconf))
    (home-page "https://www.gnu.org/software/gnulib/")
    (synopsis "Source files to share among distributions")
    (description
     "Gnulib is a central location for common infrastructure needed by GNU
packages.  It provides a wide variety of functionality, e.g., portability
across many systems, working with Unicode strings, cryptographic computation,
and much more.  The code is intended to be shared at the level of source
files, rather than being a standalone library that is distributed, built, and
installed.  The included @command{gnulib-tool} script helps with using Gnulib
code in other packages.  Gnulib also includes copies of licensing and
maintenance-related files, for convenience.")
    (native-search-paths
     (list (search-path-specification
            (variable "GNULIB_SRCDIR")
            (files (list "src/gnulib"))
            (separator #f))))
    (license (list license:lgpl2.0+ license:gpl3+))))

(define-public gnulib
  (gnulib-checkout
   #:version "2022-12-31"
   #:commit "875461ffdf58ac04677957b4ae4160465b83b940"
   #:hash (base32 "0bf7a6wdns9c5wwv60qfcn9llg0j6jz5ryd2qgsqqx2i6xkmp77c")))
