(define-module (sk packages terminals)
  #:use-module (gnu packages terminals)
  #:use-module (sk packages golang)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define-public kitty-latest
  (package
    (inherit kitty)
    (name "kitty-latest")
    (version "0.47.4")
    (source
     (origin
       (inherit (package-source kitty))
       (uri (git-reference
             (url "https://github.com/kovidgoyal/kitty")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1m8sn8hs63qw8n3hvn07pqmnd4grqfr59pxgwa4jq7ivd1nrcfsh"))))
    (native-inputs
     (modify-inputs (package-native-inputs kitty)
       (append go-github-com-emmansun-base64)
       (append go-github-com-sgtdi-fswatcher)))
    (arguments
     (substitute-keyword-arguments (package-arguments kitty)
       ((#:phases phases)
        #~(modify-phases #$phases
            (add-before 'run-python-tests 'skip-container-incompatible-tests
              (lambda _
                ;; Guix's kitty package disables the graphics test module
                ;; because it needs display-server access.  Kitty 0.47.4's
                ;; DnD kitten test imports that disabled module.  The
                ;; machine-id test assumes /etc/machine-id, which is absent in
                ;; Guix build containers.
                (for-each
                 (lambda (test)
                   (when (file-exists? test)
                     (delete-file test)))
                 '("src/github.com/kovidgoyal/kitty/kitty_tests/dnd_kitten.py"
                   "src/github.com/kovidgoyal/kitty/tools/utils/machine_id/api_test.go"))))))))))
