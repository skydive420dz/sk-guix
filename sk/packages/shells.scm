(define-module (sk packages shells)
  #:use-module (gnu packages shells)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define-public fish-latest
  (package
    (inherit fish)
    (name "fish-latest")
    (version "4.8.0")
    (source
     (origin
       (inherit (package-source fish))
       (uri (string-append "https://github.com/fish-shell/fish-shell/"
                           "releases/download/" version "/"
                           "fish-" version ".tar.xz"))
       (sha256
        (base32 "01z7cfxch2n7mkm3c065pz19ikwalip1za2gx3h5799gvz3n5brk"))))
    (arguments
     (substitute-keyword-arguments (package-arguments fish)
       ((#:configure-flags flags)
        #~(append #$flags
                  ;; Fish 4.8.0 moved localization through Git-only Fluent
                  ;; dependencies. Keep the shell source-built and reproducible;
                  ;; revisit localization when Guix main packages that graph.
                  (list "-DWITH_MESSAGE_LOCALIZATION=OFF")))
       ((#:phases phases)
        #~(modify-phases #$phases
            (replace 'patch-tests
              (lambda* (#:key inputs native-inputs #:allow-other-keys)
                (define (delete-file-if-exists file)
                  (when (file-exists? file)
                    (delete-file file)))

                (let* ((coreutils
                        (dirname
                         (dirname
                          (search-input-file
                           (or native-inputs inputs) "bin/pwd"))))
                       (bash
                        (dirname
                         (dirname
                          (search-input-file
                           (or native-inputs inputs) "bin/bash")))))
                  ;; These tests either fail in Guix build containers or assume
                  ;; global filesystem paths. Keep this aligned with Guix's fish
                  ;; package, but tolerate tests that disappeared upstream.
                  (for-each delete-file-if-exists
                            '("tests/checks/jobs.fish"
                              "tests/checks/noshebang.fish"
                              "tests/checks/__fish_posix_shell.fish"
                              "tests/checks/__fish_migrate.fish"))
                  (substitute* "tests/checks/vars_as_commands.fish"
                    (("/usr/bin") "/tmp"))
                  (substitute* "tests/checks/cd.fish"
                    (("cd bin") "cd tmp"))
                  (substitute* (cons* "src/builtins/test.rs"
                                      "src/highlight/file_tester.rs"
                                      "src/highlight/highlight.rs"
                                      (find-files "tests"))
                    (("/bin/sh" sh) (string-append bash sh))
                    (("/usr/bin/en\"") (string-append coreutils "/bin/en\""))
                    (("/usr/bin/e\"") (string-append coreutils "/bin/e\""))
                    (("\"/bin") "\"/tmp")
                    (("\"/usr") "\"/tmp"))
                  (substitute* "tests/checks/colon-delimited-var.fish"
                    (("/usr/bin:a:.:b") "/tmp/bin:a:.:b"))
                  (substitute* "tests/test_driver.py"
                    (("\"cc\"") "\"gcc\"")))))))))))
