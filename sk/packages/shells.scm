(define-module (sk packages shells)
  #:use-module (gnu packages shells)
  #:use-module (guix download)
  #:use-module (guix packages))

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
        (base32 "01z7cfxch2n7mkm3c065pz19ikwalip1za2gx3h5799gvz3n5brk"))))))
