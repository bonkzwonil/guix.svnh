;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015 Ludovic Courtès <ludo@gnu.org>
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

(define-module (guix scripts size)
  #:use-module (guix ui)
  #:use-module (guix store)
  #:use-module (guix monads)
  #:use-module (guix utils)
  #:use-module (guix packages)
  #:use-module (guix derivations)
  #:use-module (gnu packages)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-11)
  #:use-module (srfi srfi-34)
  #:use-module (srfi srfi-37)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 match)
  #:use-module (ice-9 format)
  #:export (profile?
            profile-file
            profile-self-size
            profile-closure-size
            store-profile

            guix-size))

;; Size profile of a store item.
(define-record-type <profile>
  (profile file self-size closure-size)
  profile?
  (file          profile-file)                 ;store item
  (self-size     profile-self-size)            ;size in bytes
  (closure-size  profile-closure-size))        ;size of dependencies in bytes

(define (file-size file)
  "Return the size of bytes of FILE, entering it if FILE is a directory."
  (file-system-fold (const #t)
                    (lambda (file stat result)    ;leaf
                      (+ (stat:size stat) result))
                    (lambda (directory stat result) ;down
                      (+ (stat:size stat) result))
                    (lambda (directory stat result) ;up
                      result)
                    (lambda (file stat result)    ;skip
                      result)
                    (lambda (file stat errno result)
                      (format (current-error-port)
                              "file-size: ~a: ~a~%" file
                              (strerror errno))
                      result)
                    0
                    file
                    lstat))

(define substitutable-path-info*
  (store-lift substitutable-path-info))

(define (store-item-exists? item)
  "Return #t if ITEM is in the store, and protect it from GC.  Otherwise
return #f."
  (lambda (store)
    (add-temp-root store item)
    (values (valid-path? store item) store)))

(define (file-size* item)
  "Like 'file-size', but resort to information from substitutes if ITEM is not
in the store."
  (mlet %store-monad ((exists? (store-item-exists? item)))
    (if exists?
        (return (file-size item))
        (mlet %store-monad ((info (substitutable-path-info* (list item))))
          (match info
            ((info)
             ;; The nar size is an approximation, but a good one.
             (return (substitutable-nar-size info)))
            (()
             (leave (_ "no available substitute information for '~a'~%")
                    item)))))))

(define* (display-profile profile #:optional (port (current-output-port)))
  "Display PROFILE, a list of PROFILE objects, to PORT."
  (define MiB (expt 2 20))

  (format port "~64a ~8a ~a\n"
          (_ "store item") (_ "total") (_ "self"))
  (let ((whole (reduce + 0 (map profile-self-size profile))))
    (for-each (match-lambda
                (($ <profile> name self total)
                 (format port "~64a  ~6,1f  ~6,1f ~5,1f%\n"
                         name (/ total MiB) (/ self MiB)
                         (* 100. (/ self whole 1.)))))
              (sort profile
                    (match-lambda*
                      ((($ <profile> _ _ total1) ($ <profile> _ _ total2))
                       (> total1 total2)))))))

(define display-profile*
  (lift display-profile %store-monad))

(define (substitutable-requisites store item)
  "Return the list of requisites of ITEM based on information available in
substitutes."
  (let loop ((items  (list item))
             (result '()))
    (match items
      (()
       (delete-duplicates result))
      (items
       (let ((info (substitutable-path-info store
                                            (delete-duplicates items))))
         (loop (remove (lambda (item)             ;XXX: complexity
                         (member item result))
                       (append-map substitutable-references info))
               (append (append-map substitutable-references info)
                       result)))))))

(define (requisites* item)
  "Return as a monadic value the requisites of ITEMS, based either on the
information available in the local store or using information about
substitutes."
  (lambda (store)
    (guard (c ((nix-protocol-error? c)
               (values (substitutable-requisites store item)
                       store)))
      (values (requisites store item) store))))

(define (store-profile item)
  "Return as a monadic value a list of <profile> objects representing the
profile of ITEM and its requisites."
  (mlet* %store-monad ((refs  (>>= (requisites* item)
                                   (lambda (refs)
                                     (return (delete-duplicates
                                              (cons item refs))))))
                       (sizes (mapm %store-monad
                                    (lambda (item)
                                      (>>= (file-size* item)
                                           (lambda (size)
                                             (return (cons item size)))))
                                    refs)))
    (define (dependency-size item)
      (mlet %store-monad ((deps (requisites* item)))
        (foldm %store-monad
               (lambda (item total)
                 (return (+ (assoc-ref sizes item) total)))
               0
               (delete-duplicates (cons item deps)))))

    (mapm %store-monad
          (match-lambda
            ((item . size)
             (mlet %store-monad ((dependencies (dependency-size item)))
               (return (profile item size dependencies)))))
          sizes)))

(define* (ensure-store-item spec-or-item)
  "Return a store file name.  If SPEC-OR-ITEM is a store file name, return it
as is.  Otherwise, assume SPEC-OR-ITEM is a package output specification such
as \"guile:debug\" or \"gcc-4.8\" and return its store file name."
  (with-monad %store-monad
    (if (store-path? spec-or-item)
        (return spec-or-item)
        (let-values (((package output)
                      (specification->package+output spec-or-item)))
          (mlet %store-monad ((drv (package->derivation package)))
            ;; Note: we don't try building DRV like 'guix archive' does
            ;; because we don't have to since we can instead rely on
            ;; substitute meta-data.
            (return (derivation->output-path drv output)))))))


;;;
;;; Charts.
;;;

;; Autoload Guile-Charting.
;; XXX: Use this hack instead of #:autoload to avoid compilation errors.
;; See <http://bugs.gnu.org/12202>.
(module-autoload! (current-module)
                  '(charting) '(make-page-map))

(define (profile->page-map profiles file)
  "Write a 'page map' chart of PROFILES, a list of <profile> objects, to FILE,
the name of a PNG file."
  (define (strip name)
    (string-drop name (+ (string-length (%store-prefix)) 28)))

  (define data
    (fold2 (lambda (profile result offset)
             (match profile
               (($ <profile> name self)
                (let ((self (inexact->exact
                             (round (/ self (expt 2. 10))))))
                  (values `((,(strip name) ,offset . ,self)
                            ,@result)
                          (+ offset self))))))
           '()
           0
           (sort profiles
                 (match-lambda*
                   ((($ <profile> _ _ total1) ($ <profile> _ _ total2))
                    (> total1 total2))))))

  ;; TRANSLATORS: This is the title of a graph, meaning that the graph
  ;; represents a profile of the store (the "store" being the place where
  ;; packages are stored.)
  (make-page-map (_ "store profile") data
                 #:write-to-png file))


;;;
;;; Options.
;;;

(define (show-help)
  (display (_ "Usage: guix size [OPTION]... PACKAGE
Report the size of PACKAGE and its dependencies.\n"))
  (display (_ "
  -m, --map-file=FILE    write to FILE a graphical map of disk usage"))
  (display (_ "
  -s, --system=SYSTEM    consider packages for SYSTEM--e.g., \"i686-linux\""))
  (newline)
  (display (_ "
  -h, --help             display this help and exit"))
  (display (_ "
  -V, --version          display version information and exit"))
  (newline)
  (show-bug-report-information))

(define %options
  ;; Specifications of the command-line options.
  (list (option '(#\s "system") #t #f
                (lambda (opt name arg result)
                  (alist-cons 'system arg
                              (alist-delete 'system result eq?))))
        (option '(#\m "map-file") #t #f
                (lambda (opt name arg result)
                  (alist-cons 'map-file arg result)))
        (option '(#\h "help") #f #f
                (lambda args
                  (show-help)
                  (exit 0)))
        (option '(#\V "version") #f #f
                (lambda args
                  (show-version-and-exit "guix size")))))

(define %default-options
  `((system . ,(%current-system))))


;;;
;;; Entry point.
;;;

(define (guix-size . args)
  (with-error-handling
    (let* ((opts     (parse-command-line args %options (list %default-options)))
           (files    (filter-map (match-lambda
                                   (('argument . file) file)
                                   (_ #f))
                                 opts))
           (map-file (assoc-ref opts 'map-file))
           (system   (assoc-ref opts 'system)))
      (match files
        (()
         (leave (_ "missing store item argument\n")))
        ((file)
         (leave-on-EPIPE
          (with-store store
            (run-with-store store
              (mlet* %store-monad ((item    (ensure-store-item file))
                                   (profile (store-profile item)))
                (if map-file
                    (begin
                      (profile->page-map profile map-file)
                      (return #t))
                    (display-profile* profile)))
              #:system system))))
        ((files ...)
         (leave (_ "too many arguments\n")))))))
