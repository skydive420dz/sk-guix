(define-module (sk packages golang)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages golang-build)
  #:use-module (gnu packages golang-check)
  #:use-module (guix build-system go)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages))

(define-public go-github-com-emmansun-base64
  (package
    (name "go-github-com-emmansun-base64")
    (version "0.9.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/emmansun/base64")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0c1i624nkqb3zcrx5gnmynjg2yvlsglygaw7ms8vry5153dr6i51"))))
    (build-system go-build-system)
    (arguments
     (list
      #:go go-1.26
      #:import-path "github.com/emmansun/base64"))
    (propagated-inputs
     (list go-golang-org-x-sys))
    (home-page "https://github.com/emmansun/base64")
    (synopsis "Base64 encoding and decoding for Go")
    (description
     "Package base64 provides Base64 encoding and decoding helpers for Go.")
    (license license:bsd-3)))

(define-public go-github-com-sgtdi-fswatcher
  (package
    (name "go-github-com-sgtdi-fswatcher")
    (version "1.3.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/sgtdi/fswatcher")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "134swn5x2g0dn8nn48f66r49h5mxfl8yrwrlmkargl25mi7yw383"))))
    (build-system go-build-system)
    (arguments
     (list
      #:go go-1.26
      #:import-path "github.com/sgtdi/fswatcher"))
    (native-inputs
     (list go-github-com-stretchr-testify))
    (propagated-inputs
     (list go-golang-org-x-sys))
    (home-page "https://github.com/sgtdi/fswatcher")
    (synopsis "File system watcher for Go")
    (description
     "Package fswatcher provides file system change notification helpers for Go.")
    (license license:expat)))
