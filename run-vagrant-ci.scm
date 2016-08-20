#!read-macro=sagittarius/regex
(import (rnrs)
	(text json)
	(getopt)
	(sagittarius)
	(sagittarius process)
	(sagittarius control)
	(sagittarius regex)
	(srfi :13 strings)
	(srfi :39 parameters)
	(util file)
	(pp))

(define-constant +vagrant-file+ "Vagrantfile")
(define *timeout* (make-parameter 1800)) ;; 30min

(define (execute-plans plans)
  (define os-name (car plans))
  (define versions (cdr plans))
  (define (execute-plan os-name plan)
    (define version (car plan))
    (define commands (cdr plan))
    (define base-dir (build-path os-name version))
    (define work-dir (build-path "platforms" base-dir))
    (define template
      (file->string (string-append (build-path "vagrant" base-dir) ".template")))
    (define provisioning-configuration
      (file->string (build-path* "vagrant" os-name "provisioning.p")))

    (define (resolve-provisioning config commands)
      (define len (vector-length commands))
      (define (replace command)
	(regex-replace-all #/#{packages}/ config command))
      (let loop ((i 0))
	(cond ((= i len) "")
	      ((string=? (car (vector-ref commands i)) "provisioning")
	       (replace (string-join (cdr (vector-ref commands i)))))
	      (else (loop (+ i 1))))))

    (define (resolve-command commands)
      (define len (vector-length commands))
      (let loop ((i 0))
	(cond ((= i len) "")
	      ((string=? (car (vector-ref commands i)) "commands")
	       (string-join (cdr (vector-ref commands i)) "; "))
	      (else (loop (+ i 1))))))
    
    (unless (file-exists? work-dir) (create-directory* work-dir))
    (parameterize ((current-directory work-dir))
      (let* ((provisioning
	      (resolve-provisioning provisioning-configuration commands))
	     (vagrantfile
	      (regex-replace-all #/#{provisioning}/template provisioning))
	     (ssh-command (resolve-command commands)))
	(when (file-exists? +vagrant-file+) (delete-file +vagrant-file+))
	(call-with-output-file +vagrant-file+
	  (lambda (out) (put-string out vagrantfile)))
	(unwind-protect
	 (or (and-let* ((dr (run "vagrant" "destroy" "-f"))
			( (zero? dr) )
			(ur (run "vagrant" "up"))
			( (zero? ur) )
			(p (call "vagrant" "ssh" "--" "-t" ssh-command))
			(r (process-wait p :timeout (*timeout*))))
	       ;; TODO proper result showing
	       (if r (list r) (cons -1 "Process timeout")))
	     (cons -1 "Failed to up"))
	 (run "vagrant" "destroy" "-f")))))

  (do ((len (vector-length versions))
       (i 0 (+ i 1))
       (r '() (cons (execute-plan os-name (vector-ref versions i)) r)))
      ((= i len) r)))

(define (analyse-result results) )

(define (main args)
  (with-args (cdr args)
      ((help      (#\h "help") #f #f)
       (plan-file (#\p "plan") #t "plan.json")
       ;; TODO
       . rest)
    (let ((root-plan (call-with-input-file plan-file json-read)))
      (do ((len (vector-length root-plan))
	   (i 0 (+ i 1))
	   (r '() (cons (execute-plans (vector-ref root-plan i)) r)))
	  ((= i len) (analyse-result r))))))
