#!/usr/bin/picolisp /usr/lib/picolisp/lib.l
#
# picoSIP Internet Chat Client
#
# (c) Alexander Sharikhin
# 21 june 17


(load "@lib/misc.l")

# Starting params 

(setq *Host (opt))
(setq *Port 4004)
(setq *Nick (opt))
(setq *Online NIL)

# Misc funcs 

(de usage NIL
   (prinl "client.l <host> <nick>")
   (bye) )

(de get-line NIL
   (pack (reverse *Line)) )

(de backspace NIL 
   (prin "^H ^H") )

(de clean-line NIL
   (do (length *Line)
      (backspace) ) )

(de termlog (Line)
   (clean-line)
   (prinl (tim$ (time)) " " Line)
   (prin (get-line))
   (flush) ) 

(de is-get (What)
   (= What (in *Connection (line T))) )

(de send-message (Line)
   (out *Connection (prinl Line)) )

(if (not (and *Host *Nick)) (usage))

(setq *Connection (connect *Host *Port))

(unless *Connection (quit (cons "Can't connect to " *Host)))

# AUTH state

(de auth-wait-loop NIL
   (ifn (is-get "AUTH") (auth-wait-loop)) )  

(auth-wait-loop)

(out *Connection (prinl *Nick) (flush))

(in *Connection (unless (is-get "OK") (quit "Auth failed")))

# Chatting state

(setq *Line NIL)

# Received messages 
(task
   *Connection
   (in @
      (setq
         *In (chop (line T))
         *Cmd (car *In)
         *Str (pack (cdr *In)) )
      (case *Cmd
         ("*" (termlog *Str))
         ("+" (termlog (cons *Str " is online")) (push '*Online *Str))
         ("-" (termlog (cons *Str " is offline")) (del *Str '*Online)) ) ) ) 

(loop
   (case (key)
      ("^[" (bye))
      (("^H" "^?") (when *Line (backspace) (pop '*Line)))
      (("^J" "^M")
         (when *Line (send-message (get-line)) (clean-line) (off *Line)) )
      (T (prin (push '*Line @))) ) )
(bye)
