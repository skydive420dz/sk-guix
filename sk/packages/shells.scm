(define-module (sk packages shells)
  #:use-module (gnu packages shells)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define %fish-fluent-rs
  (let ((commit "cf712bced280b217b6307edabc2089b3e57204ab"))
    (origin
      (method git-fetch)
      (uri (git-reference
            (url "https://github.com/danielrainer/fluent-rs")
            (commit commit)))
      (file-name (git-file-name "fish-fluent-rs" commit))
      (sha256
       (base32 "0c3qd6cvldfpf46cbb2j4hkbrycq4q6b206qiq8vch1gadrvdr50")))))

(define %fish-fluent-ftl-tools
  (let ((commit "5917664c8f2e4928ef1e480ff5c13bbe1e226066"))
    (origin
      (method git-fetch)
      (uri (git-reference
            (url "https://codeberg.org/danielrainer/fluent-ftl-tools")
            (commit commit)))
      (file-name (git-file-name "fish-fluent-ftl-tools" commit))
      (sha256
       (base32 "0yivm9rpvjfs98rczndab6zfah5gjmbcxkhxjm0c1p31jqrngzj9")))))

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
       ((#:phases phases)
        #~(modify-phases #$phases
            (add-after 'unpack 'vendor-fish-git-dependencies
              (lambda _
                ;; Fish 4.8.0 depends on fixed Fluent Git revisions that are
                ;; not part of Guix's fish 4.7.1 Cargo input set.
                (mkdir-p "sk-vendor")
                (copy-recursively #$%fish-fluent-rs
                                  "sk-vendor/fluent-rs")
                (copy-recursively #$%fish-fluent-ftl-tools
                                  "sk-vendor/fluent-ftl-tools")
                (substitute* "Cargo.toml"
                  (("members = \\[\"crates/\\*\"\\]")
                   "members = [\"crates/*\"]\nexclude = [\"sk-vendor\"]")
                  (("fluent = \\{ git = \"https://github.com/danielrainer/fluent-rs\", rev = \"[^\"]+\" \\}")
                   "fluent = { path = \"sk-vendor/fluent-rs/fluent\" }")
                  (("fluent-syntax = \\{ git = \"https://github.com/danielrainer/fluent-rs\", rev = \"[^\"]+\" \\}")
                   "fluent-syntax = { path = \"sk-vendor/fluent-rs/fluent-syntax\" }")
                  (("fluent-ftl-tools = \\{ git = \"https://codeberg.org/danielrainer/fluent-ftl-tools\", rev = \"[^\"]+\" \\}")
                   "fluent-ftl-tools = { path = \"sk-vendor/fluent-ftl-tools\" }"))
                (substitute* "sk-vendor/fluent-ftl-tools/Cargo.toml"
                  (("fluent = \\{ git = \"https://github.com/danielrainer/fluent-rs\", rev = \"[^\"]+\" \\}")
                   "fluent = { path = \"../fluent-rs/fluent\" }")
                  (("fluent-syntax = \\{ git = \"https://github.com/danielrainer/fluent-rs\", rev = \"[^\"]+\" \\}")
                   "fluent-syntax = { path = \"../fluent-rs/fluent-syntax\" }"))))
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
